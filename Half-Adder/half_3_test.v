`timescale 1ns/1ps

module half_3_test;

    // Inputs
    reg a;
    reg b;

    // Outputs
    wire s;
    wire c;

    // Instantiate the Unit Under Test (UUT)
    half_3 uut (
        .s(s),
        .c(c),
        .a(a),
        .b(b)
    );
    
    initial begin
        // Initialize inputs
        a = 1'b0;
        b = 1'b0;  

        // Apply test vectors
        #2 a = 1'b0; b = 1'b1;
        #2 a = 1'b1; b = 1'b0;
        #2 a = 1'b1; b = 1'b1;
    end

    // Monitor the output values at each time step
    initial $monitor($time, " Sum=%b Carry=%b a=%b b=%b", s, c, a, b);

    initial begin
    $dumpfile("half_3_waveform.vcd");  // Specifies the output waveform file
    $dumpvars(0, half_3_test);         // Dumps all variables in the testbench
end


    // Terminate the simulation after some time
    initial #20 $finish;
endmodule
