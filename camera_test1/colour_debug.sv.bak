module color_debug (

    input  logic        clk,
    input  logic [11:0] video_data,
    input  logic        vga_ready,
    
    output logic [9:0]  x_count,
    output logic [8:0]  y_count,
    
    // Debug outputs
    output logic [11:0] center_pixel, 
    output logic [3:0]  center_red,
    output logic [3:0]  center_green,
    output logic [3:0]  center_blue,
    
    // decimal output for display module
    output logic [10:0] red_decimal,
    output logic [10:0] green_decimal,
    output logic [10:0] blue_decimal,
    
    // Color detection flags 
    output logic        red_detected,
    output logic        green_detected,
    output logic        blue_detected
);

    // VGA position counter (640x480)
    always_ff @(posedge clk) begin 
	 
        if (vga_ready) begin 
		  
            if (x_count < 639) begin
				
                x_count <= x_count + 1; //increment x center 
					 
            end else begin 
				
                x_count <= 0;
					 
                if (y_count < 479) begin
					 
                    y_count <= y_count + 1; // increment y center
						  
                end else begin 
					 
                    y_count <= 0;
                end 
            end 
        end 
    end 
    
    // Sample center pixel (320, 240)
    always_ff @(posedge clk) begin 
	 
        if (vga_ready && x_count == 320 && y_count == 240) begin 
		  
            center_pixel <= video_data;  
        end
    end
    
    // Extract RGB components from RGB444 format
    assign center_red   = center_pixel[11:8];
    assign center_green = center_pixel[7:4];
    assign center_blue  = center_pixel[3:0];
    
    // Convert 4-bit values to 11-bit for display module
    // Values are 0-15, so just zero-extend
    assign red_decimal   = {7'b0, center_red};
    assign green_decimal = {7'b0, center_green};
    assign blue_decimal  = {7'b0, center_blue};
    
    // Simple color detection (threshold = 3, tune after testing!)
    assign red_detected   = (center_red   > center_green + 4'd3) && 
                            (center_red   > center_blue  + 4'd3) &&
                            (center_red   > 4'd6);  // Minimum brightness
                            
    assign green_detected = (center_green > center_red   + 4'd3) && 
                            (center_green > center_blue  + 4'd3) &&
                            (center_green > 4'd6);
                            
    assign blue_detected  = (center_blue  > center_red   + 4'd3) && 
                            (center_blue  > center_green + 4'd3) &&
                            (center_blue  > 4'd6);
                                
endmodule