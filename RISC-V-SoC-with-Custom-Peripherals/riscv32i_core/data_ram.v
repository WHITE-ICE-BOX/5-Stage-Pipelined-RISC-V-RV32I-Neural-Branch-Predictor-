`timescale 1ns / 1ps
module data_ram(
    input wire clk,
    input wire we,
    input wire [31:0] addr,
    input wire [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] ram [0:1023]; // 1K word

    always @(posedge clk) begin
    if (we) begin
        ram[addr[31:2]] <= data_in; // 寫入保持不變
    end
        data_out <= ram[addr[31:2]];    // 讀取改成同步
    end
endmodule