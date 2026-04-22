`timescale 1ns / 1ps
//`include "top.v"
//`include "rom.v"
//`include "data_ram.v" // [新增] 引入 RAM 模組

module risc_v_soc(
    input wire clk,
    input wire reset,

    output wire [3:0] led_out // [修改] 將 32-bit 輸出改為 4-bit，降低 I/O 功耗並配合 PYNQ-Z2 LED
);
    wire [31:0] instr;
    wire [31:0] instr_addr;

    // [新增] Data RAM 連接訊號
    wire [31:0] ram_addr;
    wire [31:0] ram_wdata;
    wire ram_we;
    wire [31:0] ram_rdata;

    // [修改] 取 PC 的 [5:2] 輸出到 LED，方便肉眼觀察執行進度
    assign led_out = instr_addr[5:2];

    top top_1(
        .clk(clk),
        .reset(reset),
        .instr_in(instr),
        .instr_addr_out(instr_addr), // [修改] 變數名稱對齊
        // [新增] 連接 Data Memory 介面
        .ram_rdata(ram_rdata),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata),
        .ram_we(ram_we)
    );
    
    rom rom_1(
        // .clk(clk), // ⚠️ 提醒：如果你之前已經把 rom.v 改成同步讀取 (加了 clk)，記得把這行的註解解開
        .addr_if_in(instr_addr),
        .instr_rom_out(instr)
    );
    
    data_ram dram_1(
        .clk(clk),
        .we(ram_we),
        .addr(ram_addr),
        .data_in(ram_wdata),
        .data_out(ram_rdata)
    );
endmodule