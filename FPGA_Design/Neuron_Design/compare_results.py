"""Compare RTL predictions against the Python fixed-point baseline.

Run after:
    python baseline.py <N>
    iverilog -o nn_tb.vvp -g2005 nn_tb.v Neural_Network.v layer.v Serializer.v \
        hardmax.v neuron.v Weight_Memory.v Sig_ROM.v ReLU.v
    vvp nn_tb.vvp
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
