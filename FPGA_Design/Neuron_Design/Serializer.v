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
                running  <= 1;
                count    <= 0;
            end

            if(running) begin
                out_data  <= in_data[count*dataWidth +: dataWidth];
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