`timescale 1ns/1ps
`include "include.v"

module NeuralNetwork #(
    parameter dataWidth      = 16,
    parameter sigmoidSize    = 5,
    parameter weightIntWidth = 1
)(
    input  clk,
    input  rst,
    input  [dataWidth-1:0] myinput,
    input  myinputValid,
    output [3:0] out_class,
    output out_valid
);

    // layer output buses and valid signals
    wire [30*dataWidth-1:0] l1_out;  wire l1_valid;
    wire [30*dataWidth-1:0] l2_out;  wire l2_valid;
    wire [10*dataWidth-1:0] l3_out;  wire l3_valid;
    wire [10*dataWidth-1:0] l4_out;  wire l4_valid;
    wire [10*dataWidth-1:0] l5_out;  wire l5_valid;

    // serializer wires between layers
    wire [dataWidth-1:0] s1_data, s2_data, s3_data, s4_data;
    wire s1_valid, s2_valid, s3_valid, s4_valid;
    wire s1_done,  s2_done,  s3_done,  s4_done;

    // unused runtime-loading ports tied off
    wire [31:0] config_layer_num  = 32'd0;
    wire [31:0] config_neuron_num = 32'd0;
    wire        weightValid       = 1'b0;
    wire        biasValid         = 1'b0;
    wire [31:0] weightValue       = 32'd0;
    wire [31:0] biasValue         = 32'd0;

    // Layer 1: 784 inputs, 30 neurons, sigmoid
    layer #(
        .layerNo(1), .numNeurons(30), .numWeights(784),
        .dataWidth(dataWidth), .sigmoidSize(sigmoidSize),
        .weightIntWidth(weightIntWidth), .actType("sigmoid"),
        .weightFile_0("weights/w_1_0.mif"),   .biasFile_0("weights/b_1_0.mif"),
        .weightFile_1("weights/w_1_1.mif"),   .biasFile_1("weights/b_1_1.mif"),
        .weightFile_2("weights/w_1_2.mif"),   .biasFile_2("weights/b_1_2.mif"),
        .weightFile_3("weights/w_1_3.mif"),   .biasFile_3("weights/b_1_3.mif"),
        .weightFile_4("weights/w_1_4.mif"),   .biasFile_4("weights/b_1_4.mif"),
        .weightFile_5("weights/w_1_5.mif"),   .biasFile_5("weights/b_1_5.mif"),
        .weightFile_6("weights/w_1_6.mif"),   .biasFile_6("weights/b_1_6.mif"),
        .weightFile_7("weights/w_1_7.mif"),   .biasFile_7("weights/b_1_7.mif"),
        .weightFile_8("weights/w_1_8.mif"),   .biasFile_8("weights/b_1_8.mif"),
        .weightFile_9("weights/w_1_9.mif"),   .biasFile_9("weights/b_1_9.mif"),
        .weightFile_10("weights/w_1_10.mif"), .biasFile_10("weights/b_1_10.mif"),
        .weightFile_11("weights/w_1_11.mif"), .biasFile_11("weights/b_1_11.mif"),
        .weightFile_12("weights/w_1_12.mif"), .biasFile_12("weights/b_1_12.mif"),
        .weightFile_13("weights/w_1_13.mif"), .biasFile_13("weights/b_1_13.mif"),
        .weightFile_14("weights/w_1_14.mif"), .biasFile_14("weights/b_1_14.mif"),
        .weightFile_15("weights/w_1_15.mif"), .biasFile_15("weights/b_1_15.mif"),
        .weightFile_16("weights/w_1_16.mif"), .biasFile_16("weights/b_1_16.mif"),
        .weightFile_17("weights/w_1_17.mif"), .biasFile_17("weights/b_1_17.mif"),
        .weightFile_18("weights/w_1_18.mif"), .biasFile_18("weights/b_1_18.mif"),
        .weightFile_19("weights/w_1_19.mif"), .biasFile_19("weights/b_1_19.mif"),
        .weightFile_20("weights/w_1_20.mif"), .biasFile_20("weights/b_1_20.mif"),
        .weightFile_21("weights/w_1_21.mif"), .biasFile_21("weights/b_1_21.mif"),
        .weightFile_22("weights/w_1_22.mif"), .biasFile_22("weights/b_1_22.mif"),
        .weightFile_23("weights/w_1_23.mif"), .biasFile_23("weights/b_1_23.mif"),
        .weightFile_24("weights/w_1_24.mif"), .biasFile_24("weights/b_1_24.mif"),
        .weightFile_25("weights/w_1_25.mif"), .biasFile_25("weights/b_1_25.mif"),
        .weightFile_26("weights/w_1_26.mif"), .biasFile_26("weights/b_1_26.mif"),
        .weightFile_27("weights/w_1_27.mif"), .biasFile_27("weights/b_1_27.mif"),
        .weightFile_28("weights/w_1_28.mif"), .biasFile_28("weights/b_1_28.mif"),
        .weightFile_29("weights/w_1_29.mif"), .biasFile_29("weights/b_1_29.mif")
    ) l1 (
        .clk(clk), .rst(rst),
        .myinput(myinput), .myinputValid(myinputValid),
        .weightValid(weightValid), .biasValid(biasValid),
        .weightValue(weightValue), .biasValue(biasValue),
        .config_layer_num(config_layer_num),
        .config_neuron_num(config_neuron_num),
        .out(l1_out), .outvalid(l1_valid)
    );

    // Serializer 1: layer 1 parallel out -> layer 2 serial in
    serializer #(.numInputs(30), .dataWidth(dataWidth)) ser1 (
        .clk(clk), .rst(rst),
        .in_valid(l1_valid), .in_data(l1_out),
        .out_data(s1_data), .out_valid(s1_valid), .done(s1_done)
    );

    // Layer 2: 30 inputs, 30 neurons, sigmoid
    layer #(
        .layerNo(2), .numNeurons(30), .numWeights(30),
        .dataWidth(dataWidth), .sigmoidSize(sigmoidSize),
        .weightIntWidth(weightIntWidth), .actType("sigmoid"),
        .weightFile_0("weights/w_2_0.mif"),   .biasFile_0("weights/b_2_0.mif"),
        .weightFile_1("weights/w_2_1.mif"),   .biasFile_1("weights/b_2_1.mif"),
        .weightFile_2("weights/w_2_2.mif"),   .biasFile_2("weights/b_2_2.mif"),
        .weightFile_3("weights/w_2_3.mif"),   .biasFile_3("weights/b_2_3.mif"),
        .weightFile_4("weights/w_2_4.mif"),   .biasFile_4("weights/b_2_4.mif"),
        .weightFile_5("weights/w_2_5.mif"),   .biasFile_5("weights/b_2_5.mif"),
        .weightFile_6("weights/w_2_6.mif"),   .biasFile_6("weights/b_2_6.mif"),
        .weightFile_7("weights/w_2_7.mif"),   .biasFile_7("weights/b_2_7.mif"),
        .weightFile_8("weights/w_2_8.mif"),   .biasFile_8("weights/b_2_8.mif"),
        .weightFile_9("weights/w_2_9.mif"),   .biasFile_9("weights/b_2_9.mif"),
        .weightFile_10("weights/w_2_10.mif"), .biasFile_10("weights/b_2_10.mif"),
        .weightFile_11("weights/w_2_11.mif"), .biasFile_11("weights/b_2_11.mif"),
        .weightFile_12("weights/w_2_12.mif"), .biasFile_12("weights/b_2_12.mif"),
        .weightFile_13("weights/w_2_13.mif"), .biasFile_13("weights/b_2_13.mif"),
        .weightFile_14("weights/w_2_14.mif"), .biasFile_14("weights/b_2_14.mif"),
        .weightFile_15("weights/w_2_15.mif"), .biasFile_15("weights/b_2_15.mif"),
        .weightFile_16("weights/w_2_16.mif"), .biasFile_16("weights/b_2_16.mif"),
        .weightFile_17("weights/w_2_17.mif"), .biasFile_17("weights/b_2_17.mif"),
        .weightFile_18("weights/w_2_18.mif"), .biasFile_18("weights/b_2_18.mif"),
        .weightFile_19("weights/w_2_19.mif"), .biasFile_19("weights/b_2_19.mif"),
        .weightFile_20("weights/w_2_20.mif"), .biasFile_20("weights/b_2_20.mif"),
        .weightFile_21("weights/w_2_21.mif"), .biasFile_21("weights/b_2_21.mif"),
        .weightFile_22("weights/w_2_22.mif"), .biasFile_22("weights/b_2_22.mif"),
        .weightFile_23("weights/w_2_23.mif"), .biasFile_23("weights/b_2_23.mif"),
        .weightFile_24("weights/w_2_24.mif"), .biasFile_24("weights/b_2_24.mif"),
        .weightFile_25("weights/w_2_25.mif"), .biasFile_25("weights/b_2_25.mif"),
        .weightFile_26("weights/w_2_26.mif"), .biasFile_26("weights/b_2_26.mif"),
        .weightFile_27("weights/w_2_27.mif"), .biasFile_27("weights/b_2_27.mif"),
        .weightFile_28("weights/w_2_28.mif"), .biasFile_28("weights/b_2_28.mif"),
        .weightFile_29("weights/w_2_29.mif"), .biasFile_29("weights/b_2_29.mif")
    ) l2 (
        .clk(clk), .rst(rst),
        .myinput(s1_data), .myinputValid(s1_valid),
        .weightValid(weightValid), .biasValid(biasValid),
        .weightValue(weightValue), .biasValue(biasValue),
        .config_layer_num(config_layer_num),
        .config_neuron_num(config_neuron_num),
        .out(l2_out), .outvalid(l2_valid)
    );

    // Serializer 2
    serializer #(.numInputs(30), .dataWidth(dataWidth)) ser2 (
        .clk(clk), .rst(rst),
        .in_valid(l2_valid), .in_data(l2_out),
        .out_data(s2_data), .out_valid(s2_valid), .done(s2_done)
    );

    // Layer 3: 30 inputs, 10 neurons, sigmoid
    layer #(
        .layerNo(3), .numNeurons(10), .numWeights(30),
        .dataWidth(dataWidth), .sigmoidSize(sigmoidSize),
        .weightIntWidth(weightIntWidth), .actType("sigmoid"),
        .weightFile_0("weights/w_3_0.mif"), .biasFile_0("weights/b_3_0.mif"),
        .weightFile_1("weights/w_3_1.mif"), .biasFile_1("weights/b_3_1.mif"),
        .weightFile_2("weights/w_3_2.mif"), .biasFile_2("weights/b_3_2.mif"),
        .weightFile_3("weights/w_3_3.mif"), .biasFile_3("weights/b_3_3.mif"),
        .weightFile_4("weights/w_3_4.mif"), .biasFile_4("weights/b_3_4.mif"),
        .weightFile_5("weights/w_3_5.mif"), .biasFile_5("weights/b_3_5.mif"),
        .weightFile_6("weights/w_3_6.mif"), .biasFile_6("weights/b_3_6.mif"),
        .weightFile_7("weights/w_3_7.mif"), .biasFile_7("weights/b_3_7.mif"),
        .weightFile_8("weights/w_3_8.mif"), .biasFile_8("weights/b_3_8.mif"),
        .weightFile_9("weights/w_3_9.mif"), .biasFile_9("weights/b_3_9.mif")
    ) l3 (
        .clk(clk), .rst(rst),
        .myinput(s2_data), .myinputValid(s2_valid),
        .weightValid(weightValid), .biasValid(biasValid),
        .weightValue(weightValue), .biasValue(biasValue),
        .config_layer_num(config_layer_num),
        .config_neuron_num(config_neuron_num),
        .out(l3_out), .outvalid(l3_valid)
    );

    // Serializer 3
    serializer #(.numInputs(10), .dataWidth(dataWidth)) ser3 (
        .clk(clk), .rst(rst),
        .in_valid(l3_valid), .in_data(l3_out),
        .out_data(s3_data), .out_valid(s3_valid), .done(s3_done)
    );

    // Layer 4: 10 inputs, 10 neurons, sigmoid
    layer #(
        .layerNo(4), .numNeurons(10), .numWeights(10),
        .dataWidth(dataWidth), .sigmoidSize(sigmoidSize),
        .weightIntWidth(weightIntWidth), .actType("sigmoid"),
        .weightFile_0("weights/w_4_0.mif"), .biasFile_0("weights/b_4_0.mif"),
        .weightFile_1("weights/w_4_1.mif"), .biasFile_1("weights/b_4_1.mif"),
        .weightFile_2("weights/w_4_2.mif"), .biasFile_2("weights/b_4_2.mif"),
        .weightFile_3("weights/w_4_3.mif"), .biasFile_3("weights/b_4_3.mif"),
        .weightFile_4("weights/w_4_4.mif"), .biasFile_4("weights/b_4_4.mif"),
        .weightFile_5("weights/w_4_5.mif"), .biasFile_5("weights/b_4_5.mif"),
        .weightFile_6("weights/w_4_6.mif"), .biasFile_6("weights/b_4_6.mif"),
        .weightFile_7("weights/w_4_7.mif"), .biasFile_7("weights/b_4_7.mif"),
        .weightFile_8("weights/w_4_8.mif"), .biasFile_8("weights/b_4_8.mif"),
        .weightFile_9("weights/w_4_9.mif"), .biasFile_9("weights/b_4_9.mif")
    ) l4 (
        .clk(clk), .rst(rst),
        .myinput(s3_data), .myinputValid(s3_valid),
        .weightValid(weightValid), .biasValid(biasValid),
        .weightValue(weightValue), .biasValue(biasValue),
        .config_layer_num(config_layer_num),
        .config_neuron_num(config_neuron_num),
        .out(l4_out), .outvalid(l4_valid)
    );

    // Serializer 4
    serializer #(.numInputs(10), .dataWidth(dataWidth)) ser4 (
        .clk(clk), .rst(rst),
        .in_valid(l4_valid), .in_data(l4_out),
        .out_data(s4_data), .out_valid(s4_valid), .done(s4_done)
    );

    // Layer 5: 10 inputs, 10 neurons, sigmoid
    layer #(
        .layerNo(5), .numNeurons(10), .numWeights(10),
        .dataWidth(dataWidth), .sigmoidSize(sigmoidSize),
        .weightIntWidth(weightIntWidth), .actType("sigmoid"),
        .weightFile_0("weights/w_5_0.mif"), .biasFile_0("weights/b_5_0.mif"),
        .weightFile_1("weights/w_5_1.mif"), .biasFile_1("weights/b_5_1.mif"),
        .weightFile_2("weights/w_5_2.mif"), .biasFile_2("weights/b_5_2.mif"),
        .weightFile_3("weights/w_5_3.mif"), .biasFile_3("weights/b_5_3.mif"),
        .weightFile_4("weights/w_5_4.mif"), .biasFile_4("weights/b_5_4.mif"),
        .weightFile_5("weights/w_5_5.mif"), .biasFile_5("weights/b_5_5.mif"),
        .weightFile_6("weights/w_5_6.mif"), .biasFile_6("weights/b_5_6.mif"),
        .weightFile_7("weights/w_5_7.mif"), .biasFile_7("weights/b_5_7.mif"),
        .weightFile_8("weights/w_5_8.mif"), .biasFile_8("weights/b_5_8.mif"),
        .weightFile_9("weights/w_5_9.mif"), .biasFile_9("weights/b_5_9.mif")
    ) l5 (
        .clk(clk), .rst(rst),
        .myinput(s4_data), .myinputValid(s4_valid),
        .weightValid(weightValid), .biasValid(biasValid),
        .weightValue(weightValue), .biasValue(biasValue),
        .config_layer_num(config_layer_num),
        .config_neuron_num(config_neuron_num),
        .out(l5_out), .outvalid(l5_valid)
    );

    // Hardmax: pick largest of 10 outputs -> predicted digit
    hardmax #(.numInputs(10), .dataWidth(dataWidth)) hm (
        .clk(clk), .rst(rst),
        .in_data(l5_out), .in_valid(l5_valid),
        .out_class(out_class), .out_valid(out_valid)
    );

endmodule