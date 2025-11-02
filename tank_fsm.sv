module tank_fsm (
    input logic         clk,
    input logic         rst,
    input logic         IR_press,
    input logic         whistle_detected,
    input logic         enemy_detected, 
    input logic         aligned,
    input logic         in_range,
    input logic         target_hit,
    input logic [15:0]  timer_value,      // Input from timer module
    output logic        timer_reset,      // Output to timer module
    output logic        timer_enable      // Output to timer module
);

// State typedef enum
typedef enum logic [2:0] {
    S0_MANUAL_MODE,
    S1_DETECT_ENEMY,
    S2_AUTO_ALIGN,
    S3_SHOOT_READY,
    S4_FIRE,
    S5_ENEMY_HIT
} state_type;

state_type current_state, next_state;

// Next state logic
always_comb begin 
    next_state = current_state;
    case (current_state) 
        S0_MANUAL_MODE: begin
            if (IR_press)
                next_state = S1_DETECT_ENEMY;
        end
        
        S1_DETECT_ENEMY: begin
            if (enemy_detected)
                next_state = S2_AUTO_ALIGN;
            else if (timer_value == 0)  // 5 sec timeout
                next_state = S0_MANUAL_MODE;
        end
        
        S2_AUTO_ALIGN: begin
            if (aligned && in_range)
                next_state = S3_SHOOT_READY;
        end
        
        S3_SHOOT_READY: begin
            if (whistle_detected)
                next_state = S4_ENEMY_HIT;
        end
        
        
        S4_ENEMY_HIT: begin
            if (target_hit)
                next_state = S0_MANUAL_MODE;
            else if (timer_value == 0)  // 5 sec to check for hit
                next_state = S2_AUTO_ALIGN;
        end
    endcase
end

// State register
always_ff @(posedge clk) begin 
    if (rst)
        current_state <= S0_MANUAL_MODE;
    else
        current_state <= next_state;
end 

// Output logic
always_comb begin 
    timer_reset = 1'b0;
    timer_enable = 1'b0;
    
    case (current_state)
        S0_MANUAL_MODE: begin
            timer_reset = 1'b1;  // Keep timer reset in manual mode
        end
        
        S1_DETECT_ENEMY: begin
            timer_enable = 1'b1;  // Enable 5s countdown for detection
        end
        
    
        S4_ENEMY_HIT: begin
            timer_enable = 1'b1;  // Enable 5s countdown to check hit
        end
    endcase
end

endmodule