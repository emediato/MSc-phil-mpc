# basys3_xadc.xdc - Constraints para o projeto XADC + ILA (Basys3)
# Derivado do Basys3_Master.xdc da Digilent (linhas relevantes descomentadas)

# ================= Clock 100 MHz =============================================
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

# ================= JXADC - par XA1 (canal VAUX6) =============================
# XA1_P = pino 1 do Pmod (J3) | XA1_N = pino 7 do Pmod (K3)
# Retorno do sinal: XA1_N + GND (pino 5 do Pmod), na origem do sinal.
# Pinos nao utilizados do JXADC: aterrar na bancada (recomendacao demo Digilent).
set_property PACKAGE_PIN J3 [get_ports vauxp6]
set_property IOSTANDARD LVCMOS33 [get_ports vauxp6]
set_property PACKAGE_PIN K3 [get_ports vauxn6]
set_property IOSTANDARD LVCMOS33 [get_ports vauxn6]

# ================= LEDs (codigo em binario) ==================================
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# ================= Configuracao =============================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
