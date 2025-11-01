/*

module top_level (
    input  CLOCK_50,
    input  [17:0] SW,
    inout  [35:0] GPIO,
    output [17:0] LEDR
);
    localparam JSON_LEN = 24;
    
    // Servo control parameters (pulse widths in microseconds)
    localparam SERVO_CENTER = 16'd1200;  // 1.2ms = straight up position (more to the left)
    localparam SERVO_RIGHT  = 16'd1600;  // 1.6ms = 90° right from straight up
    
    localparam HOLD_TIME = 5_000_000; // 0.1 seconds hold at each position
    
    logic tx_valid = 1'b0;
    logic tx_ready;
    
    logic rx_valid;
    logic rx_ready = 1'b1;
    
    logic [7:0] rx_byte;
    
    // Store the JSON strings for different commands
    logic [7:0] json_turn_left [JSON_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h2D,8'h2E,8'h35,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h35,8'h7D,8'h0A};
    logic [7:0] json_forward [JSON_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h35,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h35,8'h7D,8'h0A};
    logic [7:0] json_backward [JSON_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h2D,8'h2E,8'h35,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h2E,8'h35,8'h7D,8'h0A};
    
    logic [7:0] json_to_send [JSON_LEN];
    logic [7:0] byte_to_send = 0;
    integer char_index = 0;
    
    // UART TX instance
    uart_tx #(
        .CLKS_PER_BIT(50_000_000/115200),
        .BITS_N(8),
        .PARITY_TYPE(0)
    ) uart_tx_u (
        .clk(CLOCK_50),
        .rst(1'b0),
        .data_tx(byte_to_send),
        .valid(tx_valid),
        .uart_out(GPIO[31]),
        .ready(tx_ready)
    );
    
    // Servo control signals
    logic [15:0] servo_pulse_width;
    logic [31:0] servo_timer;
    
    typedef enum logic [1:0] {
        SERVO_IDLE,
        SERVO_MOVE_RIGHT,
        SERVO_HOLD_RIGHT,
        SERVO_MOVE_CENTER
    } servo_state_t;
    
    servo_state_t servo_state, servo_state_next;
    
    // Servo PWM instance on GPIO[27]
    logic pwm_signal;
    servo_pwm #(
        .CLK_FREQ(50_000_000),
        .PWM_FREQ(50)
    ) servo_pwm_inst (
        .clk(CLOCK_50),
        .rst(1'b0),
        .pulse_width_us(servo_pulse_width),
        .pwm_out(pwm_signal)
    );
    
    assign GPIO[27] = pwm_signal;
    
    logic [17:0] SW_prev = '0;
    
    // Debug LEDs - show state on LEDR[7:6] and pulse width on LEDR[11:8]
    always_comb begin
        LEDR[7:6] = servo_state;
        LEDR[5] = (servo_state != SERVO_IDLE); // LED on when not idle
        LEDR[4] = pwm_signal; // Mirror the PWM output to see it's toggling
        LEDR[11:8] = servo_pulse_width[11:8]; // Show upper bits of pulse width
        LEDR[3:0] = servo_pulse_width[3:0]; // Show lower bits too
        LEDR[17] = (servo_timer >= HOLD_TIME - 1); // Debug: timer reached
    end
    
    // Main control logic
    always_ff @(posedge CLOCK_50) begin
        SW_prev <= SW;
        
        // Reset timer when state changes
        if (servo_state != servo_state_next) begin
            servo_timer <= 0;
        end
        
        servo_state <= servo_state_next;
        
        // Servo control state machine
        case (servo_state)
            SERVO_IDLE: begin
                servo_pulse_width <= SERVO_CENTER;
            end
            
            SERVO_MOVE_RIGHT: begin
                servo_pulse_width <= SERVO_RIGHT;
                servo_timer <= servo_timer + 1;
            end
            
            SERVO_HOLD_RIGHT: begin
                servo_pulse_width <= SERVO_RIGHT;
                servo_timer <= servo_timer + 1;
            end
            
            SERVO_MOVE_CENTER: begin
                servo_pulse_width <= SERVO_CENTER;
                servo_timer <= servo_timer + 1;
            end
        endcase
        
        // UART control logic (existing code)
        if (!tx_valid) begin
            if (!SW_prev[0] && SW[0]) begin
                json_to_send <= json_turn_left;
                tx_valid <= 1'b1;
                byte_to_send <= json_turn_left[0];
                char_index <= 1;
            end
            else if (!SW_prev[1] && SW[1]) begin
                json_to_send <= json_forward;
                tx_valid <= 1'b1;
                byte_to_send <= json_forward[0];
                char_index <= 1;
            end
            else if (!SW_prev[2] && SW[2]) begin
                json_to_send <= json_backward;
                tx_valid <= 1'b1;
                byte_to_send <= json_backward[0];
                char_index <= 1;
            end
        end
        
        if (tx_valid && tx_ready) begin
            if (char_index >= JSON_LEN) begin
                tx_valid <= 1'b0;
            end
            else begin
                byte_to_send <= json_to_send[char_index];
                char_index <= char_index + 1;
            end
        end
    end
    
    // Servo state machine next state logic
    always_comb begin
        servo_state_next = servo_state;
        
        case (servo_state)
            SERVO_IDLE: begin
                // Check for rising edge on SW[5]
                if (!SW_prev[5] && SW[5]) begin
                    servo_state_next = SERVO_MOVE_RIGHT;
                end
            end
            
            SERVO_MOVE_RIGHT: begin
                if (servo_timer >= HOLD_TIME - 1) begin
                    servo_state_next = SERVO_MOVE_CENTER;
                end
            end
            
            SERVO_HOLD_RIGHT: begin
                if (servo_timer >= HOLD_TIME - 1) begin
                    servo_state_next = SERVO_MOVE_CENTER;
                end
            end
            
            SERVO_MOVE_CENTER: begin
                if (servo_timer >= HOLD_TIME - 1) begin
                    servo_state_next = SERVO_IDLE;
                end
            end
        endcase
    end
    
endmodule

*/