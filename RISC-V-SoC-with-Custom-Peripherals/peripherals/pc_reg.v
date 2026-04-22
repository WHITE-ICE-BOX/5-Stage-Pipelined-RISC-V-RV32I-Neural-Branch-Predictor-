//program counter
module pc_reg(
    input wire clk,
    input wire reset,
    output reg [31:0]pc_out
);
    always@(posedge clk)begin
        if(reset)begin
            pc_out <= 32'b0;
        end else begin
            pc_out <= pc_out + 32'd4;
        end
    end
endmodule