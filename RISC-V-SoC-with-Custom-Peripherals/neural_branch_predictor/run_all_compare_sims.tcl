# run_all_compare_sims.tcl
# Vivado batch simulation script: runs all 6 compare testbenches.
#
# Usage (from WSL):
#   vivado_batch /home/chiawei/SiliconAwards/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/run_all_compare_sims.tcl
#
# Output logs are written to:
#   neural_branch_predictor/sim_logs/<tb_name>.log
#
# Path-patching: the testbenches use Linux paths (/home/chiawei/...).
# When running on Windows Vivado, this script rewrites $readmemb paths to the
# Windows UNC equivalent (//wsl.localhost/Ubuntu/...) before compilation.
# ============================================================================

# ---------------------------------------------------------------------------
# 1. Compute paths
# ---------------------------------------------------------------------------
set script_path [file normalize [info script]]
set nb_dir      [file dirname $script_path]
set core_dir    [file normalize [file join $nb_dir ".." "riscv32i_core"]]
set log_dir     [file join $nb_dir "sim_logs"]
file mkdir $log_dir

puts "===================================================================="
puts " run_all_compare_sims.tcl"
puts " nb_dir  = $nb_dir"
puts " core_dir = $core_dir"
puts " log_dir  = $log_dir"
puts "===================================================================="

# ---------------------------------------------------------------------------
# 2. Determine $readmemb path: Linux vs Windows UNC
# ---------------------------------------------------------------------------
# On Windows Vivado, nb_dir will start with // (UNC) or a drive letter.
# On Linux Vivado, nb_dir will start with /.
# The testbench files hardcode the Linux path; patch them for Windows.

set linux_base "/home/chiawei/SiliconAwards/RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/"

# Build the replacement path (forward-slash UNC for Windows, or leave as-is for Linux)
if {[string match "//*" $nb_dir] || [string match {[A-Za-z]:*} $nb_dir]} {
    # Windows Vivado: nb_dir is already a Windows-style path with forward slashes
    set win_base "${nb_dir}/"
    set win_base [string map {\\ /} $win_base]
    set need_patch 1
    puts "INFO: Windows Vivado detected. Will patch \$readmemb paths."
    puts "INFO: linux_base = $linux_base"
    puts "INFO: win_base   = $win_base"
} else {
    set need_patch 0
    puts "INFO: Linux Vivado detected. Using paths as-is."
}

# ---------------------------------------------------------------------------
# 3. Helper: patch a testbench file if needed
# ---------------------------------------------------------------------------
proc get_patched_tb {nb_dir tb_name linux_base win_base need_patch log_dir} {
    set src [file join $nb_dir "${tb_name}.v"]
    if {!$need_patch} { return $src }
    set dst [file join $log_dir "${tb_name}_patched.v"]
    set f [open $src r]
    set content [read $f]
    close $f
    set content [string map [list $linux_base $win_base] $content]
    set f [open $dst w]
    puts -nonewline $f $content
    close $f
    return $dst
}

# ---------------------------------------------------------------------------
# 4. Source file lists
# ---------------------------------------------------------------------------
set bp_sources [list \
    [file join $nb_dir "define.v"]         \
    [file join $nb_dir "bp_bimodal.v"]     \
    [file join $nb_dir "bp_confidence.v"]  \
    [file join $nb_dir "bp_history.v"]     \
    [file join $nb_dir "bp_perceptron.v"]  \
    [file join $nb_dir "bp_top.v"]         \
    [file join $nb_dir "ctrl_bp.v"]        \
    [file join $nb_dir "top_bp.v"]         \
    [file join $nb_dir "risc_v_soc_bp.v"]  \
]

