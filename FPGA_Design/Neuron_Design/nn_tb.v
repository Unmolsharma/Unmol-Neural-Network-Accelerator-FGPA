`timescale 1ns/1ps
`include "include.v"

//
// Full-network testbench.
//
// Feeds NUM_IMAGES MNIST images (784 pixels each) from test_images_hex.txt,
// captures the predicted class for each, and writes them to rtl_predictions.txt
// so they can be diffed against baseline.py's output.
//
// Override the image count at compile time with:  -DNUM_IMAGES=<n>
// Enable waveform dumping with:                   -DDUMP_VCD
//
module nn_tb;

    parameter dataWidth = 16;

`ifdef NUM_IMAGES
    parameter NUM_IMAGES = `NUM_IMAGES;
`else
    parameter NUM_IMAGES = 100;
`endif

    reg clk, rst;
    reg [dataWidth-1:0] myinput;
    reg myinputValid;

    wire [3:0] out_class;
    wire out_valid;

    // All images back to back: 784 pixels each
    reg [dataWidth-1:0] image_mem [0:784*NUM_IMAGES-1];

    reg captured;
    reg [3:0] captured_class;

    integer i, img, fd, matches;

    // 100 MHz clock: 10 ns period
    always #5 clk = ~clk;

    NeuralNetwork #(
        .dataWidth(dataWidth),
        .sigmoidSize(10),
        .weightIntWidth(2)
    ) dut (
        .clk(clk),
        .rst(rst),
        .myinput(myinput),
        .myinputValid(myinputValid),
        .out_class(out_class),
        .out_valid(out_valid)
    );

`ifdef DUMP_VCD
    initial begin
        $dumpfile("nn_tb.vcd");
        $dumpvars(0, nn_tb);
    end
`endif

    // Capture the prediction as soon as the network asserts out_valid
    always @(posedge clk) begin
        if (out_valid && !captured) begin
            captured_class <= out_class;
            captured       <= 1'b1;
        end
    end

    initial begin
        $readmemh("test_images_hex.txt", image_mem);

        clk = 0;
        rst = 1;
        myinput = 0;
        myinputValid = 0;
        captured = 0;
        captured_class = 0;

        fd = $fopen("rtl_predictions.txt", "w");

        for (img = 0; img < NUM_IMAGES; img = img + 1) begin

            // Reset the network between images so no state carries over
            rst = 1;
            captured = 0;
            repeat(4) @(posedge clk);
            rst = 0;
            repeat(2) @(posedge clk);

            // Stream this image's 784 pixels.
            // Non-blocking drives keep stimulus out of the DUT's sampling race.
            for (i = 0; i < 784; i = i + 1) begin
                myinput      <= image_mem[img*784 + i];
                myinputValid <= 1;
                @(posedge clk);
            end
            myinputValid <= 0;

            // Wait for the result to propagate through all 5 layers + hardmax
            wait(captured);
            @(posedge clk);

            $fwrite(fd, "%0d\n", captured_class);
            $display("IMAGE %0d: RTL prediction = %0d", img, captured_class);
        end

        $fclose(fd);
        $display("Wrote %0d predictions to rtl_predictions.txt", NUM_IMAGES);
        $finish;
    end

endmodule
