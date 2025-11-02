module uart_json_controller (
    input  logic       clk,
    input  logic       rst,
    input  logic       turn_right,
    input  logic       turn_left,
    input  logic       forward,
    input  logic       backward,
    output logic [7:0] tx_data,
    output logic       tx_valid,
    input  logic       tx_ready
);
    
    localparam JSON_LEN = 24;
    
    // Store the JSON strings for different commands
    // {"T":1,"L":-.5,"R":0.5}\n
   // JSON command strings -
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
    
    logic [7:0] json_to_send [JSON_LEN];
    integer char_index;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_valid <= 1'b0;
            tx_data <= 8'h00;
            char_index <= 0;
        end else begin
            // Start new transmission on switch press
            if (!tx_valid) begin
                if (turn_left) begin
                    json_to_send <= json_turn_left;
                    tx_valid <= 1'b1;
                    tx_data <= json_turn_left[0];
                    char_index <= 1;
                end
                else if (forward) begin
                    json_to_send <= json_forward;
                    tx_valid <= 1'b1;
                    tx_data <= json_forward[0];
                    char_index <= 1;
                end
                else if (backward) begin
                    json_to_send <= json_backward;
                    tx_valid <= 1'b1;
                    tx_data <= json_backward[0];
                    char_index <= 1;
                end
                else if (turn_right) begin
                    json_to_send <= json_turn_right;
                    tx_valid <= 1'b1;
                    tx_data <= json_turn_right[0];
                    char_index <= 1;
                end
            end
            
            // Continue transmission
            if (tx_valid && tx_ready) begin
                if (char_index >= JSON_LEN) begin
                    tx_valid <= 1'b0;
                end
                else begin
                    tx_data <= json_to_send[char_index];
                    char_index <= char_index + 1;
                end
            end
        end
    end
    
endmodule