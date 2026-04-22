`timescale 1ns / 1ps
`include "define.v"

module ex(
    // id_ex
    input wire [31:0] id_ex_instr_in,
    input wire [31:0] id_ex_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,
    input wire [4:0]  rd_addr_in,
    input wire        reg_enable_in,

    input wire [31:0] imm_in,
    input wire [31:0] store_data_in,
    input wire        mem_we_in,
    input wire        mem_re_in,
    input wire [2:0]  func3_in,
    input wire [6:0]  opcode_in,

    // result or wb
    output reg [31:0] op_out,
    output reg [4:0]  rd_addr_out,
    output reg        reg_enable_out,

    output reg [31:0] store_data_out,
    output reg        mem_we_out,
    output reg        mem_re_out,
    output reg [2:0]  func3_out,

    output reg        branch_taken,
    output reg [31:0] branch_target_addr
);

    always @(*) begin
        // default pass-through
        op_out             = 32'b0;
        rd_addr_out        = rd_addr_in;
        reg_enable_out     = reg_enable_in;
        store_data_out     = store_data_in;
        mem_we_out         = mem_we_in;
        mem_re_out         = mem_re_in;
        func3_out          = func3_in;
        branch_taken       = 1'b0;
        branch_target_addr = 32'b0;

        case (opcode_in)
            `INST_TYPE_I: begin
                case (func3_in)
                    `INST_ADDI: op_out = op1_in + op2_in;
                    `INST_SLTI: op_out = ($signed(op1_in) < $signed(op2_in)) ? 32'd1 : 32'd0;
                    `INST_ORI:  op_out = op1_in | op2_in;
                    `INST_ANDI: op_out = op1_in & op2_in;
                    `INST_XORI: op_out = op1_in ^ op2_in;
                    `INST_SLLI: op_out = op1_in << op2_in[4:0];
                    default:    op_out = 32'b0;
                endcase
            end

            `INST_TYPE_R_M: begin
                case (func3_in)
                    `INST_ADD_SUB: begin
                        if (id_ex_instr_in[30])
                            op_out = op1_in - op2_in; // SUB
                        else
                            op_out = op1_in + op2_in; // ADD
                    end
                    `INST_SLT: op_out = ($signed(op1_in) < $signed(op2_in)) ? 32'd1 : 32'd0;
                    `INST_OR:  op_out = op1_in | op2_in;
                    `INST_AND: op_out = op1_in & op2_in;
                    `INST_XOR: op_out = op1_in ^ op2_in;
                    default:   op_out = 32'b0;
                endcase
            end

            `INST_TYPE_L: begin
                op_out = op1_in + op2_in; // address = rs1 + imm
            end

            `INST_TYPE_S: begin
                op_out = op1_in + op2_in; // address = rs1 + imm
            end

            `INST_TYPE_B: begin
                branch_target_addr = id_ex_addr_in + imm_in;
                case (func3_in)
                    `INST_BEQ: branch_taken = (op1_in == op2_in);
                    `INST_BNE: branch_taken = (op1_in != op2_in);
                    default:   branch_taken = 1'b0;
                endcase
            end

            `INST_TYPE_J: begin
                // JAL: rd = pc + 4, pc = pc + imm
                op_out             = id_ex_addr_in + 32'd4;
                branch_taken       = 1'b1;
                branch_target_addr = id_ex_addr_in + imm_in;
            end

            default: begin
                op_out = 32'b0;
            end
        endcase
    end

endmodule