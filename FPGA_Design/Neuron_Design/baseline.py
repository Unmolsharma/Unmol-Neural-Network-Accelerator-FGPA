
import sys

import torchvision
import torchvision.transforms as transforms

DATA_WIDTH = 16
WEIGHT_INT_WIDTH = 2                           
FRAC_BITS  = DATA_WIDTH - 1 - WEIGHT_INT_WIDTH  
SCALE      = 2 ** FRAC_BITS
WEIGHTS_DIR = "weights"

# neuron.v loads the bias into the TOP half of the accumulator
# (bias <= {biasReg[dataWidth-1:0], {dataWidth{1'b0}}}), scaling it by 2**DATA_WIDTH,
# so b_*.mif is quantised with this many fractional bits rather than FRAC_BITS.
BIAS_FRAC  = 2 * FRAC_BITS - DATA_WIDTH

# (layer number, neurons)
LAYERS = [(1, 30), (2, 30), (3, 10), (4, 10), (5, 10)]


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
            l = l[-width:]          #keep rightmost `width` bits
        elif len(l) < width:
            l = l.zfill(width)      #zero-pad on the left
        vals.append(bin_to_signed_int(l))
    return vals



sig_rom = load_mif_fixed_width("sigContent.mif")
SIGMOID_SIZE = len(sig_rom).bit_length() - 1
assert len(sig_rom) == 2 ** SIGMOID_SIZE, \
    f"sigContent.mif has {len(sig_rom)} entries, expected a power of two"


def sigmoid_lookup(x_top_bits):
    # Sig_ROM.v re-centres the signed index to offset binary: addr = signed(x) + 2**(n-1)
    idx = x_top_bits + (2**(SIGMOID_SIZE-1))
    idx = max(0, min(len(sig_rom)-1, idx))
    return sig_rom[idx]


def sat_add(a, b, bits):
    """Saturating add matching neuron.v's overflow clamp logic."""
    max_val = (1 << (bits - 1)) - 1
    min_val = -(1 << (bits - 1))
    result = a + b

    if a >= 0 and b >= 0 and result > max_val:
        return max_val
    elif a < 0 and b < 0 and result < min_val:
        return min_val
    else:
        return signed_nbit(result, bits)


def neuron_forward(inputs_fixed, weights_fixed, bias_fixed):
    acc = 0
    for x, w in zip(inputs_fixed, weights_fixed):
        prod = signed_nbit(x * w, 2 * DATA_WIDTH)
        acc = sat_add(acc, prod, 2 * DATA_WIDTH)

    bias_term = signed_nbit(bias_fixed << DATA_WIDTH, 2 * DATA_WIDTH)
    acc = sat_add(acc, bias_term, 2 * DATA_WIDTH)

    shift = 2 * DATA_WIDTH - SIGMOID_SIZE
    top_bits = (acc >> shift) & ((1 << SIGMOID_SIZE) - 1)
    if top_bits >= (1 << (SIGMOID_SIZE - 1)):
        top_bits -= (1 << SIGMOID_SIZE)
    return sigmoid_lookup(top_bits)


_param_cache = {}


def load_layer_params(layer_no, n):
    """Cached .mif load -- re-reading these per image dominated the runtime."""
    key = (layer_no, n)
    if key not in _param_cache:
        _param_cache[key] = (
            load_mif_fixed_width(f"{WEIGHTS_DIR}/w_{layer_no}_{n}.mif"),
            load_mif_fixed_width(f"{WEIGHTS_DIR}/b_{layer_no}_{n}.mif")[0],
        )
    return _param_cache[key]


def layer_forward(inputs_fixed, layer_no, num_neurons):
    outputs = []
    for n in range(num_neurons):
        w, b = load_layer_params(layer_no, n)
        outputs.append(neuron_forward(inputs_fixed, w, b))
    return outputs


def to_fixed(val):
    q = int(round(val * SCALE))
    return max(-(2**(DATA_WIDTH-1)), min(2**(DATA_WIDTH-1)-1, q))


def to_hex16(q):
    """Convert a signed fixed-point int to a 4-digit two's complement hex string."""
    if q < 0:
        q += (1 << DATA_WIDTH)
    return f"{q:04x}"


def run_network(pixel_values_float, verbose=False):
    x = [to_fixed(p) for p in pixel_values_float]
    for layer_no, num_neurons in LAYERS:
        x = layer_forward(x, layer_no, num_neurons)
        if verbose:
            print(f"Layer {layer_no}:", x)
    return x.index(max(x))      # hardmax


def export_images_hex(images_pixels, filename):
    """Write N images back-to-back, 784 lines each, for $readmemh."""
    with open(filename, "w") as f:
        for pixels in images_pixels:
            for p in pixels:
                f.write(to_hex16(to_fixed(p)) + "\n")


if __name__ == "__main__":
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
        for pixels in all_pixels:
            p = run_network(pixels, verbose=(num_images == 1))
            preds.append(p)
            f.write(f"{p}\n")

    correct = sum(1 for p, l in zip(preds, labels) if p == l)
    print(f"Exported {num_images} images -> test_images_hex.txt")
    print(f"Baseline predictions -> baseline_predictions.txt")
    print(f"Baseline accuracy vs true labels: {correct}/{num_images} = {100.0*correct/num_images:.1f}%")
