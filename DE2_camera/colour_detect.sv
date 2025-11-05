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
<<<<<<< Updated upstream
    parameter H_RED_HIGH1  = 10;
=======
    parameter H_RED_HIGH1  = 40;
>>>>>>> Stashed changes
    parameter H_RED_LOW2   = 350;
    parameter H_RED_HIGH2  = 359;

    // Green hue range
    parameter H_GREEN_LOW  = 80;
    parameter H_GREEN_HIGH = 140;
<<<<<<< Updated upstream
=======
	 
	 parameter H_GREEN_EXTENSION = 361;
	 
	 
	 
	 // Alternative colours:
	 
	     // Red hue range (wraps around 0°)
//    parameter H_RED_LOW1   = 0;
//    parameter H_RED_HIGH1  = 30;
//    parameter H_RED_LOW2   = 350;
//    parameter H_RED_HIGH2  = 359;
//
//    // Green hue range
//    parameter H_GREEN_LOW  = 0;
//    parameter H_GREEN_HIGH = 150;

>>>>>>> Stashed changes

    // General color thresholds
    parameter S_MIN = 60;   // Minimum saturation (to ignore washed-out colors)
    parameter V_MIN = 50;   // Minimum brightness (to ignore very dark colors)

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
			// In color_detector.sv, simplify:
			else if ((s > S_MIN && v > V_MIN) &&
						(h >= H_GREEN_LOW && h <= H_GREEN_HIGH))  // Remove || condition
				 is_green = 1'b1;

        // Black detection (low saturation and value)
        else if ((s <= S_BLACK_MAX) && (v <= V_BLACK_MAX))
            is_black = 1'b1;
    end

endmodule

//
//
//module color_detector (
//    input  logic [8:0] h,      // Hue: 0–359
//    input  logic [7:0] s, v,   // Saturation & Value: 0–255
//    output logic is_red,
//    output logic is_green,
//    output logic is_black
//);
//    // ====== Tuned Thresholds ======
//    parameter H_RED_LOW1   = 0;
//    parameter H_RED_HIGH1  = 30;    // Tighter red range
//    parameter H_RED_LOW2   = 345;   // Start earlier for wrap
//    parameter H_RED_HIGH2  = 359;
//    
//    parameter H_GREEN_LOW  = 90;    // True green range
//    parameter H_GREEN_HIGH = 150;
//    
//    parameter S_MIN = 50;           // More saturated
//    parameter V_MIN = 40;           // Brighter
//    parameter S_BLACK_MAX = 40;     // Truer black
//    parameter V_BLACK_MAX = 50;
//    
//    // ====== Detection Logic ======
//    logic is_saturated_bright;
//    assign is_saturated_bright = (s > S_MIN) && (v > V_MIN);
//    
//    logic in_red_range;
//    assign in_red_range = (h <= H_RED_HIGH1) || (h >= H_RED_LOW2);
//    
//    logic in_green_range;
//    assign in_green_range = (h >= H_GREEN_LOW) && (h <= H_GREEN_HIGH);
//    
//    always_comb begin
//        is_red   = is_saturated_bright && in_red_range;
//        is_green = is_saturated_bright && in_green_range && !is_red;
//        is_black = (s <= S_BLACK_MAX) && (v <= V_BLACK_MAX);
//    end
//endmodule
