`timescale 1ns / 1ps

module ctrl_bp(
    input  wire       rst,

    // predict redirect in ID
    input  wire       pred_take_id,

    // actual redirect in EX
    input  wire       ex_redirect_valid,

    // load-use hazard
    input  wire [4:0] id_rs1_addr,
    input  wire [4:0] id_rs2_addr,
    input  wire [4:0] ex_rd_addr,
    input  wire       ex_mem_re,

    output reg        stall_pc,
    output reg        stall_if_id,
    output reg        flush_if_id,
    output reg        flush_id_ex
);

    always @(*) begin
        stall_pc    = 1'b0;
        stall_if_id = 1'b0;
        flush_if_id = 1'b0;
        flush_id_ex = 1'b0;

        if (rst) begin
            stall_pc    = 1'b0;
            stall_if_id = 1'b0;
            flush_if_id = 1'b0;
            flush_id_ex = 1'b0;
        end
        else if (ex_redirect_valid) begin
            flush_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end
        else if (ex_mem_re &&
                 (ex_rd_addr != 5'b0) &&
                 ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr))) begin
            stall_pc    = 1'b1;
            stall_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end
        else if (pred_take_id) begin
            flush_if_id = 1'b1;
        end
    end

endmodule
