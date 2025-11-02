// Modified DE2_115_IR module with Robot Control via UART
// Based on Terasic DE2-115 IR Receiver Demo
// Added: UART transmission and robot movement control

module DE2_115_IR
	(
		//////// CLOCK //////////
		CLOCK_50,
		CLOCK2_50,
		CLOCK3_50,
		ENETCLK_25,

		//////// Sma //////////
		SMA_CLKIN,
		SMA_CLKOUT,

		//////// LED //////////
		LEDG,
		LEDR,

		//////// KEY //////////
		KEY,

		//////// SW //////////
		SW,

		//////// SEG7 //////////
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5,
		HEX6,
		HEX7,

		//////// LCD //////////
		LCD_BLON,
		LCD_DATA,
		LCD_EN,
		LCD_ON,
		LCD_RS,
		LCD_RW,

		//////// RS232 //////////
		UART_CTS,
		UART_RTS,
		UART_RXD,
		UART_TXD,

		//////// PS2 //////////
		PS2_CLK,
		PS2_DAT,
		PS2_CLK2,
		PS2_DAT2,

		//////// SDCARD //////////
		SD_CLK,
		SD_CMD,
		SD_DAT,
		SD_WP_N,

		//////// VGA //////////
		VGA_B,
		VGA_BLANK_N,
		VGA_CLK,
		VGA_G,
		VGA_HS,
		VGA_R,
		VGA_SYNC_N,
		VGA_VS,

		//////// Audio //////////
		AUD_ADCDAT,
		AUD_ADCLRCK,
		AUD_BCLK,
		AUD_DACDAT,
		AUD_DACLRCK,
		AUD_XCK,

		//////// I2C for EEPROM //////////
		EEP_I2C_SCLK,
		EEP_I2C_SDAT,

		//////// I2C for Audio and Tv-Decode //////////
		I2C_SCLK,
		I2C_SDAT,

		//////// Ethernet 0 //////////
		ENET0_GTX_CLK,
		ENET0_INT_N,
		ENET0_MDC,
		ENET0_MDIO,
		ENET0_RST_N,
		ENET0_RX_CLK,
		ENET0_RX_COL,
		ENET0_RX_CRS,
		ENET0_RX_DATA,
		ENET0_RX_DV,
		ENET0_RX_ER,
		ENET0_TX_CLK,
		ENET0_TX_DATA,
		ENET0_TX_EN,
		ENET0_TX_ER,
		ENET0_LINK100,

		//////// Ethernet 1 //////////
		ENET1_GTX_CLK,
		ENET1_INT_N,
		ENET1_MDC,
		ENET1_MDIO,
		ENET1_RST_N,
		ENET1_RX_CLK,
		ENET1_RX_COL,
		ENET1_RX_CRS,
		ENET1_RX_DATA,
		ENET1_RX_DV,
		ENET1_RX_ER,
		ENET1_TX_CLK,
		ENET1_TX_DATA,
		ENET1_TX_EN,
		ENET1_TX_ER,
		ENET1_LINK100,

		//////// TV Decoder //////////
		TD_CLK27,
		TD_DATA,
		TD_HS,
		TD_RESET_N,
		TD_VS,

		/////// USB OTG controller
		OTG_DATA,
		OTG_ADDR,
		OTG_CS_N,
		OTG_WR_N,
		OTG_RD_N,
		OTG_INT,
		OTG_RST_N,

		//////// IR Receiver //////////
		IRDA_RXD,

		//////// SDRAM //////////
		DRAM_ADDR,
		DRAM_BA,
		DRAM_CAS_N,
		DRAM_CKE,
		DRAM_CLK,
		DRAM_CS_N,
		DRAM_DQ,
		DRAM_DQM,
		DRAM_RAS_N,
		DRAM_WE_N,

		//////// SRAM //////////
		SRAM_ADDR,
		SRAM_CE_N,
		SRAM_DQ,
		SRAM_LB_N,
		SRAM_OE_N,
		SRAM_UB_N,
		SRAM_WE_N,

		//////// Flash //////////
		FL_ADDR,
		FL_CE_N,
		FL_DQ,
		FL_OE_N,
		FL_RST_N,
		FL_RY,
		FL_WE_N,
		FL_WP_N,

		//////// GPIO //////////
		GPIO,

		//////// HSMC (LVDS) //////////
		HSMC_CLKIN_P1,
		HSMC_CLKIN_P2,
		HSMC_CLKIN0,
		HSMC_CLKOUT_P1,
		HSMC_CLKOUT_P2,
		HSMC_CLKOUT0,
		HSMC_D,
		HSMC_RX_D_P,
		HSMC_TX_D_P,
		//////// EXTEND IO //////////
		EX_IO	
	   
	);

