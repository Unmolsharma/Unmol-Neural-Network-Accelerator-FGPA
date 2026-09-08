# FPGA Neural Network Accelerator

A fully synthesizable hardware implementation of a multilayer neural network for MNIST handwritten digit classification, written in Verilog. Every neuron is a physical digital circuit — multiply, accumulate, activate — running inference entirely in hardware with no CPU or GPU.

**95.24% accuracy** on MNIST · **Bit-exact RTL/software agreement** · **Synthesized for Lattice ECP5 FPGA**

---

## Results

| Metric | Value |
|---|---|
| Test accuracy (hardware) | 95.24% (10,000 images) |
| Test accuracy (float model) | 95.26% |
| Quantization loss | 0.02% |
| RTL vs Python agreement | 100% (bit-exact) |
| Inference latency | ~900 clock cycles |
| Max clock frequency | 22.34 MHz |
| Throughput | ~24,800 inferences/sec |

### FPGA Resource Utilization (Lattice ECP5-85K)

| Resource | Count | Description |
|---|---|---|
| LUT4 | 4,945 | Combinational logic |
| TRELLIS_FF | 7,597 | Flip-flops / registers |
| DP16KD | 90 | Block RAMs (weight storage) |
| MULT18X18D | 90 | Hardware DSP multipliers |
| CCU2C | 1,878 | Carry chain cells (adders) |

Synthesized with Yosys + nextpnr-ecp5 (OSS CAD Suite).

---

## Network Architecture

A 5-layer fully-connected feedforward network trained on MNIST (28×28 grayscale images, 10 digit classes).

```
Input: 784 pixels (28×28 flattened)
  │
  ▼
Layer 1: 784 → 30 neurons, sigmoid
  │
  ▼
Layer 2:  30 → 30 neurons, sigmoid
  │
  ▼
Layer 3:  30 → 10 neurons, sigmoid
  │
  ▼
Layer 4:  10 → 10 neurons, sigmoid
  │
  ▼
Layer 5:  10 → 10 neurons, sigmoid
  │
  ▼
Hardmax → predicted digit (0–9)
```

---

## Hardware Architecture

### Design Philosophy

Each layer computes all of its neurons **in parallel** — that's the advantage of doing this in hardware. Each individual neuron processes its inputs **serially** (one per clock cycle) using a single multiplier, trading area for time. A serializer module between each pair of layers converts the parallel output bus into a serial input stream for the next layer.

### Module Hierarchy

```
NeuralNetwork (top level)
├── layer (Layer 1: 784→30)
│   └── neuron × 30
│       ├── Weight_Memory (per-neuron weight ROM)
│       └── Sig_ROM (1024-entry sigmoid lookup table)
├── serializer (30 parallel → serial)
├── layer (Layer 2: 30→30)
├── serializer
├── layer (Layer 3: 30→10)
├── serializer
├── layer (Layer 4: 10→10)
├── serializer
├── layer (Layer 5: 10→10)
└── hardmax (argmax of 10 outputs → predicted digit)
```

### Neuron Datapath

Each neuron performs a multiply-accumulate (MAC) operation with saturating arithmetic:

1. Receives one input per clock cycle
2. Multiplies it by the corresponding weight from a private ROM
3. Accumulates with **saturation** — overflow clamps to max/min instead of wrapping
4. After all inputs: adds the bias (also from ROM)
5. Passes the result through a 1024-entry sigmoid lookup table
6. Outputs the 16-bit fixed-point activation

### Fixed-Point Representation

| Parameter | Value |
|---|---|
| Data width | 16 bits |
| Weight format | Q2.13 (1 sign, 2 integer, 13 fraction) |
| Accumulator width | 32 bits |
| Sigmoid LUT | 1024 entries × 16 bits (10-bit index) |
| Scale factor | 2¹³ = 8192 |

---

## Pipeline Timing

A single inference takes approximately 900 clock cycles:

