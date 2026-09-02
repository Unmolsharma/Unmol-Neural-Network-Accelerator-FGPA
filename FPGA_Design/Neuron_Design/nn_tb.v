`timescale 1ns/1ps
`include "include.v"

module nn_tb;

    parameter dataWidth = 16;

    reg clk, rst;
    reg [dataWidth-1:0] myinput;
    reg myinputValid;
    wire [3:0] out_class;
    wire out_valid;

    reg signed [dataWidth-1:0] image_mem [0:783];

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
    integer fd;
    initial begin
        // load the pixel values exported by baseline.py
        $readmemh("test_image_0_hex.txt", image_mem);

        clk = 0; rst = 1;
        myinput = 0; myinputValid = 0;

        repeat(4) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        for(i = 0; i < 784; i = i+1) begin
            myinput = image_mem[i];
            myinputValid = 1;
            @(posedge clk);
        end
        myinputValid = 0;

        repeat(3000) @(posedge clk);

        if(out_valid)
            $display("RTL_PREDICTION=%0d", out_class);
        else
            $display("RTL_PREDICTION=-1");

        $finish;
    end

endmodule