//===========================================================================
// PORT declarations
//===========================================================================
//////////// CLOCK //////////
input		          		CLOCK_50;
input		          		CLOCK2_50;
input		          		CLOCK3_50;
input		          		ENETCLK_25;

//////////// Sma //////////
input		          		SMA_CLKIN;
output		          	SMA_CLKOUT;

//////////// LED //////////
output		  [8:0]		LEDG;
output		  [17:0]		LEDR;

//////////// KEY //////////
input		     [3:0]		KEY;

//////////// SW //////////
input		     [17:0]		SW;

//////////// SEG7 //////////
output		  [6:0]		HEX0;
output		  [6:0]		HEX1;
output		  [6:0]		HEX2;
output		  [6:0]		HEX3;
output		  [6:0]		HEX4;
output		  [6:0]		HEX5;
output		  [6:0]		HEX6;
output		  [6:0]		HEX7;

//////////// LCD //////////
output		          	LCD_BLON;
inout		     [7:0]		LCD_DATA;
output		          	LCD_EN;
output		          	LCD_ON;
output		          	LCD_RS;
output		          	LCD_RW;

//////////// RS232 //////////
input		          	UART_CTS;
output		          		UART_RTS;
input		          		UART_RXD;
output		          	UART_TXD;

//////////// PS2 //////////
inout		          		PS2_CLK;
inout		          		PS2_DAT;
inout		          		PS2_CLK2;
inout		          		PS2_DAT2;

//////////// SDCARD //////////
output		          	SD_CLK;
inout		          		SD_CMD;
inout		     [3:0]		SD_DAT;
input		          		SD_WP_N;

//////////// VGA //////////
output		  [7:0]		VGA_B;
output		          	VGA_BLANK_N;
output		          	VGA_CLK;
output		  [7:0]		VGA_G;
output		          	VGA_HS;
output		  [7:0]		VGA_R;
output		          	VGA_SYNC_N;
output		          	VGA_VS;

//////////// Audio //////////
input		          		AUD_ADCDAT;
inout		          		AUD_ADCLRCK;
inout		          		AUD_BCLK;
output		          	AUD_DACDAT;
inout		          		AUD_DACLRCK;
output		          	AUD_XCK;

//////////// I2C for EEPROM //////////
output		          	EEP_I2C_SCLK;
inout		          		EEP_I2C_SDAT;

//////////// I2C for Audio and Tv-Decode //////////
output		          	I2C_SCLK;
inout		          		I2C_SDAT;

//////////// Ethernet 0 //////////
output		          	ENET0_GTX_CLK;
input		          		ENET0_INT_N;
output		          	ENET0_MDC;
inout		          		ENET0_MDIO;
output		          	ENET0_RST_N;
input		          		ENET0_RX_CLK;
input		          		ENET0_RX_COL;
input		          		ENET0_RX_CRS;
input		     [3:0]		ENET0_RX_DATA;
input		          		ENET0_RX_DV;
input		          		ENET0_RX_ER;
input		          		ENET0_TX_CLK;
output		  [3:0]		ENET0_TX_DATA;
output		          	ENET0_TX_EN;
output		          	ENET0_TX_ER;
input		          		ENET0_LINK100;

//////////// Ethernet 1 //////////
output		          	ENET1_GTX_CLK;
input		          		ENET1_INT_N;
output		          	ENET1_MDC;
inout		          		ENET1_MDIO;
output		          	ENET1_RST_N;
input		          		ENET1_RX_CLK;
input		          		ENET1_RX_COL;
input		          		ENET1_RX_CRS;
input		     [3:0]		ENET1_RX_DATA;
input		          		ENET1_RX_DV;
input		          		ENET1_RX_ER;
input		          		ENET1_TX_CLK;
output		  [3:0]		ENET1_TX_DATA;
output		          	ENET1_TX_EN;
output		          	ENET1_TX_ER;
input		          		ENET1_LINK100;

//////////// TV Decoder 1 //////////
input		          		TD_CLK27;
input		     [7:0]		TD_DATA;
input		          		TD_HS;
output		          	TD_RESET_N;
input		          		TD_VS;

//////////// USB OTG controller //////////
inout         [15:0]    OTG_DATA;
output        [1:0]     OTG_ADDR;
output                  OTG_CS_N;
output                  OTG_WR_N;
output                  OTG_RD_N;
input                   OTG_INT;
output                  OTG_RST_N;

//////////// IR Receiver //////////
input		          		IRDA_RXD;

