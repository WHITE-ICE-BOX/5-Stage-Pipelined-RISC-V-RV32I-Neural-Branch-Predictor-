`timescale 1ns/1ps

module tb_bp_metrics;

    reg clk;
    reg reset;

    integer total_branches;
    integer correct_predictions;
    integer mispredict_count;
    integer neural_used_count;
    integer total_used_steps;

    wire [31:0] debug_pc;
    wire        cond_branch_resolve;
    wire        predicted_taken;
    wire        actual_taken;
    wire        mispredict;
    wire        used_neural;
    wire [3:0]  used_steps;

    assign debug_pc            = risc_v_soc_bp_1.top_1.pc_now;
    assign cond_branch_resolve = risc_v_soc_bp_1.top_1.ex_is_cond_branch;
    assign predicted_taken     = risc_v_soc_bp_1.top_1.ex_pred_taken;
    assign actual_taken        = risc_v_soc_bp_1.top_1.branch_taken;
    assign mispredict          = risc_v_soc_bp_1.top_1.ex_mispredict;
    assign used_neural         = risc_v_soc_bp_1.top_1.ex_use_neural;
    assign used_steps          = risc_v_soc_bp_1.top_1.ex_used_steps;

    always #4 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        total_branches      = 0;
        correct_predictions = 0;
        mispredict_count    = 0;
        neural_used_count   = 0;
        total_used_steps    = 0;

        $display("===============================================================");
        $display(" Innovation CPU Metrics TB");
        $display("===============================================================");

        #10;
        reset = 1'b0;
    end

    risc_v_soc_bp risc_v_soc_bp_1(
        .clk(clk),
        .reset(reset)
    );

    initial begin
        $readmemb("/home/barkie1/riscv32i/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/instr_data_branchstress.txt",
                  risc_v_soc_bp_1.rom_1.rom_mem);
        $display("ROM[0] = %b", risc_v_soc_bp_1.rom_1.rom_mem[0]);
    end

    always @(posedge clk) begin
        if (!reset) begin
            if (cond_branch_resolve) begin
                total_branches = total_branches + 1;

                if (predicted_taken == actual_taken)
                    correct_predictions = correct_predictions + 1;
                else
                    mispredict_count = mispredict_count + 1;

                if (used_neural)
                    neural_used_count = neural_used_count + 1;

                total_used_steps = total_used_steps + used_steps;

                $display("[BP] t=%0d pc=%0d pred=%0d actual=%0d neural=%0d steps=%0d total=%0d correct=%0d mis=%0d",
                         $time, debug_pc, predicted_taken, actual_taken, used_neural, used_steps,
                         total_branches, correct_predictions, mispredict_count);
            end
        end
    end

    initial begin
        #4000;
        $display("---------------------------------------------------------------");
        $display("Innovation Summary");
        $display("Total Conditional Branches : %0d", total_branches);
        $display("Correct Predictions       : %0d", correct_predictions);
        $display("Mispredictions            : %0d", mispredict_count);

        if (total_branches != 0)
            $display("Accuracy (x10000)         : %0d",
                     (correct_predictions * 10000) / total_branches);
        else
            $display("Accuracy (x10000)         : N/A");

        $display("Neural Used Count         : %0d", neural_used_count);

        if (total_branches != 0)
            $display("Neural Use Ratio (x10000): %0d",
                     (neural_used_count * 10000) / total_branches);
        else
            $display("Neural Use Ratio (x10000): N/A");

        if (total_branches != 0)
            $display("Avg Used Steps (x10000)  : %0d",
                     (total_used_steps * 10000) / total_branches);
        else
            $display("Avg Used Steps (x10000)  : N/A");

        $display("---------------------------------------------------------------");
        $finish;
    end

endmodule