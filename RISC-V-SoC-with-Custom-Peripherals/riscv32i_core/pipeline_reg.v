// 預設32bits,但倘若呼叫變成 pipeline_reg #(1) pip_reg1 (....) WIDTH就會變成1bits
`timescale 1ns / 1ps
module pipeline_reg
#(parameter WIDTH = 32)
(
    input wire clk,
    input wire reset,
    input wire stall, // 新增: 暫停 (保持舊值)
    input wire flush, // 新增: 沖刷 (清空為 reset_data)
    input wire [WIDTH-1:0]data_in,
    input wire [WIDTH-1:0]reset_data,
    
    output reg [WIDTH-1:0]data_out
);
    always@(posedge clk)begin
        if(reset || flush)begin
            data_out <= reset_data;
        end
        else if(stall)begin
            data_out <= data_out; // 保持不變
        end else begin
            data_out <= data_in;
        end
    end
endmodule