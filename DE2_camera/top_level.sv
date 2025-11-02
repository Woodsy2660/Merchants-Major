

// DE2 top_level: merged DE2 base + your DE1 camera detection & overlay logic
module top_level(
    input  logic         CLOCK_50,
    input  logic         OV7670_PCLK,
    output logic         OV7670_XCLK,
    input  logic         OV7670_VSYNC,
    input  logic         OV7670_HREF,
    input  logic [7:0]   OV7670_DATA,
    output logic         OV7670_SIOC,
    inout  wire          OV7670_SIOD,
    output logic         OV7670_PWDN,
    output logic         OV7670_RESET,

    // VGA
    output logic         VGA_HS,
    output logic         VGA_VS,
    output logic [7:0]   VGA_R,
    output logic [7:0]   VGA_G,
    output logic [7:0]   VGA_B,
    output logic         VGA_BLANK_N,
    output logic         VGA_SYNC_N,
    output logic         VGA_CLK,
	 
	 output  logic [17:0]  LEDR,

    input  logic [3:0]   KEY,

    // 7-seg displays (kept from your DE1 design)
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5
);

    // ---------------------------------------------------------
    // Basic reset/clock plumbing
    // ---------------------------------------------------------
    logic sys_reset = 1'b0;
	 
	 

    // Camera and VGA PLL (DE2 uses clk_video name)
    logic       clk_video;
    logic       send_camera_config;   assign send_camera_config = !KEY[2];
    logic       video_pll_locked;
    logic       config_finished;

    assign OV7670_XCLK = clk_video;

    video_pll U0(
         .areset(sys_reset),
         .inclk0(CLOCK_50),
         .c0(clk_video),
         .locked(video_pll_locked)
    );

    // ---------------------------------------------------------
    // Camera programming and data stream (same as DE2 base)
    // ---------------------------------------------------------
    logic [16:0] wraddress;
    logic [11:0] wrdata;
    logic        wren;

    ov7670_controller U1(
        .clk(clk_video),
        .resend (send_camera_config),
        .config_finished (config_finished),
        .sioc   (OV7670_SIOC),
        .siod   (OV7670_SIOD),
        .reset  (OV7670_RESET),
        .pwdn   (OV7670_PWDN)
    );

    ov7670_pixel_capture DUT1 (
        .pclk(OV7670_PCLK),
        .vsync(OV7670_VSYNC),
        .href(OV7670_HREF),
        .d(OV7670_DATA),
        .addr(wraddress),
        .pixel(wrdata),
        .we(wren)
    );

    // Buffer / handshake signals (keep names consistent)
    logic filter_sop_out;
    logic filter_eop_out;
    logic vga_ready;
    logic [11:0] video_data;

    image_buffer U3 (
        .data_in(wrdata),
        .rd_clk(clk_video),
        .wr_clk(OV7670_PCLK),
        .ready(vga_ready),
        .rst(sys_reset),
        .wren(wren),
        .wraddress(wraddress),
        .image_start(filter_sop_out),
        .image_end(filter_eop_out),
        .data_out(video_data)
    );

    assign VGA_CLK = clk_video;
	 
	 logic [11:0] video_out;

    // VGA driver (DE2 base)
    vga_driver U4(
         .clk(clk_video),
         .rst(sys_reset),
         .pixel(video_out),		// putting video_out here should display the central ROI overlay
         .hsync(VGA_HS),
         .vsync(VGA_VS),
         .r(VGA_R),
         .g(VGA_G),
         .b(VGA_B),
         .VGA_BLANK_N(VGA_BLANK_N),
         .VGA_SYNC_N(VGA_SYNC_N),
         .ready(vga_ready)
    );

    // ---------------------------------------------------------
    // ====== HSV Color Detection System (from your DE1) ======
    // ---------------------------------------------------------
    logic [9:0]  debug_x_count;
    logic [8:0]  debug_y_count;
    logic [11:0] debug_center_pixel;
    logic [3:0]  debug_red, debug_green, debug_blue;
    logic [8:0]  debug_hue;
    logic [7:0]  debug_sat, debug_val;
    logic [10:0] debug_hue_dec, debug_sat_dec, debug_val_dec;
    logic        debug_red_det, debug_green_det, debug_black_det;

    color_debug U5 (
        .clk                (clk_video),
        .video_data         (video_data),
        .vga_ready          (vga_ready),
        .x_count            (debug_x_count),
        .y_count            (debug_y_count),
        .center_pixel       (debug_center_pixel),
        .center_red         (debug_red),
        .center_green       (debug_green),
        .center_blue        (debug_blue),
        .center_hue         (debug_hue),
        .center_saturation  (debug_sat),
        .center_value       (debug_val),
        .hue_decimal        (debug_hue_dec),
        .sat_decimal        (debug_sat_dec),
        .val_decimal        (debug_val_dec),
        .red_detected       (debug_red_det),
        .green_detected     (debug_green_det),
        .black_detected     (debug_black_det)
    );

    // Camera drive flags (frame-held)
    logic turn_left, turn_right, centered;

    camera_drive_flags #(
        .IMG_W(640), .IMG_H(480), .MID_X(320), .MID_Y(240),
        .MIN_COLORED_PIXELS(500)
    ) u_drive_flags (
        .clk        (clk_video),
        .vga_ready  (vga_ready),
        .x_count    (debug_x_count),
        .y_count    (debug_y_count),
        .video_data (video_data),
        .turn_left  (turn_left),
        .turn_right (turn_right),
        .centered   (centered)
    );

    // Overlay ROI / crosshairs: output pixel (overlays on top of video)
 
    roi_overlay overlay_inst (
        .x_count (debug_x_count),
        .y_count (debug_y_count),
        .video_in(video_data),
        .video_out(video_out)
    );

    // Because vga_driver expects 'pixel' input, route video_out instead of video_data
    // Reconnect U4 to use video_out -- simplest approach is to drive the vga with video_out here:
    // (If you prefer keeping vga_driver instantiation above unchanged, replace its .pixel argument with video_out.)
    // For clarity, instantiate second vga_driver replacement (or modify original): here we simply reassign
    // Note: some projects instead pass video_out directly into the existing vga_driver; edit that instance if needed.
    // We'll multiplex: if overlay modifies pixels then output video_out; otherwise fall back to video_data.
    // So update the VGA driver connection if required in your project. If you prefer, replace the original vga_driver .pixel(video_data)
    // with .pixel(video_out). This file assumes you will change the vga_driver connection to video_out.
	 
	 
	 
	 // Example mapping of detection to LEDs
	assign LEDR[0] = debug_red_det;     // lights when a red pixel is seen at the center
	assign LEDR[1] = debug_green_det;   // lights when a green pixel is seen
	assign LEDR[2] = debug_black_det;   // lights when a black pixel is seen

	// Frame-held drive decisions
	assign LEDR[3] = turn_left;        // lights when the camera wants to turn left
	assign LEDR[4] = turn_right;       // lights when the camera wants to turn right
	assign LEDR[5] = centered;         // lights when the camera sees black at the center


    // ---------------------------------------------------------
    // Camera HUE on 7-seg (keep for camera)
    // ---------------------------------------------------------
    display u_display (
        .clk     (clk_video),
        .value   (debug_hue_dec),
        .display0(HEX0),
        .display1(HEX1),
        .display2(HEX2),
        .display3(HEX3)
    );

    // If you want to show debug hex for other values, map HEX4/HEX5 accordingly:
    assign HEX4 = 7'h7F; // blank (active-low segments may differ — adjust per your SEG module)
    assign HEX5 = 7'h7F; // blank

