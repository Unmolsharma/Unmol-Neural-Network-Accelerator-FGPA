`timescale 1ns/1ps

module serializer #(
    parameter numInputs = 30,
    parameter dataWidth = 16
)(
    input clk,
    input rst,
    input in_valid,
    input [numInputs*dataWidth-1:0] in_data,
    output reg [dataWidth-1:0] out_data,
    output reg out_valid,
    output reg done
);
    parameter counterWidth = $clog2(numInputs+1);
    reg [counterWidth-1:0] count;
    reg running;

    // The producing layer drives its outputs for only one cycle (each neuron
    // clears its accumulator as soon as it pulses outvalid, so its output
    // collapses to sigmoid(0) on the next cycle). Latch the whole bus on
    // in_valid and serialize out of the latched copy.
    reg [numInputs*dataWidth-1:0] data_latched;
    wire [dataWidth-1:0] selected_data = data_latched[count*dataWidth +: dataWidth];

    always @(posedge clk) begin
        if(rst) begin
            count    <= 0;
            running  <= 0;
            out_valid<= 0;
            done     <= 0;
            out_data <= 0;
        end
        else begin
            done     <= 0;
            out_valid<= 0;

            if(in_valid && !running) begin
                running     <= 1;
                count       <= 0;
                data_latched<= in_data;
            end

            if(running) begin
                out_data  <= selected_data;
                out_valid <= 1;
                count     <= count + 1;
                if(count == numInputs-1) begin
                    running <= 0;
                    done    <= 1;
                end
            end
        end
    end
endmodule