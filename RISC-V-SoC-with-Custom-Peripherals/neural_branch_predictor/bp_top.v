`timescale 1ns / 1ps

module bp_top #(
    parameter INDEX_BITS = 4,
    parameter HIST_LEN   = 8,
    parameter W_BITS     = 4,
    parameter SUM_BITS   = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // predict in ID
    input  wire [31:0]              pc_id,
    input  wire                     is_branch_id,
    output wire                     pred_taken_id,
    output wire                     pred_use_neural_id,
    output wire [$clog2(HIST_LEN+1)-1:0] used_steps_id,
    output wire [HIST_LEN-1:0]      ghr_snapshot_id,

    // update in EX
    input  wire                     update_valid,
    input  wire [31:0]              update_pc,
    input  wire                     actual_taken,
    input  wire                     was_mispredict,
    input  wire [HIST_LEN-1:0]      update_ghr
);

    wire [INDEX_BITS-1:0] rindex = pc_id[INDEX_BITS+1:2];
    wire [INDEX_BITS-1:0] windex = update_pc[INDEX_BITS+1:2];

    wire [1:0] bimodal_ctr;
    wire       conf_high;
    wire       bimodal_taken;
    wire       neural_taken;
    wire signed [SUM_BITS-1:0] neural_sum;
    wire [HIST_LEN-1:0] ghr_wire;

    // -------------------------------------------------------------------
    // Pipeline registers: align bimodal/conf/ghr with the registered
    // perceptron output (bp_perceptron now has 1-cycle output latency).
    // All three signals are registered by 1 clock cycle so that
    // pred_taken_id is valid in the ID stage for the instruction that
    // was in IF during the previous cycle (= current if_id_pc).
    // -------------------------------------------------------------------
    reg        bimodal_taken_r;
    reg        conf_high_r;
    reg [HIST_LEN-1:0] ghr_snapshot_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bimodal_taken_r  <= 1'b0;
            conf_high_r      <= 1'b0;
            ghr_snapshot_r   <= {HIST_LEN{1'b0}};
        end else begin
            bimodal_taken_r  <= bimodal_ctr[1];
            conf_high_r      <= conf_high;
            ghr_snapshot_r   <= ghr_wire;
        end
    end

    assign ghr_snapshot_id    = ghr_snapshot_r;
    assign pred_use_neural_id = is_branch_id && !conf_high_r;
    assign pred_taken_id      = is_branch_id ? (conf_high_r ? bimodal_taken_r : neural_taken) : 1'b0;

    bp_bimodal #(
        .INDEX_BITS(INDEX_BITS)
    ) u_bimodal (
        .clk(clk),
        .rst_n(rst_n),
        .rindex(rindex),
        .rctr(bimodal_ctr),
        .we(update_valid),
        .windex(windex),
        .actual_taken(actual_taken)
    );

    bp_confidence u_conf (
        .ctr_in(bimodal_ctr),
        .conf_high(conf_high)
    );

    bp_history #(
        .HIST_LEN(HIST_LEN)
    ) u_hist (
        .clk(clk),
        .rst_n(rst_n),
        .ghr(ghr_wire),
        .upd_valid(update_valid),
        .actual_taken(actual_taken)
    );

    bp_perceptron #(
        .INDEX_BITS(INDEX_BITS),
        .HIST_LEN(HIST_LEN),
        .W_BITS(W_BITS),
        .SUM_BITS(SUM_BITS)
    ) u_perc (
        .clk(clk),
        .rst_n(rst_n),
        .pc_index(rindex),
        .ghr(ghr_wire),
        .pred_taken(neural_taken),
        .used_steps(used_steps_id),
        .pred_sum(neural_sum),
        .update_en(update_valid),
        .update_index(windex),
        .update_ghr(update_ghr),
        .actual_taken(actual_taken),
        .was_mispredict(was_mispredict)
    );

endmodule
