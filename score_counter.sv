module score_counter (
    input logic         clk,
    input logic         rst,
    input logic         target_hit,      // Pulse when target is hit
    output logic [15:0] score            // Current score value
);

// Internal register to detect rising edge of target_hit
logic target_hit_prev;

always_ff @(posedge clk) begin
    if (rst) begin
        score <= 16'd0;
        target_hit_prev <= 1'b0;
    end else begin
        target_hit_prev <= target_hit;
        
        // Detect rising edge (transition from 0 to 1)
        if (target_hit && !target_hit_prev) begin
            score <= score + 1;
        end
    end
end

endmodule
