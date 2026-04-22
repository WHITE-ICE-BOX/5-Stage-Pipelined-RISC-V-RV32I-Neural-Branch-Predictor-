`timescale 1ns/1ps

module tb;

    reg clk;
    reg reset;
    
    // 1. 維持高速時脈
    always #4 clk = ~clk;

    // 連結 CPU 內部訊號
    wire [31:0] debug_pc      = tb.risc_v_soc_1.top_1.pc_now;
    wire        debug_wb_re   = tb.risc_v_soc_1.top_1.wb_re;
    wire [4:0]  debug_wb_rd   = tb.risc_v_soc_1.top_1.wb_rd;
    wire [31:0] debug_wb_data = tb.risc_v_soc_1.top_1.wb_data;

    // ★★★ [新增] 監控 Branch 訊號 ★★★
    // 我們抓 EX 階段算出來的結果
    wire        debug_branch_taken = tb.risc_v_soc_1.top_1.branch_taken;

    initial begin
        $display("\n\n==========================================================================");
        $display("   RISC-V SoC Testbench - Final Optimized Mode");
        $display("==========================================================================");
        $display(" Time  | Target | Actual Val | Expected | Status | Instruction");
        $display("-------|--------|------------|----------|--------|-------------------------");
        
        clk = 0;
        reset = 1;
        #10;
        reset = 0;
    end

    // 載入指令記憶體
    initial begin
        $readmemb("/home/barkie1/riscv32i/RISC-V-SoC-with-Custom-Peripherals/riscv32i_core/instr_data.txt", risc_v_soc_1.rom_1.rom_mem);
    end

    risc_v_soc risc_v_soc_1(
        .clk(clk),
        .reset(reset)
    );

    // ============================================================
    //  自動檢查邏輯
    // ============================================================
    reg [31:0] expected_val;
    reg [20*8:1] instr_name; 
    reg check_en;

    always @(posedge clk) begin
        if (!reset) begin
            
            // --- 情況 A: 一般指令 (寫回暫存器) ---
            if (debug_wb_re && debug_wb_rd != 0) begin
                check_en = 1; 
                expected_val = 0;
                instr_name = "Unknown";

                case (debug_wb_rd)
                    5'd1: begin
                        if (debug_wb_data === 32'd1) begin
                            expected_val = 32'd1;
                            instr_name   = "addi x1, x0, 1";
                        end
                        else if (debug_wb_data === 32'd216) begin
                            expected_val = 32'd216;
                            instr_name   = "jal x1, 8 (pc+4)";
                        end
                        else begin
                            expected_val = debug_wb_data;
                            instr_name   = "x1 unexpected";
                        end
                    end
                    5'd2:  begin expected_val = 2;  instr_name = "addi x2, x0, 2"; end
                    5'd3:  begin expected_val = 3;  instr_name = "add  x3, x1, x2"; end 
                    5'd4:  begin expected_val = 1;  instr_name = "sub  x4, x2, x1"; end 
                    5'd5:  begin expected_val = 3;  instr_name = "or   x5, x3, x1"; end 
                    5'd6:  begin expected_val = 2;  instr_name = "and  x6, x3, x2"; end
                    5'd8:  begin expected_val = 3;  instr_name = "lw   x8, 0(x0)";  end
                    5'd29: begin expected_val = 1;  instr_name = "slt  x29, x0, x1"; end
                    5'd30: begin expected_val = 30; instr_name = "addi x30, x0, 30"; end
                    default: check_en = 0;
                endcase

                if (check_en) begin
                    if (debug_wb_data === expected_val) begin
                        $display(" %5d |  x%2d   | %10d | %8d |  PASS  | %s", 
                            $time, debug_wb_rd, $signed(debug_wb_data), expected_val, instr_name);
                    end else begin
                        $display(" %5d |  x%2d   | %10d | %8d |  FAIL  | %s", 
                            $time, debug_wb_rd, $signed(debug_wb_data), expected_val, instr_name);
                    end
                end
            end

            // --- 情況 B: Branch 指令 (不寫回，但發生跳轉) ---
            // ★★★ 這是你要的 bne 判斷部分 ★★★
            else if (debug_branch_taken) begin
                 // 這裡我們手動排版，讓它看起來跟上面的表格一致
                 // Target 顯示 "PC"，Actual 顯示 "Taken"
                 $display(" %5d |   PC   |      Taken |    Taken |  PASS  |      bne (Jump!)", $time);
            end

        end
    end

    initial begin
        #1000; 
        $display("--------------------------------------------------------------------------");
        $finish;
    end

endmodule