```
Cycles 1–784:    Feed 784 pixel values into Layer 1
                      ↓ (pipeline delay)
Layer 1 valid →  Serializer streams 30 values into Layer 2
                      ↓
Layer 2 valid →  Serializer streams 30 values into Layer 3
                      ↓
Layer 3 valid →  Serializer streams 10 values into Layer 4
                      ↓
Layer 4 valid →  Serializer streams 10 values into Layer 5
                      ↓
Layer 5 valid →  Hardmax outputs predicted digit
```

At 22.34 MHz, this gives ~40 µs per inference, or ~24,800 classifications per second.

---

## Training Pipeline

The network is trained in Python using PyTorch, then quantized and exported to hardware-readable format.

### Key Training Decisions

- **Xavier initialization** — essential for a 5-layer sigmoid network. Default PyTorch (Kaiming) initialization puts neurons in the flat regions of sigmoid where gradients vanish. Xavier keeps activations in the steep part of the S-curve so all layers can learn. First-epoch accuracy: 78.8% (Xavier) vs 26% (default).

- **Weight clamping during training** — weights are clamped to the representable Q2.13 range during training so nothing gets clipped on export. Zero parameters are lost to quantization.

- **Bias scaling** — biases are exported with 10 fractional bits (not 13 like weights) because the hardware left-shifts the bias by 16 bits into the 26-fractional-bit accumulator. Mismatched scaling was one of the bugs found and fixed during development.

### Export

`MNIST_Train.py` exports 180 `.mif` files (90 weight files + 90 bias files, one per neuron), plus the 1024-entry sigmoid lookup table (`sigContent.mif`). All values are 16-bit two's complement binary, zero-padded to exactly 16 digits per line for correct `$readmemb` loading in Verilog.

---

## Verification

The project includes a Python reference model (`baseline.py`) that replicates the exact fixed-point arithmetic of the Verilog hardware:

- Same saturating 32-bit accumulator
- Same sigmoid lookup table and addressing
- Same bias scaling and shifting
- Same truncation/padding behavior as `$readmemb`

Both RTL (Icarus Verilog simulation) and Python produce **identical predictions** on every test image, confirmed across 100 images with 100% agreement. The testbench (`nn_tb.sv`) checks every prediction against the Python baseline as it runs and fails the simulation on the first disagreement.

---

## Repository Structure

```
FPGA_Design/
├── MNIST/
│   └── MNIST_Train.py          # PyTorch training + fixed-point weight export
│
├── Neuron_Design/
│   ├── Neural_Network.v        # Top-level: 5 layers + serializers + hardmax
│   ├── layer.v                 # Instantiates 30 neuron slots in parallel
│   ├── neuron.v                # MAC + saturating accumulator + activation
│   ├── Weight_Memory.v         # Per-neuron weight ROM (loaded from .mif)
│   ├── Sig_ROM.v               # 1024-entry sigmoid lookup table
│   ├── Serializer.sv           # Parallel-to-serial converter between layers
│   ├── hardmax.sv              # Argmax of final 10 outputs
│   ├── ReLU.v                  # Alternative activation (available, unused)
│   ├── include.v               # Global defines and parameters
│   ├── nn_tb.sv                # Full-network testbench (SystemVerilog, self-checking)
│   ├── neuron_tb.sv            # Single-neuron testbench (self-checking)
│   ├── baseline.py             # Python reference model (bit-exact)
│   ├── evaluate.py             # Full test-set evaluation
│   ├── sigContent.mif          # Sigmoid lookup table (1024 × 16-bit)
│   └── weights/                # 180 .mif files (90 weight + 90 bias)
│
└── Activation_Function/
    └── gensigmoid.py           # Sigmoid LUT generator
```

---

## How to Run

### Prerequisites

- **Icarus Verilog** (`iverilog`, `vvp`) — simulation
- **Python 3** with PyTorch and torchvision — training and baseline
- **Yosys + nextpnr** (optional) — FPGA synthesis

### Train and Export Weights

```bash
cd FPGA_Design/MNIST
python MNIST_Train.py
```

This trains for 60 epochs with Xavier initialization, exports all weight/bias `.mif` files to both `MNIST/weights/` and `Neuron_Design/weights/`, and saves `best_model.pt`.

### Run the Python Baseline

```bash
cd FPGA_Design/Neuron_Design
python baseline.py
```

