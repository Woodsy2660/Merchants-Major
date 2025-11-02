module servo_pwm #(
    parameter CLK_FREQ = 50_000_000,  // 50 MHz clock
    parameter PWM_FREQ = 50           // 50 Hz PWM (20ms period)
)(
    input logic clk,
    input logic rst,
    input logic [15:0] pulse_width_us, // Pulse width in microseconds (1000-2000 for typical servo)
    output logic pwm_out
);
    // For 50MHz clock and 50Hz PWM: 20ms period = 1,000,000 clock cycles
    localparam PERIOD_CYCLES = 1_000_000;
    
    logic [19:0] counter; // 20 bits is enough for 1,000,000
    logic [19:0] pulse_cycles;
    
    // pulse_width_us * 50 = cycles (e.g., 1500us * 50 = 75,000 cycles)
    assign pulse_cycles = pulse_width_us * 20'd50;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= 20'd0;
        end else begin
            if (counter >= PERIOD_CYCLES - 1) begin
                counter <= 20'd0;
            end else begin
                counter <= counter + 20'd1;
            end
        end
    end
    
    // Output is high when counter is less than pulse_cycles
    assign pwm_out = (counter < pulse_cycles);
    
endmodule
