module edge_density_detector #(
    parameter WIDTH         = 640,
    parameter HEIGHT        = 480,
    parameter NUM_SECTIONS  = 18,     // Match number of LEDs
    parameter SMOOTH_FACTOR = 1,      // 1/2 smoothing (fast response)
    parameter HYSTERESIS    = 16'd60  // Mild threshold for switching
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        vga_ready,
    input  logic [11:0] filtered_video,  // Edge-filtered video (Sobel)
    input  logic [9:0]  x_count,
    input  logic [8:0]  y_count,
    output logic [17:0] section_leds     // One-hot encoding of highest density section
);

    // Section width (integer division)
    localparam integer SECTION_WIDTH = WIDTH / NUM_SECTIONS; // 35 px
    localparam integer REM_PIXELS    = WIDTH % NUM_SECTIONS; // 10 px remain

    // Edge counters
    logic [15:0] section_counts     [NUM_SECTIONS-1:0];
    logic [15:0] smoothed_counts    [NUM_SECTIONS-1:0];

    // Internal control
    logic [4:0] current_section;
    logic is_edge;

    integer i;

    // ------------------------------------------------------------
    // Determine if current pixel is an edge and its section
    // ------------------------------------------------------------
    assign is_edge = (filtered_video != 12'h000);

    always_comb begin
        current_section = x_count / SECTION_WIDTH;
        if (current_section >= NUM_SECTIONS)
            current_section = NUM_SECTIONS - 1; // Clamp to last section (right-side fix)
    end

    // ------------------------------------------------------------
    // Count edges per section during frame
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_SECTIONS; i++)
                section_counts[i] <= 16'd0;
        end else if (vga_ready) begin
            // Reset at start of frame
            if (x_count == 10'd0 && y_count == 9'd0) begin
                for (i = 0; i < NUM_SECTIONS; i++)
                    section_counts[i] <= 16'd0;
            end
            // Count edge pixels
            else if (is_edge && current_section < NUM_SECTIONS) begin
                section_counts[current_section] <= section_counts[current_section] + 16'd1;
            end
        end
    end

    // ------------------------------------------------------------
    // Frame-end processing: smooth, find max, update LED
    // ------------------------------------------------------------
    logic [4:0]  max_section;
    logic [15:0] max_count;
    logic [4:0]  current_led_section;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_SECTIONS; i++)
                smoothed_counts[i] <= 16'd0;
            section_leds         <= 18'd1; // Default LED 0 on
            current_led_section  <= 5'd0;
        end else if (vga_ready) begin
            if (x_count == WIDTH-1 && y_count == HEIGHT-1) begin
                // Smooth edge counts (exponential moving average)
                for (i = 0; i < NUM_SECTIONS; i = i + 1) begin
                    smoothed_counts[i] <= smoothed_counts[i]
                        - (smoothed_counts[i] >> SMOOTH_FACTOR)
                        + (section_counts[i] >> SMOOTH_FACTOR);
                end

                // Find section with maximum smoothed edge density
                max_count   = 16'd0;
                max_section = 5'd0;
                for (i = 0; i < NUM_SECTIONS; i = i + 1)
                    if (smoothed_counts[i] > max_count) begin
                        max_count   = smoothed_counts[i];
                        max_section = i[4:0];
                    end

                // Apply hysteresis to reduce flicker
                if ((smoothed_counts[max_section] >
                     smoothed_counts[current_led_section] + HYSTERESIS)
                    || (max_section == current_led_section)) begin
                    current_led_section <= max_section;
                end

                // Always keep exactly one LED on
                section_leds <= (18'd1 << current_led_section);
            end
        end
    end
endmodule
