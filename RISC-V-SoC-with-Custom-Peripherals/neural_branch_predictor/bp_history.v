`timescale 1ns / 1ps

module bp_history #(
    parameter HIST_LEN = 8
)(
    input  wire                clk,
    input  wire                rst_n,
    output wire [HIST_LEN-1:0] ghr,

    input  wire                upd_valid,
    input  wire                actual_taken
);

    reg [HIST_LEN-1:0] ghr_r;

    assign ghr = ghr_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ghr_r <= {HIST_LEN{1'b0}};
        else if (upd_valid)
            ghr_r <= {ghr_r[HIST_LEN-2:0], actual_taken};
    end

endmodule
