`timescale 1ns/1ps

`ifndef MAX_IMAGES
  `define MAX_IMAGES 1000
`endif

module nn_tb;

    localparam int MAX_IMAGES   = `MAX_IMAGES;
    localparam int DATA_WIDTH   = 16;
    localparam int PIXELS       = 784;
    localparam int NUM_CLASSES  = 10;
    localparam int SIGMOID_SIZE = 10;
    localparam int W_INT_WIDTH  = 2;
    localparam int CLK_PERIOD   = 10;

    typedef logic [DATA_WIDTH-1:0] pixel_t;
    typedef logic [3:0]            class_t;

    int    num_images  = 100;
    int    timeout_cyc = 5000;
    string image_file  = "test_images_hex.txt";
    string golden_file = "baseline_predictions.txt";
    string result_file = "rtl_predictions.txt";
    bit    dump_waves  = 1'b0;
    bit    quiet       = 1'b0;

    pixel_t images [MAX_IMAGES][PIXELS];
    int     golden [$];
    bit     have_golden = 1'b0;

    int  mism_idx [$];
    int  mism_got [$];
    int  mism_exp [$];
    int  lat_q    [$];
    int  n_run     = 0;
    int  n_checked = 0;
    int  n_matched = 0;

    logic   clk = 1'b0;
    logic   rst = 1'b1;
    pixel_t myinput = {DATA_WIDTH{1'b0}};
    logic   myinputValid = 1'b0;

    class_t out_class;
    logic   out_valid;

    int     cycle_count     = 0;
    logic   captured        = 1'b0;
    class_t captured_class;
    int     captured_cycle  = 0;
    int     drive_end_cycle = 0;
    int     fd;

    always #(CLK_PERIOD/2) clk = ~clk;

    always_ff @(posedge clk)
        cycle_count <= cycle_count + 1;

    NeuralNetwork #(
        .dataWidth      (DATA_WIDTH),
        .sigmoidSize    (SIGMOID_SIZE),
        .weightIntWidth (W_INT_WIDTH)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .myinput      (myinput),
        .myinputValid (myinputValid),
        .out_class    (out_class),
        .out_valid    (out_valid)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            captured <= 1'b0;
        end
        else if (out_valid && !captured) begin
            captured       <= 1'b1;
            captured_class <= out_class;
            captured_cycle <= cycle_count;
        end
    end

    always @(posedge clk) begin
        if (!rst && out_valid)
            assert (!$isunknown(out_class))
                else $fatal(1, "[%0t] out_class is X/Z while out_valid is asserted", $time);
    end

    task automatic apply_reset();
        rst          <= 1'b1;
        myinput      <= {DATA_WIDTH{1'b0}};
        myinputValid <= 1'b0;
        repeat (4) @(posedge clk);
        rst <= 1'b0;
        repeat (2) @(posedge clk);
    endtask

    task automatic drive_image(input int idx);
        for (int p = 0; p < PIXELS; p++) begin
            myinput      <= images[idx][p];
            myinputValid <= 1'b1;
            @(posedge clk);
        end
        myinputValid    <= 1'b0;
        drive_end_cycle  = cycle_count;
    endtask

    task automatic await_result(input  int     idx,
                                output class_t predicted,
                                output int     latency);
        int waited;
        waited = 0;
        while (!captured) begin
            @(posedge clk);
            waited++;
            if (waited > timeout_cyc)
                $fatal(1, "[%0t] image %0d: out_valid never asserted within %0d cycles",
                          $time, idx, timeout_cyc);
        end
        @(posedge clk);
        predicted = captured_class;
        latency   = captured_cycle - drive_end_cycle;
    endtask

    task automatic read_plusargs();
        void'($value$plusargs("images=%d",    num_images));
        void'($value$plusargs("timeout=%d",   timeout_cyc));
        void'($value$plusargs("imagefile=%s", image_file));
        void'($value$plusargs("golden=%s",    golden_file));
        void'($value$plusargs("results=%s",   result_file));
        dump_waves = $test$plusargs("dump");
        quiet      = $test$plusargs("quiet");

        assert (num_images >= 1 && num_images <= MAX_IMAGES)
            else $fatal(1, "+images=%0d is outside 1..%0d; rebuild with -DMAX_IMAGES=%0d",
                           num_images, MAX_IMAGES, num_images);
    endtask

    task automatic load_images();
        pixel_t last_px;

        $readmemh(image_file, images);

        last_px = images[num_images-1][PIXELS-1];
        assert (!$isunknown(last_px))
            else $fatal(1, "%0s does not hold %0d complete images of %0d pixels",
                           image_file, num_images, PIXELS);
    endtask

    task automatic load_golden();
        int gfd;
        int v;
        int code;

        gfd = $fopen(golden_file, "r");
        if (gfd == 0) begin
            $display("NOTE: %0s not found -- running in record-only mode", golden_file);
            have_golden = 1'b0;
            return;
        end

        forever begin
            code = $fscanf(gfd, "%d", v);
            if (code != 1) break;
            golden.push_back(v);
        end
        $fclose(gfd);

        have_golden = (golden.size() > 0);
        if (have_golden && golden.size() < num_images)
            $display("NOTE: %0s holds only %0d predictions; images %0d+ go unchecked",
                     golden_file, golden.size(), golden.size());
    endtask

    function automatic void print_summary();
        int n_mism;
        int n_lat;
        int lat_sum;
        int lat_min;
        int lat_max;
        int pct_x100;

        n_mism  = mism_idx.size();
        n_lat   = lat_q.size();
        lat_sum = 0;
        lat_min = 0;
        lat_max = 0;

        for (int i = 0; i < n_lat; i++) begin
            lat_sum += lat_q[i];
            if (i == 0 || lat_q[i] < lat_min) lat_min = lat_q[i];
            if (lat_q[i] > lat_max)           lat_max = lat_q[i];
        end

        $display("");
        $display("======================================================");
        $display(" nn_tb summary");
        $display("======================================================");
        $display("  images run       : %0d of %0d requested", n_run, num_images);
        $display("  predictions file : %0s", result_file);

        if (n_lat > 0)
            $display("  latency (cycles) : min %0d  avg %0d  max %0d",
                     lat_min, lat_sum / n_lat, lat_max);

        if (!have_golden) begin
            $display("  self-check       : SKIPPED (no golden file)");
        end
        else begin
            pct_x100 = (n_checked > 0) ? (10000 * n_matched) / n_checked : 0;
            $display("  checked          : %0d", n_checked);
            $display("  agreed           : %0d", n_matched);
            $display("  mismatched       : %0d", n_mism);
            if (n_checked > 0)
                $display("  agreement        : %0d.%02d%%", pct_x100 / 100, pct_x100 % 100);
            for (int i = 0; i < n_mism; i++)
                $display("    image %0d: RTL=%0d baseline=%0d",
                         mism_idx[i], mism_got[i], mism_exp[i]);
        end

        if (n_run < num_images)
            $display("  RESULT           : INCOMPLETE (stopped after %0d images)", n_run);
        else if (!have_golden)
            $display("  RESULT           : RECORDED (nothing to check against)");
        else if (n_mism == 0)
            $display("  RESULT           : PASS");
        else
            $display("  RESULT           : FAIL");

        $display("======================================================");
    endfunction

    final print_summary();

    initial begin
        class_t pred;
        int     pred_i;
        int     lat;
        int     expected;
        string  status;

        read_plusargs();

        if (dump_waves) begin
            $dumpfile("nn_tb.vcd");
            $dumpvars(0, nn_tb);
        end

        load_images();
        load_golden();

        fd = $fopen(result_file, "w");
        if (fd == 0)
            $fatal(1, "cannot open %0s for writing", result_file);

        if (have_golden)
            $display("nn_tb: %0d images from %0s, checking against %0s",
                     num_images, image_file, golden_file);
        else
            $display("nn_tb: %0d images from %0s, no reference file",
                     num_images, image_file);

        for (int img = 0; img < num_images; img++) begin
            apply_reset();
            drive_image(img);
            await_result(img, pred, lat);

            pred_i = pred;
            n_run++;
            lat_q.push_back(lat);
            $fwrite(fd, "%0d\n", pred_i);

            expected = (have_golden && img < golden.size()) ? golden[img] : -1;

            if (expected >= 0) begin
                n_checked++;
                if (pred_i == expected) begin
                    n_matched++;
                end
                else begin
                    mism_idx.push_back(img);
                    mism_got.push_back(pred_i);
                    mism_exp.push_back(expected);
                end
            end

            if (expected < 0)             status = "unchecked";
            else if (pred_i == expected)  status = "ok";
            else                          status = "MISMATCH";

            if (!quiet)
                $display("  image %0d: RTL=%0d  %0s  (%0d cycles)",
                         img, pred_i, status, lat);
            else if ((img % 100) == 99)
                $display("  ... %0d images done", img + 1);
        end

        $fclose(fd);

        if (mism_idx.size() != 0)
            $fatal(1, "RTL disagrees with the baseline on %0d of %0d images",
                      mism_idx.size(), n_checked);

        $finish;
    end

endmodule
