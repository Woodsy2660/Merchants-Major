module servo_controller (
    input  logic       clk,
    input  logic       rst,
    input  logic       trigger,      // Start servo sequence
    output logic       pwm_out,
    output logic [1:0] state,        // Current state for debug
    output logic       active        // High when not idle
);

    // Servo control parameters
    localparam SERVO_CENTER = 16'd1200;  // 1.2ms = straight up position
    localparam SERVO_RIGHT  = 16'd1600;  // 1.6ms = 90° right from straight up
    
    localparam HOLD_TIME = 5_000_000;    // 0.1 seconds hold at each position
    
    logic [15:0] servo_pulse_width;
    logic [31:0] servo_timer;
    
    typedef enum logic [1:0] {
        SERVO_IDLE,
        SERVO_MOVE_RIGHT,
        SERVO_HOLD_RIGHT,
        SERVO_MOVE_CENTER
    } servo_state_t;
    
    servo_state_t servo_state, servo_state_next;
    
    // Servo PWM generator
    servo_pwm #(
        .CLK_FREQ(50_000_000),
        .PWM_FREQ(50)
    ) servo_pwm_inst (
        .clk(clk),
        .rst(rst),
        .pulse_width_us(servo_pulse_width),
        .pwm_out(pwm_out)
    );
    
    // State machine - sequential logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            servo_state <= SERVO_IDLE;
            servo_timer <= 0;
            servo_pulse_width <= SERVO_CENTER;
        end else begin
            // Reset timer when state changes
            if (servo_state != servo_state_next) begin
                servo_timer <= 0;
            end
            
            servo_state <= servo_state_next;
            
            // Update pulse width and timer based on state
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
        end
    end
    
    // State machine - combinational logic
    always_comb begin
        servo_state_next = servo_state;
        
        case (servo_state)
            SERVO_IDLE: begin
                if (trigger) begin
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
    
    // Output assignments
    assign state = servo_state;
    assign active = (servo_state != SERVO_IDLE);
    
endmodule