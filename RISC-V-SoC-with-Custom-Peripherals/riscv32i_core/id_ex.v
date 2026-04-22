`timescale 1ns / 1ps
`include "define.v"
module id_ex(
    input wire clk,
    input wire reset,
    input wire flush, // [新增] 支援 Control Unit 的沖刷
    //id
    input wire [31:0] id_instr_in,
    input wire [31:0] id_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,
    input wire [4:0]  rd_addr_in,
    input wire reg_enable_in,
    // [新增] 擴充訊號輸入
    input wire [31:0] imm_in,
    input wire [31:0] store_data_in,
    input wire mem_we_in,
    input wire mem_re_in,
    input wire [2:0] func3_in,
    input wire [6:0] opcode_in,
    //ex
    output wire [31:0] id_ex_instr_out,
    output wire [31:0] id_ex_addr_out,
    output wire [31:0] op1_out,
    output wire [31:0] op2_out,
    output wire [4:0]  rd_addr_out,
    output wire reg_enable_out,

    // [新增] 擴充訊號輸出
    output wire [31:0] imm_out,
    output wire [31:0] store_data_out,
    output wire mem_we_out,
    output wire mem_re_out,
    output wire [2:0] func3_out,
    output wire [6:0] opcode_out
);
    // 原有的 pipeline regs (加上 flush)
    pipeline_reg #(32) pip_reg1(.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(id_instr_in), .reset_data(`INST_NOP), .data_out(id_ex_instr_out));
    pipeline_reg #(32) pip_reg2(.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(id_addr_in), .reset_data(32'b0), .data_out(id_ex_addr_out));
    pipeline_reg #(32) pip_reg3(.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(op1_in), .reset_data(32'b0), .data_out(op1_out));
    pipeline_reg #(32) pip_reg4(.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(op2_in), .reset_data(32'b0), .data_out(op2_out));
    pipeline_reg #(5)  pip_reg5(.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(rd_addr_in), .reset_data(5'b0), .data_out(rd_addr_out));
    pipeline_reg #(1)  pip_reg6(.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(reg_enable_in), .reset_data(1'b0), .data_out(reg_enable_out));
    
    // [新增] 新增訊號的 pipeline regs
    pipeline_reg #(32) pip_imm  (.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(imm_in), .reset_data(32'b0), .data_out(imm_out));
    pipeline_reg #(32) pip_sdata(.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(store_data_in), .reset_data(32'b0), .data_out(store_data_out));
    pipeline_reg #(1)  pip_mwe  (.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(mem_we_in), .reset_data(1'b0), .data_out(mem_we_out));
    pipeline_reg #(1)  pip_mre  (.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(mem_re_in), .reset_data(1'b0), .data_out(mem_re_out));
    pipeline_reg #(3)  pip_func3(.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(func3_in), .reset_data(3'b0), .data_out(func3_out));
    pipeline_reg #(7)  pip_opc  (.clk(clk), .reset(reset), .stall(1'b0), .flush(flush), .data_in(opcode_in), .reset_data(7'b0), .data_out(opcode_out));

endmodule