`timescale 1ns / 1ps
//`include "pipeline_reg.v"
module ex_mem(
    input wire clk, input wire reset,
    // Inputs from EX
    input wire [31:0] alu_in,
    input wire [31:0] store_data_in,
    input wire [4:0]  rd_addr_in,
    input wire reg_enable_in,
    input wire mem_we_in,
    input wire mem_re_in,
    input wire [2:0] func3_in,

    // Outputs to MEM
    output wire [31:0] alu_out,
    output wire [31:0] store_data_out,
    output wire [4:0]  rd_addr_out,
    output wire reg_enable_out,
    output wire mem_we_out,
    output wire mem_re_out,
    output wire [2:0] func3_out
);
    pipeline_reg #(32) p_alu(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(alu_in), .reset_data(32'b0), .data_out(alu_out));
    pipeline_reg #(32) p_sdata(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(store_data_in), .reset_data(32'b0), .data_out(store_data_out));
    pipeline_reg #(5)  p_rd(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(rd_addr_in), .reset_data(5'b0), .data_out(rd_addr_out));
    pipeline_reg #(1)  p_re(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(reg_enable_in), .reset_data(1'b0), .data_out(reg_enable_out));
    pipeline_reg #(1)  p_mwe(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(mem_we_in), .reset_data(1'b0), .data_out(mem_we_out));
    pipeline_reg #(1)  p_mre(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(mem_re_in), .reset_data(1'b0), .data_out(mem_re_out));
    pipeline_reg #(3)  p_f3(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(func3_in), .reset_data(3'b0), .data_out(func3_out));
endmodule