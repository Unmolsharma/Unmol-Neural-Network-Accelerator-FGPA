`timescale 1ns/1ps

module hardmax #(
    parameter int numInputs = 10,
    parameter int dataWidth = 16
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic [numInputs*dataWidth-1:0] in_data,
    input  logic                         in_valid,
    output logic [3:0]                   out_class,
    output logic                         out_valid
);

    logic signed [dataWidth-1:0] max_val;
    logic signed [dataWidth-1:0] current;
    logic        [3:0]           best_idx;

    always_comb begin
        max_val  = $signed(in_data[0*dataWidth +: dataWidth]);
        best_idx = 4'd0;
        for (int j = 1; j < numInputs; j++) begin
            current = $signed(in_data[j*dataWidth +: dataWidth]);
            if (current > max_val) begin
                max_val  = current;
                best_idx = j[3:0];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            out_class <= 4'd0;
            out_valid <= 1'b0;
        end
        else if (in_valid) begin
            out_class <= best_idx;
            out_valid <= 1'b1;
        end
        else begin
            out_valid <= 1'b0;
        end
    end

endmodule
