# 5 級管線 RISC-V (RV32I) 處理器核心設計

## 專案簡介

本專案實作一個以 RISC-V Core (RISCV32I) cpu，透過 Verilog RTL 撰寫與驗證。

## 開發環境

* **HDL 語言**: Verilog
* **模擬工具**: vivado/Modelsim
* **目標平台**: 設計為可合成語法可延伸至 asic 實作

## 架構說明

* 五級管線 CPU 核心微架構實現：使用 Verilog RTL 實現完整之 5-Stage Pipelined CPU 核心，定義 Datapath 與級間暫存器結構，確保資料流之時序一致性。
* 模組化 Datapath 規劃與階層設計：清晰劃分 IF/ID/EX/MEM/WB 各階段邏輯功能，透過階層化模組設計優化微架構，為關鍵路徑 (Critical Path) 之時序收斂奠定基礎。
* 管線衝突偵測與流程控制邏輯：設計 Hazard Detection Unit，透過實作 Hardware Stalling 與 Pipeline Flushing 機制，解決資料與控制相依性問題，確保管線執行之完整性。
* 系統級 SoC 整合驗證平台：建構包含指令與資料記憶體模型 (ROM/RAM) 之基礎 SoC 驗證環境，實現完整的硬體系統模擬，驗證處理器與存取子系統間之整合正確性。
* 自動化 Self-checking 驗證體系：開發具自動檢查功能之 Testbench，透過階層路徑監控 Writeback Port 與 PC 訊號進行實時比對，加速功能驗證與 Bug 定位。
* ASIC 級可合成 RTL 與時序分析：遵循 Synthesizable Coding Style 撰寫，利用 Vivado 執行邏輯合成與初步時序分析，確保電路結構具備跨平台移植性。

## 專案架構 (暫定)

```
riscv_soc/
 ├── riscv32i_core/             # RISC-V CPU RTL (Verilog)
 ├── bus/              # AXI/APB 匯流排與仲裁器 （即將新增）
 ├── peripherals/      # UART, SPI, DMA, MAC 等週邊（即將新增）
 ├── memory/           # Boot ROM, SRAM, DRAM Controller（即將新增）
 ├── sim/              # ModelSim 測試平台與 testbench（目前測試檔案在riscv32i_core/ ）
 └── doc/              # 架構圖與技術文件（即將新增）
```



---

## 🎯 未來計畫

* 完成 AXI/APB 匯流排整合
* 新增中斷控制器 (PLIC/CLINT)
* 增加 SoC 週邊 (UART, SPI, DMA, Ethernet MAC)

---

