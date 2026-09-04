`timescale 1ns/1ps
`include "include.v"

module neuron_tb;

    parameter dataWidth = 16;
    parameter numWeight = 4;
    parameter sigmoidSize = 10;

    reg clk, rst;
    reg [dataWidth-1:0] myinput;
    reg myinputValid;
    reg weightValid, biasValid;
    reg [31:0] weightValue, biasValue;
    reg [31:0] config_neuron_num;
    reg [31:0] config_layer_num;
    wire [dataWidth-1:0] out;
    wire outvalid;

    always #5 clk = ~clk;

    neuron #(
        .layerNo(0),
        .neuronNo(0),
        .numWeight(numWeight),
        .dataWidth(dataWidth),
        .sigmoidSize(sigmoidSize),
        .weightIntWidth(2),
        .actType("relu"),
        .biasFile("b_1_15.mif"),
        .weightFile("w_1_15.mif")
    ) dut (
        .clk(clk),
        .rst(rst),
        .myinput(myinput),
        .myinputValid(myinputValid),
        .weightValid(weightValid),
        .biasValid(biasValid),
        .weightValue(weightValue),
        .biasValue(biasValue),
        .config_neuron_num(config_neuron_num),
        .config_layer_num(config_layer_num),
        .out(out),
        .outvalid(outvalid)
    );

    initial begin
        $dumpfile("neuron_tb.vcd");
        $dumpvars(0, neuron_tb);
    end

    integer i;
    initial begin
        clk = 0; rst = 1;
        myinput = 0; myinputValid = 0;
        weightValid = 0; biasValid = 0;
        weightValue = 0; biasValue = 0;
        config_neuron_num = 0;
        config_layer_num = 0;

        repeat(4) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        // feed 4 inputs
        for(i = 0; i < numWeight; i = i+1) begin
            myinput = i * 100;
            myinputValid = 1;
            @(posedge clk);
        end
        myinputValid = 0;

        // wait for output
        repeat(20) @(posedge clk);

        if(outvalid)
            $display("OUTPUT VALID: out = %b (%0d)", out, $signed(out));
        else
            $display("outvalid never went high");

        $finish;
    end

endmodule