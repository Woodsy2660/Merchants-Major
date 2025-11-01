/*
module top_level (
    input  CLOCK_50,
    input  [17:0] SW,
    inout  [35:0] GPIO,
    output [17:0] LEDR
);
    
    // UART signals
    logic uart_tx_out;
    logic uart_tx_valid;
    logic uart_tx_ready;
    logic [7:0] uart_tx_data;
    
    // Servo signals
    logic servo_pwm_out;
    logic servo_trigger;
    logic [1:0] servo_state;
    logic servo_active;
    
    // Switch edge detection
    logic [17:0] SW_prev;
    
    always_ff @(posedge CLOCK_50) begin
        SW_prev <= SW;
    end
    
    // Instantiate UART JSON 
    uart_json_controller uart_json_ctrl (
        .clk(CLOCK_50),
        .rst(1'b0),
        .turn_left(!SW_prev[0] && SW[0]), //need to add triggers
        .turn_right(!SW_prev[1] && SW[1])
        .forward(!SW_prev[2] && SW[2]),
        .backward(!SW_prev[3] && SW[3]),
        .tx_data(uart_tx_data),
        .tx_valid(uart_tx_valid),
        .tx_ready(uart_tx_ready)
    );
    
    // Instantiate UART TX
    uart_tx #(
        .CLKS_PER_BIT(50_000_000/115200),
        .BITS_N(8),
        .PARITY_TYPE(0)
    ) uart_tx_inst (
        .clk(CLOCK_50),
        .rst(1'b0),
        .data_tx(uart_tx_data),
        .valid(uart_tx_valid),
        .uart_out(uart_tx_out),
        .ready(uart_tx_ready)
    );
    
    // Instantiate Servo controller
    servo_controller servo_ctrl (
        .clk(CLOCK_50),
        .rst(1'b0),
        .trigger(!SW_prev[5] && SW[5]),
        .pwm_out(servo_pwm_out),
        .state(servo_state),
        .active(servo_active)
    );
    
    // GPIO assignments
    assign GPIO[31] = uart_tx_out;
    assign GPIO[27] = servo_pwm_out;
    
    // LED assignments
    assign LEDR[7:6] = servo_state;
    assign LEDR[5] = servo_active;
    assign LEDR[4] = servo_pwm_out;
    assign LEDR[3:0] = 4'b0;  // Reserved for debug
    assign LEDR[17:8] = 10'b0;
    */
    

endmodule
