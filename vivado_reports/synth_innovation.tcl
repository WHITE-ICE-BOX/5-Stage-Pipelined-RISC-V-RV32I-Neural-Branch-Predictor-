# Vivado batch synthesis + implementation for innovation RISC-V SoC + Neural BP
# Target: xc7z020clg400-1 (PYNQ-Z2), 125 MHz clock
# Mode: non-project (in-memory)

set SRCDIR_CORE {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\RISC-V-SoC-with-Custom-Peripherals\riscv32i_core}
set SRCDIR_BP   {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\RISC-V-SoC-with-Custom-Peripherals\neural_branch_predictor}
set OUTDIR      {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\vivado_reports}
set PART        xc7z020clg400-1
set TOP         risc_v_soc_bp

# Read shared core sources (excluding define.v - will use BP version)
read_verilog [list \
    ${SRCDIR_BP}/define.v \
    ${SRCDIR_CORE}/pc_reg.v \
    ${SRCDIR_CORE}/i_f.v \
    ${SRCDIR_CORE}/if_id.v \
    ${SRCDIR_CORE}/id.v \
    ${SRCDIR_CORE}/reg_file.v \
    ${SRCDIR_CORE}/id_ex.v \
    ${SRCDIR_CORE}/ex.v \
    ${SRCDIR_BP}/ctrl_bp.v \
    ${SRCDIR_CORE}/ex_mem.v \
    ${SRCDIR_CORE}/mem.v \
    ${SRCDIR_CORE}/mem_wb.v \
    ${SRCDIR_CORE}/pipeline_reg.v \
    ${SRCDIR_CORE}/rom.v \
    ${SRCDIR_CORE}/data_ram.v \
    ${SRCDIR_BP}/bp_history.v \
    ${SRCDIR_BP}/bp_bimodal.v \
    ${SRCDIR_BP}/bp_perceptron.v \
    ${SRCDIR_BP}/bp_confidence.v \
    ${SRCDIR_BP}/bp_top.v \
    ${SRCDIR_BP}/top_bp.v \
    ${SRCDIR_BP}/risc_v_soc_bp.v \
]

# Synthesize
synth_design -top ${TOP} -part ${PART} -include_dirs [list ${SRCDIR_CORE} ${SRCDIR_BP}]

# Clock constraint: 125 MHz = 8 ns period
create_clock -period 8.000 -name clk [get_ports clk]

# Implement
opt_design
place_design
route_design

# Reports
report_utilization -file ${OUTDIR}/innovation_utilization.rpt
report_power       -file ${OUTDIR}/innovation_power.rpt

puts "=== Innovation synthesis complete ==="
