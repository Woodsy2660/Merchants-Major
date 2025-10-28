module top_level(
	input         CLOCK_50,
	inout  [35:0] GPIO,
	input  [3:0]  KEY,
	output [6:0]  HEX0,
	output [6:0]  HEX1,
	output [6:0]  HEX2,
	output [6:0]  HEX3,
	output [9:0]  LEDR
);

logic echo, trigger;
logic sonar_ready, sonar_valid;
logic SONAR_CLK;
logic [11:0] distance_mm;
logic [11:0] latched_distance_mm;
logic locked;

// Auto-trigger logic - continuously measure
logic auto_trigger;
logic [25:0] trigger_delay = 26'd0;
localparam TRIGGER_PERIOD = 26'd5_000_000; // 100ms between measurements

always_ff @(posedge CLOCK_50) begin
	if (trigger_delay >= TRIGGER_PERIOD) begin
		trigger_delay <= 26'd0;
		auto_trigger <= 1'b1;
	end else begin
		trigger_delay <= trigger_delay + 26'd1;
		auto_trigger <= 1'b0;
	end
end

// GPIO connections
assign echo = GPIO[29];
assign GPIO[27] = trigger;

// Latch distance when valid
always_ff @(posedge CLOCK_50) begin
	if (sonar_valid) begin
		latched_distance_mm <= distance_mm; 
	end
end

// PLL to generate 43.904 MHz clock
sonar_pll sonar_pll (
	.areset(~KEY[0]),       // Reset with KEY[0]
	.inclk0(CLOCK_50),
	.c0(SONAR_CLK),
	.locked(locked)
);

// Sonar range finder module	
sonar_range sonar_range(
	.clk(SONAR_CLK),           // 43.904MHz from PLL
	.start_measure(auto_trigger), // Auto-trigger continuously
	.rst(~KEY[0]),             // Reset with KEY[0]
	.echo(echo),
	.trig(trigger),
	.distance(distance_mm),
	.ready(sonar_ready),
	.valid(sonar_valid)
);

// Display distance on 7-segment
display u_display(
	.clk(CLOCK_50),
	.value(latched_distance_mm),
	.display0(HEX0),
	.display1(HEX1),
	.display2(HEX2),
	.display3(HEX3)
);

// LED distance indicator
// Each 100mm interval lights up one fewer LED
// 0-100mm: all 10 LEDs
// 100-200mm: 9 LEDs
// 200-300mm: 8 LEDs
// etc.
logic [9:0] distance_leds;

always_comb begin
	// Calculate how many LEDs should be lit
	// distance_mm / 100 gives number of 100mm intervals
	// 10 - (distance_mm / 100) gives LEDs to light
	
	if (latched_distance_mm < 12'd100)
		distance_leds = 10'b1111111111; // All 10 LEDs
	else if (latched_distance_mm < 12'd200)
		distance_leds = 10'b0111111111; // 9 LEDs
	else if (latched_distance_mm < 12'd300)
		distance_leds = 10'b0011111111; // 8 LEDs
	else if (latched_distance_mm < 12'd400)
		distance_leds = 10'b0001111111; // 7 LEDs
	else if (latched_distance_mm < 12'd500)
		distance_leds = 10'b0000111111; // 6 LEDs
	else if (latched_distance_mm < 12'd600)
		distance_leds = 10'b0000011111; // 5 LEDs
	else if (latched_distance_mm < 12'd700)
		distance_leds = 10'b0000001111; // 4 LEDs
	else if (latched_distance_mm < 12'd800)
		distance_leds = 10'b0000000111; // 3 LEDs
	else if (latched_distance_mm < 12'd900)
		distance_leds = 10'b0000000011; // 2 LEDs
	else if (latched_distance_mm < 12'd1000)
		distance_leds = 10'b0000000001; // 1 LED
	else
		distance_leds = 10'b0000000000; // No LEDs (>1000mm)
end

assign LEDR = distance_leds;
 
endmodule
