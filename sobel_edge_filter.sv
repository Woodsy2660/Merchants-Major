module sobel_edge_filter #(
    parameter WIDTH = 640,
    parameter HEIGHT = 480
)(
    input  logic        clk,
    input  logic        reset,
    
    // Simple video interface - matches your pipeline
    input  logic [11:0] video_in,     // 12-bit RGB444 from image_buffer
    input  logic        ready,         // VGA ready signal (acts as valid/enable)
    output logic [11:0] video_out      // 12-bit RGB444 output
);

    // Extract RGB from 12-bit input (RGB444 format)
    logic [3:0] r_in, g_in, b_in;
    assign r_in = video_in[11:8];
    assign g_in = video_in[7:4];
    assign b_in = video_in[3:0];
    
    // Expand to 8-bit for processing (replicate MSBs)
    logic [7:0] r_in_8bit, g_in_8bit, b_in_8bit;
    assign r_in_8bit = {r_in, r_in};
    assign g_in_8bit = {g_in, g_in};
    assign b_in_8bit = {b_in, b_in};
    
    logic [23:0] rgb_in_24bit;
    assign rgb_in_24bit = {r_in_8bit, g_in_8bit, b_in_8bit};

    // Sobel X kernel (horizontal edges)
    localparam logic signed [7:0] KX11 = -1, KX12 = 0, KX13 = 1;
    localparam logic signed [7:0] KX21 = -2, KX22 = 0, KX23 = 2;
    localparam logic signed [7:0] KX31 = -1, KX32 = 0, KX33 = 1;
    
    // Sobel Y kernel (vertical edges)
    localparam logic signed [7:0] KY11 = -1, KY12 = -2, KY13 = -1;
    localparam logic signed [7:0] KY21 =  0, KY22 =  0, KY23 =  0;
    localparam logic signed [7:0] KY31 =  1, KY32 =  2, KY33 =  1;
    
    // Position tracking
    logic [9:0] x_pos;
    logic [9:0] y_pos;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            x_pos <= 10'd0;
            y_pos <= 10'd0;
        end else if (ready) begin
            if (x_pos == WIDTH - 1) begin
                x_pos <= 10'd0;
                if (y_pos == HEIGHT - 1)
                    y_pos <= 10'd0;
                else
                    y_pos <= y_pos + 10'd1;
            end else begin
                x_pos <= x_pos + 10'd1;
            end
        end
    end
    
    // Line buffers (store 24-bit RGB)
    logic [23:0] line0 [WIDTH-1:0];
    logic [23:0] line1 [WIDTH-1:0];
    logic [23:0] line2 [WIDTH-1:0];
    
    // 3x3 pixel window
    logic [23:0] p11, p12, p13;
    logic [23:0] p21, p22, p23;
    logic [23:0] p31, p32, p33;
    
    // Update line buffers and window
    always_ff @(posedge clk) begin
        if (reset) begin
            p11 <= 24'd0; p12 <= 24'd0; p13 <= 24'd0;
            p21 <= 24'd0; p22 <= 24'd0; p23 <= 24'd0;
            p31 <= 24'd0; p32 <= 24'd0; p33 <= 24'd0;
        end else if (ready) begin
            // Shift window
            p11 <= p12; p12 <= p13; p13 <= line0[x_pos];
            p21 <= p22; p22 <= p23; p23 <= line1[x_pos];
            p31 <= p32; p32 <= p33; p33 <= line2[x_pos];
            
            // Update line buffers
            line0[x_pos] <= line1[x_pos];
            line1[x_pos] <= line2[x_pos];
            line2[x_pos] <= rgb_in_24bit;
        end
    end
    
    // Sobel edge detection
    logic [7:0] edge_magnitude;
    logic signed [31:0] gx_r, gy_r, gx_g, gy_g, gx_b, gy_b;
    logic signed [31:0] mag_r, mag_g, mag_b;

    always_comb begin
        // Compute Sobel X gradients (horizontal edges)
        gx_r = KX11 * $signed({1'b0, p11[23:16]}) +
               KX12 * $signed({1'b0, p12[23:16]}) +
               KX13 * $signed({1'b0, p13[23:16]}) +
               KX21 * $signed({1'b0, p21[23:16]}) +
               KX22 * $signed({1'b0, p22[23:16]}) +
               KX23 * $signed({1'b0, p23[23:16]}) +
               KX31 * $signed({1'b0, p31[23:16]}) +
               KX32 * $signed({1'b0, p32[23:16]}) +
               KX33 * $signed({1'b0, p33[23:16]});
        
        gx_g = KX11 * $signed({1'b0, p11[15:8]}) +
               KX12 * $signed({1'b0, p12[15:8]}) +
               KX13 * $signed({1'b0, p13[15:8]}) +
               KX21 * $signed({1'b0, p21[15:8]}) +
               KX22 * $signed({1'b0, p22[15:8]}) +
               KX23 * $signed({1'b0, p23[15:8]}) +
               KX31 * $signed({1'b0, p31[15:8]}) +
               KX32 * $signed({1'b0, p32[15:8]}) +
               KX33 * $signed({1'b0, p33[15:8]});
        
        gx_b = KX11 * $signed({1'b0, p11[7:0]}) +
               KX12 * $signed({1'b0, p12[7:0]}) +
               KX13 * $signed({1'b0, p13[7:0]}) +
               KX21 * $signed({1'b0, p21[7:0]}) +
               KX22 * $signed({1'b0, p22[7:0]}) +
               KX23 * $signed({1'b0, p23[7:0]}) +
               KX31 * $signed({1'b0, p31[7:0]}) +
               KX32 * $signed({1'b0, p32[7:0]}) +
               KX33 * $signed({1'b0, p33[7:0]});
        
        // Compute Sobel Y gradients (vertical edges)
        gy_r = KY11 * $signed({1'b0, p11[23:16]}) +
               KY12 * $signed({1'b0, p12[23:16]}) +
               KY13 * $signed({1'b0, p13[23:16]}) +
               KY21 * $signed({1'b0, p21[23:16]}) +
               KY22 * $signed({1'b0, p22[23:16]}) +
               KY23 * $signed({1'b0, p23[23:16]}) +
               KY31 * $signed({1'b0, p31[23:16]}) +
               KY32 * $signed({1'b0, p32[23:16]}) +
               KY33 * $signed({1'b0, p33[23:16]});
        
        gy_g = KY11 * $signed({1'b0, p11[15:8]}) +
               KY12 * $signed({1'b0, p12[15:8]}) +
               KY13 * $signed({1'b0, p13[15:8]}) +
               KY21 * $signed({1'b0, p21[15:8]}) +
               KY22 * $signed({1'b0, p22[15:8]}) +
               KY23 * $signed({1'b0, p23[15:8]}) +
               KY31 * $signed({1'b0, p31[15:8]}) +
               KY32 * $signed({1'b0, p32[15:8]}) +
               KY33 * $signed({1'b0, p33[15:8]});
        
        gy_b = KY11 * $signed({1'b0, p11[7:0]}) +
               KY12 * $signed({1'b0, p12[7:0]}) +
               KY13 * $signed({1'b0, p13[7:0]}) +
               KY21 * $signed({1'b0, p21[7:0]}) +
               KY22 * $signed({1'b0, p22[7:0]}) +
               KY23 * $signed({1'b0, p23[7:0]}) +
               KY31 * $signed({1'b0, p31[7:0]}) +
               KY32 * $signed({1'b0, p32[7:0]}) +
               KY33 * $signed({1'b0, p33[7:0]});
        
        // Approximate magnitude: |Gx| + |Gy| (faster than sqrt(Gx^2 + Gy^2))
        mag_r = (gx_r < 0 ? -gx_r : gx_r) + (gy_r < 0 ? -gy_r : gy_r);
        mag_g = (gx_g < 0 ? -gx_g : gx_g) + (gy_g < 0 ? -gy_g : gy_g);
        mag_b = (gx_b < 0 ? -gx_b : gx_b) + (gy_b < 0 ? -gy_b : gy_b);
        
        // Average the RGB channels for grayscale edge output
        edge_magnitude = ((mag_r + mag_g + mag_b) / 3);
        
        // Clamp to 8-bit range
        if (edge_magnitude > 255)
            edge_magnitude = 255;
    end
    
    // Convert 8-bit edge magnitude back to 4-bit for RGB444 output
    logic [3:0] edge_4bit;
    assign edge_4bit = edge_magnitude[7:4];  // Take upper 4 bits
    
    // Output as grayscale (same value for R, G, B) in RGB444 format
    assign video_out = {edge_4bit, edge_4bit, edge_4bit};
	 
endmodule