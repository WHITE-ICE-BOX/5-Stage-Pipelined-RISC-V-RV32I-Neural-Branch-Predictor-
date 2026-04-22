`timescale 1ns/1ps
`include "risc_v_soc.v"
module tb;

    reg clk;
    reg reset;
    initial begin
        clk = 0;
        reset = 1;
        #20;
        reset = 0;
    end
    //rom初始值
    initial begin
        $readmemb("D:/risc-v_RTOS/rtl/instr_data.txt", risc_v_soc_1.rom_1.rom_mem);
    end
    initial begin
    // 等待 ROM 初始化完成
    #5;
        $display("=== ROM Init Check ===");
        $display("rom_mem[0] = %b", tb.risc_v_soc_1.rom_1.rom_mem[0]);
        $display("rom_mem[1] = %b", tb.risc_v_soc_1.rom_1.rom_mem[1]);
        $display("rom_mem[2] = %b", tb.risc_v_soc_1.rom_1.rom_mem[2]);
        $display("======================");
    end

    always #10 clk = ~clk; // 10ns 週期 20ns 50MHz
    risc_v_soc risc_v_soc_1(
        .clk(clk),
        .reset(reset)
    );

    initial begin
    while(1) begin
        @(posedge clk)
        $display("x27 register value is %d", tb.risc_v_soc_1.top_1.reg_file_1.regs[27]);
        $display("x28 register value is %d", tb.risc_v_soc_1.top_1.reg_file_1.regs[28]);
        $display("x29 register value is %d", tb.risc_v_soc_1.top_1.reg_file_1.regs[29]);
        $display("---------------------------");
        $display("---------------------------");
    end
end
    initial begin
        #1000 $finish;  // 模擬 1000ns 後結束
    end

endmodule