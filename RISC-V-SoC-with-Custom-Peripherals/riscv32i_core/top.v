`timescale 1ns / 1ps
/*
`include "pc_reg.v"
`include "i_f.v"
`include "if_id.v"
`include "id.v"
`include "reg_file.v"
`include "id_ex.v"
`include "ex.v"
`include "ctrl.v"    
`include "ex_mem.v"  
`include "mem.v"     
`include "mem_wb.v"    

*/

module top(
    input wire clk,
    input wire reset,
    input wire [31:0] instr_in,      // ROM Instr
    input wire [31:0] ram_rdata,     // [新增] Data RAM Read Data
    
    output wire [31:0] instr_addr_out, // PC to ROM
    output wire [31:0] ram_addr,       // [新增] To Data RAM
    output wire [31:0] ram_wdata,
    output wire ram_we
);
    // === Control Signals ===
    wire stall_pc, stall_if_id, flush_if_id, flush_id_ex;
    wire branch_taken;
    wire [31:0] branch_target;

    // === Stage Interconnects ===
    // PC Stage
    wire [31:0] pc_now, pc_next;
    assign pc_next = branch_taken ? branch_target : (pc_now + 4); // [新增] Branch Mux

    // IF/ID
    wire [31:0] if_id_instr, if_id_pc;
    wire [31:0] if_out_instr; 
    wire [31:0] if_out_pc;

    // ID Stage
    wire [31:0] id_op1, id_op2, id_imm, id_sdata;
    wire [4:0] id_rs1, id_rs2, id_rd;
    wire [6:0] id_opcode; wire [2:0] id_func3;
    wire id_re, id_mwe, id_mre, id_branch;
    
    // ID/EX
    wire [31:0] ex_pc, ex_op1, ex_op2, ex_imm, ex_sdata;
    wire [4:0] ex_rd; wire [6:0] ex_opcode; wire [2:0] ex_func3;
    wire ex_re, ex_mwe, ex_mre;
    wire [31:0] ex_instr_wire;
    
    // EX Output
    wire [31:0] ex_alu_res, ex_sdata_out;
    wire [4:0] ex_rd_out; wire ex_re_out, ex_mwe_out, ex_mre_out;
    wire [2:0] ex_func3_out;

    // EX/MEM
    wire [31:0] mem_alu, mem_sdata;
    wire [4:0] mem_rd; wire [2:0] mem_func3;
    wire mem_re, mem_mwe, mem_mre;
    
    // MEM Output
    wire [31:0] mem_final_data;
    wire [4:0] mem_rd_final; wire mem_re_final;
    
    // MEM/WB
    wire [31:0] wb_data; wire [4:0] wb_rd; wire wb_re;

    // === Module Instantiation ===

    // 0. Control Unit [新增]
    ctrl u_ctrl(
        .rst(reset), 
        .branch_taken_in(branch_taken),
        .id_rs1_addr(id_rs1), .id_rs2_addr(id_rs2),
        .ex_rd_addr(ex_rd), .ex_mem_re(ex_mre),
        .stall_pc(stall_pc), .stall_if_id(stall_if_id),
        .flush_if_id(flush_if_id), .flush_id_ex(flush_id_ex)
    );

    // 1. PC
    pc_reg pc_reg_1(
        .clk(clk), .reset(reset), 
        .stall(stall_pc),   // [新增] 連接 stall
        .next_pc_in(pc_next), // [新增] 連接 next_pc
        .pc_out(pc_now)
    );

    // 2. IF (Pass through)
    i_f i_f_1(
        .pc_in(pc_now),
        .instr_rom_if(instr_in),
        .addr_if_rom(instr_addr_out),
        .instr_out(if_out_instr),
        .instr_addr(if_out_pc)
    );
    // 3. IF/ID
    if_id if_id_1(
        .clk(clk), .reset(reset),
        .stall(stall_if_id), .flush(flush_if_id), 
        .if_addr_in(if_out_pc),     
        .if_instr_in(if_out_instr),
        
        // 輸出保持不變
        .if_id_addr_out(if_id_pc), 
        .if_id_instr_out(if_id_instr)
    );

    // 4. ID
    // RegFile 讀取 (WB 階段寫回)
    wire [31:0] rs1_data_read, rs2_data_read;
    reg_file reg_file_1(
        .clk(clk), .reset(reset),
        .ex_reg_enable_in(wb_re),    // [修改] 接 WB 階段
        .rd_addr_in(wb_rd),          // [修改] 接 WB 階段
        .rd_data_in(wb_data),        // [修改] 接 WB 階段
        .rs1_addr_in(if_id_instr[19:15]), .rs2_addr_in(if_id_instr[24:20]),
        .rs1_data_out(rs1_data_read), .rs2_data_out(rs2_data_read)
    );

    id id_1(
        .if_id_addr_in(if_id_pc), .if_id_instr_in(if_id_instr),
        .rs1_data_in(rs1_data_read), .rs2_data_in(rs2_data_read),
        .rs1_addr_out(id_rs1), .rs2_addr_out(id_rs2),
        // Outputs
        .id_op1_data_out(id_op1), .id_op2_data_out(id_op2),
        .id_rd_addr_out(id_rd), .reg_enable(id_re),
        // [新增] 連接擴充訊號
        .id_imm_out(id_imm), .id_store_data_out(id_sdata),
        .mem_we(id_mwe), .mem_re(id_mre), .branch_flag(id_branch),
        .func3_out(id_func3), .opcode_out(id_opcode)
    );

    // 5. ID/EX
    id_ex id_ex_1(
        .clk(clk), .reset(reset), .flush(flush_id_ex), // [新增] flush
        .id_instr_in(if_id_instr), 
        .id_addr_in(if_id_pc),
        .op1_in(id_op1), .op2_in(id_op2), .rd_addr_in(id_rd), .reg_enable_in(id_re),
        // [新增] 擴充輸入
        .imm_in(id_imm), .store_data_in(id_sdata),
        .mem_we_in(id_mwe), .mem_re_in(id_mre),
        .func3_in(id_func3), .opcode_in(id_opcode),
        
        // Outputs
        .id_ex_instr_out(ex_instr_wire),
        .op1_out(ex_op1), .op2_out(ex_op2), .rd_addr_out(ex_rd), .reg_enable_out(ex_re),
        .imm_out(ex_imm), .store_data_out(ex_sdata),
        .mem_we_out(ex_mwe), .mem_re_out(ex_mre),
        .func3_out(ex_func3), .opcode_out(ex_opcode), .id_ex_addr_out(ex_pc)
    );

    // 6. EX
    ex ex_1(
        .id_ex_instr_in(ex_instr_wire), 
        .id_ex_addr_in(ex_pc),
        .op1_in(ex_op1), .op2_in(ex_op2), .rd_addr_in(ex_rd), .reg_enable_in(ex_re),
        // [新增] 擴充輸入
        .imm_in(ex_imm), .store_data_in(ex_sdata),
        .mem_we_in(ex_mwe), .mem_re_in(ex_mre),
        .func3_in(ex_func3), .opcode_in(ex_opcode),
        
        // Outputs
        .op_out(ex_alu_res), .rd_addr_out(ex_rd_out), .reg_enable_out(ex_re_out),
        .store_data_out(ex_sdata_out), .mem_we_out(ex_mwe_out), .mem_re_out(ex_mre_out),
        .func3_out(ex_func3_out),
        .branch_taken(branch_taken), .branch_target_addr(branch_target) // [新增]
    );

    // 7. EX/MEM [新增]
    ex_mem u_ex_mem(
        .clk(clk), .reset(reset),
        .alu_in(ex_alu_res), .store_data_in(ex_sdata_out),
        .reg_enable_in(ex_re_out), .mem_we_in(ex_mwe_out), .mem_re_in(ex_mre_out),
        .rd_addr_in(ex_rd_out), .func3_in(ex_func3_out),
        // Outputs
        .alu_out(mem_alu), .store_data_out(mem_sdata),
        .reg_enable_out(mem_re), .mem_we_out(mem_mwe), .mem_re_out(mem_mre),
        .rd_addr_out(mem_rd), .func3_out(mem_func3)
    );

    // 8. MEM [新增]
    mem u_mem(
        .mem_we_in(mem_mwe), .mem_re_in(mem_mre),
        .alu_in(mem_alu), .store_data_in(mem_sdata),
        .rd_addr_in(mem_rd), .reg_enable_in(mem_re), .func3(mem_func3),
        // Data RAM Interface
        .ram_rdata(ram_rdata),
        .ram_addr(ram_addr), .ram_wdata(ram_wdata), .ram_we(ram_we),
        // WB Output
        .final_data_out(mem_final_data), .rd_addr_out(mem_rd_final), .reg_enable_out(mem_re_final)
    );
    
    // 9. MEM/WB [新增]
    mem_wb u_mem_wb(
        .clk(clk), .reset(reset),
        .data_in(mem_final_data), .rd_addr_in(mem_rd_final), .reg_enable_in(mem_re_final),
        .data_out(wb_data), .rd_addr_out(wb_rd), .reg_enable_out(wb_re)
    );

endmodule