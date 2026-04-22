# Code-Version Audit: `.` (WSL repo) vs `/mnt/c/Temp` (Windows workspace)

Date: 2026-04-22
Scope: Verilog RTL, Vivado TCL scripts, and synthesis / P&R reports that
back the numbers quoted in `proposal/main.tex`.

## TL;DR

There is **not a single canonical copy**. The two locations are different
*snapshots* of the same project, and `proposal/main.tex` quotes numbers from
**both** of them:

| Evidence in the proposal | Canonical source file | Location |
|---|---|---|
| Behavioural accuracy, `used_steps` histogram, per-workload %s | Pre-retime RTL (sequential early-stop loop) | `/mnt/c/Temp/vsim_run/neural_branch_predictor/` (stale) |
| `919 LUT / 1,252 FF / 0.133 W / 0.029 W / WNS +0.006 ns / 125 MHz` (Table, §Results, Conclusion) | `impl_utilization.rpt`, `impl_power.rpt`, `impl_timing.rpt` | `/mnt/c/Temp/vivado_scripts/` **only** (not mirrored into the repo) |
| `Baseline: 408 LUT / 613 FF / 0.113 W / 0.009 W` (row `Baseline always-NT`, §Results) | `baseline_power.rpt` (new, 19:25:57) | `/mnt/c/Temp/vivado_reports/baseline_power.rpt` — repo copy is stale |
| `Ibex+SBP 2,331 LUT / 876 FF / 0.141 W / 0.038 W` | `ibex_bp_*.rpt` | Identical in both locations |
| `Innovation 919 LUT / 1,239 FF / 0.133 W / 0.029 W` (pre-retime synth only) | `innovation_*.rpt` | Identical in both locations — superseded by `impl_*.rpt` for the FF count |
| `PicoRV32 810/443/0.119/0.016` and `VexRiscv 764/561/0.133/0.030` | `picorv32_*.rpt`, `vexriscv_*.rpt` | `./vivado_reports/` **only** (not in `/mnt/c/Temp`) |

The two unambiguous issues found:

1. **`./vivado_reports/baseline_power.rpt` is a broken/stale run** — its
   dynamic power is `0.000 W`, which means the power analyzer had no
   switching activity. The proposal actually cites `0.009 W` dynamic, i.e.
   the *newer* baseline run that only exists in
   `/mnt/c/Temp/vivado_reports/baseline_power.rpt`. The repo file should be
   overwritten with the Temp copy.
2. **Doc-vs-code drift in `bp_perceptron.v`** — the proposal repeatedly
   describes a "hardware early-stopping rule in the combinational adder
   path" (Algorithm 1, §2.3, §3.2, §3.4, §4, §5). The current RTL in the
   repo has **removed** that mechanism to close timing; see the in-file
   comment "early_stop is removed from the prediction path to eliminate
   the sequential carry chain that was causing the 14-ns violation." The
   implementation paragraphs in the proposal need to be reconciled (see
   §3 below).

---

## 1. RTL comparison

Compared `./RISC-V-SoC-with-Custom-Peripherals/{riscv32i_core,neural_branch_predictor}/`
against `/mnt/c/Temp/vsim_run/{riscv32i_core,neural_branch_predictor}/`.

### `riscv32i_core/`
Identical. Extras in the repo (`instr_data.txt`, `vivado.jou`, `vivado.log`,
`vivado_linux/`) are simulation artefacts, not RTL.

### `neural_branch_predictor/` — **3 files differ**

| File | Repo (`./`) | Temp (`/mnt/c/Temp/vsim_run`) |
|---|---|---|
| `bp_perceptron.v` | 2026-03-30 13:00, **parallel tree adder + 1-cycle pipeline register**, `early_stop` **removed** | 2026-03-29 02:43, sequential early-stop loop, combinational output |
| `bp_top.v` | 2026-03-30 12:52, adds 1-cycle pipeline registers for `bimodal_taken`, `conf_high`, `ghr_snapshot` to align with the pipelined perceptron | 2026-03-29 02:43, purely combinational mux |
| `top_bp.v` | Drives `pc_id(if_out_pc)` — feeds the IF-stage PC so the pipelined perceptron output is ready when the instruction reaches ID | Drives `pc_id(if_id_pc)` |

**Interpretation.** The Temp copy is a *simulation-verified* snapshot taken
before the 2026-03-30 retiming. The repo copy is the *post-retime* version
that was synthesised to reach `WNS = +0.006 ns` at 125 MHz. The proposal's
implementation/timing claims require the repo copy; the simulation
workloads and `used_steps` histogram (Table 9, §4.3) were almost certainly
collected against the Temp copy (or an equivalent behavioural model),
because `used_steps` is no longer a meaningful output in the retimed RTL
(it is hard-wired to `HIST_LEN`).

### Simulation extras only in the repo
`results_4way/`, `run_4way.sh`, `run_all_compare_sims.tcl`, `sim_logs/`,
`tb_4way_compare.v`. These are the Icarus-based comparison harness — not
mirrored to the Windows host.

