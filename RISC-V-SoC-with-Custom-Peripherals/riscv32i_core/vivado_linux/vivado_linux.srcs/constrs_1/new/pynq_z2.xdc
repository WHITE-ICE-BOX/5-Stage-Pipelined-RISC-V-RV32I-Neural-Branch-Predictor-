# 定義 125MHz 時鐘 (PYNQ-Z2 上的 System Clock 通常是 125MHz，接在 H16)
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

# 定義 Reset (例如對應板子上的按鈕 BTN0, 腳位 D19)
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { reset }];
