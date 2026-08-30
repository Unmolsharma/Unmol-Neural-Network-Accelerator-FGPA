`timescale 1ns/1ps
`include "include.v"

module layer #(
    parameter layerNo        = 0,
    parameter numNeurons     = 30,
    parameter numWeights     = 784,
    parameter dataWidth      = 16,
    parameter sigmoidSize    = 5,
    parameter weightIntWidth = 1,
    parameter actType        = "sigmoid",
    parameter biasFile_0  = "", parameter weightFile_0  = "",
    parameter biasFile_1  = "", parameter weightFile_1  = "",
    parameter biasFile_2  = "", parameter weightFile_2  = "",
    parameter biasFile_3  = "", parameter weightFile_3  = "",
    parameter biasFile_4  = "", parameter weightFile_4  = "",
    parameter biasFile_5  = "", parameter weightFile_5  = "",
    parameter biasFile_6  = "", parameter weightFile_6  = "",
    parameter biasFile_7  = "", parameter weightFile_7  = "",
    parameter biasFile_8  = "", parameter weightFile_8  = "",
    parameter biasFile_9  = "", parameter weightFile_9  = "",
    parameter biasFile_10 = "", parameter weightFile_10 = "",
    parameter biasFile_11 = "", parameter weightFile_11 = "",
    parameter biasFile_12 = "", parameter weightFile_12 = "",
    parameter biasFile_13 = "", parameter weightFile_13 = "",
    parameter biasFile_14 = "", parameter weightFile_14 = "",
    parameter biasFile_15 = "", parameter weightFile_15 = "",
    parameter biasFile_16 = "", parameter weightFile_16 = "",
    parameter biasFile_17 = "", parameter weightFile_17 = "",
    parameter biasFile_18 = "", parameter weightFile_18 = "",
    parameter biasFile_19 = "", parameter weightFile_19 = "",
    parameter biasFile_20 = "", parameter weightFile_20 = "",
    parameter biasFile_21 = "", parameter weightFile_21 = "",
    parameter biasFile_22 = "", parameter weightFile_22 = "",
    parameter biasFile_23 = "", parameter weightFile_23 = "",
    parameter biasFile_24 = "", parameter weightFile_24 = "",
    parameter biasFile_25 = "", parameter weightFile_25 = "",
    parameter biasFile_26 = "", parameter weightFile_26 = "",
    parameter biasFile_27 = "", parameter weightFile_27 = "",
    parameter biasFile_28 = "", parameter weightFile_28 = "",
    parameter biasFile_29 = "", parameter weightFile_29 = ""
)(
    input  clk,
    input  rst,
    input  [dataWidth-1:0] myinput,
    input  myinputValid,
    input  weightValid,
    input  biasValid,
    input  [31:0] weightValue,
    input  [31:0] biasValue,
    input  [31:0] config_layer_num,
    input  [31:0] config_neuron_num,
    output [numNeurons*dataWidth-1:0] out,
    output outvalid
);

    wire [dataWidth-1:0] neuron_out [numNeurons-1:0];
    wire neuron_outvalid [numNeurons-1:0];

    assign outvalid = neuron_outvalid[0];

    genvar i;
    generate
        for (i = 0; i < numNeurons; i = i + 1) begin : neuron_out_assign
            assign out[i*dataWidth +: dataWidth] = neuron_out[i];
        end
    endgenerate

    //all neurons with their own weight/bias files
    neuron #(.layerNo(layerNo),.neuronNo(0),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_0),.weightFile(weightFile_0)) n0 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[0]),.outvalid(neuron_outvalid[0]));
    neuron #(.layerNo(layerNo),.neuronNo(1),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_1),.weightFile(weightFile_1)) n1 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[1]),.outvalid(neuron_outvalid[1]));
    neuron #(.layerNo(layerNo),.neuronNo(2),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_2),.weightFile(weightFile_2)) n2 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[2]),.outvalid(neuron_outvalid[2]));
    neuron #(.layerNo(layerNo),.neuronNo(3),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_3),.weightFile(weightFile_3)) n3 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[3]),.outvalid(neuron_outvalid[3]));
    neuron #(.layerNo(layerNo),.neuronNo(4),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_4),.weightFile(weightFile_4)) n4 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[4]),.outvalid(neuron_outvalid[4]));
    neuron #(.layerNo(layerNo),.neuronNo(5),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_5),.weightFile(weightFile_5)) n5 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[5]),.outvalid(neuron_outvalid[5]));
    neuron #(.layerNo(layerNo),.neuronNo(6),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_6),.weightFile(weightFile_6)) n6 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[6]),.outvalid(neuron_outvalid[6]));
    neuron #(.layerNo(layerNo),.neuronNo(7),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_7),.weightFile(weightFile_7)) n7 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[7]),.outvalid(neuron_outvalid[7]));
    neuron #(.layerNo(layerNo),.neuronNo(8),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_8),.weightFile(weightFile_8)) n8 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[8]),.outvalid(neuron_outvalid[8]));
    neuron #(.layerNo(layerNo),.neuronNo(9),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_9),.weightFile(weightFile_9)) n9 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[9]),.outvalid(neuron_outvalid[9]));
    neuron #(.layerNo(layerNo),.neuronNo(10),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_10),.weightFile(weightFile_10)) n10 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[10]),.outvalid(neuron_outvalid[10]));
    neuron #(.layerNo(layerNo),.neuronNo(11),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_11),.weightFile(weightFile_11)) n11 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[11]),.outvalid(neuron_outvalid[11]));
    neuron #(.layerNo(layerNo),.neuronNo(12),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_12),.weightFile(weightFile_12)) n12 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[12]),.outvalid(neuron_outvalid[12]));
    neuron #(.layerNo(layerNo),.neuronNo(13),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_13),.weightFile(weightFile_13)) n13 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[13]),.outvalid(neuron_outvalid[13]));
    neuron #(.layerNo(layerNo),.neuronNo(14),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_14),.weightFile(weightFile_14)) n14 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[14]),.outvalid(neuron_outvalid[14]));
    neuron #(.layerNo(layerNo),.neuronNo(15),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_15),.weightFile(weightFile_15)) n15 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[15]),.outvalid(neuron_outvalid[15]));
    neuron #(.layerNo(layerNo),.neuronNo(16),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_16),.weightFile(weightFile_16)) n16 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[16]),.outvalid(neuron_outvalid[16]));
    neuron #(.layerNo(layerNo),.neuronNo(17),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_17),.weightFile(weightFile_17)) n17 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[17]),.outvalid(neuron_outvalid[17]));
    neuron #(.layerNo(layerNo),.neuronNo(18),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_18),.weightFile(weightFile_18)) n18 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[18]),.outvalid(neuron_outvalid[18]));
    neuron #(.layerNo(layerNo),.neuronNo(19),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_19),.weightFile(weightFile_19)) n19 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[19]),.outvalid(neuron_outvalid[19]));
    neuron #(.layerNo(layerNo),.neuronNo(20),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_20),.weightFile(weightFile_20)) n20 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[20]),.outvalid(neuron_outvalid[20]));
    neuron #(.layerNo(layerNo),.neuronNo(21),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_21),.weightFile(weightFile_21)) n21 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[21]),.outvalid(neuron_outvalid[21]));
    neuron #(.layerNo(layerNo),.neuronNo(22),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_22),.weightFile(weightFile_22)) n22 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[22]),.outvalid(neuron_outvalid[22]));
    neuron #(.layerNo(layerNo),.neuronNo(23),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_23),.weightFile(weightFile_23)) n23 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[23]),.outvalid(neuron_outvalid[23]));
    neuron #(.layerNo(layerNo),.neuronNo(24),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_24),.weightFile(weightFile_24)) n24 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[24]),.outvalid(neuron_outvalid[24]));
    neuron #(.layerNo(layerNo),.neuronNo(25),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_25),.weightFile(weightFile_25)) n25 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[25]),.outvalid(neuron_outvalid[25]));
    neuron #(.layerNo(layerNo),.neuronNo(26),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_26),.weightFile(weightFile_26)) n26 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[26]),.outvalid(neuron_outvalid[26]));
    neuron #(.layerNo(layerNo),.neuronNo(27),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_27),.weightFile(weightFile_27)) n27 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[27]),.outvalid(neuron_outvalid[27]));
    neuron #(.layerNo(layerNo),.neuronNo(28),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_28),.weightFile(weightFile_28)) n28 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[28]),.outvalid(neuron_outvalid[28]));
    neuron #(.layerNo(layerNo),.neuronNo(29),.numWeight(numWeights),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.biasFile(biasFile_29),.weightFile(weightFile_29)) n29 (.clk(clk),.rst(rst),.myinput(myinput),.myinputValid(myinputValid),.weightValid(weightValid),.biasValid(biasValid),.weightValue(weightValue),.biasValue(biasValue),.config_layer_num(config_layer_num),.config_neuron_num(config_neuron_num),.out(neuron_out[29]),.outvalid(neuron_outvalid[29]));

endmodule