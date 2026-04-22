# Vivado batch synthesis for PicoRV32 RISC-V core (no branch prediction)
# Target: xc7z020clg400-1 (PYNQ-Z2), 125 MHz clock
# Mode: non-project (in-memory), out-of-context (core only, no memory wrapper)
# Config: base RV32I only (no PCPI, no MUL, no IRQ, no compressed)

set SRCDIR  {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\vivado_reports}
set OUTDIR  {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\vivado_reports}
set PART    xc7z020clg400-1
set TOP     picorv32

set_param general.maxThreads 4

read_verilog [list ${SRCDIR}/picorv32.v]

# Synthesize with minimal config: RV32I only, no extras
# ENABLE_MUL=0, ENABLE_DIV=0, ENABLE_IRQ=0, COMPRESSED_ISA=0, ENABLE_PCPI=0
# TWO_CYCLE_ALU=0 (default), BARREL_SHIFTER=0 (default)
synth_design \
    -top ${TOP} \
    -part ${PART} \
    -mode out_of_context \
    -generic {ENABLE_MUL=0 ENABLE_DIV=0 ENABLE_IRQ=0 COMPRESSED_ISA=0 ENABLE_PCPI=0 BARREL_SHIFTER=0 ENABLE_COUNTERS=0 ENABLE_COUNTERS64=0 ENABLE_TRACE=0}

# Clock constraint: 125 MHz = 8 ns period (same as all other designs)
create_clock -period 8.000 -name clk [get_ports clk]

# Implement
opt_design
place_design
route_design

# Reports
report_utilization -file ${OUTDIR}/picorv32_utilization.rpt
report_power       -file ${OUTDIR}/picorv32_power.rpt
report_timing_summary -file ${OUTDIR}/picorv32_timing.rpt -no_header -warn_on_violation

# Console summary
report_utilization
report_power

puts "=== PicoRV32 synthesis complete ==="
