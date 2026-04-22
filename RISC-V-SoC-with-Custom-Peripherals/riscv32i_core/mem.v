`timescale 1ns / 1ps
`include "define.v"
module mem(
    input wire mem_we_in, input wire mem_re_in,
    input wire [31:0] alu_in, input wire [31:0] store_data_in,
    input wire [4:0] rd_addr_in, input wire reg_enable_in, input wire [2:0] func3,
    // RAM Interface
    input wire [31:0] ram_rdata,
    output reg [31:0] ram_addr, output reg [31:0] ram_wdata, output reg ram_we,

    // Output to WB
    output reg [31:0] final_data_out,
    output reg [4:0] rd_addr_out, output reg reg_enable_out
);
    always @(*) begin
        // Output to RAM
        ram_addr = alu_in;
        ram_wdata = store_data_in;
        ram_we = mem_we_in;
        
        // Pass through
        rd_addr_out = rd_addr_in;
        reg_enable_out = reg_enable_in;

        // Select Data Source (ALU result or Memory Load)
        if(mem_re_in) begin
             case(func3)
                `INST_LW: final_data_out = ram_rdata;
                default:  final_data_out = ram_rdata;
             endcase
        end else begin
            final_data_out = alu_in;
        end
    end
endmodule