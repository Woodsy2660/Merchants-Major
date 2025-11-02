module rgb_to_hsv (
    input  logic [3:0] r, g, b,  // 4-bit RGB444 from camera
	 
    output logic [8:0] h,         // Hue: 0-359 degrees (9 bits)
    output logic [7:0] s,         // Saturation: 0-255
    output logic [7:0] v          // Value: 0-255
);

    // Scale up to 8-bit for better precision
    logic [7:0] r8, g8, b8;
	 
    assign r8 = {r, 4'b0};
    assign g8 = {g, 4'b0};
    assign b8 = {b, 4'b0};
    
    // Find max and min
    logic [7:0] max_val, min_val, delta;
    
    always_comb begin
	 
        // Calculate max
        if (r8 >= g8 && r8 >= b8)
            max_val = r8;
				
        else if (g8 >= r8 && g8 >= b8)
            max_val = g8;
				
        else
            max_val = b8;
            
        // Calculate min
        if (r8 <= g8 && r8 <= b8)
            min_val = r8;
				
        else if (g8 <= r8 && g8 <= b8)
            min_val = g8;
				
        else
            min_val = b8;
            
        delta = max_val - min_val;
        
        // Value (V) is simply the max
        v = max_val;
        
        // Saturation (S)
        if (max_val == 0)
            s = 0;
				
        else
            s = (delta * 255) / max_val;
        
        // Hue (H) - this is approximate, use lookup tables for better accuracy
        if (delta == 0)
            h = 0;
				
        else if (max_val == r8)
            h = ((g8 - b8) * 60) / delta;
				
        else if (max_val == g8)
            h = 120 + ((b8 - r8) * 60) / delta;
				
        else
            h = 240 + ((r8 - g8) * 60) / delta;
    end
	 
endmodule