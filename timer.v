`timescale 1ns/1ns 
module timer (
    input                     clk,
    input                     reset,
    input                     up,
    input      [15:0]         max_ms,        // 1000 for 1 sec!
    input      [15:0]         start_value,
    input                     enable,
    output [15:0]             timer_value,
    output reg                LED_toggle
);
    // Internal registers
    parameter CLKS_PER_MS = 50000;
    reg [15:0] clk_cycle_counter;
    reg [15:0] ms_counter;
    reg count_up;
    
    always @(posedge clk) begin
        if (reset) begin
            clk_cycle_counter <= 0;
            
            if (up) begin
                ms_counter <= 0;
                count_up <= 1'b1;
            end else begin
                ms_counter <= start_value;
                count_up <= 1'b0;
            end
        end else if (enable) begin
            if (clk_cycle_counter >= (CLKS_PER_MS - 1)) begin
                clk_cycle_counter <= 0;
                if (count_up) begin
                    if (ms_counter == max_ms-1) begin
                        ms_counter <= 0;
                    end else begin
                        ms_counter <= ms_counter + 1;
                    end
                end else begin
                    if (ms_counter == 0) begin
                        ms_counter <= max_ms-1;
                    end else begin
                        ms_counter <= ms_counter - 1;
                    end
                end
            end else begin
                clk_cycle_counter <= clk_cycle_counter + 1;
            end
        end
    end
    
    assign timer_value = ms_counter;
endmodule