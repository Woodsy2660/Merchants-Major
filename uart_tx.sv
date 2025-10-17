module uart_tx #(
    parameter CLKS_PER_BIT = (50_000_000/115_200), // E.g. Baud_rate = 115200 with FPGA clk = 50MHz
    parameter BITS_N       = 8,   // Number of data bits per UART frame
    parameter PARITY_TYPE  = 0    // 0 for none, 1 for odd parity, 2 for even
) (
    input  logic              clk,
    input  logic              rst,
    input  logic [BITS_N-1:0] data_tx,
    output logic              uart_out,
    input  logic              valid, // Handshake: valid = data_tx is valid
    output logic              ready  // Handshake: ready = UART can accept new data
);

   // -----------------
   // Internal signals
   // -----------------
   logic [BITS_N-1:0] data_tx_temp;
   logic [$clog2(BITS_N)-1:0] bit_n;
   logic parity_bit;

   enum {IDLE, START_BIT, DATA_BITS, PARITY_BIT, STOP_BIT} current_state, next_state;

   integer cycle_counter;
   logic baud_trigger;

   assign baud_trigger = (cycle_counter == CLKS_PER_BIT - 1);

   // -----------------
   // Next state logic
   // -----------------
   always_comb begin : fsm_next_state
      next_state = current_state;
      case (current_state)
         IDLE: begin
            next_state = (valid ? START_BIT : IDLE);
         end

         START_BIT: begin
            next_state = (baud_trigger ? DATA_BITS : START_BIT);
         end

         DATA_BITS: begin
            if (baud_trigger && (bit_n == BITS_N-1)) begin
               next_state = (PARITY_TYPE == 0) ? STOP_BIT : PARITY_BIT;
            end else if (baud_trigger) begin
               next_state = DATA_BITS;
            end
         end

         PARITY_BIT: begin
            next_state = (baud_trigger ? STOP_BIT : PARITY_BIT);
         end

         STOP_BIT: begin
            next_state = (baud_trigger ? IDLE : STOP_BIT);
         end
      endcase
   end

   // -----------------
   // State registers
   // -----------------
   always_ff @(posedge clk or posedge rst) begin : fsm_ff
      if (rst) begin
         current_state <= IDLE;
         cycle_counter <= 0;
         bit_n         <= 0;
         data_tx_temp  <= '0;
         parity_bit    <= 1'b0;
      end else begin
         current_state <= next_state;

         // baud counter
         if (current_state == IDLE || baud_trigger)
            cycle_counter <= 0;
         else
            cycle_counter <= cycle_counter + 1;

         case (current_state)
            IDLE: begin
               bit_n <= 0;
               if (valid) begin
                  data_tx_temp <= data_tx;
                  // precompute parity once
                  case (PARITY_TYPE)
                     1: parity_bit <= ~(^data_tx); // odd
                     2: parity_bit <=  (^data_tx); // even
                     default: parity_bit <= 1'b0;
                  endcase
               end
            end

            DATA_BITS: begin
               if (baud_trigger)
                  bit_n <= bit_n + 1'b1;
            end
         endcase
      end
   end

   // -----------------
   // Output logic
   // -----------------
   always_comb begin : fsm_output
      uart_out = 1'b1; // default idle
      ready    = 1'b0;

      case (current_state)
         IDLE: begin
            ready    = 1'b1;
            uart_out = 1'b1;
         end
         START_BIT: begin
            uart_out = 1'b0;
         end
         DATA_BITS: begin
            uart_out = data_tx_temp[bit_n];
         end
         PARITY_BIT: begin
            uart_out = parity_bit;
         end
         STOP_BIT: begin
            uart_out = 1'b1;
         end
      endcase
   end

endmodule
