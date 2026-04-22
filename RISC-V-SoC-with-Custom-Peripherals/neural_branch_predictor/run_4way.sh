#!/usr/bin/env bash
# run_4way.sh — compile tb_4way_compare.v with Icarus Verilog and run all 6 programs.
# Output: per-workload tables + results/4way_results.csv

set -euo pipefail
cd "$(dirname "$0")"

CORE=../riscv32i_core
BP_DIR=.
OUT_DIR=results_4way
mkdir -p "$OUT_DIR"

VVP_BIN="$OUT_DIR/tb_4way_compare.vvp"

echo "=== Compiling ==="
iverilog -g2005 -o "$VVP_BIN" \
    -I "$CORE" -I "$BP_DIR" \
    "$CORE/define.v" \
    "$CORE/ctrl.v" \
    "$CORE/pc_reg.v" \
    "$CORE/i_f.v" \
    "$CORE/if_id.v" \
    "$CORE/reg_file.v" \
    "$CORE/id.v" \
    "$CORE/id_ex.v" \
    "$CORE/ex.v" \
    "$CORE/ex_mem.v" \
    "$CORE/mem.v" \
    "$CORE/mem_wb.v" \
    "$CORE/pipeline_reg.v" \
    "$CORE/rom.v" \
    "$CORE/data_ram.v" \
    "$CORE/top.v" \
    "$CORE/risc_v_soc.v" \
    "$BP_DIR/define.v" \
    "$BP_DIR/bp_bimodal.v" \
    "$BP_DIR/bp_confidence.v" \
    "$BP_DIR/bp_history.v" \
    "$BP_DIR/bp_perceptron.v" \
    "$BP_DIR/bp_top.v" \
    "$BP_DIR/ctrl_bp.v" \
    "$BP_DIR/top_bp.v" \
    "$BP_DIR/risc_v_soc_bp.v" \
    "$BP_DIR/tb_4way_compare.v"

echo "=== Compilation done ==="
echo ""

# CSV header
CSV="$OUT_DIR/4way_results.csv"
echo "workload,branches,pico_pen,ant_acc,ant_pen,sbp_acc,sbp_pen,bht_acc,bht_pen,bp_acc,bp_pen" > "$CSV"

run_one() {
    local label="$1"
    local prog="$2"   # relative to neural_branch_predictor/
    local time="$3"

    echo "--- Running: $label ---"
    local log="$OUT_DIR/${label}.log"
    # Use short relative path — iverilog $value$plusargs %s has a byte limit
    vvp "$VVP_BIN" "+PROG=$prog" "+TIME=$time" "+LABEL=$label" | tee "$log"

    # Extract CSV line written by testbench (starts with "CSV,")
    grep "^CSV," "$log" | sed 's/^CSV,//' >> "$CSV"
    echo ""
}

run_one "branch-stress"    "instr_data_branchstress.txt"         4000
run_one "strongly-taken"   "instr_data_strongly_taken.txt"       4000
run_one "nested-loop"      "instr_data_nested_loop.txt"          8000
run_one "alt-forward"      "instr_data_alternating_forward.txt"  4000
run_one "nt-biased"        "instr_data_nt_biased.txt"            4000
run_one "long-loop"        "instr_data_long_loop.txt"            6000

echo "=== All done. Results saved to $CSV ==="
cat "$CSV"