endmodule








//
//// New Toplevel: integrated Ben's augmented camera code
//
//module top_level(
//    input   logic        CLOCK_50,
//
//    // Camera (OV7670)
//    input   logic        OV7670_PCLK, 
//    output  logic        OV7670_XCLK,
//    input   logic        OV7670_VSYNC,
//    input   logic        OV7670_HREF,
//    input   logic [7:0]  OV7670_DATA,
//    output  logic        OV7670_SIOC,
//    inout   wire         OV7670_SIOD,
//    output  logic        OV7670_PWDN,
//    output  logic        OV7670_RESET,
//
//    // Board inputs/outputs
//    input   logic [3:0]  KEY,
//    input   logic [17:0] SW,          // Use SW[17] to enable/disable IR
//    inout   wire  [0:35] GPIO_1,
//
//    output  logic [9:0]  LEDR,
//    
//    // IR Receiver
//    input   logic        IRDA_RXD,
//
//    // ==== DE1-SoC AUDIO + I2C (FFT/MIC section) ====
//    output logic         FPGA_I2C_SCLK,
//    inout  wire          FPGA_I2C_SDAT,
//    input  logic         AUD_ADCDAT,
//    input  logic         AUD_BCLK,
//    output logic         AUD_XCK,
//    input  logic         AUD_ADCLRCK,
//
//    // VGA
//    output logic         VGA_HS,
//    output logic         VGA_VS,
//    output logic [7:0]   VGA_R,
//    output logic [7:0]   VGA_G,
//    output logic [7:0]   VGA_B,
//    output logic         VGA_BLANK_N,
//    output logic         VGA_SYNC_N,
//    output logic         VGA_CLK,
//
//    // 7-seg (camera only)
//    output [6:0] HEX0,
//    output [6:0] HEX1,
//    output [6:0] HEX2,
//    output [6:0] HEX3,
//    output [6:0] HEX4,
//    output [6:0] HEX5
//);
//
//
//    // =========================================================
//    // Common / Camera Section (YOUR EXISTING CODE)
//    // =========================================================
//    logic sys_reset = 1'b0;
//
//    // Camera and VGA PLL
//    logic       clk_25_vga;
//    logic       resend_camera_config;
//    logic       video_pll_locked;
//    logic       config_finished;
//
//    assign OV7670_XCLK        = clk_25_vga;
//    assign resend_camera_config = ~KEY[0];
//
//		video_pll U0(
//			 .areset(sys_reset),
//			 .inclk0(CLOCK_50),
//			 .c0(clk_video),
//			 .locked(video_pll_locked)
//		);
//
//    // Camera programming and data stream
//    logic [16:0] wraddress;
//    logic [11:0] wrdata;
//    logic        wren;
//
//    ov7670_controller U1(
//        .clk    (clk_25_vga),
//        .resend (resend_camera_config),
//        .config_finished(config_finished),
//        .sioc   (OV7670_SIOC),
//        .siod   (OV7670_SIOD),
//        .reset  (OV7670_RESET),
//        .pwdn   (OV7670_PWDN)
//    );
//
//    ov7670_pixel_capture DUT1 (
//        .pclk (OV7670_PCLK),
//        .vsync(OV7670_VSYNC),
//        .href (OV7670_HREF),
//        .d    (OV7670_DATA),
//        .addr (wraddress),
//        .pixel(wrdata),
//        .we   (wren)
//    );
//
//    logic filter_sop_out, filter_eop_out;
//    logic vga_ready;
//    logic [11:0] video_data /* synthesis keep */;
//
//    image_buffer U3 (
//        .data_in   (wrdata),
//        .rd_clk    (clk_25_vga),
//        .wr_clk    (OV7670_PCLK),
//        .ready     (vga_ready),
//        .rst       (sys_reset),
//        .wren      (wren),
//        .wraddress (wraddress),
//        .image_start(filter_sop_out),
//        .image_end  (filter_eop_out),
//        .data_out  (video_data)
//    );
//
//    assign VGA_CLK = clk_25_vga;
//
//    // VGA driver
//    logic [11:0] video_out;
//
//    vga_driver U4(
//        .clk          (clk_25_vga),
//        .rst          (sys_reset),
//        .pixel        (video_out),
//        .hsync        (VGA_HS),
//        .vsync        (VGA_VS),
//        .r            (VGA_R),
//        .g            (VGA_G),
//        .b            (VGA_B),
//        .VGA_BLANK_N  (VGA_BLANK_N),
//        .VGA_SYNC_N   (VGA_SYNC_N),
//        .ready        (vga_ready)
//    );
//
//    // ========== HSV Color Detection System ==========
//    logic [9:0]  debug_x_count;
//    logic [8:0]  debug_y_count;
//    logic [11:0] debug_center_pixel;
//    logic [3:0]  debug_red, debug_green, debug_blue;
//    logic [8:0]  debug_hue;
//    logic [7:0]  debug_sat, debug_val;
//    logic [10:0] debug_hue_dec, debug_sat_dec, debug_val_dec;
//    logic        debug_red_det, debug_green_det, debug_black_det;
//
//    color_debug U5 (
//        .clk                (clk_25_vga),
//        .video_data         (video_data),
//        .vga_ready          (vga_ready),
//        .x_count            (debug_x_count),
//        .y_count            (debug_y_count),
//        .center_pixel       (debug_center_pixel),
//        .center_red         (debug_red),
//        .center_green       (debug_green),
//        .center_blue        (debug_blue),
//        .center_hue         (debug_hue),
//        .center_saturation  (debug_sat),
//        .center_value       (debug_val),
//        .hue_decimal        (debug_hue_dec),
//        .sat_decimal        (debug_sat_dec),
//        .val_decimal        (debug_val_dec),
//        .red_detected       (debug_red_det),
//        .green_detected     (debug_green_det),
//        .black_detected     (debug_black_det)
//    );
//
//    // Camera drive flags (frame-held)
//    logic turn_left, turn_right, centered;
//
//    camera_drive_flags #(
//        .IMG_W(640), .IMG_H(480), .MID_X(320), .MID_Y(240),
//        .MIN_COLORED_PIXELS(500)
//    ) u_drive_flags (
//        .clk        (clk_25_vga),
//        .vga_ready  (vga_ready),
//        .x_count    (debug_x_count),
//        .y_count    (debug_y_count),
//        .video_data (video_data),
//        .turn_left  (turn_left),
//        .turn_right (turn_right),
//        .centered   (centered)
//    );
//
//    // Overlay ROI / crosshairs
//    roi_overlay overlay_inst (
//        .x_count (debug_x_count),
//        .y_count (debug_y_count),
//        .video_in(video_data),
//        .video_out(video_out)
//    );
//
//    // Camera HUE on 7-seg (keep for camera)
//    display u_display (
//        .clk     (clk_25_vga),
//        .value   (debug_hue_dec),
//        .display0(HEX0),
//        .display1(HEX1),
//        .display2(HEX2),
//        .display3(HEX3)
//    );
// 
//
//endmodule
//

