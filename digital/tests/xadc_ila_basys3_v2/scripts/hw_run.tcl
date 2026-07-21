# =============================================================================
# hw_run.tcl - Programa a Basys3, configura o ILA (trigger 0x800 + captura
# qualificada por cap_en) e exporta a captura em CSV.
#
# Uso: com a Basys3 conectada e o bitstream gerado,
#   vivado -mode batch -source scripts/hw_run.tcl -tclargs ensaio_60hz
# (o argumento vira o nome do CSV; default: "ensaio")
#
# Janela capturada: 1024 amostras x 50 us = 51,2 ms
#   60 Hz  -> ~3 ciclos  (~333 amostras por ciclo)
#   400 Hz -> ~20 ciclos (~50 amostras por ciclo)
# =============================================================================

set nome "ensaio"
if { $argc > 0 } { set nome [lindex $argv 0] }

set bitfile   "./vivado_proj/xadc_ila_basys3.runs/impl_1/top.bit"
set probefile "./vivado_proj/xadc_ila_basys3.runs/impl_1/top.ltx"

# ----------------- Conexao e programacao -------------------------------------
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set dev [current_hw_device]
set_property PROGRAM.FILE $bitfile $dev
if { [file exists $probefile] } {
    set_property PROBES.FILE      $probefile $dev
    set_property FULL_PROBES.FILE $probefile $dev
}
program_hw_devices $dev
refresh_hw_device $dev

# ----------------- ILA: captura qualificada + trigger ------------------------
set ila [lindex [get_hw_ilas] 0]

# Capture Control BASIC: 1 amostra por strobe decimado (cap_en == 1)
set_property CONTROL.CAPTURE_MODE BASIC $ila
set p_cap [get_hw_probes -of_objects $ila *cap*]
set_property CAPTURE_COMPARE_VALUE {eq1'b1} $p_cap

# Trigger: cruzamento do meio da escala (codigo == 0x800), janela centrada
set p_cod [get_hw_probes -of_objects $ila *codigo*]
set_property TRIGGER_COMPARE_VALUE {eq12'h800} $p_cod
set_property CONTROL.TRIGGER_POSITION 512 $ila

# ----------------- Disparo, upload e export ----------------------------------
run_hw_ila $ila
puts ">> Aguardando trigger (codigo == 0x800)... ligue a saida do gerador."
wait_on_hw_ila $ila
set dados [upload_hw_ila_data $ila]
display_hw_ila_data $dados
write_hw_ila_data -force -csv_file "${nome}.csv" $dados
puts ">> Captura exportada: ${nome}.csv (1024 amostras, 50 us entre elas)"
puts ">> No MATLAB:"
puts "     d = readmatrix('${nome}.csv');  cod = d(:,end);"
puts "     t = (0:numel(cod)-1)*50e-6;     plot(t, cod); grid on"
puts "     xlabel('t (s)'); ylabel('codigo'); % zero esperado ~2048"

# Dica GUI: botao direito na probe 'codigo' ->
#   Radix -> Unsigned Decimal   e   Waveform Style -> Analog
