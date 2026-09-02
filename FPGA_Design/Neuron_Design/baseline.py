import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms

DATA_WIDTH = 16
FRAC_BITS  = 14
SCALE      = 2 ** FRAC_BITS
SIGMOID_SIZE = 5

WEIGHTS_DIR = "weights"

def bin_to_signed_int(bstr):
    val = int(bstr, 2)
    if val >= (1 << (len(bstr)-1)):
        val -= (1 << len(bstr))
    return val

def load_mif(path):
    with open(path) as f:
        lines = [l.strip() for l in f if l.strip()]
    return [bin_to_signed_int(l) for l in lines]

# load sigmoid ROM (32 entries for sigmoidSize=5)
sig_rom = load_mif("sigContent.mif")

def sigmoid_lookup(x_top_bits):
    # x_top_bits is a signed 5-bit index, offset to unsigned 0-31
    idx = x_top_bits + (2**(SIGMOID_SIZE-1))
    idx = max(0, min(len(sig_rom)-1, idx))
    return sig_rom[idx]

def neuron_forward(inputs_fixed, weights_fixed, bias_fixed):
    """
    inputs_fixed: list of int16 fixed-point inputs
    weights_fixed: list of int16 fixed-point weights
    bias_fixed: int16 fixed-point bias
    Returns: fixed-point sigmoid output (int16)
    """
    acc = 0
    for x, w in zip(inputs_fixed, weights_fixed):
        prod = x * w  # 32-bit fixed intermediate (Q(FRAC*2))
        acc += prod
    # bias is stored at same scale as one dataWidth value shifted, matches neuron.v: bias <<= dataWidth in hw
    acc += bias_fixed << DATA_WIDTH
    # take top sigmoidSize bits of the 2*dataWidth accumulator, matching sum[2*dataWidth-1 -: sigmoidSize]
    total_bits = 2 * DATA_WIDTH
    shift = total_bits - SIGMOID_SIZE
    top_bits = (acc >> shift) & ((1 << SIGMOID_SIZE) - 1)
    if top_bits >= (1 << (SIGMOID_SIZE - 1)):
        top_bits -= (1 << SIGMOID_SIZE)
    return sigmoid_lookup(top_bits)

def layer_forward(inputs_fixed, layer_no, num_neurons, num_weights):
    outputs = []
    for n in range(num_neurons):
        w = load_mif(f"{WEIGHTS_DIR}/w_{layer_no}_{n}.mif")
        b = load_mif(f"{WEIGHTS_DIR}/b_{layer_no}_{n}.mif")[0]
        out = neuron_forward(inputs_fixed, w, b)
        outputs.append(out)
    return outputs

def to_fixed(val):
    q = int(round(val * SCALE))
    q = max(-(2**(DATA_WIDTH-1)), min(2**(DATA_WIDTH-1)-1, q))
    return q

def to_hex16(q):
    """Convert a signed fixed-point int to a 4-digit two's complement hex string."""
    if q < 0:
        q += (1 << DATA_WIDTH)
    return f"{q:04x}"

def run_network(pixel_values_float):
    x = [to_fixed(p) for p in pixel_values_float]
    x = layer_forward(x, 1, 30, 784)
    x = layer_forward(x, 2, 30, 30)
    x = layer_forward(x, 3, 10, 30)
    x = layer_forward(x, 4, 10, 10)
    x = layer_forward(x, 5, 10, 10)
    return x.index(max(x))  # hardmax

def export_image_hex(pixel_values_float, filename):
    with open(filename, "w") as f:
        for p in pixel_values_float:
            q = to_fixed(p)
            f.write(to_hex16(q) + "\n")

if __name__ == "__main__":
    transform = transforms.Compose([transforms.ToTensor()])
    test_set = torchvision.datasets.MNIST(root="./data", train=False, download=True, transform=transform)
    image, label = test_set[0]
    pixels = image.view(-1).tolist()

    export_image_hex(pixels, "test_image_0_hex.txt")

    pred = run_network(pixels)
    print(f"True label: {label}  Predicted: {pred}")