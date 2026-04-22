# 5-Stage Pipelined RISC-V RV32I CPU with Neural Branch Predictor

> Custom **RV32I** processor built from scratch in Verilog, featuring a **Perceptron-based Neural Branch Predictor** with **Bimodal / Confidence arbitration** and **Early-Exit**.
> Measured branch-prediction accuracy **3× over always-not-taken baseline**; mispredictions and penalty cycles both **-66.7 %**.

![Arch](https://img.shields.io/badge/ISA-RISC--V%20RV32I-blue)
![Pipeline](https://img.shields.io/badge/Pipeline-5--Stage-brightgreen)
![Predictor](https://img.shields.io/badge/Branch%20Predictor-Perceptron%20%2B%20Bimodal%20Hybrid-orange)
![Verified](https://img.shields.io/badge/Self--Checking%20TB-Pass-success)
![Synth](https://img.shields.io/badge/Vivado-Synthesizable-lightgrey)

---

## Key Results

| Metric | Baseline (always-not-taken) | **Neural BP (this work)** | Delta |
|--------|-----------------------------|---------------------------|-------|
| Branch-prediction accuracy | 25 % | **75 %** | **3 ×** |
| Mispredictions (out of 40) | 30 | **10** | **-66.7 %** |
| Mispredict penalty cycles | 60 | **20** | **-66.7 %** |
| Perceptron utilisation | — | 55 % | Used only when bimodal confidence is low |
| Early-Exit steps | — | 3 – 8 (dynamic) | Reduces predictor switching activity |

> Measured on the `tb_compare_metrics` self-checking testbench (branch-stress workload).

---

## Highlights

- 🧠 **Perceptron Neural Branch Predictor** — 4-bit signed per-history weights + 8-bit Global History Register (GHR), updated by **saturation increment / decrement** (pure add/sub, **no multiplier**).
- 🎯 **Hybrid Arbitration** — 2-bit saturating **Bimodal** predictor with a confidence detector; bimodal takes the fast path when confidence is high, perceptron is invoked only when bimodal is uncertain.
- ⏩ **Early-Exit Accumulation** — dynamically bounds remaining-weight sum; terminates the perceptron dot-product once the final polarity is decidable (used_steps 3-8), cutting down dynamic power.
- 🔄 **Complete 5-Stage Pipeline** — IF / ID / EX / MEM / WB with full **Hazard Detection Unit** (stalling + flushing resolves RAW / WAR / WAW data hazards and control hazards).
- ✅ **Self-Checking SoC Verification** — hierarchical probes on Writeback Port + PC enable automatic PC-stream comparison and fast bug localisation.
- 🔧 **ASIC-Friendly Coding Style** — Synthesizable RTL, no vendor-only primitives; Vivado synthesis confirms cross-platform (FPGA / ASIC) portability.

---

## Microarchitecture

```
 ┌──────┐ ┌──────┐ ┌──────────┐ ┌──────┐ ┌──────┐
 │  IF  │→│  ID  │→│    EX    │→│ MEM  │→│  WB  │
 └──────┘ └──────┘ └──────────┘ └──────┘ └──────┘
     ▲        │         ▲           │        │
     │        ▼         │           ▼        ▼
     │   ┌──────────────┴──────────────────┐ │
     │   │    Hazard Detection Unit        │ │
     │   │   (Stalling / Flushing / Fwd)   │ │
     │   └─────────────────────────────────┘ │
     │                                       │
 ┌───┴────────────────────────────────────┐  │
 │  Branch Predictor (ID-stage lookup)    │  │
 │  ┌─────────────┐   ┌─────────────┐     │  │
 │  │   Bimodal   │   │ Perceptron  │     │  │
 │  │  2-bit ctr  │   │  4-bit w ×  │     │  │
 │  │   + conf    │◀──│  8-bit GHR  │     │  │
 │  └──────┬──────┘   └──────┬──────┘     │  │
 │         └──── Arbiter ────┘            │  │
 │       (High conf → Bimodal path        │  │
 │        Low conf  → Perceptron path)    │  │
 │                   +                    │  │
 │             Early-Exit logic           │  │
 └────────────────────────────────────────┘  │
                     ▲                       │
                     │ update (actual_taken, │
                     │  was_mispredict, ghr) │
                     └───────────────────────┘
```

---

## Repository Structure

```
.
├── RISC-V-SoC-with-Custom-Peripherals/
│   ├── riscv32i_core/               # Baseline 5-stage RV32I (Datapath + Control)
│   │   ├── i_f.v / id.v / ex.v      # Pipeline stages
│   │   ├── if_id.v / id_ex.v        # Pipeline registers
│   │   ├── pipeline_reg.v           # Generic pipeline register
│   │   ├── reg_file.v               # Architectural register file
│   │   ├── pc_reg.v                 # Program counter
│   │   ├── rom.v                    # Instruction memory model
│   │   ├── risc_v_soc.v / top.v     # Baseline SoC + top
│   │   └── tb.v                     # Baseline testbench
│   ├── neural_branch_predictor/     # Innovation: hybrid neural BP
│   │   ├── bp_bimodal.v             # 2-bit saturating counter
│   │   ├── bp_confidence.v          # Confidence detector
│   │   ├── bp_history.v             # Global History Register
│   │   ├── bp_perceptron.v          # Perceptron predictor + Early-Exit
│   │   ├── bp_top.v                 # Hybrid arbiter + fan-out
│   │   ├── ctrl_bp.v                # BP update controller
│   │   ├── risc_v_soc_bp.v          # SoC integrated with neural BP
│   │   ├── top_bp.v                 # Top with BP
│   │   ├── tb_bp_metrics.v          # Standalone BP metrics TB
│   │   ├── tb_baseline_metrics.v    # Baseline metrics TB
│   │   ├── tb_compare_metrics.v     # Head-to-head comparison TB
│   │   ├── tb_bp_branchstress_check.v # Branch-stress sanity check
│   │   └── instr_data_branchstress.txt # Branch-stress workload
│   ├── bus/                         # (WIP) AXI / APB arbitration
│   ├── peripherals/                 # (WIP) UART / SPI / DMA / MAC
│   ├── memory/                      # (WIP) Boot ROM / SRAM / DRAM ctrl
│   └── doc/                         # Architecture diagrams, spec
├── proposal/                        # English thesis-style proposal
├── proposal_tw/                     # Chinese proposal
├── vivado_reports/                  # Synthesis / Implementation reports
├── layout.png / power.jpg / utilization.jpg
└── README.md
```

---

## Branch Predictor — Algorithmic Detail

### Perceptron (`bp_perceptron.v`)

```
pred_sum = bias[pc] + Σᵢ (ghr[i] ? +w[pc][i] : -w[pc][i])
pred_taken = (pred_sum >= 0)

# Early-Exit: abort if outcome is already decidable
if |sum_acc| >= (HIST_LEN - 1 - i) × W_MAX:  break
```

- `INDEX_BITS = 4` → 16 perceptron entries
- `HIST_LEN   = 8` → 8-bit GHR
- `W_BITS     = 4` → signed weights in [-8, +7], saturation-clamped
- Update rule: `wᵢ += 1` if `(actual == ghr[i])`, else `-= 1`
- Bias updated the same way; only on **mispredict**

### Bimodal + Confidence (`bp_bimodal.v`, `bp_confidence.v`)

- 2-bit saturating counter per PC-index entry
- Confidence is **high** when counter is 2'b00 or 2'b11 → take bimodal directly
- Otherwise fall back to perceptron

### Arbiter (`bp_top.v`)

```
pred_use_neural = is_branch && !conf_high
pred_taken      = is_branch ? (conf_high ? bimodal_taken : neural_taken) : 0
```

---

## Verification

Three-tier self-checking strategy:

1. **Unit-level** — `bp_perceptron`, `bp_bimodal`, `bp_history` individually driven with directed and stress vectors.
2. **Integrated BP** — `tb_bp_metrics` / `tb_bp_branchstress_check` exercise the full BP subsystem with a realistic branch-stress workload.
3. **Head-to-head** — `tb_compare_metrics` instantiates **two** SoCs (baseline vs. innovation) side-by-side, feeds identical instruction streams, and tallies:
   - Total branches / correct / mispredicted
   - Perceptron usage ratio
   - `used_steps` histogram (Early-Exit efficacy)
   - Mispredict-penalty-cycle reduction

Reference numbers on the branch-stress workload are reported in **Key Results** above.

---

## Tools & Environment

| Category | Tool |
|----------|------|
| HDL | Verilog |
| Simulation | Vivado xsim / ModelSim |
| Synthesis | Vivado (logic synthesis + initial STA for FPGA/ASIC portability check) |
| Proposal / Documentation | LaTeX |

---

## What Was Demonstrated

- Clean 5-stage RV32I microarchitecture with full **hazard handling** (stall + flush + forwarding).
- **Novel** branch-predictor design — a hybrid Perceptron + Bimodal arbiter with Early-Exit, quantitatively improving accuracy by 3× and cutting penalty cycles by two-thirds.
- Disciplined verification — side-by-side SoC comparison TBs producing reproducible metrics.
- Synthesizable, ASIC-friendly RTL ready for downstream DC / Genus flows.

---

## Roadmap

- [ ] AXI / APB bus integration (in progress)
- [ ] Interrupt controller (PLIC / CLINT)
- [ ] UART / SPI / DMA / Ethernet MAC peripherals
- [ ] Tape-out preparation on TSMC N16 ADFP

---

## Contact

**Po-Chun Huang (黃柏鈞 / Barkie)** — Zhubei, Hsinchu, Taiwan
📧 [barkie.huang@gmail.com](mailto:barkie.huang@gmail.com)
🔗 GitHub: [WHITE-ICE-BOX](https://github.com/WHITE-ICE-BOX)

> M.S. student at National Chung Cheng University CSIE, specialising in
> digital IC front-end design, CPU microarchitecture, and ASIC system integration.
