`timescale 1ns/1ps

module ReLU #(parameter dataWidth=16, weightIntWidth=1)(
    input clk,
    input [2*dataWidth-1:0] x,
    output reg [dataWidth-1:0] out
);
    always @(posedge clk) begin
        if(x[2*dataWidth-1])
            out <= 0;
        else
            out <= x[2*dataWidth-2-:dataWidth];
    end
endmodule