set core_sources [list \
    [file join $core_dir "pc_reg.v"]       \
    [file join $core_dir "i_f.v"]          \
    [file join $core_dir "if_id.v"]        \
    [file join $core_dir "reg_file.v"]     \
    [file join $core_dir "id.v"]           \
    [file join $core_dir "id_ex.v"]        \
    [file join $core_dir "ex.v"]           \
    [file join $core_dir "ctrl.v"]         \
    [file join $core_dir "ex_mem.v"]       \
    [file join $core_dir "mem.v"]          \
    [file join $core_dir "mem_wb.v"]       \
    [file join $core_dir "pipeline_reg.v"] \
    [file join $core_dir "rom.v"]          \
    [file join $core_dir "data_ram.v"]     \
    [file join $core_dir "risc_v_soc.v"]   \
]

# List of compare testbenches to run (in order)
set tb_list {
    tb_compare_metrics
    tb_compare_strongly_taken
    tb_compare_nested_loop
    tb_compare_alternating_forward
    tb_compare_nt_biased
    tb_compare_long_loop
}

# ---------------------------------------------------------------------------
# 5. Verify all source files exist
# ---------------------------------------------------------------------------
puts "\n--- Verifying source files ---"
foreach f [concat $bp_sources $core_sources] {
    if {![file exists $f]} {
        puts "ERROR: Missing source file: $f"
        exit 1
    }
}
puts "All design sources found."

foreach tb $tb_list {
    set tb_src [file join $nb_dir "${tb}.v"]
    if {![file exists $tb_src]} {
        puts "ERROR: Missing testbench: $tb_src"
        exit 1
    }
}
puts "All testbench sources found."

# ---------------------------------------------------------------------------
# 6. Create in-memory Vivado project
# ---------------------------------------------------------------------------
puts "\n--- Creating in-memory project ---"
create_project -in_memory -part xc7z020clg400-1
set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]

# Add all design sources
add_files -norecurse -fileset [get_filesets sources_1] $bp_sources
add_files -norecurse -fileset [get_filesets sources_1] $core_sources
set_property top risc_v_soc_bp [get_filesets sources_1]

puts "Design sources added."

# ---------------------------------------------------------------------------
# 7. Run each testbench
# ---------------------------------------------------------------------------
foreach tb $tb_list {
    puts "\n===================================================================="
    puts " TESTBENCH: $tb"
    puts "===================================================================="

    # Get (possibly patched) testbench file
    set tb_file [get_patched_tb $nb_dir $tb $linux_base $win_base $need_patch $log_dir]
    puts "TB file: $tb_file"

    # Add testbench to sim fileset (remove any previous TB first)
    set sim_fs [get_filesets sim_1]
    set prev_tb_files [get_files -of_objects $sim_fs -filter {FILE_TYPE == "Verilog"}]
    foreach pf $prev_tb_files {
        remove_files -fileset $sim_fs $pf
    }
    add_files -norecurse -fileset $sim_fs $tb_file
    set_property top $tb          $sim_fs
    set_property top_lib xil_defaultlib $sim_fs

    # Redirect sim output to per-TB log
    set tb_log [file join $log_dir "${tb}.log"]

    # Launch simulation
    puts "Launching simulation -> log: $tb_log"
    if {[catch {
        launch_simulation
        run all
        close_sim
    } err]} {
        puts "ERROR in $tb: $err"
        set f [open $tb_log w]
        puts $f "ERROR: $err"
        close $f
        continue
    }

    # Copy Vivado console output to per-TB log by parsing the transcript
    # (Vivado writes $display output to the project simulation log)
    set xsim_log [file join [get_property DIRECTORY [current_project]] \
                  "${tb}.sim" "sim_1" "behav" "xsim" "simulate.log"]
    if {[file exists $xsim_log]} {
        file copy -force $xsim_log $tb_log
        puts "Copied xsim log -> $tb_log"
    } else {
        puts "WARNING: Could not find xsim log at $xsim_log"
    }

    puts "DONE: $tb"
}

close_project
puts "\n===================================================================="
puts " All simulations complete. Check $log_dir for per-TB results."
puts "===================================================================="