---

## 2. Vivado TCL & report comparison

### `synth_baseline.tcl`, `synth_innovation.tcl`, `synth_ibex.tcl`

Both copies are *logically equivalent* but **target different hosts**:

* `/mnt/c/Temp/vivado_scripts/` uses Windows paths (`C:\temp\...`) and a
  synthesis-friendly ROM stub (`rom_synth.v`). This is the version that
  was actually executed on the Windows Vivado installation.
* `./vivado_reports/` uses `\\wsl.localhost\...` UNC paths and
  `${SRCDIR_CORE}/rom.v`. This is the WSL-side "master" that was staged
  for the Windows run.

They produce the same synthesised netlist for the baseline/innovation
flows except that the repo version reads `rom.v` (initialized) and the
Windows version reads `rom_synth.v` (stub). The repo version is the
reference; the Windows version is the one that ran.

### `full_flow.tcl` — diverges substantively

| | Repo `./vivado_reports/full_flow.tcl` | Temp `/mnt/c/Temp/vivado_scripts/full_flow.tcl` |
|---|---|---|
| Timestamp | 2026-03-30 01:13 | 2026-03-30 13:22 |
| Synthesis directive | default | `-directive PerformanceOptimized` |
| Implementation | `opt → place → route` | `opt → place ExtraTimingOpt → phys_opt AggressiveExplore → route AggressiveExplore → phys_opt AggressiveExplore` |
| Checkpoint | not written | `write_checkpoint impl_checkpoint.dcp` |
| Output dir | `vivado_reports/` in repo | `C:\temp\vivado_scripts\` |

**The 2026-03-30 13:22 Temp version is the one that produced the
`WNS = +0.006 ns` result cited in the proposal.** The repo copy is the
earlier (less aggressive) flow and is effectively dead — it will not
reproduce the reported timing closure on its own.

### Report-file map

Files that only appear in one location are in **bold**. `=` means byte-
identical (modulo whitespace).

```
                                        repo `./vivado_reports/`        Temp `/mnt/c/Temp/vivado_reports/`      Temp `/mnt/c/Temp/vivado_scripts/`
