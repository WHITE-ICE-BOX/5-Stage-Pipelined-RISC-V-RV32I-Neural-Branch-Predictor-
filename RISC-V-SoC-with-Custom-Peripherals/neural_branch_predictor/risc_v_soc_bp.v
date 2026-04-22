`timescale 1ns / 1ps

module risc_v_soc_bp(
    input wire clk,
    input wire reset,
    output wire [3:0] led_out // [修改] 將 32-bit 縮減為 4-bit
);
    wire [31:0] instr;
    wire [31:0] instr_addr;

    wire [31:0] ram_addr;
    wire [31:0] ram_wdata;
    wire        ram_we;
    wire [31:0] ram_rdata;

    // [修改] 只把 PC 的 [5:2] 接到 LED，方便肉眼觀察執行進度
    assign led_out = instr_addr[5:2];

    top_bp top_1(
        .clk(clk),
        .reset(reset),
        .instr_in(instr),
        .ram_rdata(ram_rdata),
        .instr_addr_out(instr_addr),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata),
        .ram_we(ram_we)
    );

    rom rom_1(
        .addr_if_in(instr_addr),
        .instr_rom_out(instr)
    );

    data_ram dram_1(
        .clk(clk),
        .we(ram_we),
        .addr(ram_addr),
        .data_in(ram_wdata),
        .data_out(ram_rdata)
    );

endmodule