`timescale 1ns / 1ps

module bp_confidence(
    input  wire [1:0] ctr_in,
    output wire       conf_high
);

    assign conf_high = (ctr_in == 2'b00) || (ctr_in == 2'b11);

endmodule
