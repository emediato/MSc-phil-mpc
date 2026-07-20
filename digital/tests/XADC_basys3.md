umn.edu/mxp-fpga/home/vivado-notes/basys3-analog-to-digital-converter-xadc


# BASYS3 Analog-to-Digital Converter (ADC) General Information and Input Specifications

Xilinx Information on the ADC:

https://www.xilinx.com/support/documentation/user_guides/ug480_7Series_XADC.pdf - page 23
http://www.xilinx.com/support/documentation/user_guides/ug475_7Series_Pkg_Pinout.pdf
https://docs.amd.com/r/en-US/ug480_7Series_XADC/Status-Registers


##  Hardware Specification:
Bits: 12, i.e, 212 = 4096 "levels"

## Conversion Rate:
The sampling rate is 154 kSPS to 1000 kSPS, or  a maximum of 1 MSPS.

It takes 26 clock cycles for one conversion, implying, that the maximum clock frequency for the ADC, ADCCL, of 26 MHz should never be exceeded.  (This is automatically configured by the XADC wizard.)  For more information, see pg. 28 of the user manual linked above.

Input Voltage Range:
The ADC can be operated either in a unipolar or bipolar configuration.

Unipolar Range: 0 <= Vin <= 1.0V, corresponding to a digital output of 000h, or, FFFh respectively.  The resolution is: 1.0V / 212 = 244 uV.  Hence, an analog input voltage, Van will produce the forllowing digital output: Van/244 uV.  Note: in the unipolar setting, the positive analog input must always be larger than the negaive one, i.e.,  Vp > Vn.  Also, Vn, can have a maxium 0.5V DC offset.  (See page 31 of the user guide, linked above.)

Bipolar Range: 0 <= Vin < 1.0V.  In the bipolar configuration, the positive and negative analog inputs, Vp, Vn, can be positive or negative. 
However, the absolute value of Vp - Vn can never exceed 0.5V.  
Note: the DC offset must remain within 0.25V to 0.75V, in other words, none of the input signals should ever go negative!  
In the bipolar configuration, the digital output format for the ADC is represented by a 12 bit 2's complement notation.  
In other words, a Vp - Vn of +0.5V is reprsented by 7FFh, and Vp- Vn = -0.5 V is 800h; 0V is still 000h. (See page 27 of the user guide, linked above.)

##  ADC Pin-outs

First, you must decide on the input channel(s) for the ADC.  Since the direct inputs vp_in and vn_in are disabled on the BASYS3 boards, you are required to use one of the 8 available auxiliary AUX channels shown in the table below.  Next, you will need to link the aux input channel to a port on the BASYS3 board.

For example, when ADC AUX channel 5 has been selected, then you must assign:

    assign vauxp5 = JA[4];

    assign vauxn5 = JA[0];

 

Finally, to read the value from an ADC conversion, the MUX address must be specified in  the  .daddr_in(MUX_address).  The MUX_address correspond to a value of 10h to 1fh.  It is related to the ADC AUX channel by:  MUX_address = ADC AUX channel + 16.  See the table below for the values (in hex notation.)


## ADC Operating Modes

Trigger Mode: 

The ADC trigger mode specifies the specific time at which data is acquired and converted; it can be configured for a continuous or an event mode.

In the continuous mode, data is acquired continuously (unless configured otherwise) at the maximum sample rate, 1 MSPS.

In the event trigger mode, data is acquired and converted only when the CONVST or CONVSTCLK input initiates it on a rising clock edge.

See page page 71 of the user guide linked above.

(Startup) Channel Selection:

In the simplest case, a single channel can be read by in the Single Channel Mode.

Multiple channels can be read in either the Independent or the Sequencer Mode.

Finally, in the Simultaneous Mode, two ADC channels are read at the same time.  The two channels must be offset by 8, i.e., for example AUX channel 4 and 12 can be sampled simultaneously with the two on board ADCs in the FPGA.


## No Hardware Manager — onde a senoide aparece

4. Open Hardware Manager → Open Target → Program Device. A janela do ILA (hw_ila_1) abre sozinha com as duas probes.

