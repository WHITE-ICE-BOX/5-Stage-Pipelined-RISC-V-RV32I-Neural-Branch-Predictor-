# Full Vivado flow: elaboration check -> synthesis -> timing check -> implementation -> reports
# Target: risc_v_soc_bp on xc7z020clg400-1 (PYNQ-Z2), 125 MHz
# Mode: non-project (in-memory)

set SRCDIR_CORE {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\RISC-V-SoC-with-Custom-Peripherals\riscv32i_core}
set SRCDIR_BP   {\\wsl.localhost\Ubuntu\home\chiawei\SiliconAwards\RISC-V-SoC-with-Custom-Peripherals\neural_branch_predictor}
set SYNTHDIR    {C:\temp\vivado_scripts}
set OUTDIR      {C:\temp\vivado_scripts}
set PART        xc7z020clg400-1
set TOP         risc_v_soc_bp

puts "=== [1/5] Reading sources ==="
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
    ${SYNTHDIR}/rom_synth.v \
    ${SRCDIR_CORE}/data_ram.v \
    ${SRCDIR_BP}/bp_history.v \
    ${SRCDIR_BP}/bp_bimodal.v \
    ${SRCDIR_BP}/bp_perceptron.v \
    ${SRCDIR_BP}/bp_confidence.v \
    ${SRCDIR_BP}/bp_top.v \
    ${SRCDIR_BP}/top_bp.v \
    ${SRCDIR_BP}/risc_v_soc_bp.v \
]

puts "=== [2/5] Synthesis ==="
synth_design -top ${TOP} -part ${PART} -include_dirs [list ${SRCDIR_CORE} ${SRCDIR_BP}] -directive PerformanceOptimized

# Apply clock constraint after synthesis
create_clock -period 8.000 -name clk [get_ports clk]

puts "=== [3/5] Post-synthesis timing check ==="
report_timing_summary -file ${OUTDIR}/synth_timing.rpt -no_header
report_timing_summary -no_header

puts "=== [4/5] Implementation (opt -> place -> route -> phys_opt) ==="
opt_design
place_design -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design -directive AggressiveExplore
phys_opt_design -directive AggressiveExplore

puts "=== [5/5] Post-implementation reports ==="
report_timing_summary -file ${OUTDIR}/impl_timing.rpt     -no_header -warn_on_violation
report_utilization    -file ${OUTDIR}/impl_utilization.rpt
report_power          -file ${OUTDIR}/impl_power.rpt

report_timing_summary -no_header -warn_on_violation
report_utilization
report_power

write_checkpoint -force ${OUTDIR}/impl_checkpoint.dcp

puts "=== Full flow complete ==="
puts "Reports written to C:/temp/vivado_scripts/"
puts "Checkpoint: C:/temp/vivado_scripts/impl_checkpoint.dcp"
