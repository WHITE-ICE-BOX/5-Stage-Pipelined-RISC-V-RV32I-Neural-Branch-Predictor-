`timescale 1ns / 1ps

module bp_perceptron #(
    parameter INDEX_BITS = 4,
    parameter HIST_LEN   = 8,
    parameter W_BITS     = 4,
    parameter SUM_BITS   = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // predict
    input  wire [INDEX_BITS-1:0]    pc_index,
    input  wire [HIST_LEN-1:0]      ghr,
    output reg                      pred_taken,
    output reg [$clog2(HIST_LEN+1)-1:0] used_steps,
    output reg signed [SUM_BITS-1:0] pred_sum,

    // update
    input  wire                     update_en,
    input  wire [INDEX_BITS-1:0]    update_index,
    input  wire [HIST_LEN-1:0]      update_ghr,
    input  wire                     actual_taken,
    input  wire                     was_mispredict
);

    localparam ENTRIES = (1 << INDEX_BITS);
    localparam signed [W_BITS-1:0] WMAX = (1 << (W_BITS-1)) - 1;
    localparam signed [W_BITS-1:0] WMIN = -(1 << (W_BITS-1));

    reg signed [W_BITS-1:0] bias_mem [0:ENTRIES-1];
    reg signed [W_BITS-1:0] w_mem    [0:ENTRIES-1][0:HIST_LEN-1];

    integer i, j;

    function signed [W_BITS-1:0] sat_inc;
        input signed [W_BITS-1:0] val;
        begin
            if (val >= WMAX) sat_inc = WMAX;
            else             sat_inc = val + 1'sb1;
        end
    endfunction

    function signed [W_BITS-1:0] sat_dec;
        input signed [W_BITS-1:0] val;
        begin
            if (val <= WMIN) sat_dec = WMIN;
            else             sat_dec = val - 1'sb1;
        end
    endfunction

    // ---------------------------------------------------------------
    // Stage 1: Parallel tree adder — no sequential data dependency.
    //
    // Each term[i] = +w_i if ghr[i]=1, -w_i if ghr[i]=0 (W_BITS+1 bits).
    // Terms are computed independently, then summed in a balanced tree:
    //   Level 1 (parallel): sum_01, sum_23, sum_45, sum_67
    //   Level 2 (parallel): sum_0123, sum_4567
    //   Level 3           : bias + sum_0123 + sum_4567
    // Total logic depth ≈ 3 adder levels << 8 ns clock period.
    //
    // Note: early_stop is removed from the prediction path to eliminate
    // the sequential carry chain that was causing the 14-ns violation.
    // used_steps is fixed to HIST_LEN; it is not used by any update path.
    // ---------------------------------------------------------------

    // Sign-extended terms (+/-w_i, W_BITS+1 bits to hold negation of WMIN)
    wire signed [W_BITS:0] term [0:HIST_LEN-1];

    genvar g;
    generate
        for (g = 0; g < HIST_LEN; g = g + 1) begin : gen_terms
            assign term[g] = ghr[g]
                ?  $signed({{1{w_mem[pc_index][g][W_BITS-1]}}, w_mem[pc_index][g]})
                : -$signed({{1{w_mem[pc_index][g][W_BITS-1]}}, w_mem[pc_index][g]});
        end
    endgenerate

    // Bias sign-extended to SUM_BITS
    wire signed [SUM_BITS-1:0] bias_ext;
    assign bias_ext = {{(SUM_BITS-W_BITS){bias_mem[pc_index][W_BITS-1]}}, bias_mem[pc_index]};

    // Tree adder levels
    wire signed [W_BITS+1:0] sum_01, sum_23, sum_45, sum_67;
    wire signed [W_BITS+2:0] sum_0123, sum_4567;
    wire signed [SUM_BITS-1:0] sum_acc_comb;

    assign sum_01      = term[0] + term[1];
    assign sum_23      = term[2] + term[3];
    assign sum_45      = term[4] + term[5];
    assign sum_67      = term[6] + term[7];
    assign sum_0123    = sum_01 + sum_23;
    assign sum_4567    = sum_45 + sum_67;
    assign sum_acc_comb = bias_ext + sum_0123 + sum_4567;

    // ---------------------------------------------------------------
    // Stage 2: Register outputs (pipeline break — 1-cycle latency).
    // Inputs to this stage are all stable register outputs (pc_index
    // from pc_reg, ghr from bp_history), so timing is well-bounded.
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pred_taken <= 1'b0;
            used_steps <= HIST_LEN[$clog2(HIST_LEN+1)-1:0];
            pred_sum   <= {SUM_BITS{1'b0}};
        end else begin
            pred_taken <= (sum_acc_comb >= 0);
            used_steps <= HIST_LEN[$clog2(HIST_LEN+1)-1:0];
            pred_sum   <= sum_acc_comb;
        end
    end

    // ---------------------------------------------------------------
    // Weight / bias update (on misprediction in EX stage)
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                bias_mem[i] <= {W_BITS{1'b0}};
                for (j = 0; j < HIST_LEN; j = j + 1)
                    w_mem[i][j] <= {W_BITS{1'b0}};
            end
        end
        else if (update_en && was_mispredict) begin
            // bias update
            if (actual_taken)
                bias_mem[update_index] <= sat_inc(bias_mem[update_index]);
            else
                bias_mem[update_index] <= sat_dec(bias_mem[update_index]);

            // weight update: wi <- wi + t*xi
            for (j = 0; j < HIST_LEN; j = j + 1) begin
                if (actual_taken == update_ghr[j])
                    w_mem[update_index][j] <= sat_inc(w_mem[update_index][j]);
                else
                    w_mem[update_index][j] <= sat_dec(w_mem[update_index][j]);
            end
        end
    end

endmodule
