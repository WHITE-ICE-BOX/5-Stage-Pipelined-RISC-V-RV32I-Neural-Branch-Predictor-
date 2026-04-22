`timescale 1ns / 1ps
//`include "pipeline_reg.v"
module mem_wb(
    input wire clk, input wire reset,
    input wire [31:0] data_in, input wire [4:0] rd_addr_in, input wire reg_enable_in,
    
    output wire [31:0] data_out, output wire [4:0] rd_addr_out, output wire reg_enable_out
);
    pipeline_reg #(32) p_data(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(data_in), .reset_data(32'b0), .data_out(data_out));
    pipeline_reg #(5)  p_rd(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(rd_addr_in), .reset_data(5'b0), .data_out(rd_addr_out));
    pipeline_reg #(1)  p_re(.clk(clk), .reset(reset), .stall(1'b0), .flush(1'b0), .data_in(reg_enable_in), .reset_data(1'b0), .data_out(reg_enable_out));
endmodule