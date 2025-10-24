// Color Debug Module with HSV-based Color Detection
// Samples center pixel, converts to HSV, and uses color_detector for detection

module color_debug (
    input  logic        clk,
    input  logic [11:0] video_data,
    input  logic        vga_ready,
    
    output logic [9:0]  x_count,
    output logic [8:0]  y_count,
    
    // RGB Debug outputs (from center pixel)
    output logic [11:0] center_pixel, 
    output logic [3:0]  center_red,
    output logic [3:0]  center_green,
    output logic [3:0]  center_blue,
    
    // HSV outputs (converted from RGB)
    output logic [8:0]  center_hue,        // 0-359 degrees
    output logic [7:0]  center_saturation, // 0-255
    output logic [7:0]  center_value,      // 0-255
    
    // Decimal output for display module
    output logic [10:0] hue_decimal,
    output logic [10:0] sat_decimal,
    output logic [10:0] val_decimal,
    
    // Color detection flags
    output logic        red_detected,
    output logic        green_detected,
    output logic        blue_detected
);

    // ========== VGA Position Counter (640x480) ==========
	 
    always_ff @(posedge clk) begin 
	 
        if (vga_ready) begin 
		  
            if (x_count < 639) begin
				
                x_count <= x_count + 1;
					 
            end else begin 
				
                x_count <= 0;
					 
                if (y_count < 479) begin
					 
                    y_count <= y_count + 1;
						  
                end else begin 
					 
                    y_count <= 0;
						  
                end 
            end 
        end 
    end 
    
    // ========== Sample Center Pixel (320, 240) ==========
    logic center_pixel_valid;
	 
    always_ff @(posedge clk) begin 
	 
        center_pixel_valid <= 1'b0;
		  
        if (vga_ready && x_count == 320 && y_count == 240) begin 
		  
            center_pixel <= video_data;
				
            center_pixel_valid <= 1'b1;
				
        end
    end
    
    // ========== Extract RGB Components from RGB444 Format ==========
    assign center_red   = center_pixel[11:8];
    assign center_green = center_pixel[7:4];
    assign center_blue  = center_pixel[3:0];
    
    // ========== RGB to HSV Conversion ==========
    logic hsv_valid;
    rgb_to_hsv hsv_converter (
        .clk(clk),
        .r_in(center_red),
        .g_in(center_green),
        .b_in(center_blue),
        .valid_in(center_pixel_valid),
        .h_out(center_hue),
        .s_out(center_saturation),
        .v_out(center_value),
        .valid_out(hsv_valid)
    );
    
    // ========== Convert HSV to Decimal for Display ==========
    assign hue_decimal = {2'b0, center_hue};        // 0-359
    assign sat_decimal = {3'b0, center_saturation}; // 0-255
    assign val_decimal = {3'b0, center_value};      // 0-255
    
    // ========== USE YOUR EXISTING COLOR_DETECTOR MODULE ==========
    color_detector detector (
        .h(center_hue),
        .s(center_saturation),
        .v(center_value),
        .is_red(red_detected),
        .is_green(green_detected),
        .is_blue(blue_detected)
    );
    
endmodule