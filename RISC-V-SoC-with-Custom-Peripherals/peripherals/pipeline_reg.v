// 預設32bits,但倘若呼叫變成 pipeline_reg #(1) pip_reg1 (....) WIDTH就會變成1bits
module pipeline_reg
#(parameter WIDTH = 32)
(
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0]data_in,
    input wire [WIDTH-1:0]reset_data,
    
    output reg [WIDTH-1:0]data_out
);
    always@(posedge clk)begin
        if(reset)begin
            data_out <= reset_data;
        end else begin
            data_out <= data_in;
        end
    end
endmodule