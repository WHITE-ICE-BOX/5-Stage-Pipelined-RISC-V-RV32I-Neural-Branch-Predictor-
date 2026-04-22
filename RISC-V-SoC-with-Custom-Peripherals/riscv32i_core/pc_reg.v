//program counter
`timescale 1ns / 1ps
module pc_reg(
    input wire clk,
    input wire reset,
    input wire stall,       // 新增: 來自 ctrl
    input wire [31:0] next_pc_in, // 新增: 來自 top (可能是 pc+4 或 jump target)
    output reg [31:0]pc_out
);
    always@(posedge clk)begin
        if(reset)begin
            pc_out <= 32'b0;
        end else if(stall)begin
            pc_out <= pc_out; // 保持不變
        end else begin
            pc_out <= next_pc_in;
        end
    end
endmodule