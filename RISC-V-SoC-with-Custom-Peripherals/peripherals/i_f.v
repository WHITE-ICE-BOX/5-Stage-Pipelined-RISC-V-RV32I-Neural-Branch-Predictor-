//instruction fetch
module i_f(
    input wire [31:0]pc_in,
    input wire [31:0]instr_rom_if,

    output wire [31:0]addr_if_rom,
    output wire [31:0]instr_out,
    output wire [31:0]instr_addr_out
);
    assign addr_if_rom = pc_in;

    assign instr_addr_out = pc_in;

    assign ainstr_out = instr_rom_if;
    
endmodule