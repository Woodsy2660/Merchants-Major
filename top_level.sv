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
        Forward,
        Backward,
        Left,
        Right
    } state_type;

    state_type current_state = Idle;
    state_type next_state;

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
    // FSM next state logic with edge detection
    // ---------------------------
    always_comb begin
        next_state = current_state;
        case (current_state)
            Idle: begin
                // Detect rising edge of switches
                if (!SW_prev[0] && SW[0]) next_state = Forward;
                else if (!SW_prev[1] && SW[1]) next_state = Backward;
                else if (!SW_prev[2] && SW[2]) next_state = Left;
                else if (!SW_prev[3] && SW[3]) next_state = Right;
                else next_state = Idle;
            end
            Forward, Backward, Left, Right: begin
                // Stay in state until transmission is complete
                if (!tx_valid) next_state = Idle;
                else next_state = current_state;
            end
            default: next_state = Idle;
        endcase
    end

    // ---------------------------
    // FSM state register and edge detection
    // ---------------------------
    always_ff @(posedge CLOCK_50) begin
        SW_prev <= SW;
        current_state <= next_state;
    end

    // ---------------------------
    // Send JSON based on FSM
    // ---------------------------
    always_ff @(posedge CLOCK_50) begin
        if (!tx_valid) begin
            case (current_state)
                Forward: begin
                    tx_valid <= 1'b1;
                    byte_to_send <= json_forward[0];
                    char_index <= 1;
                    json_len <= FWD_LEN;
                end
                Backward: begin
                    tx_valid <= 1'b1;
                    byte_to_send <= json_backward[0];
                    char_index <= 1;
                    json_len <= BWD_LEN;
                end
                Left: begin
                    tx_valid <= 1'b1;
                    byte_to_send <= json_left[0];
                    char_index <= 1;
                    json_len <= LEFT_LEN;
                end
                Right: begin
                    tx_valid <= 1'b1;
                    byte_to_send <= json_right[0];
                    char_index <= 1;
                    json_len <= RIGHT_LEN;
                end
            endcase
        end
        else if (tx_valid && tx_ready) begin
            if (char_index >= json_len) begin
                tx_valid <= 1'b0;
            end
            else begin
                case (current_state)
                    Forward:  byte_to_send <= json_forward[char_index];
                    Backward: byte_to_send <= json_backward[char_index];
                    Left:     byte_to_send <= json_left[char_index];
                    Right:    byte_to_send <= json_right[char_index];
                endcase
                char_index <= char_index + 1;
            end
        end
    end

endmodule