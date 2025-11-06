module sobel_edge_filter #(
    parameter WIDTH = 640,
    parameter HEIGHT = 480,
    parameter ANGLE_THRESHOLD = 10  // Degrees from H/V axis (adjustable)
)(
    input  logic        clk,
    input  logic        reset,
    
    input  logic [11:0] video_in,
    input  logic        ready,
    output logic [11:0] video_out
);

    // Extract and expand RGB
    logic [3:0] r_in, g_in, b_in;
    assign r_in = video_in[11:8];
    assign g_in = video_in[7:4];
    assign b_in = video_in[3:0];
    
    logic [7:0] r_in_8bit, g_in_8bit, b_in_8bit;
    assign r_in_8bit = {r_in, r_in};
    assign g_in_8bit = {g_in, g_in};
    assign b_in_8bit = {b_in, b_in};
    
    logic [23:0] rgb_in_24bit;
    assign rgb_in_24bit = {r_in_8bit, g_in_8bit, b_in_8bit};

    // Sobel kernels
    localparam logic signed [7:0] KX11 = -1, KX12 = 0, KX13 = 1;
    localparam logic signed [7:0] KX21 = -2, KX22 = 0, KX23 = 2;
    localparam logic signed [7:0] KX31 = -1, KX32 = 0, KX33 = 1;
    
    localparam logic signed [7:0] KY11 = -1, KY12 = -2, KY13 = -1;
    localparam logic signed [7:0] KY21 =  0, KY22 =  0, KY23 =  0;
    localparam logic signed [7:0] KY31 =  1, KY32 =  2, KY33 =  1;
    
    // Position tracking
    logic [9:0] x_pos, y_pos;
    
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
    
    // Line buffers
    logic [23:0] line0 [WIDTH-1:0];
    logic [23:0] line1 [WIDTH-1:0];
    logic [23:0] line2 [WIDTH-1:0];
    
    // 3x3 window
    logic [23:0] p11, p12, p13;
    logic [23:0] p21, p22, p23;
    logic [23:0] p31, p32, p33;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            p11 <= 24'd0; p12 <= 24'd0; p13 <= 24'd0;
            p21 <= 24'd0; p22 <= 24'd0; p23 <= 24'd0;
            p31 <= 24'd0; p32 <= 24'd0; p33 <= 24'd0;
        end else if (ready) begin
            p11 <= p12; p12 <= p13; p13 <= line0[x_pos];
            p21 <= p22; p22 <= p23; p23 <= line1[x_pos];
            p31 <= p32; p32 <= p33; p33 <= line2[x_pos];
            
            line0[x_pos] <= line1[x_pos];
            line1[x_pos] <= line2[x_pos];
            line2[x_pos] <= rgb_in_24bit;
        end
    end
    
    // Edge detection with direction filtering
    logic [7:0] edge_output;
    logic signed [31:0] gx_avg, gy_avg;
    logic signed [31:0] gx_r, gy_r, gx_g, gy_g, gx_b, gy_b;
    logic [31:0] abs_gx, abs_gy;
    logic [31:0] magnitude;
    logic is_horizontal, is_vertical;

    always_comb begin
        // Compute Sobel gradients for each channel
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
        
        // Average gradients across RGB channels
        gx_avg = (gx_r + gx_g + gx_b) / 3;
        gy_avg = (gy_r + gy_g + gy_b) / 3;
        
        // Absolute values
        abs_gx = (gx_avg < 0) ? -gx_avg : gx_avg;
        abs_gy = (gy_avg < 0) ? -gy_avg : gy_avg;
        
        // Compute magnitude (always)
        magnitude = abs_gx + abs_gy;
        
        // Direction detection:
        // Vertical edge: Gx >> Gy (strong horizontal gradient)
        // Horizontal edge: Gy >> Gx (strong vertical gradient)
        // For 15° threshold: tan(15°) ≈ 0.268, so use ratio of ~4:1
        
        is_vertical = (abs_gx > (abs_gy << 2));    // Gx > 4*Gy (vertical lines)
        is_horizontal = (abs_gy > (abs_gx << 2));  // Gy > 4*Gx (horizontal lines)
        
        // Only output edge if it's horizontal or vertical
        if (is_horizontal || is_vertical) begin
            // Clamp to 8-bit
            if (magnitude > 255)
                edge_output = 8'd255;
            else
                edge_output = magnitude[7:0];
        end else begin
            edge_output = 8'd0;  // Suppress diagonal/noisy edges
        end
    end
    
    // Convert to 4-bit RGB444
    logic [3:0] edge_4bit;
    assign edge_4bit = edge_output[7:4];
    assign video_out = {edge_4bit, edge_4bit, edge_4bit};

endmodule