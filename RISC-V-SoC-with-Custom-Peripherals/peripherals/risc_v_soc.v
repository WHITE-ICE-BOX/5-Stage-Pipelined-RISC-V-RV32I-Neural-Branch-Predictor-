`timescale 1ns / 1ps
`include "top.v"
`include "rom.v"
module risc_v_soc(
    input wire clk,
    input wire reset
);
    wire [31:0] instr;
    wire [31:0] addr;

    top top_1(
        .clk(clk),
        .reset(reset),
        .instr_in(instr),
        .addr_out(addr)
    );
    rom rom_1(
        .addr_if_in(addr),
        .instr_rom_out(instr)
    );
endmodule