baseline_utilization.rpt                =                                =                                       -
baseline_power.rpt                      **stale, 0.000 W dynamic**       **current, 0.009 W dynamic**            -
innovation_utilization.rpt              =                                =                                       -
innovation_power.rpt                    =                                =                                       -
ibex_bp_utilization.rpt                 =                                =                                       -
ibex_bp_power.rpt                       =                                =                                       -
picorv32_*.rpt, synth_picorv32.log      **only here**                    -                                       -
vexriscv_*.rpt, synth_vexriscv.log      **only here**                    -                                       -
picorv32.v, VexRiscv_dynamic_bht.v      **only here**                    -                                       -
synth_timing.rpt                        -                                -                                       **only here** (post-synth)
impl_timing.rpt, impl_power.rpt,
impl_utilization.rpt                    -                                -                                       **only here — canonical for the report's 919/1,252 / 0.006 ns / 0.029 W numbers**
impl_checkpoint.dcp                     -                                -                                       **only here**
```

### Concrete numeric cross-check against `proposal/main.tex`

| Proposal claim (line) | Value quoted | Source file | Match? |
|---|---|---|---|
| Baseline always-NT row (1095) | `408 / 613 / 0 / 0 / 0.113 / 0.009` | `/mnt/c/Temp/vivado_reports/baseline_power.rpt` + `baseline_utilization.rpt` | ✓ — **but the repo's baseline_power.rpt says `0.103 / 0.000` and must be refreshed** |
| Innovation (This work) row (1098, 1127, 1155) | `919 / 1,252 / 0 / 0 / 0.133 / 0.029` | `/mnt/c/Temp/vivado_scripts/impl_utilization.rpt` + `impl_power.rpt` | ✓ — `innovation_utilization.rpt` in **both** locations reports 1,239 FF, not 1,252. The 1,252 number only exists in the `impl_*.rpt` full-flow run. |
| `WNS +0.006 ns`, zero setup/hold violations (85, 298, 1184–1185, 1304) | 0.006 ns | `/mnt/c/Temp/vivado_scripts/impl_timing.rpt` | ✓ |
| `125 MHz`, `8.00 ns period` (85, 298, 694, 1304) | — | Clock constraint in every TCL | ✓ |
| Ibex+SBP row (1096) | `2,331 / 876 / 0 / 0 / 0.141 / 0.038` | `ibex_bp_*.rpt` (both locations) | ✓ |
| VexRiscv+BHT row (1097) | `764 / 561 / 1.5 / 0 / 0.133 / 0.030` | `./vivado_reports/vexriscv_*.rpt` | ✓ (only in repo) |
| PicoRV32 row (1094) | `810 / 443 / 0 / 0 / 0.119 / 0.016` | `./vivado_reports/picorv32_*.rpt` | ✓ (only in repo) |

---

## 3. Issues that still need fixing

### 3.1 `./vivado_reports/baseline_power.rpt` is stale
It is the 19:19:39 run with `0.000 W` dynamic power. The report cites
`0.009 W` dynamic, which is from the 19:25:57 run that now only exists in
`/mnt/c/Temp/vivado_reports/`. Recommended action:
```
cp /mnt/c/Temp/vivado_reports/baseline_power.rpt ./vivado_reports/
```

### 3.2 Timing-closure run artefacts are not in the repo
`impl_utilization.rpt` / `impl_power.rpt` / `impl_timing.rpt` from
`/mnt/c/Temp/vivado_scripts/` are the primary evidence for the
`919 LUT / 1,252 FF / WNS +0.006 ns` claim, yet nothing in the repo
captures them. The newer `full_flow.tcl` (the one that actually
produced these numbers) is also missing from the repo. Recommended:
```
cp /mnt/c/Temp/vivado_scripts/impl_timing.rpt      ./vivado_reports/
cp /mnt/c/Temp/vivado_scripts/impl_utilization.rpt ./vivado_reports/
cp /mnt/c/Temp/vivado_scripts/impl_power.rpt       ./vivado_reports/
cp /mnt/c/Temp/vivado_scripts/synth_timing.rpt     ./vivado_reports/
cp /mnt/c/Temp/vivado_scripts/full_flow.tcl        ./vivado_reports/full_flow.tcl   # overwrites the stale Mar 30 01:13 version
```
(The `.dcp` checkpoint is ~1 MB and optional.)

### 3.3 Proposal vs RTL: "early-stopping rule" description is obsolete
Every paragraph below describes an early-stop mechanism that the current
`bp_perceptron.v` does **not** contain (see the in-file comment
"early_stop is removed from the prediction path ..."):

* line 66 — "hardware early-stopping rule in the combinational ..."
* line 173 — "Implement a hardware early-stopping rule within ..."
* line 251 — "The early-stop rule ..."
* lines 278–280 — "combinational adder tree and early-stop comparator ..."
* line 380 — "confidence gating, early stopping, ..."
* line 413 — table entry "From: early stopping"
* lines 611–620 — Algorithm 1 `alg:earlystop`
* line 926 — "early-stop mechanism reduces combinational ..."
* lines 946–949 — "The early-stopping mechanism eliminates ..."
* line 1078 — `used_steps` histogram caption

The cleanest fix is to reframe these as: *the pre-retime behavioural model
used for the accuracy study included combinational early-stop; in the
final timing-closed RTL this was replaced by a parallel tree adder with a
one-cycle pipeline register (§3.2).* That keeps the accuracy numbers
honest (they came from the early-stop model) and aligns the implementation
section with the RTL that was actually synthesised.

A stricter alternative is to re-run the accuracy study against the
post-retime RTL and regenerate Tables 7–9, but the *function* of the
predictor is unchanged (same weight-update and same prediction sign), so
the doc-only fix is defensible.

### 3.4 Simulation-verified RTL in `/mnt/c/Temp/vsim_run/` is stale
The `vsim_run` copy of `bp_perceptron.v`, `bp_top.v`, and `top_bp.v` is
the *pre-retime* version. If the team plans to rerun the Icarus /
XSim accuracy harness, they should copy the current repo RTL over it:
```
cp ./RISC-V-SoC-with-Custom-Peripherals/neural_branch_predictor/{bp_perceptron,bp_top,top_bp}.v \
   /mnt/c/Temp/vsim_run/neural_branch_predictor/
```
(Do this before quoting any new accuracy numbers — the retimed RTL has a
one-cycle-later prediction, which shifts the testbench scoreboard by one
cycle.)

---

## 4. Judgement: which version is "used in the formal report"?

Neither location alone is the source of truth. The report effectively
pulls from:

1. **Post-retime repo RTL** (`./RISC-V-SoC-with-Custom-Peripherals/...`)
   for every claim about timing closure, resource cost, and power.
2. **Post-retime Windows synthesis artefacts** (`/mnt/c/Temp/vivado_scripts/impl_*.rpt`)
   for the specific numbers `919 / 1,252 / 0.006 ns / 0.133 W / 0.029 W`.
3. **Pre-retime behavioural model** (whatever produced Tables 7, 8, 9 —
   matches `/mnt/c/Temp/vsim_run/neural_branch_predictor/`) for accuracy
   and the `used_steps` histogram.
4. **Repo-only baseline reports** (`./vivado_reports/picorv32_*`,
   `./vivado_reports/vexriscv_*`) for competitor comparison.

The only *erroneous* asymmetry is the stale
`./vivado_reports/baseline_power.rpt` (see §3.1); fixing that plus
copying the three `impl_*.rpt` files into the repo (§3.2) brings the
repository into full agreement with the numbers printed in the report.
The proposal text still needs the "early-stop" edit described in §3.3.
