// ================================
// RISC-V instruction defines
// RV32I + M extension
// ================================

// ---------- I-type ----------
`define INST_TYPE_I   7'b0010011   // I-type base opcode
`define INST_ADDI     3'b000
`define INST_SLTI     3'b010
`define INST_SLTIU    3'b011
`define INST_XORI     3'b100
`define INST_ORI      3'b110
`define INST_ANDI     3'b111
`define INST_SLLI     3'b001
`define INST_SRI      3'b101      // SRL/SRA 根據 func7 區分

// ---------- L-type (Load) ----------
`define INST_TYPE_L   7'b0000011
`define INST_LB       3'b000
`define INST_LH       3'b001
`define INST_LW       3'b010
`define INST_LBU      3'b100
`define INST_LHU      3'b101

// ---------- S-type (Store) ----------
`define INST_TYPE_S   7'b0100011
`define INST_SB       3'b000
`define INST_SH       3'b001
`define INST_SW       3'b010

// ---------- R-type ----------
`define INST_TYPE_R_M 7'b0110011
// R 基本算術
`define INST_ADD_SUB  3'b000   // func7 區分 ADD/SUB
`define INST_SLL      3'b001
`define INST_SLT      3'b010
`define INST_SLTU     3'b011
`define INST_XOR      3'b100
`define INST_SR       3'b101   // func7 區分 SRL/SRA
`define INST_OR       3'b110
`define INST_AND      3'b111
// R-M (乘法/除法)
`define INST_MUL      3'b000
`define INST_MULH     3'b001
`define INST_MULHSU   3'b010
`define INST_MULHU    3'b011
`define INST_DIV      3'b100
`define INST_DIVU     3'b101
`define INST_REM      3'b110
`define INST_REMU     3'b111

// ---------- B-type (Branch) ----------
`define INST_TYPE_B   7'b1100011
`define INST_BEQ      3'b000
`define INST_BNE      3'b001
`define INST_BLT      3'b100
`define INST_BGE      3'b101
`define INST_BLTU     3'b110
`define INST_BGEU     3'b111

// ---------- J-type ----------
`define INST_TYPE_J   7'b1101111   // JAL
`define INST_TYPE_JR  7'b1100111   // JALR (I-type 格式)

// ---------- U-type ----------
`define INST_TYPE_U_LUI   7'b0110111   // LUI
`define INST_TYPE_U_AUIPC 7'b0010111   // AUIPC

// ---------- 系統指令 ----------
`define INST_TYPE_SYS     7'b1110011
`define INST_ECALL        32'h00000073
`define INST_EBREAK       32'h00100073

// ---------- NOP (特殊定義) ----------
`define INST_NOP          32'h00000013   // ADDI x0, x0, 0
