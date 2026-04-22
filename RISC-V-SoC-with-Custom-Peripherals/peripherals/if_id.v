`include "define.v"
`include "pipeline_reg.v"
// IF/ID pipeline register
module if_id(
    input wire clk,
    input wire reset,
    input wire [31:0] if_addr_in,
    input wire [31:0] if_instr_in,

    output wire [31:0] if_id_addr_out,
    output wire [31:0] if_id_instr_out
);
    // for if_instr
    pipeline_reg #(32) pip_reg1(
        .clk(clk),
        .reset(reset),
        .data_in(if_instr_in),
        .reset_data(`INST_NOP),
        .data_out(if_id_instr_out)
    );
    // for if_addr
    pipeline_reg #(32) pip_reg2(
        .clk(clk),
        .reset(reset),
        .data_in(if_addr_in),
        .reset_data(32'b0),
        .data_out(if_id_addr_out)
    );
endmodule


/* 
如果不呼叫pipeline_reg 直接寫也可以

always@(posedge clk)begin
        if(reset)begin
            if_id_instr_out <= INST_NOP;
            if_id_addr_out <= 32'b0;
        end else begin
            if_id_instr_out <= if_instr_in;
            if_id_addr_out <= if_addr_in;
        end
    end
*/