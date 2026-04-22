//rom memory 簡化版一次讀32bits
module rom(
    input wire [31:0] addr_if_in,
    output reg [31:0] instr_rom_out
);
    reg [31:0] rom_mem [0:4095]; // 4096個32bits空間

    always@(*)begin
        instr_rom_out = rom_mem[addr_if_in >> 2]; //pc=pc+4,要除 4 因為一次讀32bits
    end


endmodule