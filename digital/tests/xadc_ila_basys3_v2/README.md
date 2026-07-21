# XADC + ILA na Basys3 — ensaio com gerador de sinais (VAUX6 / XA1)

Projeto para validar a cadeia de aquisição: senoide de 60 Hz (depois 400 Hz)
do gerador → XADC → código visualizado como forma de onda no ILA.

**Janela do ILA: 1024 amostras × 50 µs = 51,2 ms** (~3 ciclos de 60 Hz,
~20 ciclos de 400 Hz). A decimação é feita no `top.vhd`; o ILA continua
rodando a 100 MHz, mas só *armazena* quando `cap_en = 1`.

## Estrutura

```
xadc_ila_basys3/
├── src/
│   ├── top.vhd            # XADC (laço eoc→den) + registro + decimação + ILA + LEDs
│   └── basys3_xadc.xdc    # clock W5, JXADC XA1 (J3/K3), 16 LEDs
├── scripts/
│   ├── create_project.tcl # cria o projeto com os dois IPs configurados
│   └── hw_run.tcl         # programa, arma trigger/captura e exporta CSV
└── README.md
```

## Uso

**1. Criar o projeto:**

```
cd xadc_ila_basys3
vivado -mode batch -source scripts/create_project.tcl
```

(ou, no Tcl Console do Vivado: `cd <caminho>/xadc_ila_basys3` e
`source scripts/create_project.tcl`)

Abra `vivado_proj/xadc_ila_basys3.xpr` → Run Synthesis → Implementation →
Generate Bitstream.

**2. Bancada:** gerador na saída **MAIN** (não SYNC), **carga High-Z**,
senoide 60 Hz, **High = 0,9 V / Low = 0,1 V** (= 0,8 Vpp com offset +0,5 V).
Conferir no osciloscópio em **acoplamento DC** antes de conectar.
Sinal → XA1_P (pino 1 do Pmod, J3); retorno → XA1_N (pino 7, K3) **e** GND
(pino 5). Nada nos pinos 6/12 (3,3 V). Aterrar pinos não usados do JXADC.

**3. Capturar:**

```
vivado -mode batch -source scripts/hw_run.tcl -tclargs ensaio_60hz
```

O script programa a placa, configura Capture Control (qualificador
`cap_en == 1`), arma o trigger em `codigo == 0x800` com janela centrada
(posição 512), espera o disparo e grava `ensaio_60hz.csv`.
Repita com o gerador em 400 Hz: `-tclargs ensaio_400hz`.

**Pela GUI:** Hardware Manager → janela do ILA → Capture Setup: BASIC,
`cap_en == 1` → Trigger: `codigo == 800` (hex), posição 512 → botão direito
na probe `codigo`: Radix → Unsigned Decimal, Waveform Style → **Analog** →
Run Trigger. A senoide aparece desenhada.

**4. MATLAB:**

```matlab
d = readmatrix('ensaio_60hz.csv');  cod = d(:,end);
t = (0:numel(cod)-1)*50e-6;
plot(t, cod); grid on; xlabel('t (s)'); ylabel('codigo');
```

Registrar: código no zero (~2048), pico+, pico−, frequência, tensões lidas no
osciloscópio (não no display do gerador), data.

## Verificações de sanidade na tela

- 60 Hz → **~3 ciclos** na janela; um ciclo ≈ **333 amostras** (16,7 ms / 50 µs)
- 400 Hz → **~20 ciclos**; um ciclo ≈ **50 amostras**
- Eixo: índice de amostra × 50 µs = tempo em segundos

## Notas de projeto

- XADC: DRP, contínuo, canal único VAUX6, unipolar, sequencer off, averaging
  none, **aquisição estendida (ACQ) habilitada** — margem de settling para os
  ~10 kΩ de R_MUX dos canais auxiliares (UG480 Eq. 2-4).
- Dado válido do XADC de 12 bits: bits **[15:4]** de `do_out`.
- A decimação usa `pend` + `drdy`: o contador marca a hora, mas a amostra só é
  registrada na próxima conversão concluída (jitter ≤ 1 conversão ≈ 1 µs).
- LEDs mostram o código congelado a cada 50 ms — legível a olho.
- Ajustar a janela: `DEC_MAX = 4999` → 50 µs/amostra. Para 0,1 s de janela com
  o mesmo depth, use `DEC_MAX = 9999`; para mais resolução na mesma janela,
  aumente `C_DATA_DEPTH` em vez de reduzir a decimação.

## Depuração

- **"no matching formal port for vauxp6"**: o IP foi gerado sem o canal VAUX6.
  Confira em IP Sources → `xadc_wiz_0` → Instantiation Template (`.vho`) quais
  portas existem; recustomize o wizard (Single Channel → VAUXP6 VAUXN6,
  Bipolar desmarcado) e regenere. O log de `create_project.tcl` mostra AVISO
  para cada propriedade que a sua versão do Vivado não aceitou.
- **Wrapper com `reset_in`**: se a sua versão não permitir desabilitar o reset,
  acrescente `reset_in : in std_logic;` ao component e `reset_in => '0',` à
  instância no `top.vhd`.
- **Probe não encontrada no hw_run.tcl**: liste com `get_hw_probes` e ajuste os
  padrões `*cap*` / `*codigo*` (a síntese pode sufixar os nets).
- **Trigger nunca dispara**: use Trigger Mode `immediate` (Run sem condição)
  para confirmar que há dados vivos, ou troque a condição para `>= 800`.
- **Valores presos em 0 ou 4095**: sinal fora de 0–1 V no pino — conferir
  High-Z do gerador e o osciloscópio antes de suspeitar do código.

## Evolução (próximos degraus da metodologia)

- E4b: defasagem a 60/400 Hz (SYNC do gerador num pino digital + probe extra).
- Dois canais simultâneos (i_U/i_V): wizard em Event mode + simultaneous
  (VAUX6/VAUX14), `convst_in` do escalonador — ver "Dual channel simultaneous
  mode" no tutorial de Meghdadi (Unilim).