5. Capture Setup (a configuração que separa sucesso de frustração): na aba Capture Setup, Capture Mode = BASIC; adicione a condição drdy == 1 (R = valor 1) como capture qualifier. Resultado: o ILA só armazena uma amostra quando há conversão nova — cada linha do buffer = uma amostra do XADC (~1 µs entre elas), e os 65536 pontos cobrem ~4 ciclos de 60 Hz ou ~26 ciclos de 400 Hz.

6. Trigger Setup: adicione codigo == 800 (radix hex) — cruzamento do meio da escala; Trigger position in window = 32768 (centro), para ver ciclos antes e depois do disparo.

7. O toque final — desenhar como onda: na janela de waveform, botão direito sobre codigo → Radix → Unsigned Decimal → botão direito de novo → Waveform Style → Analog. Ajuste a altura da linha (arraste a borda). Clique em Run Trigger (▶). Com o gerador ligado em 60 Hz, a senoide aparece desenhada na tela, oscilando em torno de ~2048 — esta é a evidência visual do ensaio.

8. Medir e exportar: dois marcadores na janela dão pico+, pico− e o valor médio; para levar ao MATLAB, no Tcl Console:

tcl
write_hw_ila_data -csv_file ensaio_60hz.csv [upload_hw_ila_data hw_ila_1]

Troque o gerador para 400 Hz, Run Trigger de novo, exporte ensaio_400hz.csv. Pronto — os dois arquivos do ensaio do professor, com a forma de onda vista na tela e os dados brutos arquivados.

## Caminho GUI (recomendado para a primeira ida)
Abra o Vivado → abra o projeto (vivado_proj/xadc_ila_basys3.xpr) — ou, se estiver noutro PC, basta o Vivado Lab Edition/qualquer Vivado, nem precisa do projeto: só do par de arquivos top.bit + top.ltx (leve-os num pendrive; estão em vivado_proj/xadc_ila_basys3.runs/impl_1/).
Flow → Open Hardware Manager → Open Target → Auto Connect (Basys3 no USB, chave POWER ligada).
Atenção ao detalhe que pega todo mundo: se a placa perdeu a energia desde a gravação, o bitstream sumiu (a FPGA é volátil) — reprograme: Program Device → aponte o top.bit e, no campo de baixo, o top.ltx (é o arquivo de probes; sem ele o ILA não aparece!). Se a placa ficou energizada, só Refresh Device e o hw_ila_1 já aparece.
Na janela do ILA: Capture Setup → mode BASIC → qualifier drdy == 1; Trigger Setup → codigo == 800 (hex), posição 32768.
Botão direito na probe codigo → Radix → Unsigned Decimal → Waveform Style → Analog.
Ligue o gerador (High-Z, High 0,9 / Low 0,1, 60 Hz, conferido no osciloscópio) → Run Trigger (▶) → senoide na tela.
Gravar o resultado — no Tcl Console, com a captura na tela:
tcl
write_hw_ila_data -force -csv_file ensaio_60hz.csv [current_hw_ila_data]

(O CSV cai na pasta de onde o Vivado foi aberto — pwd mostra onde; cd antes se quiser mandar direto para a pasta de evidências.) Troque para 400 Hz, Run Trigger de novo, exporte ensaio_400hz.csv.

Caminho script (depois que o fluxo estiver redondo)

Da raiz do projeto, com a placa no USB:

vivado -mode batch -source scripts/hw_run.tcl -tclargs ensaio_60hz

Ele reprograma, arma tudo e fica em "Aguardando trigger..." — ligue o gerador nesse momento; o CSV sai sozinho. Depois -tclargs ensaio_400hz.

Checklist de bolso para anotar junto dos CSVs: tensões reais lidas no osciloscópio (não no display do gerador), código no zero (~2048), pico+ e pico−, frequência, data. E se o Auto Connect não achar a placa: cabo na porta PROG (a micro-USB ao lado da chave), chave ligada, e nenhum outro programa (Adept/outro Vivado) segurando o JTAG.

Qualquer coisa estranha na tela — platôs, valores presos, trigger que não dispara — me escreve do lab que a gente depura em tempo real. Bom ensaio! 🙂
