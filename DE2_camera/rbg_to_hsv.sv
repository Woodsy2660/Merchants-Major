// RGB to HSV Converter - Optimized for FPGA Implementation
// Converts RGB444 (4-bit per channel) to HSV color space

module rgb_to_hsv (

    input  logic        clk,
    input  logic [3:0]  r_in,      // 4-bit red input
    input  logic [3:0]  g_in,      // 4-bit green input
    input  logic [3:0]  b_in,      // 4-bit blue input
    input  logic        valid_in,  // Input valid signal
    
    output logic [8:0]  h_out,     // Hue: 0-359 degrees (9 bits)
    output logic [7:0]  s_out,     // Saturation: 0-255 (8 bits)
    output logic [7:0]  v_out,     // Value: 0-255 (8 bits)
    output logic        valid_out  // Output valid signal
	 
);

    // Scale 4-bit RGB to 8-bit for better precision
    logic [7:0] r8, g8, b8;
    assign r8 = {r_in, r_in};  // Replicate bits: 4'b1111 -> 8'b11111111
    assign g8 = {g_in, g_in};
    assign b8 = {b_in, b_in};
    
    // Pipeline stage 1: Find max, min, and delta
    logic [7:0] max_val, min_val, delta;
    logic [1:0] max_channel; // 0=R, 1=G, 2=B
    
    always_ff @(posedge clk) begin
	 
        // Find maximum value and which channel it belongs to
        if (r8 >= g8 && r8 >= b8) begin
            max_val <= r8;
            max_channel <= 2'd0; // Red is max
				
        end else if (g8 >= r8 && g8 >= b8) begin
            max_val <= g8;
            max_channel <= 2'd1; // Green is max
				
        end else begin
            max_val <= b8;
            max_channel <= 2'd2; // Blue is max
        end
        
        // Find minimum value
        if (r8 <= g8 && r8 <= b8)
            min_val <= r8;
				
        else if (g8 <= r8 && g8 <= b8)
            min_val <= g8;
				
        else
            min_val <= b8;
    end
    
    // Pipeline stage 2: Calculate V, S, and H
    logic [7:0] r8_d, g8_d, b8_d;      // Delayed RGB for hue calculation
    logic [7:0] max_val_d, min_val_d;  // Delayed max/min
    logic [1:0] max_channel_d;
    logic       valid_d1, valid_d2;
    
    always_ff @(posedge clk) begin
        // Delay RGB values for pipeline
        r8_d <= r8;
        g8_d <= g8;
        b8_d <= b8;
        max_val_d <= max_val;
        min_val_d <= min_val;
        max_channel_d <= max_channel;
        valid_d1 <= valid_in;
        
        // Calculate delta
        delta <= max_val - min_val;
        
        // Calculate Value (V) - simply the max
        v_out <= max_val;
        
        // Calculate Saturation (S)
        if (max_val == 8'd0)
            s_out <= 8'd0;
        else
            s_out <= (delta << 8) / max_val;  // (delta * 256) / max_val
    end
    
    // Pipeline stage 3: Calculate Hue
    logic signed [15:0] hue_temp;
    
    always_ff @(posedge clk) begin
        valid_d2 <= valid_d1;
        
        if (delta == 8'd0) begin
            // No color (grayscale)
            h_out <= 9'd0;
				
        end else begin
		  
            case (max_channel_d)
                2'd0: begin // Red is max
           
                    hue_temp = (g8_d - b8_d) * 60;
						  
                    if (hue_temp < 0)
						  
                        h_out <= 9'd360 + (hue_temp / delta);
                    else
                        h_out <= (hue_temp / delta);
                end
                
                2'd1: begin // Green is max
                 
                    hue_temp = (b8_d - r8_d) * 60;
						  
                    h_out <= 9'd120 + (hue_temp / delta);
						  
                end
                
                2'd2: begin // Blue is max
            
                    hue_temp = (r8_d - g8_d) * 60;
						  
                    h_out <= 9'd240 + (hue_temp / delta);
						  
                end
                
                default: h_out <= 9'd0;
					 
            endcase
        end
    end
    
    assign valid_out = valid_d2;

endmodule