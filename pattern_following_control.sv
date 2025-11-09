// Automatic Edge Tracking Robot Control - Proportional Speed Control
module auto_robot_control (
    // Clock and Reset
    input  logic        clk_50,
    input  logic        reset_n,
    
    // UART Output (via GPIO)
    output logic        uart_tx,
    
    // Auto-tracking inputs
    input  logic [17:0] edge_density_leds,  // From edge_density_detector
    
    // Debug outputs (optional - connect to LEDs)
    output logic        uart_transmitting,
    output logic        uart_ready,
    output logic [4:0]  control_state_out
);

//=============================================================================
// UART Transmitter
//=============================================================================
logic tx_valid;
logic tx_ready;
logic [7:0] byte_to_send;

uart_tx #(
    .CLKS_PER_BIT(50_000_000/115200),
    .BITS_N(8),
    .PARITY_TYPE(0)
) u_uart (
    .clk(clk_50), 
    .rst(1'b0), 
    .data_tx(byte_to_send),
    .valid(tx_valid),
    .uart_out(uart_tx),
    .ready(tx_ready)
);

//=============================================================================
// JSON Commands - Multiple Speed Levels
//=============================================================================
localparam JSON_LEN_TURN = 27;
localparam JSON_LEN_STOP = 24;

// Slow turn commands (±0.05 speed) - 25 bytes
// Format: {"T":1,"L":-0.05,"R":0.05}\n
logic [7:0] json_turn_right_slow [JSON_LEN_TURN] = '{
    8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,  // {"T":1,"
    8'h4C,8'h22,8'h3A,8'h2D,8'h30,8'h2E,8'h30,8'h35,  // L":-0.05
    8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h30,  // ,"R":0.0
    8'h35,8'h7D,8'h0A                                   // 5}\n
};

logic [7:0] json_turn_left_slow [JSON_LEN_TURN] = '{
    8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,  // {"T":1,"
    8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h30,8'h35,8'h2C,  // L":0.05,
    8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h30,8'h2E,8'h30,  // "R":-0.0
    8'h35,8'h7D,8'h0A                                   // 5}\n
};

// Medium turn commands (±0.08 speed) - 25 bytes
// Format: {"T":1,"L":-0.08,"R":0.08}\n
logic [7:0] json_turn_right_med [JSON_LEN_TURN] = '{
    8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,  // {"T":1,"
    8'h4C,8'h22,8'h3A,8'h2D,8'h30,8'h2E,8'h30,8'h38,  // L":-0.08
    8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h30,  // ,"R":0.0
    8'h38,8'h7D,8'h0A                                   // 8}\n
};

logic [7:0] json_turn_left_med [JSON_LEN_TURN] = '{
    8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,  // {"T":1,"
    8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h30,8'h38,8'h2C,  // L":0.08,
    8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h30,8'h2E,8'h30,  // "R":-0.0
    8'h38,8'h7D,8'h0A                                   // 8}\n
};

// Stop command - 24 bytes
logic [7:0] json_stop [JSON_LEN_STOP] = '{
    8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,
    8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h30,8'h2C,8'h22,
    8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h30,8'h7D,8'h0A
};

//=============================================================================
// Auto-Tracking Logic with Proportional Control
//=============================================================================
logic [4:0] detected_section;
logic [4:0] mirrored_section;
logic signed [5:0] error;  // Signed error from center

// Decode which section has the edge pattern
always_comb begin
    detected_section = 5'd9; // Default to center
    for (int i = 17; i >= 0; i--) begin
        if (edge_density_leds[i])
            detected_section = i[4:0];
    end
end

assign mirrored_section = 5'd17 - detected_section;

