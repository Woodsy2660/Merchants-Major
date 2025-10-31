module color_detector (

    input  logic [8:0] h,      // Hue: 0–359
    input  logic [7:0] s, v,   // Saturation & Value: 0–255
	 
    output logic is_red,
    output logic is_green,
    output logic is_black
	 
);
    // ====== HSV Thresholds ======
    // (Tune using color_debug as before)

    // Red hue range (wraps around 0°)
    parameter H_RED_LOW1   = 0;
    parameter H_RED_HIGH1  = 10;
    parameter H_RED_LOW2   = 350;
    parameter H_RED_HIGH2  = 359;

    // Green hue range
    parameter H_GREEN_LOW  = 80;
    parameter H_GREEN_HIGH = 140;

    // General color thresholds
    parameter S_MIN = 50;   // Minimum saturation (to ignore washed-out colors)
    parameter V_MIN = 40;   // Minimum brightness (to ignore very dark colors)

    // Black thresholds (low brightness & low saturation)
    parameter S_BLACK_MAX = 60;
    parameter V_BLACK_MAX = 50;

    // ====== Color Detection ======
    always_comb begin
        // Default all flags to 0
        is_red   = 1'b0;
        is_green = 1'b0;
        is_black = 1'b0;

        // Red detection (wraps around hue 0°)
        if ((s > S_MIN && v > V_MIN) &&
            ((h >= H_RED_LOW1 && h <= H_RED_HIGH1) ||
             (h >= H_RED_LOW2 && h <= H_RED_HIGH2)))
            is_red = 1'b1;

        // Green detection
        else if ((s > S_MIN && v > V_MIN) &&
                 (h >= H_GREEN_LOW && h <= H_GREEN_HIGH))
            is_green = 1'b1;

        // Black detection (low saturation and value)
        else if ((s <= S_BLACK_MAX) && (v <= V_BLACK_MAX))
            is_black = 1'b1;
    end

endmodule
