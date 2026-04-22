`timescale 1ns/1ps

module tb_baseline_metrics;

    reg clk;
    reg reset;

    integer total_branches;
    integer correct_predictions;
    integer mispredict_count;

    // 不依賴 define.v，直接寫 B-type opcode = 7'b1100011
    wire [31:0] debug_pc      = tb_baseline_metrics.risc_v_soc_1.top_1.pc_now;
    wire [6:0]  ex_opcode     = tb_baseline_metrics.risc_v_soc_1.top_1.ex_opcode;
    wire        actual_taken  = tb_baseline_metrics.risc_v_soc_1.top_1.branch_taken;

    wire        cond_branch_resolve;
    wire        predicted_taken;

    assign cond_branch_resolve = (ex_opcode == 7'b1100011);
    assign predicted_taken     = 1'b0;   // baseline = always not-taken

    always #4 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        total_branches = 0;
        correct_predictions = 0;
        mispredict_count = 0;

        $display("\n===============================================================");
        $display(" Baseline CPU Metrics TB");
        $display("===============================================================");

        #10;
        reset = 0;
    end

    initial begin
        // 你說先不要改路徑，這裡保留你原本習慣
       $readmemb("/home/barkie1/riscv32i/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/instr_data_branchstress.txt", risc_v_soc_1.rom_1.rom_mem);
    end
    risc_v_soc risc_v_soc_1(
        .clk(clk),
        .reset(reset)
    );

    always @(posedge clk) begin
        if (!reset) begin
            if (cond_branch_resolve) begin
                total_branches = total_branches + 1;

                if (predicted_taken == actual_taken)
                    correct_predictions = correct_predictions + 1;
                else
                    mispredict_count = mispredict_count + 1;

                $display("[BASE] t=%0d pc=%0d pred=%0d actual=%0d total=%0d correct=%0d mis=%0d",
                         $time, debug_pc, predicted_taken, actual_taken,
                         total_branches, correct_predictions, mispredict_count);
            end
        end
    end

    initial begin
        #2000;
        $display("---------------------------------------------------------------");
        $display("Baseline Summary");
        $display("Total Conditional Branches : %0d", total_branches);
        $display("Correct Predictions       : %0d", correct_predictions);
        $display("Mispredictions            : %0d", mispredict_count);
        if (total_branches != 0)
            $display("Accuracy (x10000)         : %0d",
                     (correct_predictions * 10000) / total_branches);
        else
            $display("Accuracy (x10000)         : N/A");
        $display("---------------------------------------------------------------");
        $finish;
    end

endmodule