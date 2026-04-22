# Vivado batch synthesis for Ibex RISC-V core with static branch predictor (BranchPredictor=1)
# Target: xc7z020clg400-1 (PYNQ-Z2), 125 MHz clock
# Mode: non-project (in-memory), out-of-context (core only, no memory wrapper)
# Note: core-only synthesis — excludes instruction/data memory for direct BP-logic comparison

set IBEXDIR  {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\ibex\rtl}
set STUBDIR  {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\vivado_reports\ibex_synth}
set OUTDIR   {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\vivado_reports}
set PART     xc7z020clg400-1
set TOP      ibex_core

# prim_assert.sv and dv_fcov_macros.svh are synthesis stubs placed in STUBDIR.
# They are found via -include_dirs in synth_design (not via read_verilog).
set_param general.maxThreads 4

# Read all Ibex RTL sources (SystemVerilog)
# Note: ibex_icache.sv and ibex_dummy_instr.sv are excluded because
#   ICache=0 and DummyInstructions=0 (SecureIbex=0), so they are not elaborated.
# Using ibex_register_file_fpga for FPGA-optimized LUTRAM register file.
read_verilog -sv [list \
    ${IBEXDIR}/ibex_pkg.sv \
    ${IBEXDIR}/ibex_alu.sv \
    ${IBEXDIR}/ibex_branch_predict.sv \
    ${IBEXDIR}/ibex_compressed_decoder.sv \
    ${IBEXDIR}/ibex_controller.sv \
    ${IBEXDIR}/ibex_counter.sv \
    ${IBEXDIR}/ibex_cs_registers.sv \
    ${IBEXDIR}/ibex_csr.sv \
    ${IBEXDIR}/ibex_decoder.sv \
    ${IBEXDIR}/ibex_ex_block.sv \
    ${IBEXDIR}/ibex_id_stage.sv \
    ${IBEXDIR}/ibex_if_stage.sv \
    ${IBEXDIR}/ibex_wb_stage.sv \
    ${IBEXDIR}/ibex_load_store_unit.sv \
    ${IBEXDIR}/ibex_multdiv_fast.sv \
    ${IBEXDIR}/ibex_multdiv_slow.sv \
    ${IBEXDIR}/ibex_prefetch_buffer.sv \
    ${IBEXDIR}/ibex_fetch_fifo.sv \
    ${IBEXDIR}/ibex_pmp.sv \
    ${IBEXDIR}/ibex_register_file_fpga.sv \
    ${IBEXDIR}/ibex_core.sv \
]

# Synthesize with BranchPredictor=1, FPGA register file, minimal feature set
# RV32M=0 (RV32MNone): disable multiply/divide (our SoC has no M extension)
# RegFile=1 (RegFileFPGA): use LUTRAM register file for FPGA
# WritebackStage=0: 5-stage pipeline (matches our 5-stage design)
# BranchPredictor=1: enable static branch predictor
synth_design \
    -top ${TOP} \
    -part ${PART} \
    -mode out_of_context \
    -include_dirs [list ${IBEXDIR} ${STUBDIR}] \
    -generic {BranchPredictor=1 RegFile=1 RV32M=0 WritebackStage=0}

# Clock constraint: 125 MHz = 8 ns period (same as our design)
create_clock -period 8.000 -name clk_i [get_ports clk_i]

# Implement
opt_design
place_design
route_design

# Reports
report_utilization -file ${OUTDIR}/ibex_bp_utilization.rpt
report_power       -file ${OUTDIR}/ibex_bp_power.rpt

puts "=== Ibex+SBP synthesis complete ==="
