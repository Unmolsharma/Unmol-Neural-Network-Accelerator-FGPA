"""Generates the sigmoid look up table contents (sigContent.mif) used by Sig_ROM.v.
This is done because hardware complexity for computing sigmoid is quite computationally
expensive, and a LUT is a good tradeoff between accuracy and hardware cost.

neuron.v drives the ROM with sum[2*dataWidth-1 -: sigmoidSize], the top bits of the MAC
accumulator, and Sig_ROM.v re-centres that to offset binary. Entry i therefore holds
sigmoid(x) for

    x    = (i - 2**(sigmoidSize-1)) * step
    step = 2**(accIntWidth + 1 - sigmoidSize)

stored in the same Q format as the activations, since the ROM output feeds straight into
the next layer's multiplier.
"""

import math
import os


def genSigContent(dataWidth=16, sigmoidSize=10, weightIntWidth=2, path="sigContent.mif"):
    fracBits = dataWidth - 1 - weightIntWidth
    accIntWidth = 2 * dataWidth - 1 - 2 * fracBits
    step = 2.0 ** (accIntWidth + 1 - sigmoidSize)
    half = 2 ** (sigmoidSize - 1)

    with open(path, "w") as f:
        for i in range(2 ** sigmoidSize):
            f.write(DtoB(sigmoid((i - half) * step), dataWidth, fracBits) + "\n")


def DtoB(num, dataWidth, fracBits):  # two's complement fixed point
    q = int(round(num * (2 ** fracBits)))
    q = max(-(2 ** (dataWidth - 1)), min(2 ** (dataWidth - 1) - 1, q))  # saturate
    if q < 0:
        q += 2 ** dataWidth
    return format(q, "0{}b".format(dataWidth))


def sigmoid(x):
    if x < -60:
        return 0.0
    return 1 / (1 + math.exp(-x))


if __name__ == "__main__":
    DATA_WIDTH       = 16
    SIGMOID_SIZE     = 10   # `sigmoidSize in include.v
    WEIGHT_INT_WIDTH = 2    # `weightIntWidth in include.v

    genSigContent(DATA_WIDTH, SIGMOID_SIZE, WEIGHT_INT_WIDTH)

    # Keep the copy the RTL actually reads in step with this one
    dest = "../Neuron_Design/sigContent.mif"
    if os.path.isdir(os.path.dirname(dest)):
        with open("sigContent.mif") as src, open(dest, "w") as out:
            out.write(src.read())
        print("wrote sigContent.mif and", dest)