Outputs the predicted digit and true label for the first MNIST test image.

### Simulate the Hardware

The full-network testbench is SystemVerilog, so it needs `-g2012`:

```bash
cd FPGA_Design/Neuron_Design
iverilog -g2012 -o nn_tb.vvp nn_tb.sv Neural_Network.v layer.v Serializer.sv \
    hardmax.sv neuron.v Weight_Memory.v Sig_ROM.v ReLU.v
vvp nn_tb.vvp
```

It self-checks against `baseline_predictions.txt` and exits non-zero on any
mismatch, timeout, or missing stimulus, so it can be run directly in CI. All
of its knobs are runtime plusargs -- none of them need a rebuild:

| Plusarg | Default | Meaning |
|---|---|---|
| `+images=N` | 100 | How many images to classify |
| `+imagefile=<path>` | `test_images_hex.txt` | Stimulus file |
| `+golden=<path>` | `baseline_predictions.txt` | Reference predictions (self-check skipped if absent) |
| `+results=<path>` | `rtl_predictions.txt` | Where predictions are written |
| `+timeout=N` | 5000 | Watchdog cycles per image |
| `+dump` | off | Write `nn_tb.vcd` |
| `+quiet` | off | Summary only, no per-image lines |

```bash
vvp nn_tb.vvp +images=10          # quick smoke test
vvp nn_tb.vvp +quiet              # summary only
vvp nn_tb.vvp +dump               # waveforms for GTKWave
```

The only compile-time knob left is the stimulus array size, because
`$readmemh` can only fill a static memory. It defaults to 1000 images:

```bash
iverilog -g2012 -DMAX_IMAGES=10000 -o nn_tb.vvp nn_tb.sv ...
```

At compile time Icarus prints two `sorry: constant selects in always_*
processes are not fully supported` notes for `hardmax.sv`. They say the
`always_comb` block will be sensitive to every bit of `in_data`, which is
exactly what an argmax over the whole bus should be. They are cosmetic.

Icarus prints two more families of harmless warnings during a run: a `$readmemb
... behaviour changed in the 1364-2005 standard` note from `Sig_ROM.v` and
`Weight_Memory.v`, and a `$readmemh: Not enough words in the file` note when
the image file holds fewer than `MAX_IMAGES` images. Filter them with
`vvp nn_tb.vvp 2>&1 | grep -v "^WARNING"`.

The single-neuron testbench is self-checking too. It carries a reference
model of the neuron datapath (saturating MAC, bias, ReLU) and compares every
vector against it:

```bash
iverilog -g2012 -o neuron_tb.vvp neuron_tb.sv neuron.v \
    Weight_Memory.v Sig_ROM.v ReLU.v
vvp neuron_tb.vvp
```

### FPGA Synthesis (Yosys + nextpnr)

```bash
# Comment out `define pretrained in include.v first
yosys -p "read_verilog include.v Neural_Network.v layer.v neuron.v \
    Weight_Memory.v Sig_ROM.v ReLU.v; read_verilog -sv Serializer.sv hardmax.sv; \
    synth_ecp5 -top NeuralNetwork -json nn.json"

nextpnr-ecp5 --85k --package CABGA381 --json nn.json --freq 100 --textcfg nn.config
```

---

## Tools Used

- **Icarus Verilog** — open-source Verilog simulator
- **GTKWave** — waveform viewer
- **Yosys** — open-source RTL synthesis
- **nextpnr-ecp5** — open-source FPGA place and route
- **Python 3 / PyTorch** — model training and verification
- **VS Code** — editor
- **Git/GitHub** — version control

---

## What This Project Demonstrates

- Implementing a real trained neural network as synthesizable RTL
- Fixed-point quantization (floating-point → Q2.13) with minimal accuracy loss (0.02%)
- Hardware/software co-verification with bit-exact agreement
- Understanding of FPGA resource tradeoffs (area vs speed, LUT size vs accuracy)
- Debugging real hardware bugs: pipeline timing, bus latching, fixed-point scaling
- Full flow from trained model → exported weights → working silicon-ready hardware → FPGA synthesis numbers
