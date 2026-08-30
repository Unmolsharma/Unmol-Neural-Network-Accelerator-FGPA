`timescale 1ns/1ps

module hardmax #(
    parameter numInputs = 10,
    parameter dataWidth = 16
)(
    input clk,
    input rst,
    input [numInputs*dataWidth-1:0] in_data,
    input in_valid,
    output reg [3:0] out_class,
    output reg out_valid
);
    integer j;
    reg signed [dataWidth-1:0] max_val;
    reg signed [dataWidth-1:0] current;

    always @(posedge clk) begin
        if(rst) begin
            out_class <= 0;
            out_valid <= 0;
            max_val   <= {1'b1,{dataWidth-1{1'b0}}}; // most negative value
        end
        else if(in_valid) begin
            max_val   <= $signed(in_data[0*dataWidth +: dataWidth]);
            out_class <= 0;
            for(j = 1; j < numInputs; j = j+1) begin
                current = $signed(in_data[j*dataWidth +: dataWidth]);
                if(current > max_val) begin
                    max_val   <= current;
                    out_class <= j;
                end
            end
            out_valid <= 1;
        end
        else begin
            out_valid <= 0;
        end
    end
endmodule