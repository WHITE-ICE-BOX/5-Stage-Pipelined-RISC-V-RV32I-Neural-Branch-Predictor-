module reg_file(
    //WB才用到
    input wire clk, 
    input wire reset,
    input wire ex_reg_enable_in,
    input wire [4:0] rd_addr_in,
    input wire [31:0] rd_data_in,
    //id
    input [4:0] rs1_addr_in,
    input [4:0] rs2_addr_in,
    output reg [31:0] rs1_data_out,
    output reg [31:0] rs2_data_out
);
    reg [31:0] regs[0:31]; // 32個32bits的暫存器
    integer i;

    always@(*)begin
        if(reset)
            rs1_data_out = 32'b0;
        else if(rs1_addr_in == 5'b0)
            rs1_data_out = 32'b0;
        else if(rs1_addr_in == rd_addr_in) // data hazard use forwarding to solve
            rs1_data_out = rd_data_in;
        else
            rs1_data_out = regs[rs1_addr_in];
    end
    always@(*)begin
        if(reset)
            rs2_data_out = 32'b0;
        else if(rs2_addr_in == 5'b0)
            rs2_data_out = 32'b0;
        else if(rs2_addr_in == rd_addr_in)// data hazard use forwarding to solve
            rs2_data_out = rd_data_in;
        else
            rs2_data_out = regs[rs2_addr_in];
    end
    always@(posedge clk)begin
        if(reset)begin
            for(i=0 ; i<32 ; i=i+1)begin
                regs[i] <= 32'b0;
            end
        end
        else if(ex_reg_enable_in && rd_addr_in != 5'b0)begin
            regs[rd_addr_in] <= rd_data_in;
        end
    end
endmodule