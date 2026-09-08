"""Compare RTL predictions against the Python fixed-point baseline.

Run after:
    python baseline.py <N>
    iverilog -g2012 -o nn_tb.vvp nn_tb.sv Neural_Network.v layer.v Serializer.sv \
        hardmax.sv neuron.v Weight_Memory.v Sig_ROM.v ReLU.v
    vvp nn_tb.vvp

Note that nn_tb.sv already self-checks against baseline_predictions.txt and
exits non-zero on any mismatch, so this script is now a convenience rather
than the primary check.
"""

def read_ints(path):
    with open(path) as f:
        return [int(line.strip()) for line in f if line.strip()]

rtl = read_ints("rtl_predictions.txt")
base = read_ints("baseline_predictions.txt")

n = min(len(rtl), len(base))
if len(rtl) != len(base):
    print(f"WARNING: length mismatch (rtl={len(rtl)}, baseline={len(base)}); comparing first {n}")

mismatches = [(i, r, b) for i, (r, b) in enumerate(zip(rtl[:n], base[:n])) if r != b]
agree = n - len(mismatches)

print(f"RTL/software agreement: {agree}/{n} = {100.0*agree/n:.2f}%")
if mismatches:
    print(f"\n{len(mismatches)} mismatch(es):")
    for i, r, b in mismatches[:20]:
        print(f"  image {i}: RTL={r} baseline={b}")
    if len(mismatches) > 20:
        print(f"  ... and {len(mismatches)-20} more")
else:
    print("All predictions match.")
