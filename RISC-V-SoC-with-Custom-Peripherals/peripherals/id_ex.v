`include "define.v"
module id_ex(
    input wire clk,
    input wire reset,
    //id
    input wire [31:0] id_instr_in,
    input wire [31:0] id_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,
    input wire [4:0]  rd_addr_in,
    input wire reg_enable_in,
    //ex
    output wire [31:0] id_ex_instr_out,
    output wire [31:0] id_ex_addr_out,
    output wire [31:0] op1_out,
    output wire [31:0] op2_out,
    output wire [4:0]  rd_addr_out,
    output wire reg_enable_out
);
    pipeline_reg #(32) pip_reg1(
        .clk(clk),
        .reset(reset),
        .data_in(id_instr_in),
        .reset_data(`INST_NOP),
        .data_out(id_ex_instr_out)
    );

    pipeline_reg #(32) pip_reg2(
        .clk(clk),
        .reset(reset),
        .data_in(id_addr_in),
        .reset_data(32'b0),
        .data_out(id_ex_addr_out)
    );

    pipeline_reg #(32) pip_reg3(
        .clk(clk),
        .reset(reset),
        .data_in(op1_in),
        .reset_data(32'b0),
        .data_out(op1_out)
    );

    pipeline_reg #(32) pip_reg4(
        .clk(clk),
        .reset(reset),
        .data_in(op2_in),
        .reset_data(32'b0),
        .data_out(op2_out)
    );

    pipeline_reg #(5) pip_reg5(
        .clk(clk),
        .reset(reset),
        .data_in(rd_addr_in),
        .reset_data(5'b0),
        .data_out(rd_addr_out)
    );

    pipeline_reg #(1) pip_reg6(
        .clk(clk),
        .reset(reset),
        .data_in(reg_enable_in),
        .reset_data(1'b0),
        .data_out(reg_enable_out)
    );

endmodule