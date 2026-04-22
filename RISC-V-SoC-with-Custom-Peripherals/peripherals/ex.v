`include "define.v"
module ex(
    //id_ex
    input wire [31:0] id_ex_instr_in,
    input wire [31:0] id_ex_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,
    input wire [4:0]  rd_addr_in,
    input wire reg_enable_in,

    //result or wb
    output reg [31:0] op_out,
    output reg [4:0]  rd_addr_out,
    output reg reg_enable_out
);
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  func3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [6:0]  func7;
    wire [11:0] imm;

    assign opcode = id_ex_instr_in[6:0];
    assign rd     = id_ex_instr_in[11:7];
    assign func3  = id_ex_instr_in[14:12];
    assign rs1    = id_ex_instr_in[19:15];
    assign rs2    = id_ex_instr_in[24:20];
    assign func7  = id_ex_instr_in[31:25];
    assign imm    = id_ex_instr_in[31:20];

    always@(*)begin
        reg_enable_out = reg_enable_in;
        case(opcode)
            `INST_TYPE_I:begin
                case(func3)
                    `INST_ADDI:begin
                        op_out = op1_in + op2_in;
                        rd_addr_out = rd_addr_in;
                    end
                    default:begin
                        op_out = 32'b0;
                        rd_addr_out = 5'b0;
                    end
                endcase
            end
            `INST_TYPE_R_M:begin
                case(func3)
                    `INST_ADD_SUB:begin
                        rd_addr_out = rd_addr_in;
                        if(func7 == 7'b0100000)      // SUB
                            op_out = op2_in - op1_in;// 注意順序
                        else                         // ADD
                            op_out = op1_in + op2_in;
                    end
                    default:begin
                        op_out = 32'b0;
                        rd_addr_out = 5'b0;
                    end
                endcase
            end 
            default:begin
                op_out = 32'b0;
                rd_addr_out = 5'b0; 
            end
        endcase
    end

endmodule