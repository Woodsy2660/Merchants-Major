module top_level(
    input   logic        CLOCK_50,

    // Camera (OV7670)
    input   logic        OV7670_PCLK, 
    output  logic        OV7670_XCLK,
    input   logic        OV7670_VSYNC,
    input   logic        OV7670_HREF,
    input   logic [7:0]  OV7670_DATA,
    output  logic        OV7670_SIOC,
    inout   wire         OV7670_SIOD,
    output  logic        OV7670_PWDN,
    output  logic        OV7670_RESET,

    // Board inputs/outputs
    input   logic [3:0]  KEY,
    input   logic [17:0] SW,          // Use SW[17] to enable/disable IR
    inout   wire  [0:35] GPIO_1,

    output  logic [9:0]  LEDR,
    
    // IR Receiver
    input   logic        IRDA_RXD,

    // ==== DE1-SoC AUDIO + I2C (FFT/MIC section) ====
    output logic         FPGA_I2C_SCLK,
    inout  wire          FPGA_I2C_SDAT,
    input  logic         AUD_ADCDAT,
    input  logic         AUD_BCLK,
    output logic         AUD_XCK,
    input  logic         AUD_ADCLRCK,

    // VGA
    output logic         VGA_HS,
    output logic         VGA_VS,
    output logic [7:0]   VGA_R,
    output logic [7:0]   VGA_G,
    output logic [7:0]   VGA_B,
    output logic         VGA_BLANK_N,
    output logic         VGA_SYNC_N,
    output logic         VGA_CLK,

    // 7-seg (camera only)
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5
);

    // =========================================================
    // IR CONTROLLER SECTION - STANDALONE FOR DE1-SOC
    // =========================================================
    
    // Instead of instantiating the full DE2_115_IR module,
    // let's recreate just the IR control logic here for DE1-SoC
    
    // PLL for IR - Use DE1-SoC compatible PLL
    logic clk50_ir;
    logic ir_pll_locked;
    
    // Use your existing video_PLL or create a simple one for 50MHz passthrough
    // For now, just use CLOCK_50 directly
    assign clk50_ir = CLOCK_50;  // Bypass PLL for testing
    assign ir_pll_locked = 1'b1;
    
    // IR Receiver signals
    logic        ir_data_ready;
    logic [31:0] ir_hex_data;

    // IR Receiver module
    IR_RECEIVE ir_receive_inst(
        .iCLK(clk50_ir), 
        .iRST_n(KEY[0]),        
        .iIRDA(IRDA_RXD),       					
        .oDATA_READY(ir_data_ready),
        .oDATA(ir_hex_data)        
    );

    // UART and Robot Control signals
    localparam int IR_JSON_LEN = 24;
    
    // IR remote button codes (upper 16 bits)
    localparam [15:0] IR_BTN_FORWARD  = 16'hEC13;
    localparam [15:0] IR_BTN_BACKWARD = 16'hFD02;
    localparam [15:0] IR_BTN_LEFT     = 16'hF00F;
    localparam [15:0] IR_BTN_RIGHT    = 16'hEF10;
    localparam [15:0] IR_BTN_STOP     = 16'hFA05;

    // UART handshake signals
    logic ir_tx_valid = 1'b0;
    logic ir_tx_ready;
    logic [7:0] ir_byte_to_send = 0;
    logic ir_uart_out;
    integer ir_char_index = 0;

    // JSON command strings
    logic [7:0] ir_json_turn_left [0:IR_JSON_LEN-1] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h2D,8'h2E,8'h31,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h31,8'h7D,8'h0A};
    logic [7:0] ir_json_turn_right [0:IR_JSON_LEN-1] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h31,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h2E,8'h31,8'h7D,8'h0A};
    logic [7:0] ir_json_forward [0:IR_JSON_LEN-1] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h31,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h31,8'h7D,8'h0A};
    logic [7:0] ir_json_backward [0:IR_JSON_LEN-1] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h2D,8'h2E,8'h31,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h2E,8'h31,8'h7D,8'h0A};
    logic [7:0] ir_json_stop [0:IR_JSON_LEN-1] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h30,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h30,8'h7D,8'h0A};
    logic [7:0] ir_json_to_send [0:IR_JSON_LEN-1];

    // Button state detection
    logic [4:0] ir_button_state = 5'b0;
    logic [4:0] ir_button_state_prev = 5'b0;
    
    // Debug counters
    logic [31:0] ir_data_ready_count = 0;
    logic [31:0] ir_tx_count = 0;
    logic ir_any_button_pressed = 1'b0;

    // UART transmitter for IR commands
    uart_tx #(
        .CLKS_PER_BIT(50_000_000/115200),
        .BITS_N(8),
        .PARITY_TYPE(0)
    ) ir_uart_tx_inst (
        .clk(CLOCK_50), 
        .rst(~KEY[0]),  // Active high reset
        .data_tx(ir_byte_to_send),
        .valid(ir_tx_valid),
        .uart_out(ir_uart_out),
        .ready(ir_tx_ready)
    );
    
    // Connect UART to GPIO_1[31] - check your DE1-SoC pinout!
    // DE1-SoC GPIO might be indexed differently than DE2-115
    assign GPIO_1[31] = ir_uart_out;

    // IR Control Logic with extensive debugging
    always_ff @(posedge CLOCK_50) begin
        // Count IR data ready events for debugging
        if (ir_data_ready) begin
            ir_data_ready_count <= ir_data_ready_count + 1;
        end
        
        // Update button state based on IR input
        if (ir_data_ready) begin
            case (ir_hex_data[31:16])
                IR_BTN_FORWARD:  begin
                    ir_button_state <= 5'b10000;
                    ir_any_button_pressed <= 1'b1;
                end
                IR_BTN_BACKWARD: begin
                    ir_button_state <= 5'b01000;
                    ir_any_button_pressed <= 1'b1;
                end
                IR_BTN_LEFT: begin
                    ir_button_state <= 5'b00100;
                    ir_any_button_pressed <= 1'b1;
                end
                IR_BTN_RIGHT: begin
                    ir_button_state <= 5'b00010;
                    ir_any_button_pressed <= 1'b1;
                end
                IR_BTN_STOP: begin
                    ir_button_state <= 5'b00001;
                    ir_any_button_pressed <= 1'b1;
                end
                default: begin
                    ir_button_state <= 5'b00000;
                    ir_any_button_pressed <= 1'b0;
                end
            endcase
        end
        else begin
            ir_button_state <= 5'b00000;
        end
        
        ir_button_state_prev <= ir_button_state;
        
        // Check for rising edge on any button
        if (!ir_tx_valid) begin
            if (!ir_button_state_prev[4] && ir_button_state[4]) begin
                // Forward button pressed
                ir_json_to_send <= ir_json_forward;
                ir_tx_valid <= 1'b1;
                ir_byte_to_send <= ir_json_forward[0];
                ir_char_index <= 1;
                ir_tx_count <= ir_tx_count + 1;
            end
            else if (!ir_button_state_prev[3] && ir_button_state[3]) begin
                // Backward button pressed
                ir_json_to_send <= ir_json_backward;
                ir_tx_valid <= 1'b1;
                ir_byte_to_send <= ir_json_backward[0];
                ir_char_index <= 1;
                ir_tx_count <= ir_tx_count + 1;
            end
            else if (!ir_button_state_prev[2] && ir_button_state[2]) begin
                // Left button pressed
                ir_json_to_send <= ir_json_turn_left;
                ir_tx_valid <= 1'b1;
                ir_byte_to_send <= ir_json_turn_left[0];
                ir_char_index <= 1;
                ir_tx_count <= ir_tx_count + 1;
            end
            else if (!ir_button_state_prev[1] && ir_button_state[1]) begin
                // Right button pressed
                ir_json_to_send <= ir_json_turn_right;
                ir_tx_valid <= 1'b1;
                ir_byte_to_send <= ir_json_turn_right[0];
                ir_char_index <= 1;
                ir_tx_count <= ir_tx_count + 1;
            end
            else if (!ir_button_state_prev[0] && ir_button_state[0]) begin
                // Stop button pressed
                ir_json_to_send <= ir_json_stop;
                ir_tx_valid <= 1'b1;
                ir_byte_to_send <= ir_json_stop[0];
                ir_char_index <= 1;
                ir_tx_count <= ir_tx_count + 1;
            end
        end
        
        // Handshake protocol for transmission
        if (ir_tx_valid && ir_tx_ready) begin
            if (ir_char_index >= IR_JSON_LEN) begin
                ir_tx_valid <= 1'b0;
                ir_char_index <= 0;
            end
            else begin
                ir_byte_to_send <= ir_json_to_send[ir_char_index];
                ir_char_index <= ir_char_index + 1;
            end
        end
    end

    // =========================================================
    // Common / Camera Section (YOUR EXISTING CODE)
    // =========================================================
    logic sys_reset = 1'b0;

    // Camera and VGA PLL
    logic       clk_25_vga;
    logic       resend_camera_config;
    logic       video_pll_locked;
    logic       config_finished;

    assign OV7670_XCLK        = clk_25_vga;
    assign resend_camera_config = ~KEY[0];

    video_PLL U0(
        .refclk   (CLOCK_50),
        .rst      (sys_reset),
        .outclk_1 (clk_25_vga),
        .locked   (video_pll_locked)
    );

    // Camera programming and data stream
    logic [16:0] wraddress;
    logic [11:0] wrdata;
    logic        wren;

    ov7670_controller U1(
        .clk    (clk_25_vga),
        .resend (resend_camera_config),
        .config_finished(config_finished),
        .sioc   (OV7670_SIOC),
        .siod   (OV7670_SIOD),
        .reset  (OV7670_RESET),
        .pwdn   (OV7670_PWDN)
    );

    ov7670_pixel_capture DUT1 (
        .pclk (OV7670_PCLK),
        .vsync(OV7670_VSYNC),
        .href (OV7670_HREF),
        .d    (OV7670_DATA),
        .addr (wraddress),
        .pixel(wrdata),
        .we   (wren)
    );

    logic filter_sop_out, filter_eop_out;
    logic vga_ready;
    logic [11:0] video_data /* synthesis keep */;

    image_buffer U3 (
        .data_in   (wrdata),
        .rd_clk    (clk_25_vga),
        .wr_clk    (OV7670_PCLK),
        .ready     (vga_ready),
        .rst       (sys_reset),
        .wren      (wren),
        .wraddress (wraddress),
        .image_start(filter_sop_out),
        .image_end  (filter_eop_out),
        .data_out  (video_data)
    );

    assign VGA_CLK = clk_25_vga;

    // VGA driver
    logic [11:0] video_out;

    vga_driver U4(
        .clk          (clk_25_vga),
        .rst          (sys_reset),
        .pixel        (video_out),
        .hsync        (VGA_HS),
        .vsync        (VGA_VS),
        .r            (VGA_R),
        .g            (VGA_G),
        .b            (VGA_B),
        .VGA_BLANK_N  (VGA_BLANK_N),
        .VGA_SYNC_N   (VGA_SYNC_N),
        .ready        (vga_ready)
    );

    // ========== HSV Color Detection System ==========
    logic [9:0]  debug_x_count;
    logic [8:0]  debug_y_count;
    logic [11:0] debug_center_pixel;
    logic [3:0]  debug_red, debug_green, debug_blue;
    logic [8:0]  debug_hue;
    logic [7:0]  debug_sat, debug_val;
    logic [10:0] debug_hue_dec, debug_sat_dec, debug_val_dec;
    logic        debug_red_det, debug_green_det, debug_black_det;

    color_debug U5 (
        .clk                (clk_25_vga),
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
        .clk        (clk_25_vga),
        .vga_ready  (vga_ready),
        .x_count    (debug_x_count),
        .y_count    (debug_y_count),
        .video_data (video_data),
        .turn_left  (turn_left),
        .turn_right (turn_right),
        .centered   (centered)
    );

    // Overlay ROI / crosshairs
    roi_overlay overlay_inst (
        .x_count (debug_x_count),
        .y_count (debug_y_count),
        .video_in(video_data),
        .video_out(video_out)
    );

    // Camera HUE on 7-seg (keep for camera)
    display u_display (
        .clk     (clk_25_vga),
        .value   (debug_hue_dec),
        .display0(HEX0),
        .display1(HEX1),
        .display2(HEX2),
        .display3(HEX3)
    );
    
    // IR debug on HEX4/HEX5 - show last 2 digits of hex code received
    SEG_HEX ir_hex4(.iDIG(ir_hex_data[19:16]), .oHEX_D(HEX4));
    SEG_HEX ir_hex5(.iDIG(ir_hex_data[23:20]), .oHEX_D(HEX5));

    // =========================================================
    // ==================  FFT / MIC SECTION  ==================
    // =========================================================
    localparam int W         = 16;
    localparam int NSamples  = 1024;
    localparam logic [32:0] THRESHOLD = 33'h1000_0000;

    // I2C + ADC PLLs
    logic i2c_clk;
    i2c_pll i2c_pll_u (.areset(1'b0), .inclk0(CLOCK_50), .c0(i2c_clk));

    logic adc_clk;
    adc_pll adc_pll_u (.areset(1'b0), .inclk0(CLOCK_50), .c0(adc_clk));

    assign AUD_XCK = adc_clk;

    set_audio_encoder set_codec_de1_soc (
        .i2c_clk (i2c_clk),
        .I2C_SCLK(FPGA_I2C_SCLK),
        .I2C_SDAT(FPGA_I2C_SDAT)
    );

    logic [W-1:0] audio_input_data;
    logic         audio_input_valid;

    mic_load #(.N(W)) u_mic_load (
        .adclrc     (AUD_ADCLRCK),
        .bclk       (AUD_BCLK),
        .adcdat     (AUD_ADCDAT),
        .sample_data(audio_input_data),
        .valid      (audio_input_valid)
    );

    logic [$clog2(NSamples)-1:0] pitch_output_data;
    logic                        pitch_output_valid;
    logic                        whistle_detected;

    logic audio_reset;
    assign audio_reset = ~KEY[0]; 

    fft_pitch_detect #(
        .W         (W),
        .NSamples  (NSamples),
        .THRESHOLD (THRESHOLD)
    ) u_fft_pitch_detect (
        .audio_clk          (AUD_BCLK),
        .fft_clk            (adc_clk),
        .reset              (audio_reset),
        .audio_input_data   (audio_input_data),
        .audio_input_valid  (audio_input_valid),
        .pitch_output_data  (pitch_output_data),
        .pitch_output_valid (pitch_output_valid),
        .fire               (whistle_detected)
    );

    // =========================================================
    // ============ COMPREHENSIVE LED DEBUG MAPPING ============
    // =========================================================
    
    assign LEDR[0] = ir_data_ready;              // IR signal received
    assign LEDR[1] = ir_any_button_pressed;      // Any IR button recognized
    assign LEDR[2] = ir_button_state[4];         // Forward button
    assign LEDR[3] = ir_button_state[3];         // Backward button  
    assign LEDR[4] = ir_button_state[2];         // Left button
    assign LEDR[5] = ir_button_state[1];         // Right button
    assign LEDR[6] = ir_button_state[0];         // Stop button
    assign LEDR[7] = ir_tx_valid;                // UART transmitting
    assign LEDR[8] = ir_uart_out;                // UART TX line state
    assign LEDR[9] = ir_data_ready_count[20];    // Blink when IR data received (divided)

endmodule
