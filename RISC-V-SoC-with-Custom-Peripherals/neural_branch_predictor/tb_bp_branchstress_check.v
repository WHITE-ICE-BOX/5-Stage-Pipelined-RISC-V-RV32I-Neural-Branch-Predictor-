`timescale 1ns/1ps

module tb_bp_branchstress_check;

    reg clk;
    reg reset;

    wire        wb_re;
    wire [4:0]  wb_rd;
    wire [31:0] wb_data;

    reg [31:0] x3_final;
    reg [31:0] x4_final;
    reg [31:0] x30_final;

    assign wb_re   = tb_bp_branchstress_check.u_bp.top_1.wb_re;
    assign wb_rd   = tb_bp_branchstress_check.u_bp.top_1.wb_rd;
    assign wb_data = tb_bp_branchstress_check.u_bp.top_1.wb_data;

    always #4 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        x3_final = 32'd0;
        x4_final = 32'd0;
        x30_final = 32'd0;

        $display("\n===============================================================");
        $display(" Innovation CPU Branch-Stress Functional Check");
        $display("===============================================================");

        #10;
        reset = 0;
    end

    initial begin
        $readmemb("/home/barkie1/riscv32i/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/instr_data_branchstress.txt",
          u_bp.rom_1.rom_mem);
    end

    risc_v_soc_bp u_bp(
        .clk(clk),
        .reset(reset)
    );

    always @(posedge clk) begin
        if (!reset && wb_re) begin
            case (wb_rd)
                5'd3:  x3_final  <= wb_data;
                5'd4:  x4_final  <= wb_data;
                5'd30: x30_final <= wb_data;
                default: begin end
            endcase
        end
    end

    initial begin
        #4000;
        $display("---------------------------------------------------------------");
        $display("x3  final = %0d (expected 10)", x3_final);
        $display("x4  final = %0d (expected 20)", x4_final);
        $display("x30 final = %0d (expected 30)", x30_final);

        if ((x3_final == 32'd10) && (x4_final == 32'd20) && (x30_final == 32'd30))
            $display("STATUS: PASS");
        else
            $display("STATUS: FAIL");
        $display("---------------------------------------------------------------");
        $finish;
    end

endmodule