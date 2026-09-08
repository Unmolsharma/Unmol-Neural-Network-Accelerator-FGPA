`timescale 1ns/1ps

module neuron_tb;

    localparam int DATA_WIDTH   = 16;
    localparam int NUM_WEIGHT   = 4;
    localparam int SIGMOID_SIZE = 10;
    localparam int W_INT_WIDTH  = 2;
    localparam int ACC_WIDTH    = 2*DATA_WIDTH;
    localparam int CLK_PERIOD   = 10;
    localparam int TIMEOUT_CYC  = 200;

    localparam string WEIGHT_FILE = "weights/w_2_15.mif";
    localparam string BIAS_FILE   = "weights/b_2_15.mif";

    typedef logic        [DATA_WIDTH-1:0] data_t;
    typedef logic signed [ACC_WIDTH-1:0]  acc_t;

    localparam int NUM_VECTORS = 5;
    data_t vectors [NUM_VECTORS][NUM_WEIGHT];

    logic  clk = 1'b0;
    logic  rst = 1'b1;
    data_t myinput = '0;
    logic  myinputValid = 1'b0;

    logic        weightValid = 1'b0;
    logic        biasValid   = 1'b0;
    logic [31:0] weightValue = '0;
    logic [31:0] biasValue   = '0;
    logic [31:0] config_neuron_num = '0;
    logic [31:0] config_layer_num  = '0;

    data_t out;
    logic  outvalid;

    logic [DATA_WIDTH-1:0] ref_w [NUM_WEIGHT-1:0];
    logic [31:0]           ref_b [0:0];

    initial begin
        $readmemb(WEIGHT_FILE, ref_w);
        $readmemb(BIAS_FILE,   ref_b);
    end

    initial begin
        logic any_nonzero;
        #1;
        any_nonzero = 1'b0;
        for (int i = 0; i < NUM_WEIGHT; i++)
            if (ref_w[i] != '0) any_nonzero = 1'b1;
        assert (any_nonzero)
            else $fatal(1, "all %0d weights read from %0s are zero -- this test would prove nothing",
                           NUM_WEIGHT, WEIGHT_FILE);
    end

    logic  captured = 1'b0;
    data_t captured_out;

    int n_checked = 0;
    int n_failed  = 0;
    bit dump_waves = 1'b0;

    always #(CLK_PERIOD/2) clk = ~clk;

    neuron #(
        .layerNo        (0),
        .neuronNo       (0),
        .numWeight      (NUM_WEIGHT),
        .dataWidth      (DATA_WIDTH),
        .sigmoidSize    (SIGMOID_SIZE),
        .weightIntWidth (W_INT_WIDTH),
        .actType        ("relu"),
        .biasFile       (BIAS_FILE),
        .weightFile     (WEIGHT_FILE)
    ) dut (
        .clk               (clk),
        .rst               (rst),
        .myinput           (myinput),
        .myinputValid      (myinputValid),
        .weightValid       (weightValid),
        .biasValid         (biasValid),
        .weightValue       (weightValue),
        .biasValue         (biasValue),
        .config_neuron_num (config_neuron_num),
        .config_layer_num  (config_layer_num),
        .out               (out),
        .outvalid          (outvalid)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            captured <= 1'b0;
        end
        else if (outvalid && !captured) begin
            captured     <= 1'b1;
            captured_out <= out;
        end
    end

    function automatic acc_t sat_add(input acc_t a, input acc_t b);
        acc_t s;
        s = a + b;
        if (!a[ACC_WIDTH-1] && !b[ACC_WIDTH-1] && s[ACC_WIDTH-1])
            return {1'b0, {(ACC_WIDTH-1){1'b1}}};
        else if (a[ACC_WIDTH-1] && b[ACC_WIDTH-1] && !s[ACC_WIDTH-1])
            return {1'b1, {(ACC_WIDTH-1){1'b0}}};
        else
            return s;
    endfunction

    function automatic data_t relu_of(input acc_t x);
        if (x[ACC_WIDTH-1]) return '0;
        else                return x[ACC_WIDTH-2 -: DATA_WIDTH];
    endfunction

    function automatic data_t expected_out(input int vec);
        acc_t acc;
        acc_t product;
        acc_t bias_full;

        acc = '0;
        for (int i = 0; i < NUM_WEIGHT; i++) begin
            product = $signed(vectors[vec][i]) * $signed(ref_w[i]);
            acc     = sat_add(acc, product);
        end

        bias_full = {ref_b[0][DATA_WIDTH-1:0], {DATA_WIDTH{1'b0}}};
        acc       = sat_add(acc, bias_full);

        return relu_of(acc);
    endfunction

    task automatic apply_reset();
        rst          <= 1'b1;
        myinput      <= '0;
        myinputValid <= 1'b0;
        repeat (4) @(posedge clk);
        rst <= 1'b0;
        repeat (2) @(posedge clk);
    endtask

    task automatic drive_vector(input int vec);
        for (int i = 0; i < NUM_WEIGHT; i++) begin
            myinput      <= vectors[vec][i];
            myinputValid <= 1'b1;
            @(posedge clk);
        end
        myinputValid <= 1'b0;
    endtask

    task automatic await_result(input int vec, output data_t observed);
        int waited;
        waited = 0;
        while (!captured) begin
            @(posedge clk);
            waited++;
            if (waited > TIMEOUT_CYC)
                $fatal(1, "[%0t] vector %0d: outvalid never asserted within %0d cycles",
                          $time, vec, TIMEOUT_CYC);
        end
        @(posedge clk);
        observed = captured_out;
    endtask

    function automatic void print_summary();
        $display("");
        $display("==================================================");
        $display(" neuron_tb: %0d checked, %0d failed", n_checked, n_failed);
        if (n_checked == NUM_VECTORS && n_failed == 0)
            $display(" RESULT: PASS");
        else if (n_failed > 0)
            $display(" RESULT: FAIL");
        else
            $display(" RESULT: INCOMPLETE (stopped after %0d vectors)", n_checked);
        $display("==================================================");
    endfunction

    final print_summary();

    initial begin
        data_t observed;
        data_t expected;

        vectors[0][0] = 16'd0;
        vectors[0][1] = 16'd100;
        vectors[0][2] = 16'd200;
        vectors[0][3] = 16'd300;

        for (int i = 0; i < NUM_WEIGHT; i++) vectors[1][i] = 16'd0;

        for (int i = 0; i < NUM_WEIGHT; i++) vectors[2][i] = 16'h7FFF;

        for (int i = 0; i < NUM_WEIGHT; i++) vectors[3][i] = 16'h8000;

        vectors[4][0] = 16'h7FFF;
        vectors[4][1] = 16'h8000;
        vectors[4][2] = 16'd1234;
        vectors[4][3] = -16'sd4321;

        dump_waves = $test$plusargs("dump");
        if (dump_waves) begin
            $dumpfile("neuron_tb.vcd");
            $dumpvars(0, neuron_tb);
        end

        $display("neuron_tb: %0d vectors, weights=%0s bias=%0s, actType=relu",
                 NUM_VECTORS, WEIGHT_FILE, BIAS_FILE);

        for (int v = 0; v < NUM_VECTORS; v++) begin
            apply_reset();
            drive_vector(v);
            await_result(v, observed);

            expected = expected_out(v);
            n_checked++;

            if ($isunknown(observed) || $isunknown(expected)) begin
                n_failed++;
                $display("  vector %0d: out = 0x%h  X/Z  (model gave 0x%h) -- weight or bias file missing?",
                         v, observed, expected);
            end
            else if (observed === expected) begin
                $display("  vector %0d: out = %0d (0x%h)  ok",
                         v, $signed(observed), observed);
            end
            else begin
                n_failed++;
                $display("  vector %0d: out = 0x%h  MISMATCH  expected 0x%h",
                         v, observed, expected);
            end
        end

        if (n_failed != 0)
            $fatal(1, "%0d of %0d vectors disagree with the reference model",
                      n_failed, n_checked);

        $finish;
    end

endmodule
