"""Train the 784-30-30-10-10-10 sigmoid MLP and export it as .mif files for the RTL."""

import os
import sys
import time

import torch
import torch.nn as nn
import torchvision
import torchvision.transforms as transforms

#fixed-point format
DATA_WIDTH       = 16
WEIGHT_INT_WIDTH = 2                                     
FRAC_BITS        = DATA_WIDTH - 1 - WEIGHT_INT_WIDTH     # 1 sign + 2 int + 13 frac
BIAS_FRAC        = 2 * FRAC_BITS - DATA_WIDTH           
SCALE            = 2 ** FRAC_BITS

W_MAX = ((1 << (DATA_WIDTH - 1)) - 1) / SCALE            # +-3.99988
B_MAX = ((1 << (DATA_WIDTH - 1)) - 1) / 2 ** BIAS_FRAC   # +-31.99902

OUT_DIR   = "weights"
MIRROR_DIR = os.path.join("..", "Neuron_Design", "weights")
EPOCHS  = int(sys.argv[1]) if len(sys.argv) > 1 else 60

os.makedirs(OUT_DIR, exist_ok=True)
torch.manual_seed(0)


class Net(nn.Module):
    def __init__(self):
        super().__init__()
        self.layers = nn.Sequential(
            nn.Linear(784, 30), nn.Sigmoid(),
            nn.Linear(30, 30),  nn.Sigmoid(),
            nn.Linear(30, 10),  nn.Sigmoid(),
            nn.Linear(10, 10),  nn.Sigmoid(),
            nn.Linear(10, 10),
        )
        # Xavier init suits sigmoid far better than PyTorch's Kaiming-uniform default;
        for m in self.layers:
            if isinstance(m, nn.Linear):
                nn.init.xavier_uniform_(m.weight, gain=1.0)
                nn.init.zeros_(m.bias)

    def forward(self, x):
        return self.layers(x)


def clamp_to_representable(model):
    """Projected-gradient step: keep every parameter inside the .mif range."""
    with torch.no_grad():
        for name, p in model.named_parameters():
            p.clamp_(-W_MAX, W_MAX) if "weight" in name else p.clamp_(-B_MAX, B_MAX)


def evaluate(model, loader):
    model.eval()
    correct = total = 0
    with torch.no_grad():
        for images, labels in loader:
            pred = model(images.view(-1, 784)).argmax(dim=1)
            correct += (pred == labels).sum().item()
            total += labels.numel()
    return 100.0 * correct / total


def to_fixed_bin(val, frac_bits, width=DATA_WIDTH):
    """Float -> two's complement binary string, saturating."""
    q = int(round(val * (2 ** frac_bits)))
    q = max(-(2 ** (width - 1)), min(2 ** (width - 1) - 1, q))
    if q < 0:
        q += 1 << width
    return format(q, "0{}b".format(width))


def export(model):
    linear_layers = [m for m in model.layers if isinstance(m, nn.Linear)]
    layer_map = [(1, 784, 30), (2, 30, 30), (3, 30, 10), (4, 10, 10), (5, 10, 10)]
    dirs = [d for d in (OUT_DIR, MIRROR_DIR) if os.path.isdir(d)]
    clipped = 0
    for (layer_no, n_in, n_out), lin in zip(layer_map, linear_layers):
        W = lin.weight.detach().numpy()
        b = lin.bias.detach().numpy()
        clipped += int((abs(W) > W_MAX).sum() + (abs(b) > B_MAX).sum())
        for neuron_no in range(n_out):
            wtxt = "".join(to_fixed_bin(w, FRAC_BITS) + "\n" for w in W[neuron_no])
            btxt = to_fixed_bin(b[neuron_no], BIAS_FRAC) + "\n"
            for d in dirs:
                with open(os.path.join(d, "w_{}_{}.mif".format(layer_no, neuron_no)), "w") as f:
                    f.write(wtxt)
                with open(os.path.join(d, "b_{}_{}.mif".format(layer_no, neuron_no)), "w") as f:
                    f.write(btxt)
    return clipped, dirs


if __name__ == "__main__":
    transform  = transforms.Compose([transforms.ToTensor()])
    train_set  = torchvision.datasets.MNIST(root="./data", train=True,  download=True, transform=transform)
    test_set   = torchvision.datasets.MNIST(root="./data", train=False, download=True, transform=transform)
    train_load = torch.utils.data.DataLoader(train_set, batch_size=128, shuffle=True)
    test_load  = torch.utils.data.DataLoader(test_set,  batch_size=2500)

    model     = Net()
    optimizer = torch.optim.Adam(model.parameters(), lr=3e-3, weight_decay=1e-5)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=EPOCHS)
    criterion = nn.CrossEntropyLoss()

    print("Format: Q{}.{} weights, Q?.{} biases, accumulator {} bits / {} frac".format(
        WEIGHT_INT_WIDTH, FRAC_BITS, BIAS_FRAC, 2 * DATA_WIDTH, 2 * FRAC_BITS))
    print("Training for {} epochs...".format(EPOCHS))

    best_acc, t0 = -1.0, time.time()
    for epoch in range(EPOCHS):
        model.train()
        total_loss = 0.0
        for images, labels in train_load:
            optimizer.zero_grad()
            loss = criterion(model(images.view(-1, 784)), labels)
            loss.backward()
            optimizer.step()
            clamp_to_representable(model)
            total_loss += loss.item()
        scheduler.step()
        acc = evaluate(model, test_load)
        if acc > best_acc:
            best_acc = acc
            torch.save(model.state_dict(), "best_model.pt")
        print("  epoch {:3d}/{}  loss={:.4f}  test={:.2f}%  ({:.0f}s)".format(
            epoch + 1, EPOCHS, total_loss / len(train_load), acc, time.time() - t0), flush=True)

    model.load_state_dict(torch.load("best_model.pt"))
    print("Best float test accuracy: {:.2f}%".format(evaluate(model, test_load)))
    clipped, dirs = export(model)
    print("Exported to {} ({} parameters needed clipping)".format(", ".join(dirs), clipped))
