`timescale 1ns/1ps

module tb_compare_metrics;

    reg clk;
    reg reset;

    // -------------------------------
    // baseline counters
    // -------------------------------
    integer base_total_branches;
    integer base_correct_predictions;
    integer base_mispredict_count;
    integer base_penalty_cycles;

    // -------------------------------
    // innovation counters
    // -------------------------------
    integer bp_total_branches;
    integer bp_correct_predictions;
    integer bp_mispredict_count;
    integer bp_neural_used_count;
    integer bp_total_used_steps;
    integer bp_penalty_cycles;

    integer bp_neural_correct;
    integer bp_neural_wrong;
    integer bp_bimodal_path_count;
    integer bp_bimodal_path_correct;
    integer bp_bimodal_path_wrong;

    integer bp_full_step_count;
    integer bp_early_exit_count;

    // used_steps histogram: 0~8
    integer step_hist_0;
    integer step_hist_1;
    integer step_hist_2;
    integer step_hist_3;
    integer step_hist_4;
    integer step_hist_5;
    integer step_hist_6;
    integer step_hist_7;
    integer step_hist_8;

    // -------------------------------
    // summary integers (x10000)
    // -------------------------------
    integer base_accuracy_x10000;
    integer bp_accuracy_x10000;
    integer accuracy_improvement_x10000;

    integer bp_neural_ratio_x10000;
    integer bp_avg_steps_x10000;

    integer mispredict_reduction_ratio_x10000;
    integer penalty_reduction_ratio_x10000;

    integer bp_neural_accuracy_x10000;
    integer bp_bimodal_path_accuracy_x10000;

    // -------------------------------
    // baseline wires
    // -------------------------------
    wire [31:0] base_pc;
    wire [6:0]  base_ex_opcode;
    wire        base_actual_taken;
    wire        base_cond_branch;
    wire        base_pred_taken;

    // -------------------------------
    // innovation wires
    // -------------------------------
    wire [31:0] bp_pc;
    wire        bp_cond_branch;
    wire        bp_pred_taken;
    wire        bp_actual_taken;
    wire        bp_mispredict;
    wire        bp_use_neural;
    wire [3:0]  bp_used_steps;

    // -------------------------------
    // assumptions
    // -------------------------------
    // 五級管線 branch mispredict 近似代價
    localparam MISPREDICT_PENALTY = 2;

    assign base_pc           = u_base.top_1.pc_now;
    assign base_ex_opcode    = u_base.top_1.ex_opcode;
    assign base_actual_taken = u_base.top_1.branch_taken;
    assign base_cond_branch  = (base_ex_opcode == 7'b1100011);
    assign base_pred_taken   = 1'b0; // baseline = always not-taken

    assign bp_pc           = u_bp.top_1.pc_now;
    assign bp_cond_branch  = u_bp.top_1.ex_is_cond_branch;
    assign bp_pred_taken   = u_bp.top_1.ex_pred_taken;
    assign bp_actual_taken = u_bp.top_1.branch_taken;
    assign bp_mispredict   = u_bp.top_1.ex_mispredict;
    assign bp_use_neural   = u_bp.top_1.ex_use_neural;
    assign bp_used_steps   = u_bp.top_1.ex_used_steps;

    always #4 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        // baseline
        base_total_branches      = 0;
        base_correct_predictions = 0;
        base_mispredict_count    = 0;
        base_penalty_cycles      = 0;

        // innovation
        bp_total_branches        = 0;
        bp_correct_predictions   = 0;
        bp_mispredict_count      = 0;
        bp_neural_used_count     = 0;
        bp_total_used_steps      = 0;
        bp_penalty_cycles        = 0;

        bp_neural_correct        = 0;
        bp_neural_wrong          = 0;
        bp_bimodal_path_count    = 0;
        bp_bimodal_path_correct  = 0;
        bp_bimodal_path_wrong    = 0;

        bp_full_step_count       = 0;
        bp_early_exit_count      = 0;

        step_hist_0 = 0;
        step_hist_1 = 0;
        step_hist_2 = 0;
        step_hist_3 = 0;
        step_hist_4 = 0;
        step_hist_5 = 0;
        step_hist_6 = 0;
        step_hist_7 = 0;
        step_hist_8 = 0;

        base_accuracy_x10000          = 0;
        bp_accuracy_x10000            = 0;
        accuracy_improvement_x10000   = 0;
        bp_neural_ratio_x10000        = 0;
        bp_avg_steps_x10000           = 0;
        mispredict_reduction_ratio_x10000 = 0;
        penalty_reduction_ratio_x10000    = 0;
        bp_neural_accuracy_x10000     = 0;
        bp_bimodal_path_accuracy_x10000 = 0;

        $display("\n==============================================================================");
        $display(" Enhanced Comparison: Baseline CPU vs Innovation CPU");
        $display("==============================================================================");

        #10;
        reset = 0;
    end

    // baseline program load
    initial begin
        $readmemb("/home/barkie1/riscv32i/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/instr_data_branchstress.txt",
                  u_base.rom_1.rom_mem);
    end

    // innovation program load
    initial begin
        $readmemb("/home/barkie1/riscv32i/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/instr_data_branchstress.txt",
                  u_bp.rom_1.rom_mem);
    end

    risc_v_soc u_base(
        .clk(clk),
        .reset(reset)
    );

    risc_v_soc_bp u_bp(
        .clk(clk),
        .reset(reset)
    );

    // -------------------------------
    // baseline metrics
    // -------------------------------
    always @(posedge clk) begin
        if (!reset) begin
            if (base_cond_branch) begin
                base_total_branches = base_total_branches + 1;

                if (base_pred_taken == base_actual_taken)
                    base_correct_predictions = base_correct_predictions + 1;
                else begin
                    base_mispredict_count = base_mispredict_count + 1;
                    base_penalty_cycles = base_penalty_cycles + MISPREDICT_PENALTY;
                end

                $display("[BASE] t=%0d pc=%0d pred=%0d actual=%0d total=%0d correct=%0d mis=%0d pen=%0d",
                         $time, base_pc, base_pred_taken, base_actual_taken,
                         base_total_branches, base_correct_predictions,
                         base_mispredict_count, base_penalty_cycles);
            end
        end
    end

    // -------------------------------
    // innovation metrics
    // -------------------------------
    always @(posedge clk) begin
        if (!reset) begin
            if (bp_cond_branch) begin
                bp_total_branches = bp_total_branches + 1;

                if (bp_pred_taken == bp_actual_taken)
                    bp_correct_predictions = bp_correct_predictions + 1;
                else begin
                    bp_mispredict_count = bp_mispredict_count + 1;
                    bp_penalty_cycles = bp_penalty_cycles + MISPREDICT_PENALTY;
                end

                if (bp_use_neural) begin
                    bp_neural_used_count = bp_neural_used_count + 1;

                    if (bp_pred_taken == bp_actual_taken)
                        bp_neural_correct = bp_neural_correct + 1;
                    else
                        bp_neural_wrong = bp_neural_wrong + 1;
                end
                else begin
                    bp_bimodal_path_count = bp_bimodal_path_count + 1;

                    if (bp_pred_taken == bp_actual_taken)
                        bp_bimodal_path_correct = bp_bimodal_path_correct + 1;
                    else
                        bp_bimodal_path_wrong = bp_bimodal_path_wrong + 1;
                end

                bp_total_used_steps = bp_total_used_steps + bp_used_steps;

                if (bp_used_steps == 8)
                    bp_full_step_count = bp_full_step_count + 1;
                else
                    bp_early_exit_count = bp_early_exit_count + 1;

                case (bp_used_steps)
                    0: step_hist_0 = step_hist_0 + 1;
                    1: step_hist_1 = step_hist_1 + 1;
                    2: step_hist_2 = step_hist_2 + 1;
                    3: step_hist_3 = step_hist_3 + 1;
                    4: step_hist_4 = step_hist_4 + 1;
                    5: step_hist_5 = step_hist_5 + 1;
                    6: step_hist_6 = step_hist_6 + 1;
                    7: step_hist_7 = step_hist_7 + 1;
                    8: step_hist_8 = step_hist_8 + 1;
                    default: begin end
                endcase

                $display("[BP  ] t=%0d pc=%0d pred=%0d actual=%0d neural=%0d steps=%0d total=%0d correct=%0d mis=%0d pen=%0d",
                         $time, bp_pc, bp_pred_taken, bp_actual_taken, bp_use_neural, bp_used_steps,
                         bp_total_branches, bp_correct_predictions,
                         bp_mispredict_count, bp_penalty_cycles);
            end
        end
    end

    initial begin
        #4000;

        // accuracy
        if (base_total_branches != 0)
            base_accuracy_x10000 = (base_correct_predictions * 10000) / base_total_branches;
        else
            base_accuracy_x10000 = 0;

        if (bp_total_branches != 0)
            bp_accuracy_x10000 = (bp_correct_predictions * 10000) / bp_total_branches;
        else
            bp_accuracy_x10000 = 0;

        accuracy_improvement_x10000 = bp_accuracy_x10000 - base_accuracy_x10000;

        // neural ratio
        if (bp_total_branches != 0)
            bp_neural_ratio_x10000 = (bp_neural_used_count * 10000) / bp_total_branches;
        else
            bp_neural_ratio_x10000 = 0;

        // avg steps
        if (bp_total_branches != 0)
            bp_avg_steps_x10000 = (bp_total_used_steps * 10000) / bp_total_branches;
        else
            bp_avg_steps_x10000 = 0;

        // mispredict reduction ratio
        if (base_mispredict_count != 0)
            mispredict_reduction_ratio_x10000 =
                ((base_mispredict_count - bp_mispredict_count) * 10000) / base_mispredict_count;
        else
            mispredict_reduction_ratio_x10000 = 0;

        // penalty reduction ratio
        if (base_penalty_cycles != 0)
            penalty_reduction_ratio_x10000 =
                ((base_penalty_cycles - bp_penalty_cycles) * 10000) / base_penalty_cycles;
        else
            penalty_reduction_ratio_x10000 = 0;

        // neural accuracy
        if (bp_neural_used_count != 0)
            bp_neural_accuracy_x10000 = (bp_neural_correct * 10000) / bp_neural_used_count;
        else
            bp_neural_accuracy_x10000 = 0;

        // bimodal path accuracy
        if (bp_bimodal_path_count != 0)
            bp_bimodal_path_accuracy_x10000 =
                (bp_bimodal_path_correct * 10000) / bp_bimodal_path_count;
        else
            bp_bimodal_path_accuracy_x10000 = 0;

        $display("------------------------------------------------------------------------------");
        $display("FINAL ENHANCED COMPARISON");
        $display("------------------------------------------------------------------------------");
        $display("Baseline Total Branches         : %0d", base_total_branches);
        $display("Baseline Correct                : %0d", base_correct_predictions);
        $display("Baseline Mispredict             : %0d", base_mispredict_count);
        $display("Baseline Accuracy (x10000)      : %0d", base_accuracy_x10000);
        $display("Baseline Penalty Cycles         : %0d", base_penalty_cycles);

        $display("------------------------------------------------------------------------------");
        $display("Innovation Total Branches       : %0d", bp_total_branches);
        $display("Innovation Correct              : %0d", bp_correct_predictions);
        $display("Innovation Mispredict           : %0d", bp_mispredict_count);
        $display("Innovation Accuracy (x10000)    : %0d", bp_accuracy_x10000);
        $display("Innovation Penalty Cycles       : %0d", bp_penalty_cycles);
        $display("Innovation Neural Used          : %0d", bp_neural_used_count);
        $display("Innovation Neural Ratio         : %0d", bp_neural_ratio_x10000);
        $display("Innovation Avg Steps            : %0d", bp_avg_steps_x10000);

        $display("------------------------------------------------------------------------------");
        $display("Neural Correct                  : %0d", bp_neural_correct);
        $display("Neural Wrong                    : %0d", bp_neural_wrong);
        $display("Neural Accuracy (x10000)        : %0d", bp_neural_accuracy_x10000);

        $display("Bimodal-Path Count              : %0d", bp_bimodal_path_count);
        $display("Bimodal-Path Correct            : %0d", bp_bimodal_path_correct);
        $display("Bimodal-Path Wrong              : %0d", bp_bimodal_path_wrong);
        $display("Bimodal-Path Accuracy (x10000)  : %0d", bp_bimodal_path_accuracy_x10000);

        $display("------------------------------------------------------------------------------");
        $display("Full-Step Count                 : %0d", bp_full_step_count);
        $display("Early-Exit Count                : %0d", bp_early_exit_count);
        $display("used_steps histogram:");
        $display("  step 0 : %0d", step_hist_0);
        $display("  step 1 : %0d", step_hist_1);
        $display("  step 2 : %0d", step_hist_2);
        $display("  step 3 : %0d", step_hist_3);
        $display("  step 4 : %0d", step_hist_4);
        $display("  step 5 : %0d", step_hist_5);
        $display("  step 6 : %0d", step_hist_6);
        $display("  step 7 : %0d", step_hist_7);
        $display("  step 8 : %0d", step_hist_8);

        $display("------------------------------------------------------------------------------");
        $display("Accuracy Improvement (x10000)   : %0d", accuracy_improvement_x10000);
        $display("Mispredict Reduction            : %0d", base_mispredict_count - bp_mispredict_count);
        $display("Mispredict Reduction Ratio      : %0d", mispredict_reduction_ratio_x10000);
        $display("Penalty Reduction Ratio         : %0d", penalty_reduction_ratio_x10000);
        $display("------------------------------------------------------------------------------");

        $finish;
    end

endmodule
