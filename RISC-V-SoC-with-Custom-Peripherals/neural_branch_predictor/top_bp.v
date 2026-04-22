`timescale 1ns / 1ps
`include "define.v"

module top_bp(
    input wire clk,
    input wire reset,
    input wire [31:0] instr_in,
    input wire [31:0] ram_rdata,

    output wire [31:0] instr_addr_out,
    output wire [31:0] ram_addr,
    output wire [31:0] ram_wdata,
    output wire        ram_we
);
    // ------------------------------
    // Control / PC
    // ------------------------------
    wire stall_pc, stall_if_id, flush_if_id, flush_id_ex;

    wire [31:0] pc_now, pc_next;

    // ------------------------------
    // IF/ID
    // ------------------------------
    wire [31:0] if_out_instr, if_out_pc;
    wire [31:0] if_id_instr, if_id_pc;

    // ------------------------------
    // ID
    // ------------------------------
    wire [31:0] id_op1, id_op2, id_imm, id_sdata;
    wire [4:0]  id_rs1, id_rs2, id_rd;
    wire [6:0]  id_opcode;
    wire [2:0]  id_func3;
    wire        id_re, id_mwe, id_mre, id_branch;
    wire [31:0] rs1_data_read, rs2_data_read;

    wire        is_cond_branch_id;
    wire [31:0] id_branch_target;
    wire        pred_taken_id;
    wire        pred_use_neural_id;
    wire [$clog2(8+1)-1:0] used_steps_id;
    wire [7:0]  ghr_snapshot_id;

    // ------------------------------
    // ID/EX
    // ------------------------------
    wire [31:0] ex_pc, ex_op1, ex_op2, ex_imm, ex_sdata;
    wire [4:0]  ex_rd;
    wire [6:0]  ex_opcode;
    wire [2:0]  ex_func3;
    wire        ex_re, ex_mwe, ex_mre;
    wire [31:0] ex_instr_wire;

    // predictor sideband pipeline
    wire        ex_pred_taken;
    wire        ex_is_cond_branch;
    wire [7:0]  ex_ghr_snapshot;
    wire        ex_use_neural;
    wire [$clog2(8+1)-1:0] ex_used_steps;

    // ------------------------------
    // EX output
    // ------------------------------
    wire [31:0] ex_alu_res, ex_sdata_out;
    wire [4:0]  ex_rd_out;
    wire        ex_re_out, ex_mwe_out, ex_mre_out;
    wire [2:0]  ex_func3_out;
    wire        branch_taken;
    wire [31:0] branch_target;

    // ------------------------------
    // EX/MEM/MEM/WB
    // ------------------------------
    wire [31:0] mem_alu, mem_sdata;
    wire [4:0]  mem_rd;
    wire [2:0]  mem_func3;
    wire        mem_re, mem_mwe, mem_mre;

    wire [31:0] mem_final_data;
    wire [4:0]  mem_rd_final;
    wire        mem_re_final;

    wire [31:0] wb_data;
    wire [4:0]  wb_rd;
    wire        wb_re;

    // ------------------------------
    // predictor update / redirect
    // ------------------------------
    wire ex_is_jal = (ex_opcode == `INST_TYPE_J);
    wire ex_actual_taken = branch_taken;
    wire ex_mispredict   = ex_is_cond_branch && (ex_actual_taken != ex_pred_taken);
    wire ex_redirect_valid = ex_is_jal || ex_mispredict;
    wire [31:0] ex_redirect_pc = ex_actual_taken ? branch_target : (ex_pc + 32'd4);

    assign is_cond_branch_id = (id_opcode == `INST_TYPE_B);
    assign id_branch_target  = if_id_pc + id_imm;

    assign pc_next = ex_redirect_valid ? ex_redirect_pc :
                     ((is_cond_branch_id && pred_taken_id) ? id_branch_target : (pc_now + 32'd4));

    // ------------------------------
    // modules
    // ------------------------------
    ctrl_bp u_ctrl_bp(
        .rst(reset),
        .pred_take_id(is_cond_branch_id && pred_taken_id),
        .ex_redirect_valid(ex_redirect_valid),
        .id_rs1_addr(id_rs1),
        .id_rs2_addr(id_rs2),
        .ex_rd_addr(ex_rd),
        .ex_mem_re(ex_mre),
        .stall_pc(stall_pc),
        .stall_if_id(stall_if_id),
        .flush_if_id(flush_if_id),
        .flush_id_ex(flush_id_ex)
    );

    pc_reg pc_reg_1(
        .clk(clk),
        .reset(reset),
        .stall(stall_pc),
        .next_pc_in(pc_next),
        .pc_out(pc_now)
    );

    i_f i_f_1(
        .pc_in(pc_now),
        .instr_rom_if(instr_in),
        .addr_if_rom(instr_addr_out),
        .instr_out(if_out_instr),
        .instr_addr(if_out_pc)
    );

    if_id if_id_1(
        .clk(clk),
        .reset(reset),
        .stall(stall_if_id),
        .flush(flush_if_id),
        .if_addr_in(if_out_pc),
        .if_instr_in(if_out_instr),
        .if_id_addr_out(if_id_pc),
        .if_id_instr_out(if_id_instr)
    );

    reg_file reg_file_1(
        .clk(clk),
        .reset(reset),
        .ex_reg_enable_in(wb_re),
        .rd_addr_in(wb_rd),
        .rd_data_in(wb_data),
        .rs1_addr_in(if_id_instr[19:15]),
        .rs2_addr_in(if_id_instr[24:20]),
        .rs1_data_out(rs1_data_read),
        .rs2_data_out(rs2_data_read)
    );

    id id_1(
        .if_id_addr_in(if_id_pc),
        .if_id_instr_in(if_id_instr),
        .rs1_data_in(rs1_data_read),
        .rs2_data_in(rs2_data_read),
        .rs1_addr_out(id_rs1),
        .rs2_addr_out(id_rs2),
        .id_instr_out(),
        .id_addr_out(),
        .id_op1_data_out(id_op1),
        .id_op2_data_out(id_op2),
        .id_imm_out(id_imm),
        .id_store_data_out(id_sdata),
        .id_rd_addr_out(id_rd),
        .reg_enable(id_re),
        .mem_we(id_mwe),
        .mem_re(id_mre),
        .branch_flag(id_branch),
        .func3_out(id_func3),
        .opcode_out(id_opcode)
    );

    bp_top #(
        .INDEX_BITS(4),
        .HIST_LEN(8),
        .W_BITS(4),
        .SUM_BITS(8)
    ) u_bp (
        .clk(clk),
        .rst_n(~reset),
        // Feed the IF-stage PC (one cycle ahead of if_id_pc) so that the
        // pipelined perceptron output is ready when the instruction reaches ID.
        .pc_id(if_out_pc),
        .is_branch_id(is_cond_branch_id),
        .pred_taken_id(pred_taken_id),
        .pred_use_neural_id(pred_use_neural_id),
        .used_steps_id(used_steps_id),
        .ghr_snapshot_id(ghr_snapshot_id),
        .update_valid(ex_is_cond_branch),
        .update_pc(ex_pc),
        .actual_taken(ex_actual_taken),
        .was_mispredict(ex_mispredict),
        .update_ghr(ex_ghr_snapshot)
    );

    id_ex id_ex_1(
        .clk(clk),
        .reset(reset),
        .flush(flush_id_ex),
        .id_instr_in(if_id_instr),
        .id_addr_in(if_id_pc),
        .op1_in(id_op1),
        .op2_in(id_op2),
        .rd_addr_in(id_rd),
        .reg_enable_in(id_re),
        .imm_in(id_imm),
        .store_data_in(id_sdata),
        .mem_we_in(id_mwe),
        .mem_re_in(id_mre),
        .func3_in(id_func3),
        .opcode_in(id_opcode),
        .id_ex_instr_out(ex_instr_wire),
        .id_ex_addr_out(ex_pc),
        .op1_out(ex_op1),
        .op2_out(ex_op2),
        .rd_addr_out(ex_rd),
        .reg_enable_out(ex_re),
        .imm_out(ex_imm),
        .store_data_out(ex_sdata),
        .mem_we_out(ex_mwe),
        .mem_re_out(ex_mre),
        .func3_out(ex_func3),
        .opcode_out(ex_opcode)
    );

    // predictor sideband pipeline regs
    pipeline_reg #(1) p_pred_taken (
        .clk(clk), .reset(reset), .stall(1'b0), .flush(flush_id_ex),
        .data_in(pred_taken_id), .reset_data(1'b0), .data_out(ex_pred_taken)
    );

    pipeline_reg #(1) p_is_branch (
        .clk(clk), .reset(reset), .stall(1'b0), .flush(flush_id_ex),
        .data_in(is_cond_branch_id), .reset_data(1'b0), .data_out(ex_is_cond_branch)
    );

    pipeline_reg #(8) p_ghr_snap (
        .clk(clk), .reset(reset), .stall(1'b0), .flush(flush_id_ex),
        .data_in(ghr_snapshot_id), .reset_data(8'b0), .data_out(ex_ghr_snapshot)
    );

    pipeline_reg #(1) p_use_neural (
        .clk(clk), .reset(reset), .stall(1'b0), .flush(flush_id_ex),
        .data_in(pred_use_neural_id), .reset_data(1'b0), .data_out(ex_use_neural)
    );

    pipeline_reg #($clog2(8+1)) p_used_steps (
        .clk(clk), .reset(reset), .stall(1'b0), .flush(flush_id_ex),
        .data_in(used_steps_id), .reset_data({$clog2(8+1){1'b0}}), .data_out(ex_used_steps)
    );

    ex ex_1(
        .id_ex_instr_in(ex_instr_wire),
        .id_ex_addr_in(ex_pc),
        .op1_in(ex_op1),
        .op2_in(ex_op2),
        .rd_addr_in(ex_rd),
        .reg_enable_in(ex_re),
        .imm_in(ex_imm),
        .store_data_in(ex_sdata),
        .mem_we_in(ex_mwe),
        .mem_re_in(ex_mre),
        .func3_in(ex_func3),
        .opcode_in(ex_opcode),
        .op_out(ex_alu_res),
        .rd_addr_out(ex_rd_out),
        .reg_enable_out(ex_re_out),
        .store_data_out(ex_sdata_out),
        .mem_we_out(ex_mwe_out),
        .mem_re_out(ex_mre_out),
        .func3_out(ex_func3_out),
        .branch_taken(branch_taken),
        .branch_target_addr(branch_target)
    );

    ex_mem u_ex_mem(
        .clk(clk),
        .reset(reset),
        .alu_in(ex_alu_res),
        .store_data_in(ex_sdata_out),
        .reg_enable_in(ex_re_out),
        .mem_we_in(ex_mwe_out),
        .mem_re_in(ex_mre_out),
        .rd_addr_in(ex_rd_out),
        .func3_in(ex_func3_out),
        .alu_out(mem_alu),
        .store_data_out(mem_sdata),
        .reg_enable_out(mem_re),
        .mem_we_out(mem_mwe),
        .mem_re_out(mem_mre),
        .rd_addr_out(mem_rd),
        .func3_out(mem_func3)
    );

    mem u_mem(
        .mem_we_in(mem_mwe),
        .mem_re_in(mem_mre),
        .alu_in(mem_alu),
        .store_data_in(mem_sdata),
        .rd_addr_in(mem_rd),
        .reg_enable_in(mem_re),
        .func3(mem_func3),
        .ram_rdata(ram_rdata),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata),
        .ram_we(ram_we),
        .final_data_out(mem_final_data),
        .rd_addr_out(mem_rd_final),
        .reg_enable_out(mem_re_final)
    );

    mem_wb u_mem_wb(
        .clk(clk),
        .reset(reset),
        .data_in(mem_final_data),
        .rd_addr_in(mem_rd_final),
        .reg_enable_in(mem_re_final),
        .data_out(wb_data),
        .rd_addr_out(wb_rd),
        .reg_enable_out(wb_re)
    );

endmodule
