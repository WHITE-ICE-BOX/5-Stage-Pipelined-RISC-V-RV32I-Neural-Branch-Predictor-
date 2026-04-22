`include "define.v"
module id(
    //if_id
    input wire [31:0] if_id_addr_in,
    input wire [31:0] if_id_instr_in,

    //reg_file
    input wire [31:0] rs1_data_in,
    input wire [31:0] rs2_data_in,
    output reg [4:0] rs1_addr_out,
    output reg [4:0] rs2_addr_out,

    //ex
    output reg [31:0] id_instr_out,
    output reg [31:0] id_addr_out,
    output reg [31:0] id_op1_data_out,
    output reg [31:0] id_op2_data_out,
    output reg [4:0] id_rd_addr_out,
    output reg reg_enable
);
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  func3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [6:0]  func7;
    wire [11:0] imm;

    assign opcode = if_id_instr_in[6:0];
    assign rd     = if_id_instr_in[11:7];
    assign func3  = if_id_instr_in[14:12];
    assign rs1    = if_id_instr_in[19:15];
    assign rs2    = if_id_instr_in[24:20];
    assign func7  = if_id_instr_in[31:25];
    assign imm    = if_id_instr_in[31:20];

    always@(*)begin
        id_instr_out = if_id_instr_in;
        id_addr_out  = if_id_addr_in;
        case(opcode)
            `INST_TYPE_I:begin
                case(func3)
                    `INST_ADDI:begin
                        id_op1_data_out = rs1_data_in;
                        id_op2_data_out = {{20{imm[11]}},imm[11:0]}; //擴展符號位到32bits
                        reg_enable      = 1'b1;
                        id_rd_addr_out  = rd;
                        rs1_addr_out    = rs1;
                        rs2_addr_out    = 5'b0; //不需要
                    end
                    default:begin
                        id_op1_data_out = 32'b0;
                        id_op2_data_out = 32'b0;
                        reg_enable      = 1'b0;
                        id_rd_addr_out  = 5'b0;
                        rs1_addr_out    = 5'b0;
                        rs2_addr_out    = 5'b0; 
                    end
                endcase
            end
            `INST_TYPE_R_M:begin
                case(func3)
                    `INST_ADD_SUB:begin
                        id_op1_data_out = rs1_data_in;
                        id_op2_data_out = rs2_data_in;
                        reg_enable      = 1'b1;
                        id_rd_addr_out  = rd;
                        rs1_addr_out    = rs1;
                        rs2_addr_out    = rs2;
                    end
                    default:begin
                        id_op1_data_out = 32'b0;
                        id_op2_data_out = 32'b0;
                        reg_enable      = 1'b0;
                        id_rd_addr_out  = 5'b0;
                        rs1_addr_out    = 5'b0;
                        rs2_addr_out    = 5'b0; 
                    end
                endcase
            end 
            default:begin
                id_op1_data_out = 32'b0;
                id_op2_data_out = 32'b0;
                reg_enable      = 1'b0;
                id_rd_addr_out  = 5'b0;
                rs1_addr_out    = 5'b0;
                rs2_addr_out    = 5'b0; 
            end
        endcase
    end


endmodule