//////////// SDRAM //////////
output		  [12:0]		DRAM_ADDR;
output		  [1:0]		DRAM_BA;
output		          	DRAM_CAS_N;
output		          	DRAM_CKE;
output		          	DRAM_CLK;
output		          	DRAM_CS_N;
inout		     [31:0]		DRAM_DQ;
output		  [3:0]		DRAM_DQM;
output		          	DRAM_RAS_N;
output		          	DRAM_WE_N;

//////////// SRAM //////////
output		 [19:0]		SRAM_ADDR;
output		          	SRAM_CE_N;
inout		    [15:0]		SRAM_DQ;
output		          	SRAM_LB_N;
output		          	SRAM_OE_N;
output		          	SRAM_UB_N;
output		          	SRAM_WE_N;

//////////// Flash //////////
output		 [22:0]		FL_ADDR;
output		          	FL_CE_N;
inout		    [7:0]		FL_DQ;
output		          	FL_OE_N;
output		          	FL_RST_N;
input		          		FL_RY;
output		          	FL_WE_N;
output		          	FL_WP_N;

//////////// GPIO //////////
inout		    [35:0]		GPIO;

//////////// HSMC (LVDS) //////////
input		          		HSMC_CLKIN_P1;
input		          		HSMC_CLKIN_P2;
input		          		HSMC_CLKIN0;
output		          	HSMC_CLKOUT_P1;
output		          	HSMC_CLKOUT_P2;
output		          	HSMC_CLKOUT0;
inout		     [3:0]		HSMC_D;
input		     [16:0]		HSMC_RX_D_P;
output		  [16:0]		HSMC_TX_D_P;

//////// EXTEND IO //////////
inout		     [6:0]		EX_IO;


//=============================================================================
// Structural coding
//=============================================================================

// All inout ports turn to tri-state (unchanged from original)
assign	SD_DAT		=	4'b1zzz;  
assign	AUD_ADCLRCK	=	AUD_DACLRCK;
assign	HSMC_D   	=	4'hz;
assign	EX_IO   	=	7'bzz;

// PLL for IR receiver clock
pll1 u0(
		.inclk0(CLOCK_50),
		.c0(clk50),          
		.c1()
);

// IR Receiver module (unchanged from original)
IR_RECEIVE u1(
		.iCLK(clk50), 
		.iRST_n(KEY[0]),        
		.iIRDA(IRDA_RXD),       					
		.oDATA_READY(data_ready),
		.oDATA(hex_data)        
);

