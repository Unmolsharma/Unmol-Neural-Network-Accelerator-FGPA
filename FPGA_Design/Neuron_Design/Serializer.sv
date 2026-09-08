`timescale 1ns/1ps

module serializer #(
    parameter int numInputs = 30,
    parameter int dataWidth = 16
)(
    input  logic                           clk,
    input  logic                           rst,
    input  logic                           in_valid,
    input  logic [numInputs*dataWidth-1:0] in_data,
    output logic [dataWidth-1:0]           out_data,
    output logic                           out_valid,
    output logic                           done
);

    localparam int counterWidth = $clog2(numInputs+1);

    typedef enum logic {
        IDLE,
        STREAM
    } state_t;

    state_t                        state;
    logic [counterWidth-1:0]       count;
    logic [numInputs*dataWidth-1:0] data_latched;

    wire [dataWidth-1:0] selected_data = data_latched[count*dataWidth +: dataWidth];

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            count     <= '0;
            out_data  <= '0;
            out_valid <= 1'b0;
            done      <= 1'b0;
        end
        else begin

            out_valid <= 1'b0;
            done      <= 1'b0;

            case (state)
                IDLE: begin
                    if (in_valid) begin
                        data_latched <= in_data;
                        count        <= '0;
                        state        <= STREAM;
                    end
                end

                STREAM: begin
                    out_data  <= selected_data;
                    out_valid <= 1'b1;
                    count     <= count + 1'b1;
                    if (count == numInputs-1) begin
                        state <= IDLE;
                        done  <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
