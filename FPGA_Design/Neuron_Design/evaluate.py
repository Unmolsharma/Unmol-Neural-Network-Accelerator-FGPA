"""Bit-exact accuracy sweep of the accelerator over the MNIST test set.

Same arithmetic as baseline.py but vectorised over the whole batch, since the
per-image reference is far too slow for 10,000 images. That includes neuron.v's
*sequential* saturating accumulation: the running sum clamps as it goes, so the
result is order-dependent and not the same as clamping the exact total once.
"""

import sys

import numpy as np
import torchvision
import torchvision.transforms as transforms

DATA_WIDTH = 16
WEIGHT_INT_WIDTH = 2                             # `weightIntWidth in include.v
FRAC_BITS  = DATA_WIDTH - 1 - WEIGHT_INT_WIDTH   # activations/weights are Q2.13
ACC_BITS   = 2 * DATA_WIDTH
ACC_MAX    = (1 << (ACC_BITS - 1)) - 1
ACC_MIN    = -(1 << (ACC_BITS - 1))

LAYERS = [(1, 784, 30), (2, 30, 30), (3, 30, 10), (4, 10, 10), (5, 10, 10)]
WEIGHTS_DIR = "weights"


def bin_to_signed(bits, width=DATA_WIDTH):
    bits = bits[-width:].zfill(width)
    v = int(bits, 2)
    return v - (1 << width) if v >= (1 << (width - 1)) else v


def load_mif(path, width=DATA_WIDTH):
    with open(path) as f:
        return [bin_to_signed(l.strip(), width) for l in f if l.strip()]


def load_network(wdir=WEIGHTS_DIR):
    net = []
    for layer_no, n_in, n_out in LAYERS:
        W = np.array([load_mif(f"{wdir}/w_{layer_no}_{n}.mif") for n in range(n_out)], dtype=np.int64)
        b = np.array([load_mif(f"{wdir}/b_{layer_no}_{n}.mif")[0] for n in range(n_out)], dtype=np.int64)
        assert W.shape == (n_out, n_in), f"layer {layer_no}: got {W.shape}, expected {(n_out, n_in)}"
        net.append((W, b))
    return net


def load_rom(path="sigContent.mif"):
    rom = np.array(load_mif(path), dtype=np.int64)
    size = len(rom).bit_length() - 1
    assert len(rom) == 2 ** size, f"{path}: {len(rom)} entries is not a power of two"
    return rom, size


def sat_add(a, b):
    """Vectorised two's complement saturating add, matching neuron.v's clamp."""
    r = a + b
    r = np.where((a >= 0) & (b >= 0) & (r > ACC_MAX), ACC_MAX, r)
    r = np.where((a < 0) & (b < 0) & (r < ACC_MIN), ACC_MIN, r)
    return r


def forward(X, net, rom, sig_size, stats=None):
    """X: (N, 784) int64 fixed point -> (N, 10) final layer outputs."""
    half = 1 << (sig_size - 1)
    shift = ACC_BITS - sig_size
    for li, (W, b) in enumerate(net):
        acc = np.zeros((X.shape[0], W.shape[0]), dtype=np.int64)
        for k in range(W.shape[1]):                       # one weight index per cycle
            acc = sat_add(acc, X[:, k, None] * W[None, :, k])
        acc = sat_add(acc, (b << DATA_WIDTH)[None, :])    # bias added last, as in neuron.v
        if stats is not None:
            stats.append((li + 1, int(((acc == ACC_MAX) | (acc == ACC_MIN)).sum()), acc.size))
        X = rom[(acc >> shift) + half]
    return X


def load_test_set(n):
    ds = torchvision.datasets.MNIST(root="./data", train=False, download=True,
                                    transform=transforms.ToTensor())
    n = min(n, len(ds))
    imgs = np.stack([np.asarray(ds[i][0]).reshape(-1) for i in range(n)])
    labels = np.array([ds[i][1] for i in range(n)])
    q = np.clip(np.round(imgs * (2 ** FRAC_BITS)), -(1 << (DATA_WIDTH - 1)),
                (1 << (DATA_WIDTH - 1)) - 1).astype(np.int64)
    return q, labels


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 10000

    X, labels = load_test_set(n)
    net = load_network()
    rom, sig_size = load_rom()

    stats = []
    out = forward(X, net, rom, sig_size, stats)
    pred = out.argmax(axis=1)
    correct = int((pred == labels).sum())

    # hardmax picks the lowest index on a tie, i.e. the LUT could not separate the top two
    ties = int(((out == out.max(axis=1, keepdims=True)).sum(axis=1) > 1).sum())

    print(f"LUT: {len(rom)} x {DATA_WIDTH}-bit entries (sigmoidSize={sig_size})")
    for layer, sat, total in stats:
        if sat:
            print(f"  layer {layer}: {sat}/{total} accumulators saturated")
    print(f"  output ties at hardmax: {ties}/{len(labels)}")
    print(f"ACCURACY: {correct}/{len(labels)} = {100.0 * correct / len(labels):.2f}%")
