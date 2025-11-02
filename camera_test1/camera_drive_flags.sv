// camera_drive_flags.sv (frame-held decision)
// Majority RED => turn_right; Majority GREEN => turn_left; Center BLACK => centered.
// Outputs are held for the FULL FRAME until the next decision at SOF.

module camera_drive_flags #(
    parameter int IMG_W  = 640,
    parameter int IMG_H  = 480,
    parameter int MID_X  = 320,
    parameter int MID_Y  = 240,
    parameter int MIN_COLORED_PIXELS = 500
)(
    input  logic        clk,
    input  logic        vga_ready,          // 1 pixel/cycle valid
    input  logic [9:0]  x_count,            // 0..639
    input  logic [8:0]  y_count,            // 0..479
    input  logic [11:0] video_data,         // RGB444

    // Frame-held decisions (mutually exclusive; centered has priority)
    output logic        turn_left,
    output logic        turn_right,
    output logic        centered
);

    // --- RGB444 unpack ---
    logic [3:0] r4, g4, b4;
    assign r4 = video_data[11:8];
    assign g4 = video_data[7:4];
    assign b4 = video_data[3:0];

    // --- Pipeline align coords with HSV ---
    logic       vld_d1, vld_d2;
    logic [9:0] x_d1, x_d2;
    logic [8:0] y_d1, y_d2;
    always_ff @(posedge clk) begin
        vld_d1 <= vga_ready;
        vld_d2 <= vld_d1;
        x_d1   <= x_count;  x_d2 <= x_d1;
        y_d1   <= y_count;  y_d2 <= y_d1;
    end

    // --- RGB -> HSV ---
    logic [8:0] h;
    logic [7:0] s, v;
    logic       hsv_valid;
    rgb_to_hsv u_hsv (
        .clk      (clk),
        .r_in     (r4),
        .g_in     (g4),
        .b_in     (b4),
        .valid_in (vga_ready),
        .h_out    (h),
        .s_out    (s),
        .v_out    (v),
        .valid_out(hsv_valid)
    );

    // --- Color detector (your tuned thresholds inside) ---
    logic is_red_px, is_green_px, is_black_px;
    color_detector u_det (
        .h(h), .s(s), .v(v),
        .is_red  (is_red_px),
        .is_green(is_green_px),
        .is_black(is_black_px)
    );

    // --- Frame counters + centre-black sample (for current frame) ---
    logic [19:0] red_cnt, green_cnt;
    logic        center_black_seen;

    // Convenience wire
    logic [20:0] total_colored;
    assign total_colored = red_cnt + green_cnt;

    // Start-of-frame aligned to classifier timing
    logic sof;
    assign sof = vld_d2 && (x_d2 == 10'd0) && (y_d2 == 9'd0);

    // Frame-held decision registers
    // Default after reset: no turn, not centered.
    always_ff @(posedge clk) begin
        if (sof) begin
            // Decide for the frame we just finished, then HOLD these until next SOF
            // Priority: centered > turn_left/turn_right > none
            if (center_black_seen) begin
                centered   <= 1'b1;
                turn_left  <= 1'b0;
                turn_right <= 1'b0;
            end else if (total_colored >= MIN_COLORED_PIXELS) begin
                centered   <= 1'b0;
                if (red_cnt > green_cnt) begin
                    turn_right <= 1'b1;
                    turn_left  <= 1'b0;
                end else if (green_cnt > red_cnt) begin
                    turn_left  <= 1'b1;
                    turn_right <= 1'b0;
                end else begin
                    // tie: no command this frame
                    turn_left  <= 1'b0;
                    turn_right <= 1'b0;
                end
            end else begin
                // not enough colored pixels → hold neutral
                centered   <= 1'b0;
                turn_left  <= 1'b0;
                turn_right <= 1'b0;
            end

            // Reset accumulators for the new frame
            red_cnt           <= '0;
            green_cnt         <= '0;
            center_black_seen <= 1'b0;

        end else begin
            // Accumulate for current frame
            if (hsv_valid) begin
                if (is_red_px)   red_cnt   <= red_cnt   + 1;
                if (is_green_px) green_cnt <= green_cnt + 1;

                // Sample exact centre pixel (after pipeline alignment)
                if ((x_d2 == MID_X) && (y_d2 == MID_Y) && is_black_px)
                    center_black_seen <= 1'b1;
            end
        end
    end

endmodule
