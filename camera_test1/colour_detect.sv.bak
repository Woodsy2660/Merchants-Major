module color_detector (

    input  logic [8:0] h,
    input  logic [7:0] s, v,
	 
    output logic is_red,
    output logic is_green,
    output logic is_blue
	 
);
    // Define thresholds (tune these with your colour_debug module!)
    parameter H_RED_LOW1   = 0;
    parameter H_RED_HIGH1  = 10;
    parameter H_RED_LOW2   = 350;
    parameter H_RED_HIGH2  = 359;
    parameter H_GREEN_LOW  = 80;
    parameter H_GREEN_HIGH = 140;
    parameter H_BLUE_LOW   = 200;
    parameter H_BLUE_HIGH  = 260;
    
    parameter S_MIN = 50;   // Minimum saturation (ignore washed out colors)
    parameter V_MIN = 40;   // Minimum brightness (ignore too dark)
    
    always_comb begin
	 
        // Red detection (wraps around 0°)
        is_red = (s > S_MIN && v > V_MIN) && 
                 ((h >= H_RED_LOW1 && h <= H_RED_HIGH1) ||
                  (h >= H_RED_LOW2 && h <= H_RED_HIGH2));
        
        // Green detection
        is_green = (s > S_MIN && v > V_MIN) &&
                   (h >= H_GREEN_LOW && h <= H_GREEN_HIGH);
        
        // Blue detection
        is_blue = (s > S_MIN && v > V_MIN) &&
                  (h >= H_BLUE_LOW && h <= H_BLUE_HIGH);
    end
endmodule