# Vivado batch synthesis for VexRiscv with DYNAMIC branch prediction (2-bit BHT)
# Generated from SpinalHDL: GenDynamicBHT config (RV32I, no cache, no MMU, no MUL/DIV)
# Target: xc7z020clg400-1 (PYNQ-Z2), 125 MHz clock
# Mode: non-project (in-memory), out-of-context (core only, no memory wrapper)

set SRCDIR  {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\vivado_reports}
set OUTDIR  {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\vivado_reports}
set PART    xc7z020clg400-1
set TOP     VexRiscv

set_param general.maxThreads 4

read_verilog [list ${SRCDIR}/VexRiscv_dynamic_bht.v]

synth_design \
    -top ${TOP} \
    -part ${PART} \
    -mode out_of_context

# Clock constraint: 125 MHz = 8 ns period (same as all other designs)
create_clock -period 8.000 -name clk [get_ports clk]

# Implement
opt_design
place_design
route_design

# Reports
report_utilization -file ${OUTDIR}/vexriscv_utilization.rpt
report_power       -file ${OUTDIR}/vexriscv_power.rpt
report_timing_summary -file ${OUTDIR}/vexriscv_timing.rpt -no_header -warn_on_violation

# Console summary
report_utilization
report_power

puts "=== VexRiscv+BHT synthesis complete ==="
