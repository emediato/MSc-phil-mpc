# =============================================================================
# create_project.tcl - Cria o projeto Vivado completo: XADC Wizard + ILA
# Basys3 (XC7A35T-1CPG236C)
#
# Uso (a partir da pasta raiz xadc_ila_basys3/):
#   vivado -mode batch -source scripts/create_project.tcl
# ou no Tcl Console do Vivado:
#   cd <caminho>/xadc_ila_basys3 ; source scripts/create_project.tcl
#
# Depois: Run Synthesis -> Implementation -> Generate Bitstream (ou descomente
# o bloco BUILD no final para compilar tudo automaticamente).
#
# NOTA: as propriedades sao aplicadas UMA A UMA com catch. Se alguma tiver
# nome diferente na sua versao do Vivado, aparece um AVISO nomeado no log e as
# demais continuam valendo (com -dict, uma falha derrubaria todas e o IP sairia
# com defaults - causa classica do erro "no matching formal port for vauxp6").
# =============================================================================

set proj_name  "xadc_ila_basys3"
set proj_dir   "./vivado_proj"
set part       "xc7a35tcpg236-1"
set src_dir    "./src"

# ----------------- Projeto ---------------------------------------------------
create_project $proj_name $proj_dir -part $part -force
set_property target_language VHDL [current_project]

# ----------------- Fontes ----------------------------------------------------
add_files -norecurse [list "$src_dir/top.vhd"]
add_files -fileset constrs_1 -norecurse [list "$src_dir/basys3_xadc.xdc"]
set_property top top [current_fileset]

# ----------------- Helper ----------------------------------------------------
proc set_ip_props {ip props} {
    foreach {p v} $props {
        if {[catch {set_property $p $v [get_ips $ip]} msg]} {
            puts "AVISO: $ip -> $p nao aplicada ($msg). Ajuste no wizard (GUI)."
        }
    }
}

# ----------------- XADC Wizard ----------------------------------------------
# DRP | Continuo | Canal unico VAUX6 | Unipolar | Sequencer Off | Sem alarmes
# Aquisicao estendida (ACQ) habilitada: margem de settling para os ~10 kOhm
# de RMUX dos canais auxiliares + resistencia externa (UG480 Eq. 2-4).
create_ip -name xadc_wiz -vendor xilinx.com -library ip -module_name xadc_wiz_0

set_ip_props xadc_wiz_0 {
    CONFIG.INTERFACE_SELECTION             Enable_DRP
    CONFIG.XADC_STARUP_SELECTION           single_channel
    CONFIG.TIMING_MODE                     Continuous
    CONFIG.SEQUENCER_MODE                  Off
    CONFIG.SINGLE_CHANNEL_SELECTION        VAUXP6_VAUXN6
    CONFIG.CHANNEL_ENABLE_VAUXP6_VAUXN6    true
    CONFIG.CHANNEL_ENABLE_VP_VN            false
    CONFIG.BIPOLAR_VAUXP6_VAUXN6           false
    CONFIG.SINGLE_CHANNEL_ACQUISITION_TIME true
    CONFIG.CHANNEL_AVERAGING               None
    CONFIG.ENABLE_RESET                    false
    CONFIG.OT_ALARM                        false
    CONFIG.USER_TEMP_ALARM                 false
    CONFIG.VCCINT_ALARM                    false
    CONFIG.VCCAUX_ALARM                    false
}

# ----------------- ILA -------------------------------------------------------
# 2 probes | depth 1024
# Com a decimacao do top.vhd (1 amostra a cada 50 us), 1024 amostras
# equivalem a uma janela de 51,2 ms: ~3 ciclos de 60 Hz, ~20 de 400 Hz.
# C_EN_STRG_QUAL = 1 -> Capture Control (qualificador cap_en == 1)
create_ip -name ila -vendor xilinx.com -library ip -module_name ila_0

set_ip_props ila_0 {
    CONFIG.C_NUM_OF_PROBES       2
    CONFIG.C_DATA_DEPTH          1024
    CONFIG.C_EN_STRG_QUAL        1
    CONFIG.C_ADV_TRIGGER         false
    CONFIG.ALL_PROBE_SAME_MU_CNT 2
    CONFIG.C_PROBE0_WIDTH        12
    CONFIG.C_PROBE1_WIDTH        1
    CONFIG.C_INPUT_PIPE_STAGES   1
}

# ----------------- Gerar produtos dos IPs ------------------------------------
generate_target all [get_ips]

puts "=============================================================="
puts " Projeto criado em $proj_dir/$proj_name.xpr"
puts " Janela do ILA: 1024 amostras x 50 us = 51,2 ms"
puts "   60 Hz  -> ~3 ciclos   |  400 Hz -> ~20 ciclos"
puts " Proximo passo: Run Synthesis -> Implementation -> Bitstream"
puts "=============================================================="

# ----------------- BUILD automatico (opcional) -------------------------------
# launch_runs synth_1 -jobs 4
# wait_on_run synth_1
# launch_runs impl_1 -to_step write_bitstream -jobs 4
# wait_on_run impl_1
# puts "Bitstream: $proj_dir/$proj_name.runs/impl_1/top.bit"