// Calculate error from center (section 9)
// Positive error = too far right, need to turn left
// Negative error = too far left, need to turn right
assign error = $signed({1'b0, detected_section}) - 6'sd9;

//=============================================================================
// Control Zones - WIDER Dead Zone to Prevent Oscillation
//=============================================================================
typedef enum logic [2:0] {
    STATE_STOP = 3'b000,
    STATE_TURN_LEFT = 3'b001,
    STATE_TURN_RIGHT = 3'b010
} control_state_t;

control_state_t next_action;

// Single-speed proportional control with wider dead zone
always_comb begin
    if (error >= -3 && error <= 3) begin
        // Wide dead zone - ±3 sections (covers 7 sections total)
        next_action = STATE_STOP;
    end
    else if (error > 3) begin
        // Turn left slowly
        next_action = STATE_TURN_LEFT;
    end
    else begin
        // Turn right slowly
        next_action = STATE_TURN_RIGHT;
    end
end

//=============================================================================
// Command Transmission - Faster Update Rate
//=============================================================================
logic [23:0] command_counter;
logic command_trigger;

always_ff @(posedge clk_50) begin
    if (!reset_n) begin
        command_counter <= 24'd0;
        command_trigger <= 1'b0;
    end else begin
        // Trigger every ~100ms (5M cycles at 50MHz) - slower updates
        if (command_counter >= 24'd5_000_000) begin
            command_counter <= 24'd0;
            command_trigger <= 1'b1;
        end else begin
            command_counter <= command_counter + 24'd1;
            command_trigger <= 1'b0;
        end
    end
end

//=============================================================================
// FSM for Command Transmission
//=============================================================================
typedef enum logic [1:0] {
    FSM_WAIT_TRIGGER,
    FSM_START_TX,
    FSM_TRANSMITTING
} fsm_state_t;

fsm_state_t fsm_state;
control_state_t current_action;
logic [7:0] json_to_send [JSON_LEN_TURN];  // Use larger size
integer char_index;
integer json_length;  // Track actual length to send

always_ff @(posedge clk_50) begin
    if (!reset_n) begin
        fsm_state <= FSM_WAIT_TRIGGER;
        current_action <= STATE_STOP;
        tx_valid <= 1'b0;
        char_index <= 0;
        json_length <= 0;
    end else begin
        case (fsm_state)
            FSM_WAIT_TRIGGER: begin
                tx_valid <= 1'b0;
                
                if (command_trigger) begin
                    current_action <= next_action;
                    fsm_state <= FSM_START_TX;
                end
            end
            
            FSM_START_TX: begin
                // Select appropriate command based on current action
                case (current_action)
                    STATE_TURN_LEFT: begin
                        for (int i = 0; i < JSON_LEN_TURN; i++)
                            json_to_send[i] <= json_turn_left_slow[i];
                        byte_to_send <= json_turn_left_slow[0];
                        json_length <= JSON_LEN_TURN;
                    end
                    STATE_TURN_RIGHT: begin
                        for (int i = 0; i < JSON_LEN_TURN; i++)
                            json_to_send[i] <= json_turn_right_slow[i];
                        byte_to_send <= json_turn_right_slow[0];
                        json_length <= JSON_LEN_TURN;
                    end
                    STATE_STOP: begin
                        for (int i = 0; i < JSON_LEN_STOP; i++)
                            json_to_send[i] <= json_stop[i];
                        byte_to_send <= json_stop[0];
                        json_length <= JSON_LEN_STOP;
                    end
                    default: begin
                        for (int i = 0; i < JSON_LEN_STOP; i++)
                            json_to_send[i] <= json_stop[i];
                        byte_to_send <= json_stop[0];
                        json_length <= JSON_LEN_STOP;
                    end
                endcase
                
                char_index <= 1;
                tx_valid <= 1'b1;
                fsm_state <= FSM_TRANSMITTING;
            end
            
            FSM_TRANSMITTING: begin
                if (tx_ready) begin
                    if (char_index >= json_length) begin
                        tx_valid <= 1'b0;
                        char_index <= 0;
                        fsm_state <= FSM_WAIT_TRIGGER;
                    end
                    else begin
                        byte_to_send <= json_to_send[char_index];
                        char_index <= char_index + 1;
                    end
                end
            end
            
            default: begin
                fsm_state <= FSM_WAIT_TRIGGER;
            end
        endcase
    end
end

//=============================================================================
// Debug outputs
//=============================================================================
assign uart_transmitting = tx_valid;
assign uart_ready = tx_ready;
assign control_state_out = {2'b0, current_action};

endmodule