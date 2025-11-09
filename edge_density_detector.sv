module edge_density_detector #(
    parameter WIDTH         = 640,
    parameter HEIGHT        = 480,
    parameter NUM_SECTIONS  = 18,       // Match number of LEDs
    parameter EDGE_THRESH   = 12'd128,  // Ignore weak Sobel responses
    parameter SMOOTH_FACTOR = 2,        // Higher = slower response, more stable
    parameter HYST_PERCENT  = 8,        // Hysteresis threshold (% of current)
    parameter ACTIVATION_THRESH = 16'd30  // NEW: Min smoothed count to activate
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        vga_ready,
    input  logic [11:0] filtered_video, // Edge-filtered video (Sobel)
    input  logic [9:0]  x_count,
    input  logic [8:0]  y_count,
    output logic [17:0] section_leds    // One-hot encoding of highest density section
);

    // ------------------------------------------------------------
    // Internal signals and memories
    // ------------------------------------------------------------
    logic [15:0] section_counts  [NUM_SECTIONS-1:0];
    logic [15:0] smoothed_counts [NUM_SECTIONS-1:0];
    logic [4:0]  current_section;
    logic        is_edge;
    logic        pattern_detected;  // NEW: Flag when pattern is strong enough

    integer i;

    // ------------------------------------------------------------
    // Edge detection with threshold
    // ------------------------------------------------------------
    assign is_edge = (filtered_video > EDGE_THRESH);

    // ------------------------------------------------------------
    // Map pixel x position to LED section (uniform mapping)
    // ------------------------------------------------------------
    always_comb begin
        current_section = (x_count * NUM_SECTIONS) / WIDTH;
        if (current_section >= NUM_SECTIONS)
            current_section = NUM_SECTIONS - 1;
    end

    // ------------------------------------------------------------
    // Count edges per section during frame
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_SECTIONS; i++)
                section_counts[i] <= 16'd0;
        end else if (vga_ready) begin
            // Reset counts at start of frame
            if (x_count == 10'd0 && y_count == 9'd0) begin
                for (i = 0; i < NUM_SECTIONS; i++)
                    section_counts[i] <= 16'd0;
            end
            // Increment section counter when edge detected
            else if (is_edge && current_section < NUM_SECTIONS) begin
                section_counts[current_section] <= section_counts[current_section] + 16'd1;
            end
        end
    end

    // ------------------------------------------------------------
    // Frame-end processing: smooth, find max, update LEDs
    // ------------------------------------------------------------
    logic [4:0]  max_section;
    logic [15:0] max_count;
    logic [4:0]  current_led_section;
    logic [15:0] hysteresis_value;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_SECTIONS; i++)
                smoothed_counts[i] <= 16'd0;
            section_leds        <= 18'd0;   // All LEDs off by default
            current_led_section <= 5'd0;
            pattern_detected    <= 1'b0;
        end else if (vga_ready) begin
            if (x_count == WIDTH-1 && y_count == HEIGHT-1) begin
                // Exponential smoothing with slight decay
                for (i = 0; i < NUM_SECTIONS; i++) begin
                    smoothed_counts[i] <=
                        ((smoothed_counts[i] * 15) >> 4) +  // ~0.9375 decay
                        (section_counts[i] >> SMOOTH_FACTOR);
                end

                // Find section with maximum smoothed edge density
                max_count   = 16'd0;
                max_section = 5'd0;
                for (i = 0; i < NUM_SECTIONS; i++) begin
                    if (smoothed_counts[i] > max_count) begin
                        max_count   = smoothed_counts[i];
                        max_section = i[4:0];
                    end
                end

                // NEW: Check if maximum exceeds activation threshold
                pattern_detected <= (max_count >= ACTIVATION_THRESH);

                // Proportional hysteresis to reduce flicker
                hysteresis_value = smoothed_counts[current_led_section] >> HYST_PERCENT;

                if (pattern_detected) begin
                    // Only update LED when pattern is detected
                    if ((smoothed_counts[max_section] >
                         smoothed_counts[current_led_section] + hysteresis_value)
                        || (max_section == current_led_section)) begin
                        current_led_section <= max_section;
                    end
                    // Turn on the LED
                    section_leds <= (18'd1 << current_led_section);
                end else begin
                    // No pattern detected - turn off all LEDs
                    section_leds <= 18'd0;
                end
            end
        end
    end

endmodule