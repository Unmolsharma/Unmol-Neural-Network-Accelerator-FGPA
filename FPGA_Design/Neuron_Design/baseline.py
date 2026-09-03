import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms

DATA_WIDTH = 16
FRAC_BITS  = 14
SCALE      = 2 ** FRAC_BITS
SIGMOID_SIZE = 5

WEIGHTS_DIR = "weights"

def signed_nbit(value, bits):
    value &= (1 << bits) - 1
    if value >= (1 << (bits - 1)):
        value -= (1 << bits)
    return value

def bin_to_signed_int(bstr):
    val = int(bstr, 2)
    if val >= (1 << (len(bstr)-1)):
        val -= (1 << len(bstr))
    return val

def load_mif_fixed_width(path, width=DATA_WIDTH):
    """Mimics Verilog $readmemb loading into a fixed-width register:
       truncate excess high bits, zero-pad if too short."""
    with open(path) as f:
        lines = [l.strip() for l in f if l.strip()]
    vals = []
    for l in lines:
        if len(l) > width:
            l = l[-width:]          # keep rightmost `width` bits
        elif len(l) < width:
            l = l.zfill(width)      # zero-pad on the left
        vals.append(bin_to_signed_int(l))
    return vals

# load sigmoid ROM (32 entries for sigmoidSize=5)
sig_rom = load_mif_fixed_width("sigContent.mif")

def sigmoid_lookup(x_top_bits):
    # x_top_bits is a signed 5-bit index, offset to unsigned 0-31
    idx = x_top_bits + (2**(SIGMOID_SIZE-1))
    idx = max(0, min(len(sig_rom)-1, idx))
    return sig_rom[idx]

def sat_add(a, b, bits):
    """Saturating add matching neuron.v's overflow clamp logic."""
    max_val = (1 << (bits - 1)) - 1
    min_val = -(1 << (bits - 1))
    result = a + b
    a_sign = a < 0
    b_sign = b < 0
    result_sign = result < min_val or result > max_val

    if not a_sign and not b_sign and (result > max_val):
        return max_val
    elif a_sign and b_sign and (result < min_val):
        return min_val
    else:
        return signed_nbit(result, bits)

def neuron_forward(inputs_fixed, weights_fixed, bias_fixed):
    acc = 0
    for x, w in zip(inputs_fixed, weights_fixed):
        prod = x * w
        prod = signed_nbit(prod, 2 * DATA_WIDTH)
        acc = sat_add(acc, prod, 2 * DATA_WIDTH)

    bias_term = bias_fixed << DATA_WIDTH
    bias_term = signed_nbit(bias_term, 2 * DATA_WIDTH)
    acc = sat_add(acc, bias_term, 2 * DATA_WIDTH)

    total_bits = 2 * DATA_WIDTH
    shift = total_bits - SIGMOID_SIZE
    top_bits = (acc >> shift) & ((1 << SIGMOID_SIZE) - 1)
    if top_bits >= (1 << (SIGMOID_SIZE - 1)):
        top_bits -= (1 << SIGMOID_SIZE)
    return sigmoid_lookup(top_bits)

def layer_forward(inputs_fixed, layer_no, num_neurons, num_weights):
    outputs = []
    for n in range(num_neurons):
        w = load_mif_fixed_width(f"{WEIGHTS_DIR}/w_{layer_no}_{n}.mif")
        b = load_mif_fixed_width(f"{WEIGHTS_DIR}/b_{layer_no}_{n}.mif")[0]
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

def run_network(pixel_values_float, verbose=False):
    x = [to_fixed(p) for p in pixel_values_float]

    x = layer_forward(x, 1, 30, 784)
    if verbose: print("Layer 1:", x)

    x = layer_forward(x, 2, 30, 30)
    if verbose: print("Layer 2:", x)

    x = layer_forward(x, 3, 10, 30)
    if verbose: print("Layer 3:", x)

    x = layer_forward(x, 4, 10, 10)
    if verbose: print("Layer 4:", x)

    x = layer_forward(x, 5, 10, 10)
    if verbose: print("Layer 5:", x)

    return x.index(max(x))

def export_images_hex(images_pixels, filename):
    """Write N images back-to-back, 784 lines each, for $readmemh."""
    with open(filename, "w") as f:
        for pixels in images_pixels:
            for p in pixels:
                f.write(to_hex16(to_fixed(p)) + "\n")

if __name__ == "__main__":
    import sys
    num_images = int(sys.argv[1]) if len(sys.argv) > 1 else 100

    transform = transforms.Compose([transforms.ToTensor()])
    test_set = torchvision.datasets.MNIST(root="./data", train=False, download=True, transform=transform)

    all_pixels, labels = [], []
    for i in range(num_images):
        image, label = test_set[i]
        all_pixels.append(image.view(-1).tolist())
        labels.append(label)

    # stimulus consumed by nn_tb.v
    export_images_hex(all_pixels, "test_images_hex.txt")
    # single-image file kept for the original single-image flow
    export_images_hex(all_pixels[:1], "test_image_0_hex.txt")

    preds = []
    with open("baseline_predictions.txt", "w") as f:
        for i, pixels in enumerate(all_pixels):
            p = run_network(pixels, verbose=(num_images == 1))
            preds.append(p)
            f.write(f"{p}\n")

    correct = sum(1 for p, l in zip(preds, labels) if p == l)
    print(f"Exported {num_images} images -> test_images_hex.txt")
    print(f"Baseline predictions -> baseline_predictions.txt")
    print(f"Baseline accuracy vs true labels: {correct}/{num_images} = {100.0*correct/num_images:.1f}%")