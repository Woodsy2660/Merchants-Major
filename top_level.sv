module top_level (
      input  CLOCK_50,
      input  [17:0] SW,
      inout  [35:0] GPIO,
      output [17:0] LEDR
);

    // ---------------------------
    // UART handshake signals
    // ---------------------------
    logic tx_valid = 1'b0;
    logic tx_ready;
    logic tx_ready_prev = 1'b0;
    logic [7:0] byte_to_send = 0;
    integer char_index = 0;
    integer json_len = 0;

    // ---------------------------
    // Switch edge detection
    // ---------------------------
    logic [17:0] SW_prev = '0;

    // ---------------------------
    // FSM state type
    // ---------------------------
    typedef enum logic [2:0] {
        Idle,
        Sending
    } state_type;

    state_type current_state = Idle;
    state_type next_state;

    // Which command to send
      typedef enum logic [2:0] {
        CMD_NONE,
        CMD_FORWARD,
        CMD_BACKWARD,
        CMD_LEFT,
        CMD_RIGHT
    } command_type;
    
    command_type current_cmd = CMD_NONE;

    // ---------------------------
    // JSON strings for each command
    // ---------------------------
    localparam FWD_LEN = 24;
    localparam BWD_LEN = 26;
    localparam LEFT_LEN = 27;
    localparam RIGHT_LEN = 27;

    logic [7:0] json_forward [FWD_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h35,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h35,8'h7D,8'h0A};
    logic [7:0] json_backward [BWD_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h2D,8'h30,8'h2E,8'h35,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h30,8'h2E,8'h35,8'h7D,8'h0A};
    logic [7:0] json_left [LEFT_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h2D,8'h30,8'h2E,8'h32,8'h35,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h30,8'h2E,8'h32,8'h35,8'h7D,8'h0A};
    logic [7:0] json_right [RIGHT_LEN] = '{8'h7B,8'h22,8'h54,8'h22,8'h3A,8'h31,8'h2C,8'h22,8'h4C,8'h22,8'h3A,8'h30,8'h2E,8'h32,8'h35,8'h2C,8'h22,8'h52,8'h22,8'h3A,8'h2D,8'h30,8'h2E,8'h32,8'h35,8'h7D,8'h0A};

    // ---------------------------
    // UART TX module
    // ---------------------------
    uart_tx #(.CLKS_PER_BIT(50_000_000/115200),.BITS_N(8),.PARITY_TYPE(0)) uart_tx_u (
        .clk(CLOCK_50),
        .rst(1'b0),
        .data_tx(byte_to_send),
        .valid(tx_valid),
        .uart_out(GPIO[31]),
        .ready(tx_ready)
    );

    // ---------------------------
    // Detect rising edge of tx_ready
    // ---------------------------
    wire tx_ready_edge = tx_ready && !tx_ready_prev;

    // ---------------------------
    // Main transmission logic
    // ---------------------------
    always_ff @(posedge CLOCK_50) begin
        SW_prev <= SW;
        tx_ready_prev <= tx_ready;
        
        case (current_state)
            Idle: begin
                // Detect switch press and start transmission
                if (!SW_prev[0] && SW[0]) begin
                    current_state <= Sending;
                    current_cmd <= CMD_FORWARD;
                    char_index <= 0;
                    json_len <= FWD_LEN;
                    tx_valid <= 1'b1;
                    byte_to_send <= json_forward[0];
                end
                else if (!SW_prev[1] && SW[1]) begin
                    current_state <= Sending;
                    current_cmd <= CMD_BACKWARD;
                    char_index <= 0;
                    json_len <= BWD_LEN;
                    tx_valid <= 1'b1;
                    byte_to_send <= json_backward[0];
                end
                else if (!SW_prev[2] && SW[2]) begin
                    current_state <= Sending;
                    current_cmd <= CMD_LEFT;
                    char_index <= 0;
                    json_len <= LEFT_LEN;
                    tx_valid <= 1'b1;
                    byte_to_send <= json_left[0];
                end
                else if (!SW_prev[3] && SW[3]) begin
                    current_state <= Sending;
                    current_cmd <= CMD_RIGHT;
                    char_index <= 0;
                    json_len <= RIGHT_LEN;
                    tx_valid <= 1'b1;
                    byte_to_send <= json_right[0];
                end
            end
            
            Sending: begin
                // Wait for UART to become ready (finish transmitting previous byte)
                if (tx_ready_edge) begin
                    char_index <= char_index + 1;
                    
                    if (char_index + 1 >= json_len) begin
                        // Done sending all bytes
                        tx_valid <= 1'b0;
                        current_state <= Idle;
                        current_cmd <= CMD_NONE;
                    end
                    else begin
                        // Send next byte
                        case (current_cmd)
                            CMD_FORWARD:  byte_to_send <= json_forward[char_index + 1];
                            CMD_BACKWARD: byte_to_send <= json_backward[char_index + 1];
                            CMD_LEFT:     byte_to_send <= json_left[char_index + 1];
                            CMD_RIGHT:    byte_to_send <= json_right[char_index + 1];
                        endcase
                    end
                end
            end
        endcase
    end

endmodule
