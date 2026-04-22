`timescale 1ns/1ps
// ============================================================================
// tb_4way_compare.v
// Four-way branch-predictor comparison testbench (Icarus Verilog).
//
// Predictors under comparison (in one simulation):
//   (1) PicoRV32-like   — no prediction, every branch stalls 2 cycles
//   (2) Baseline        — always-not-taken (our reference CPU)
//   (3) Ibex + SBP      — static backward-taken / forward-not-taken heuristic
//   (4) VexRiscv + BHT  — 2-bit saturating-counter, 16-entry direct-mapped BHT
//   (5) This work       — confidence-adaptive hybrid + early stopping (our CPU)
//
// Strategy: predictors (1)-(4) are BEHAVIOURAL models driven by the same
// branch sequence observed from the baseline CPU.  No external RTL is needed.
// The innovation CPU runs in parallel for (5).
//
// Usage:
//   vvp <compiled.vvp> \
//       +PROG=/path/to/instr_data_xxx.txt \
//       +TIME=<sim_ns>                    \
//       +LABEL=<workload-name>
// ============================================================================

module tb_4way_compare;

    reg clk, reset;
    always #4 clk = ~clk;

    localparam MISPREDICT_PENALTY = 2;

    // ── Wires into the two CPU instances ──────────────────────────────────
    wire [31:0] base_pc;
    wire [6:0]  base_ex_opcode;
    wire        base_actual_taken;
    wire        base_cond_branch;
    wire [31:0] base_branch_target; // pc + sign-extended imm (EX stage)

    wire        bp_cond_branch;
    wire        bp_pred_taken;
    wire        bp_actual_taken;
    wire        bp_use_neural;
    wire [3:0]  bp_used_steps;

    assign base_pc            = u_base.top_1.pc_now;
    assign base_ex_opcode     = u_base.top_1.ex_opcode;
    assign base_actual_taken  = u_base.top_1.branch_taken;
    assign base_cond_branch   = (base_ex_opcode == 7'b1100011);
    assign base_branch_target = u_base.top_1.branch_target;

    assign bp_cond_branch  = u_bp.top_1.ex_is_cond_branch;
    assign bp_pred_taken   = u_bp.top_1.ex_pred_taken;
    assign bp_actual_taken = u_bp.top_1.branch_taken;
    assign bp_use_neural   = u_bp.top_1.ex_use_neural;
    assign bp_used_steps   = u_bp.top_1.ex_used_steps;

    // ── CPU instances ──────────────────────────────────────────────────────
    risc_v_soc    u_base(.clk(clk), .reset(reset));
    risc_v_soc_bp u_bp  (.clk(clk), .reset(reset));

    // ── Program load ───────────────────────────────────────────────────────
    reg [511:0] prog_file;
    initial begin
        if (!$value$plusargs("PROG=%s", prog_file)) begin
            $display("ERROR: +PROG=<path> is required"); $finish;
        end
        $readmemb(prog_file, u_base.rom_1.rom_mem);
        $readmemb(prog_file, u_bp.rom_1.rom_mem);
    end

    // ── Counters for each predictor ────────────────────────────────────────
    // (1) PicoRV32 – stall-to-resolve, no prediction
    integer pico_total, pico_penalty;

    // (2) Baseline always-NT
    integer ant_total, ant_correct, ant_penalty;

    // (3) Ibex SBP: backward branch (target < pc) → predict taken
    integer sbp_total, sbp_correct, sbp_penalty;
    wire sbp_pred = (base_branch_target < base_pc);

    // (4) VexRiscv BHT: 2-bit saturating counter, 16-entry, indexed by pc[5:2]
    integer bht_total, bht_correct, bht_penalty;
    reg [1:0] bht_table [0:15];
    reg bht_pred_latch;

    // (5) Innovation CPU
    integer bp_total, bp_correct, bp_penalty;
    integer bp_neural_used, bp_total_steps;
    integer bp_early_exit, bp_full_step;

    // ── Initialisation ─────────────────────────────────────────────────────
    integer k;
    initial begin
        clk = 0; reset = 1;

        pico_total = 0;  pico_penalty = 0;

        ant_total  = 0;  ant_correct  = 0;  ant_penalty = 0;

        sbp_total  = 0;  sbp_correct  = 0;  sbp_penalty = 0;

        bht_total  = 0;  bht_correct  = 0;  bht_penalty = 0;
        for (k = 0; k < 16; k = k + 1)
            bht_table[k] = 2'b01;           // init: weakly-not-taken

        bp_total      = 0;  bp_correct   = 0;  bp_penalty    = 0;
        bp_neural_used = 0;  bp_total_steps = 0;
        bp_early_exit = 0;  bp_full_step   = 0;

        #10; reset = 0;
    end

    // ── Branch-event monitor: predictors (1)-(4) driven by baseline CPU ───
    always @(posedge clk) begin
        if (!reset && base_cond_branch) begin

            // (1) PicoRV32 – every branch is a "miss" (stall on every branch)
            pico_total   = pico_total   + 1;
            pico_penalty = pico_penalty + MISPREDICT_PENALTY;

            // (2) Baseline always-NT
            ant_total = ant_total + 1;
            if (!base_actual_taken)  ant_correct  = ant_correct + 1;
            else                     ant_penalty  = ant_penalty + MISPREDICT_PENALTY;

            // (3) Ibex SBP
            sbp_total = sbp_total + 1;
            if (sbp_pred == base_actual_taken)
                sbp_correct = sbp_correct + 1;
            else
                sbp_penalty = sbp_penalty + MISPREDICT_PENALTY;

            // (4) VexRiscv BHT – sample current counter THEN update
            bht_total = bht_total + 1;
            bht_pred_latch = bht_table[base_pc[5:2]][1]; // MSB = prediction
            if (bht_pred_latch == base_actual_taken)
                bht_correct = bht_correct + 1;
            else
                bht_penalty = bht_penalty + MISPREDICT_PENALTY;
            // saturating update
            if (base_actual_taken) begin
                if (bht_table[base_pc[5:2]] < 2'b11)
                    bht_table[base_pc[5:2]] = bht_table[base_pc[5:2]] + 2'b01;
            end else begin
                if (bht_table[base_pc[5:2]] > 2'b00)
                    bht_table[base_pc[5:2]] = bht_table[base_pc[5:2]] - 2'b01;
            end
        end
    end

    // ── Branch-event monitor: predictor (5) – innovation CPU ──────────────
    always @(posedge clk) begin
        if (!reset && bp_cond_branch) begin
            bp_total = bp_total + 1;
            if (bp_pred_taken == bp_actual_taken)
                bp_correct  = bp_correct  + 1;
            else
                bp_penalty  = bp_penalty  + MISPREDICT_PENALTY;
            if (bp_use_neural)
                bp_neural_used = bp_neural_used + 1;
            bp_total_steps = bp_total_steps + bp_used_steps;
            if (bp_used_steps == 4'd8) bp_full_step  = bp_full_step  + 1;
            else                       bp_early_exit = bp_early_exit + 1;
        end
    end

    // ── Final report ───────────────────────────────────────────────────────
    integer sim_time;
    reg [255:0] label;

    integer ant_acc, sbp_acc, bht_acc, bp_acc;
    integer pico_red, ant_red, sbp_red, bht_red, bp_red;

    initial begin
        if (!$value$plusargs("TIME=%d", sim_time)) sim_time = 4000;
        if (!$value$plusargs("LABEL=%s", label))   label    = "workload";

        #(sim_time);

        // accuracies (x10000 fixed-point)
        ant_acc = (ant_total > 0) ? (ant_correct * 10000) / ant_total : 0;
        sbp_acc = (sbp_total > 0) ? (sbp_correct * 10000) / sbp_total : 0;
        bht_acc = (bht_total > 0) ? (bht_correct * 10000) / bht_total : 0;
        bp_acc  = (bp_total  > 0) ? (bp_correct  * 10000) / bp_total  : 0;

        // penalty reduction relative to PicoRV32 baseline (x10000)
        pico_red = 0; // PicoRV32 is the reference
        ant_red  = (pico_penalty > 0) ? ((pico_penalty - ant_penalty) * 10000) / pico_penalty : 0;
        sbp_red  = (pico_penalty > 0) ? ((pico_penalty - sbp_penalty) * 10000) / pico_penalty : 0;
        bht_red  = (pico_penalty > 0) ? ((pico_penalty - bht_penalty) * 10000) / pico_penalty : 0;
        bp_red   = (pico_penalty > 0) ? ((pico_penalty - bp_penalty)  * 10000) / pico_penalty : 0;

        $display("============================================================================");
        $display("  4-Way Predictor Comparison  |  Workload: %0s", label);
        $display("============================================================================");
        $display("%-32s  %5s  %7s  %6s  %8s",
                 "Predictor", "Br.", "Acc %", "Pen.Cy", "Pen.Red%");
        $display("----------------------------------------------------------------------------");
        $display("%-32s  %5d  %7s  %6d  %8s",
                 "PicoRV32 (stall-to-resolve)", pico_total, "  0.00", pico_penalty, "  ref.");
        $display("%-32s  %5d  %7.2f  %6d  %8.2f",
                 "Baseline always-NT",
                 ant_total, ant_acc/100.0, ant_penalty, ant_red/100.0);
        $display("%-32s  %5d  %7.2f  %6d  %8.2f",
                 "Ibex + SBP (bk-T / fwd-NT)",
                 sbp_total, sbp_acc/100.0, sbp_penalty, sbp_red/100.0);
        $display("%-32s  %5d  %7.2f  %6d  %8.2f",
                 "VexRiscv + BHT (2-bit)",
                 bht_total, bht_acc/100.0, bht_penalty, bht_red/100.0);
        $display("%-32s  %5d  %7.2f  %6d  %8.2f",
                 "This work (hybrid+CG+ES)",
                 bp_total,  bp_acc/100.0,  bp_penalty,  bp_red/100.0);
        $display("----------------------------------------------------------------------------");
        $display("Innovation: neural used=%0d/%0d, avg_steps=%.2f, early_exit=%0d",
                 bp_neural_used, bp_total,
                 (bp_total > 0) ? (bp_total_steps * 1.0) / bp_total : 0.0,
                 bp_early_exit);
        $display("============================================================================");

        // CSV line for easy aggregation (script reads this line)
        $display("CSV,%0s,%0d,%0d,%0d,%.2f,%0d,%.2f,%0d,%.2f,%0d,%.2f,%0d",
                 label,
                 pico_total, pico_penalty,
                 ant_total,  ant_acc/100.0,  ant_penalty,
                 sbp_total,  sbp_acc/100.0,  sbp_penalty,
                 bht_total,  bht_acc/100.0,  bht_penalty,
                 bp_total,   bp_acc/100.0,   bp_penalty);

        $finish;
    end

endmodule