// UART Transmitter - sends JSON commands to robot via GPIO[31]
// Make sure you have uart_tx.v in your project!
uart_tx #(
		.CLKS_PER_BIT(50_000_000/115200),
		.BITS_N(8),
		.PARITY_TYPE(0)
) uart_tx_inst (
		.clk(CLOCK_50), 
		.rst(1'b0), 
		.data_tx(byte_to_send),
		.valid(tx_valid),
		.uart_out(GPIO[31]),  // UART output on GPIO pin 31
		.ready(tx_ready)
);

// 7-Segment display modules (unchanged from original)
// Display IR codes on HEX displays
SEG_HEX u2(.iDIG(hex_data[31:28]), .oHEX_D(HEX0));  
SEG_HEX u3(.iDIG(hex_data[27:24]), .oHEX_D(HEX1));
SEG_HEX u4(.iDIG(hex_data[23:20]), .oHEX_D(HEX2));
SEG_HEX u5(.iDIG(hex_data[19:16]), .oHEX_D(HEX3));
SEG_HEX u6(.iDIG(hex_data[15:12]), .oHEX_D(HEX4));
SEG_HEX u7(.iDIG(hex_data[11:8]),  .oHEX_D(HEX5));
SEG_HEX u8(.iDIG(hex_data[7:4]),   .oHEX_D(HEX6));
SEG_HEX u9(.iDIG(hex_data[3:0]),   .oHEX_D(HEX7));

//=============================================================================
// REG/WIRE declarations
//=============================================================================

// IR Receiver signals
wire    data_ready;        // IR data_ready flag
wire    [31:0] hex_data;   // IR decoded data
wire    clk50;             // PLL 50M output for IRDA

//=============================================================================
// IR ROBOT CONTROL - FIXED VERSION
//=============================================================================

// UART and Robot Control signals
localparam JSON_LEN = 24;  // Back to 24 characters

// IR remote button codes (upper 16 bits of hex_data)
localparam [15:0] BTN_FORWARD  = 16'hEC13;
localparam [15:0] BTN_BACKWARD = 16'hFD02;
localparam [15:0] BTN_LEFT     = 16'hF00F;
localparam [15:0] BTN_RIGHT    = 16'hEF10;
localparam [15:0] BTN_STOP     = 16'hFA05;

// UART handshake signals
logic tx_valid = 1'b0;
logic tx_ready;

// Data to transmit
logic [7:0] byte_to_send = 0;
integer char_index = 0;

// JSON command strings - Very slow speeds (0.1), T=1 second
// Turn left: {"T":1,"L":-.1,"R":0.1}
logic [7:0] json_turn_left [JSON_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h2D,8'h2E,8'h31,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h31,8'h7D,8'h0A};
// Turn right: {"T":1,"L":0.1,"R":-.1}
logic [7:0] json_turn_right [JSON_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h31,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h2E,8'h31,8'h7D,8'h0A};
// Move forward: {"T":1,"L":0.1,"R":0.1}
logic [7:0] json_forward [JSON_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h31,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h31,8'h7D,8'h0A};
// Move backward: {"T":1,"L":-.1,"R":-.1}
logic [7:0] json_backward [JSON_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h2D,8'h2E,8'h31,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h2E,8'h31,8'h7D,8'h0A};
// Stop: {"T":1,"L":0.0,"R":0.0}
logic [7:0] json_stop [JSON_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h30,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h30,8'h7D,8'h0A};

// Intermediate array to hold command being sent
logic [7:0] json_to_send [JSON_LEN];

// Store the most recent button pressed
logic [4:0] button_state = 5'b0;
logic [4:0] button_state_prev = 5'b0;

// Improved edge detection - capture stable data
logic [31:0] hex_data_captured = 32'h0;
logic data_ready_d1 = 1'b0;
logic data_ready_d2 = 1'b0;
wire data_ready_stable = data_ready_d1 && data_ready_d2;  // Data ready for 2 cycles = stable

//=============================================================================
// Main Control Logic - FIXED
//=============================================================================
always_ff @(posedge CLOCK_50) begin
    // Update button state based on IR input
    if (data_ready) begin
        case (hex_data[31:16])
            BTN_FORWARD:  button_state <= 5'b10000;
            BTN_BACKWARD: button_state <= 5'b01000;
            BTN_LEFT:     button_state <= 5'b00100;
            BTN_RIGHT:    button_state <= 5'b00010;
            BTN_STOP:     button_state <= 5'b00001;
            default:      button_state <= 5'b00000;
        endcase
    end
    else begin
        button_state <= 5'b00000;  // Clear when no IR signal
    end
    
    button_state_prev <= button_state;
    
    // Check for rising edge on any button
    if (!tx_valid) begin
        if (!button_state_prev[4] && button_state[4]) begin
            // Forward button pressed
            json_to_send <= json_forward;
            tx_valid <= 1'b1;
            byte_to_send <= json_forward[0];
            char_index <= 1;
        end
        else if (!button_state_prev[3] && button_state[3]) begin
            // Backward button pressed
            json_to_send <= json_backward;
            tx_valid <= 1'b1;
            byte_to_send <= json_backward[0];
            char_index <= 1;
        end
        else if (!button_state_prev[2] && button_state[2]) begin
            // Left button pressed
            json_to_send <= json_turn_left;
            tx_valid <= 1'b1;
            byte_to_send <= json_turn_left[0];
            char_index <= 1;
        end
        else if (!button_state_prev[1] && button_state[1]) begin
            // Right button pressed
            json_to_send <= json_turn_right;
            tx_valid <= 1'b1;
            byte_to_send <= json_turn_right[0];
            char_index <= 1;
        end
        else if (!button_state_prev[0] && button_state[0]) begin
            // Stop button pressed
            json_to_send <= json_stop;
            tx_valid <= 1'b1;
            byte_to_send <= json_stop[0];
            char_index <= 1;
        end
    end
    
    // Handshake protocol for transmission
    if (tx_valid && tx_ready) begin
        if (char_index >= JSON_LEN) begin
            tx_valid <= 1'b0;
            char_index <= 0;  // CRITICAL FIX: Reset char_index!
        end
        else begin
            byte_to_send <= json_to_send[char_index];
            char_index <= char_index + 1;
        end
    end
end

//=============================================================================
// LED DEBUGGING INDICATORS
//=============================================================================
assign LEDR[0] = data_ready;
assign LEDR[1] = tx_valid;
assign LEDR[2] = tx_ready;
assign LEDR[3] = data_ready_stable;  // Shows when data is stable
assign LEDR[7:4] = 4'b0;
assign LEDR[12:8] = button_state;
assign LEDR[17:13] = char_index[4:0];

assign LEDG[0] = button_state[4];  // Forward
assign LEDG[1] = button_state[3];  // Backward
assign LEDG[2] = button_state[2];  // Left
assign LEDG[3] = button_state[1];  // Right
assign LEDG[4] = button_state[0];  // Stop

endmodule
