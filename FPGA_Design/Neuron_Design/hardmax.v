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
    reg [3:0] best_idx;

    always @(posedge clk) begin
        if(rst) begin
            out_class <= 0;
            out_valid <= 0;
        end
        else if(in_valid) begin
            // blocking assignments: the running max must update within the loop
            max_val  = $signed(in_data[0*dataWidth +: dataWidth]);
            best_idx = 0;
            for(j = 1; j < numInputs; j = j+1) begin
                current = $signed(in_data[j*dataWidth +: dataWidth]);
                if(current > max_val) begin
                    max_val  = current;
                    best_idx = j[3:0];
                end
            end
            out_class <= best_idx;
            out_valid <= 1;
        end
        else begin
            out_valid <= 0;
        end
    end
endmodule