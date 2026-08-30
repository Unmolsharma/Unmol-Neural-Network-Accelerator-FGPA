`timescale 1ns/1ps
`include "include.v"

module nn_tb;

    parameter dataWidth = 16;

    reg clk, rst;
    reg [dataWidth-1:0] myinput;
    reg myinputValid;
    wire [3:0] out_class;
    wire out_valid;

    always #5 clk = ~clk;

    NeuralNetwork #(
        .dataWidth(dataWidth),
        .sigmoidSize(5),
        .weightIntWidth(1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .myinput(myinput),
        .myinputValid(myinputValid),
        .out_class(out_class),
        .out_valid(out_valid)
    );

    initial begin
        $dumpfile("nn_tb.vcd");
        $dumpvars(0, nn_tb);
    end

    integer i;
    initial begin
        clk = 0; rst = 1;
        myinput = 0; myinputValid = 0;

        repeat(4) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        //feed 784 inputs (all set to 100 as a test vector)
        for(i = 0; i < 784; i = i+1) begin
            myinput = 16'd100;
            myinputValid = 1;
            @(posedge clk);
        end
        myinputValid = 0;

        //wait long enough for all 5 layers to process
        repeat(2000) @(posedge clk);

        if(out_valid)
            $display("PREDICTED CLASS: %0d", out_class);
        else
            $display("out_valid never went high - pipeline issue");

        $finish;
    end

endmodule