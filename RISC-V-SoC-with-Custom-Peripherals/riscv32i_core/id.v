`timescale 1ns / 1ps
`include "define.v"

module id(
    // if_id
    input wire [31:0] if_id_addr_in,
    input wire [31:0] if_id_instr_in,

    // reg_file
    input wire [31:0] rs1_data_in,
    input wire [31:0] rs2_data_in,
    output reg [4:0] rs1_addr_out,
    output reg [4:0] rs2_addr_out,

    // ex
    output reg [31:0] id_instr_out,
    output reg [31:0] id_addr_out,
    output reg [31:0] id_op1_data_out,
    output reg [31:0] id_op2_data_out,
    output reg [31:0] id_imm_out,
    output reg [31:0] id_store_data_out,
    output reg [4:0]  id_rd_addr_out,

    // control signals
    output reg        reg_enable,
    output reg        mem_we,
    output reg        mem_re,
    output reg        branch_flag,
    output reg [2:0]  func3_out,
    output reg [6:0]  opcode_out
);

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] func3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] func7;

    wire [11:0] imm_i;
    wire [11:0] imm_s;

    wire [31:0] imm_i_ext;
    wire [31:0] imm_s_ext;
    wire [31:0] imm_b_ext;
    wire [31:0] imm_j_ext;

    assign opcode = if_id_instr_in[6:0];
    assign rd     = if_id_instr_in[11:7];
    assign func3  = if_id_instr_in[14:12];
    assign rs1    = if_id_instr_in[19:15];
    assign rs2    = if_id_instr_in[24:20];
    assign func7  = if_id_instr_in[31:25];

    assign imm_i = if_id_instr_in[31:20];
    assign imm_s = {if_id_instr_in[31:25], if_id_instr_in[11:7]};

    assign imm_i_ext = {{20{imm_i[11]}}, imm_i};
    assign imm_s_ext = {{20{imm_s[11]}}, imm_s};

    assign imm_b_ext = {{19{if_id_instr_in[31]}},
                        if_id_instr_in[31],
                        if_id_instr_in[7],
                        if_id_instr_in[30:25],
                        if_id_instr_in[11:8],
                        1'b0};

    assign imm_j_ext = {{11{if_id_instr_in[31]}},
                        if_id_instr_in[31],
                        if_id_instr_in[19:12],
                        if_id_instr_in[20],
                        if_id_instr_in[30:21],
                        1'b0};

    always @(*) begin
        // default
        id_instr_out      = if_id_instr_in;
        id_addr_out       = if_id_addr_in;

        opcode_out        = opcode;
        func3_out         = func3;

        id_op1_data_out   = 32'b0;
        id_op2_data_out   = 32'b0;
        id_imm_out        = 32'b0;
        id_store_data_out = 32'b0;
        id_rd_addr_out    = 5'b0;

        rs1_addr_out      = 5'b0;
        rs2_addr_out      = 5'b0;

        reg_enable        = 1'b0;
        mem_we            = 1'b0;
        mem_re            = 1'b0;
        branch_flag       = 1'b0;

        case (opcode)

            // I-type arithmetic
            `INST_TYPE_I: begin
                case (func3)
                    `INST_ADDI,
                    `INST_SLTI,
                    `INST_ORI,
                    `INST_ANDI,
                    `INST_XORI,
                    `INST_SLLI: begin
                        id_op1_data_out = rs1_data_in;
                        id_op2_data_out = imm_i_ext;
                        id_imm_out      = imm_i_ext;
                        id_rd_addr_out  = rd;
                        rs1_addr_out    = rs1;
                        rs2_addr_out    = 5'b0;
                        reg_enable      = 1'b1;
                    end
                    default: begin
                    end
                endcase
            end

            // R-type
            `INST_TYPE_R_M: begin
                case (func3)
                    `INST_ADD_SUB,
                    `INST_OR,
                    `INST_AND,
                    `INST_XOR,
                    `INST_SLT: begin
                        id_op1_data_out = rs1_data_in;
                        id_op2_data_out = rs2_data_in;
                        id_rd_addr_out  = rd;
                        rs1_addr_out    = rs1;
                        rs2_addr_out    = rs2;
                        reg_enable      = 1'b1;
                    end
                    default: begin
                    end
                endcase
            end

            // Load
            `INST_TYPE_L: begin
                id_op1_data_out = rs1_data_in;
                id_op2_data_out = imm_i_ext;
                id_imm_out      = imm_i_ext;
                id_rd_addr_out  = rd;
                rs1_addr_out    = rs1;
                rs2_addr_out    = 5'b0;
                reg_enable      = 1'b1;
                mem_re          = 1'b1;
                mem_we          = 1'b0;
            end

            // Store
            `INST_TYPE_S: begin
                id_op1_data_out   = rs1_data_in;
                id_op2_data_out   = imm_s_ext;
                id_imm_out        = imm_s_ext;
                id_store_data_out = rs2_data_in;
                id_rd_addr_out    = 5'b0;
                rs1_addr_out      = rs1;
                rs2_addr_out      = rs2;
                reg_enable        = 1'b0;
                mem_re            = 1'b0;
                mem_we            = 1'b1;
            end

            // Branch
            `INST_TYPE_B: begin
                id_op1_data_out = rs1_data_in;
                id_op2_data_out = rs2_data_in;
                id_imm_out      = imm_b_ext;
                id_rd_addr_out  = 5'b0;
                rs1_addr_out    = rs1;
                rs2_addr_out    = rs2;
                reg_enable      = 1'b0;
                mem_re          = 1'b0;
                mem_we          = 1'b0;
                branch_flag     = 1'b1;
            end

            // JAL
            `INST_TYPE_J: begin
                id_imm_out      = imm_j_ext;
                id_rd_addr_out  = rd;
                rs1_addr_out    = 5'b0;
                rs2_addr_out    = 5'b0;
                reg_enable      = 1'b1;   // rd <- pc + 4
                mem_re          = 1'b0;
                mem_we          = 1'b0;
                branch_flag     = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule