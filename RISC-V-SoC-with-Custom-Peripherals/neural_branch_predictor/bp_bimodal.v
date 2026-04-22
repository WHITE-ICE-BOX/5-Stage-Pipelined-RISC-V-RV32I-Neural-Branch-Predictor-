`timescale 1ns / 1ps

module bp_bimodal #(
    parameter INDEX_BITS = 4
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire [INDEX_BITS-1:0]  rindex,
    output wire [1:0]             rctr,

    input  wire                   we,
    input  wire [INDEX_BITS-1:0]  windex,
    input  wire                   actual_taken
);

    localparam ENTRIES = (1 << INDEX_BITS);

    reg [1:0] ctr_table [0:ENTRIES-1];
    integer i;

    assign rctr = ctr_table[rindex];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ENTRIES; i = i + 1)
                ctr_table[i] <= 2'b01; // weak not-taken
        end
        else if (we) begin
            if (actual_taken) begin
                if (ctr_table[windex] != 2'b11)
                    ctr_table[windex] <= ctr_table[windex] + 2'b01;
            end
            else begin
                if (ctr_table[windex] != 2'b00)
                    ctr_table[windex] <= ctr_table[windex] - 2'b01;
            end
        end
    end

endmodule
