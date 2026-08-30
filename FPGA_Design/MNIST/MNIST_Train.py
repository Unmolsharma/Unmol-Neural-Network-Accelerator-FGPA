import torch
import torch.nn as nn
import torchvision
import torchvision.transforms as transforms
import numpy as np
import os

DATA_WIDTH = 16
INT_BITS = 1   # to matches weightIntWidth
FRAC_BITS = DATA_WIDTH - INT_BITS - 1   # 1 sign + 1 int + 14 frac
SCALE = 2 ** FRAC_BITS
OUT_DIR = "weights"

os.makedirs(OUT_DIR, exist_ok=True)


class Net(nn.Module):
    def __init__(self):
        super().__init__()
        self.layers = nn.Sequential(
            nn.Linear(784, 30),
            nn.Sigmoid(),
            nn.Linear(30, 30),
            nn.Sigmoid(),
            nn.Linear(30, 10),
            nn.Sigmoid(),
            nn.Linear(10, 10),
            nn.Sigmoid(),
            nn.Linear(10, 10),
        )
    def forward(self, x):
        return self.layers(x)

transform = transforms.Compose([transforms.ToTensor()])
train_set  = torchvision.datasets.MNIST(root="./data", train=True,  download=True, transform=transform)
test_set   = torchvision.datasets.MNIST(root="./data", train=False, download=True, transform=transform)
train_loader = torch.utils.data.DataLoader(train_set, batch_size=64, shuffle=True)
test_loader  = torch.utils.data.DataLoader(test_set,  batch_size=1000)

model     = Net()
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
criterion = nn.CrossEntropyLoss()

print("Training...")
for epoch in range(10):
    model.train()
    total_loss = 0
    for images, labels in train_loader:
        x = images.view(-1, 784)
        optimizer.zero_grad()
        loss = criterion(model(x), labels)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
    print(f"  Epoch {epoch+1}/10  loss={total_loss/len(train_loader):.4f}")

model.eval()
correct = 0
with torch.no_grad():
    for images, labels in test_loader:
        x = images.view(-1, 784)
        pred = model(x).argmax(dim=1)
        correct += (pred == labels).sum().item()
print(f"Test accuracy: {correct/len(test_set)*100:.2f}%")

def to_fixed_bin(val, width=DATA_WIDTH):
    """Convert float to two's complement binary string of given width."""
    q = int(round(val * SCALE))
    q = max(-(2**(width-1)), min(2**(width-1)-1, q))   # clamp
    if q < 0:
        q = q + (1 << width)
    return format(q, f'0{width}b')

linear_layers = [m for m in model.layers if isinstance(m, nn.Linear)]
layer_map = [
    (1, 784, 30),
    (2, 30,  30),
    (3, 30,  10),
    (4, 10,  10),
    (5, 10,  10),
]

for (layer_no, n_in, n_out), lin in zip(layer_map, linear_layers):
    W = lin.weight.detach().numpy()   # shape [n_out, n_in]
    b = lin.bias.detach().numpy()     # shape [n_out]
    for neuron_no in range(n_out):
        # weights
        wfile = os.path.join(OUT_DIR, f"w_{layer_no}_{neuron_no}.mif")
        with open(wfile, "w") as f:
            for w in W[neuron_no]:
                f.write(to_fixed_bin(w) + "\n")
        # bias
        bfile = os.path.join(OUT_DIR, f"b_{layer_no}_{neuron_no}.mif")
        with open(bfile, "w") as f:
            f.write(to_fixed_bin(b[neuron_no]) + "\n")
