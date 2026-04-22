`timescale 1ns / 1ps
`include "define.v"
module ctrl(
    input wire rst,
    input wire branch_taken_in,      // 來自 EX: 分支是否成立
    input wire [4:0] id_rs1_addr,    // 來自 ID: 目前指令來源暫存器
    input wire [4:0] id_rs2_addr,
    input wire [4:0] ex_rd_addr,     // 來自 EX: 上一道指令的目標暫存器
    input wire ex_mem_re,            // 來自 EX: 上一道指令是否讀取記憶體 (Load)
    
    output reg stall_pc,
    output reg stall_if_id,
    output reg flush_if_id,
    output reg flush_id_ex
);
    always @(*) begin
        stall_pc = 1'b0;
        stall_if_id = 1'b0;
        flush_if_id = 1'b0;
        flush_id_ex = 1'b0;

        if (rst) begin
            // do nothing
        end else if (branch_taken_in) begin
            // Branch/Jump 發生：沖刷 IF/ID 和 ID/EX
            flush_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end else if (ex_mem_re && ex_rd_addr != 5'b0 && 
                    (ex_rd_addr == id_rs1_addr || ex_rd_addr == id_rs2_addr)) begin
            // Load-Use Hazard：暫停 PC 和 IF/ID，沖刷 ID/EX (插入 bubble)
            stall_pc = 1'b1;
            stall_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end
    end
endmodule