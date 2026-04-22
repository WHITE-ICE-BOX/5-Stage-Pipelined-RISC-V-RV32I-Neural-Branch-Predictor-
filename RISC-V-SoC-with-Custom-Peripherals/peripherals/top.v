`timescale 1ns / 1ps
`include "pc_reg.v"
`include "i_f.v"
`include "if_id.v"
`include "id.v"
`include "reg_file.v"
`include "id_ex.v"
`include "ex.v"

module  top(
    input wire clk,
    input wire reset,
    input wire [31:0] instr_in,
    output wire  [31:0] addr_out
);
    // pc to if 
    wire [31:0] pc_if; 

    // if to if_id 
    wire [31:0] if_if_id_instr;
    wire [31:0] if_if_id_addr;

    //if_id to id
    wire [31:0] if_id_id_instr;
    wire [31:0] if_id_id_addr;

    //id to reg_file
    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    //id to id_ex
    wire [31:0] id_id_ex_instr;
    wire [31:0] id_id_ex_addr;
    wire [31:0] id_id_ex_op1_data;
    wire [31:0] id_id_ex_op2_data;
    wire [4:0]  id_id_ex_rd_addr;
    wire id_id_ex_reg_enable;

    //id_ex to ex
    wire [31:0] id_ex_ex_instr;
    wire [31:0] id_ex_ex_addr;
    wire [31:0] id_ex_ex_op1_data;
    wire [31:0] id_ex_ex_op2_data;
    wire [4:0]  id_ex_ex_rd_addr;
    wire id_ex_ex_reg_enable;

    //ex wb to reg_file
    wire ex_wb_reg_enable_in;
    wire [4:0]  ex_wb_rd_addr_in;
    wire [31:0] ex_wb_rd_data_in;
    

    pc_reg pc_reg_1(
        .clk(clk),
        .reset(reset),
        .pc_out(pc_if)
    );

    i_f i_f_1(
        .pc_in(pc_if),
        .instr_rom_if(instr_in),
        .addr_if_rom(addr_out),
        .instr_out(if_if_id_instr),
        .instr_addr_out(if_if_id_addr)
    );

    if_id if_id_1(
        .clk(clk),
        .reset(reset),
        .if_addr_in(if_if_id_addr),
        .if_instr_in(if_if_id_instr),
        .if_id_addr_out(if_id_id_addr),
        .if_id_instr_out(if_id_id_instr)
    );

    id id_1(
        .if_id_addr_in(if_id_id_addr),
        .if_id_instr_in(if_id_id_instr),

        .rs1_data_in(rs1_data),
        .rs2_data_in(rs2_data),
        .rs1_addr_out(rs1_addr),
        .rs2_addr_out(rs2_addr),

        .id_instr_out(id_id_ex_instr),
        .id_addr_out(id_id_ex_addr),
        .id_op1_data_out(id_id_ex_op1_data),
        .id_op2_data_out(id_id_ex_op2_data),
        .id_rd_addr_out(id_id_ex_rd_addr),
        .reg_enable(id_id_ex_reg_enable)
    );

    reg_file reg_file_1(
        .clk(clk), 
        .reset(reset),
        .ex_reg_enable_in(ex_wb_reg_enable_in),
        .rd_addr_in(ex_wb_rd_addr_in),
        .rd_data_in(ex_wb_rd_data_in),
        .rs1_addr_in(rs1_addr),
        .rs2_addr_in(rs2_addr),
        .rs1_data_out(rs1_data),
        .rs2_data_out(rs2_data)
    );

    id_ex id_ex_1(
        .clk(clk),
        .reset(reset),
        .id_instr_in(id_id_ex_instr),
        .id_addr_in(id_id_ex_addr),
        .op1_in(id_id_ex_op1_data),
        .op2_in(id_id_ex_op2_data),
        .rd_addr_in(id_id_ex_rd_addr),
        .reg_enable_in(id_id_ex_reg_enable),
        .id_ex_instr_out(id_ex_ex_instr),
        .id_ex_addr_out(id_ex_ex_addr),
        .op1_out(id_ex_ex_op1_data),
        .op2_out(id_ex_ex_op2_data),
        .rd_addr_out(id_ex_ex_rd_addr),
        .reg_enable_out(id_ex_ex_reg_enable)
    );

    ex ex_1(
        .id_ex_instr_in(id_ex_ex_instr),
        .id_ex_addr_in(id_ex_ex_addr),
        .op1_in(id_ex_ex_op1_data),
        .op2_in(id_ex_ex_op2_data),
        .rd_addr_in(id_ex_ex_rd_addr),
        .reg_enable_in(id_ex_ex_reg_enable),
        .op_out(ex_wb_rd_data_in),
        .rd_addr_out(ex_wb_rd_addr_in),
        .reg_enable_out(ex_wb_reg_enable_in)
);
endmodule