# Vivado batch synthesis + implementation for baseline RISC-V SoC (no branch predictor)
# Target: xc7z020clg400-1 (PYNQ-Z2), 125 MHz clock
# Mode: non-project (in-memory)

set SRCDIR {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\RISC-V-SoC-with-Custom-Peripherals\riscv32i_core}
set OUTDIR {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\vivado_reports}
set PART    xc7z020clg400-1
set TOP     risc_v_soc

# Read all design sources (no testbenches)
read_verilog [list \
    ${SRCDIR}/define.v \
    ${SRCDIR}/pc_reg.v \
    ${SRCDIR}/i_f.v \
    ${SRCDIR}/if_id.v \
    ${SRCDIR}/id.v \
    ${SRCDIR}/reg_file.v \
    ${SRCDIR}/id_ex.v \
    ${SRCDIR}/ex.v \
    ${SRCDIR}/ctrl.v \
    ${SRCDIR}/ex_mem.v \
    ${SRCDIR}/mem.v \
    ${SRCDIR}/mem_wb.v \
    ${SRCDIR}/pipeline_reg.v \
    ${SRCDIR}/rom.v \
    ${SRCDIR}/data_ram.v \
    ${SRCDIR}/top.v \
    ${SRCDIR}/risc_v_soc.v \
]

# Synthesize
synth_design -top ${TOP} -part ${PART} -include_dirs ${SRCDIR}

# Clock constraint: 125 MHz = 8 ns period
create_clock -period 8.000 -name clk [get_ports clk]

# Implement
opt_design
place_design
route_design

# Reports
report_utilization -file ${OUTDIR}/baseline_utilization.rpt
report_power       -file ${OUTDIR}/baseline_power.rpt

puts "=== Baseline synthesis complete ==="
