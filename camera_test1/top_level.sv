module top_level(
	input 	logic 		 CLOCK_50,
	input  	logic        OV7670_PCLK, 
	output 	logic        OV7670_XCLK,
	input 	logic        OV7670_VSYNC,
	input  	logic        OV7670_HREF,
	input  	logic [7:0]  OV7670_DATA,
	output 	logic        OV7670_SIOC,
	inout  	wire         OV7670_SIOD,
	output 	logic        OV7670_PWON,
	output 	logic        OV7670_RESET,
	input 	logic [3:0]  KEY,
	
	output logic        VGA_HS,
	output logic        VGA_VS,
	output logic [7:0]  VGA_R,
	output logic [7:0]  VGA_G,
	output logic [7:0]  VGA_B,
	output logic        VGA_BLANK_N,
	output logic        VGA_SYNC_N,
	output logic        VGA_CLK,
	
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3

);
	logic sys_reset = 1'b0;

	//Camera and VGA PLL
	logic       clk_25_vga;
	logic       clk_12_camera; 
	logic 		resend_camera_config;
	logic			video_pll_locked;
	logic 		config_finished;
	assign OV7670_XCLK = clk_25_vga;
	assign resent_camera_config = ~KEY[0];
	
	video_PLL U0(
		.refclk(CLOCK_50),  
		.rst(sys_reset),      
		.outclk_1(clk_25_vga), 
		.locked(video_pll_locked)   
	);
	
	//Camera programming and data stream
	logic [16:0] wraddress;
	logic [11:0] wrdata;
	logic wren;

	ov7670_controller U1(
		.clk(clk_25_vga),  
		.resend (resend_camera_config),
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



	logic filter_sop_out;
	logic filter_eop_out;
	logic vga_ready;
	logic [11:0] video_data /*synthesis keep*/;
	wire vga_blank;  
	wire vga_sync;   


	image_buffer U3
	(
		.data_in(wrdata),
		.rd_clk(clk_25_vga),
		.wr_clk(OV7670_PCLK),
		.ready(vga_ready), 
		.rst(sys_reset),
		.wren(wren),
		.wraddress(wraddress), 
		.image_start(filter_sop_out),
		.image_end(filter_eop_out),
		.data_out(video_data)
	);
	assign VGA_CLK = clk_25_vga;
	
	vga_driver U4(
		 .clk(clk_25_vga), 
		 .rst(sys_reset),
		 .pixel(video_data),
		 .hsync(VGA_HS),
		 .vsync(VGA_VS),
		 .r(VGA_R),
		 .g(VGA_G),
		 .b(VGA_B),
	    .VGA_BLANK_N(VGA_BLANK_N),
	    .VGA_SYNC_N(VGA_SYNC_N),
		 .ready(vga_ready)
	);
	
	// ========== Color Debug ==========
    
    logic [9:0]  debug_x_count;
    logic [8:0]  debug_y_count;
    logic [11:0] debug_center_pixel;
    logic [3:0]  debug_red, debug_green, debug_blue;
    logic [10:0] debug_red_dec;
    logic        debug_red_det, debug_green_det, debug_blue_det;
    
    // Color debug module
    color_debug U5 (
        .clk(clk_25_vga),
        .video_data(video_data),
        .vga_ready(vga_ready),
        .x_count(debug_x_count),
        .y_count(debug_y_count),
        .center_pixel(debug_center_pixel),
        .center_red(debug_red),
        .center_green(debug_green),
        .center_blue(debug_blue),
        .red_decimal(debug_red_dec),
        .green_decimal(), 
        .blue_decimal(),  
        .red_detected(debug_red_det),
        .green_detected(debug_green_det),
        .blue_detected(debug_blue_det)
    );
    
    // Display RED value on all 4 digits (only HEX1-0 will show 00-15)
    display u_display (
        .clk(clk_25_vga),
        .value(debug_red_dec),
        .display0(HEX0),  // Red units
        .display1(HEX1),  // Red tens  
        .display2(HEX2),  // Will be 0
        .display3(HEX3)   // Will be 0
    );
    

endmodule