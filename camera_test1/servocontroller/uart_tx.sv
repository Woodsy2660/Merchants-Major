module uart_tx #(
    parameter CLKS_PER_BIT = (50_000_000/115_200), // E.g. Baud_rate = 115200 with FPGA clk = 50MHz
    parameter BITS_N       = 8, // Number of data bits per UART frame
    parameter PARITY_TYPE  = 0  // 0 for none, 1 for odd parity, 2 for even.
) (
    input clk,
    input rst,
    input [BITS_N-1:0] data_tx,
    output logic uart_out,
    input valid,            // Handshake protocol: valid (when `data_tx` is valid to be sent onto the UART).
    output logic ready      // Handshake protocol: ready (when this UART module is ready to send data).
);

    logic [BITS_N-1:0] data_tx_temp;
    logic [2:0]        bit_n;
    logic [$clog2(CLKS_PER_BIT)-1:0] clk_count;  // Counter for baud rate timing
    logic parity_bit;  // Calculated parity bit

    enum {IDLE, START_BIT, DATA_BITS, PARITY_BIT, STOP_BIT} current_state, next_state;

    // Calculate parity bit based on data_tx_temp
    always_comb begin
        case (PARITY_TYPE)
            1: parity_bit = ~^data_tx_temp; // Odd parity: invert XOR result
            2: parity_bit = ^data_tx_temp;  // Even parity: XOR result
            default: parity_bit = 1'b0;     // No parity
        endcase
    end

    always_comb begin : fsm_next_state
        case (current_state)
            IDLE:        next_state = valid ? START_BIT : IDLE; // Handshake protocol: Only start sending data when valid data comes through.
            START_BIT:   next_state = (clk_count == CLKS_PER_BIT-1) ? DATA_BITS : START_BIT;
            DATA_BITS:   begin
                if (clk_count == CLKS_PER_BIT-1) begin
                    if (bit_n == BITS_N-1) begin
                        next_state = (PARITY_TYPE == 0) ? STOP_BIT : PARITY_BIT; // Skip parity if not used
                    end else begin
                        next_state = DATA_BITS;
                    end
                end else begin
                    next_state = DATA_BITS;
                end
            end
            PARITY_BIT:  next_state = (clk_count == CLKS_PER_BIT-1) ? STOP_BIT : PARITY_BIT;
            STOP_BIT:    next_state = (clk_count == CLKS_PER_BIT-1) ? IDLE : STOP_BIT;
            default:     next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin : fsm_ff
        if (rst) begin
            current_state <= IDLE;
            data_tx_temp <= 0;
            bit_n <= 0;
            clk_count <= 0;
        end
        else begin
            current_state <= next_state;
            case (current_state)
                IDLE: begin // Idle -- register the data to send (in case it gets corrupted by an external module). Reset counters.
                    data_tx_temp <= data_tx;
                    bit_n <= 0;
                    clk_count <= 0;
                end
                START_BIT: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                DATA_BITS: begin // Data transfer -- Count up the bit-index to send.
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        bit_n <= bit_n + 1'b1;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                PARITY_BIT: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                STOP_BIT: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
            endcase
        end
    end

    always_comb begin : fsm_output
        uart_out = 1'b1; // Default: The UART line is high.
        ready = 1'b0;    // Default: This UART module is only ready for new data when in the IDLE state.
        case (current_state)
            IDLE: begin
                ready = 1'b1;  // Handshake protocol: This UART module is ready for new data to send.
            end
            START_BIT: begin
                uart_out = 1'b0; // The start condition is a zero.
            end
            DATA_BITS: begin
                uart_out = data_tx_temp[bit_n]; // Set the UART TX line to the current bit being sent.
            end
            PARITY_BIT: begin
                uart_out = parity_bit; // Send the calculated parity bit.
            end
            STOP_BIT: begin
                uart_out = 1'b1; // Stop bit is high.
            end
        endcase
    end

endmodule