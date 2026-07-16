# Metodologia de Validação do XADC (Basys3 / Artix-7) para Aquisição de Correntes de Fase

**Contexto:** plataforma P-HIL para comparação FCS-MPC × CCS-GPC em PMSM; cadeia LEM LESR → condicionador (diff-amp G ≈ 0,787 + offset 0,5 V) → XADC (canais auxiliares via JXADC).
**Escopo:** este procedimento valida a cadeia de aquisição do XADC em malha aberta, com estímulo por gerador de funções. Não valida controle em malha fechada nem o modelo da planta (ver §8).

---

## 1. Referências

| Ref. | Documento | Uso nesta metodologia |
|---|---|---|
| [R1] | IEEE Std 1241 – Terminology and Test Methods for ADCs | Definições e procedimentos dos ensaios E3–E5 |
| [R2] | IEEE Std 1057 – Digitizing Waveform Recorders | Caracterização da cadeia completa como registrador |
| [R3] | Xilinx UG480 – 7 Series XADC User Guide | Modos, temporização, DRP, sequenciador (Cap. 4) |
| [R4] | Xilinx PG091 – XADC Wizard Product Guide | Configuração do IP e mapa de registradores |
| [R5] | Digilent Basys3 Reference Manual | JXADC, filtro anti-alias parcial (C33–C36) |
| [R6] | Digilent Basys3 XADC Demo (GitHub) | Verificação funcional E1; mapa XA↔VAUX |
| [R7] | LEM LESR series datasheet | Parâmetros do sensor emulado no ensaio E7 |

Mapa de canais (fixo da Basys3): XA1→VAUX6 (J3/K3), XA2→VAUX14, XA3→VAUX7, XA4→VAUX15. Endereço DRP do VAUX6: 0x16, dado em bits [15:4].

## 2. Grandezas sob validação e critérios de aceitação

A validação é dirigida pelo requisito do controle, não pelo datasheet. Critérios derivados do orçamento de erro da malha de corrente (LESR 25-NP, G_amp = 0,787):

| ID | Grandeza | Critério de aceitação | Ensaio |
|---|---|---|---|
| C1 | Ganho da cadeia | 4096 ± 2% códigos/V (antes de calibração) | E2 |
| C2 | Offset residual pós-calibração | ≤ 2 LSB | E2 |
| C3 | Não-linearidade (INL) | ≤ 4 LSB na faixa 0,1–0,9 V | E2/E3 |
| C4 | Ruído com entrada DC | σ ≤ 2 LSB (≈ 25 mA_rms referido à corrente) | E3 |
| C5 | ENOB dinâmico a 1 kHz | ≥ 10 bits (declarada a limitação do gerador) | E4 |
| C6 | Latência amostra→dado disponível | ≤ 5 µs, jitter ≤ 1 período de DCLK | E5 |
| C7 | Erro total referido à corrente | ≤ 0,5% de I_span após calibração | E7 |

Os valores de C1–C7 devem ser confirmados/ajustados com o orientador (ver §9, P1–P3).

## 3. Materiais e setup

Basys3 + Vivado (versão casada com a tag do release Digilent [R6]); gerador de funções com modo DC e saída configurada **High-Z**; multímetro 5½ dígitos (referência dos ensaios estáticos — um 3½ dígitos não resolve 244 µV/LSB); osciloscópio; conector: Pmod TPH2 ou header macho 2×6 com coaxial até o par; jumpers; opcional: filtro passa-baixas passivo para E4.

Conexão padrão: vivo → XA1_P (J3); retorno → XA1_N (K3) **e** GND do Pmod (pino 5). Nunca conectar sinal aos pinos 6/12 (3,3 V). Conferir pinagem com multímetro antes de energizar. Se usados, carregar C33–C36 (1 nF) para completar o filtro anti-alias do PCB [R5].

Segurança do estímulo: sinal confinado a 0–1 V, verificado no osciloscópio antes de conectar; resistor de 1 kΩ em série durante os ensaios.

## 4. Ensaios

### E0 — Teste de vida (sem código)
1. Programar a FPGA com qualquer bitstream (ou nenhum design de usuário) e abrir o Vivado Hardware Manager.
2. Verificar no dashboard do System Monitor a leitura de temperatura do die e trilhos internos via JTAG.
3. **Prova:** o bloco XADC responde. **Não prova:** canais externos, JXADC, lógica de usuário.

### E1 — Verificação funcional (demo Digilent)
1. Baixar o release do Basys3 XADC Demo compatível com a versão do Vivado, gerar bitstream e programar.
2. Aplicar DC de 0 a 1 V no XA1 e verificar a progressão dos 16 LEDs.
3. Repetir para XA2–XA4. **Prova:** JXADC, roteamento, canais VAUX. Registrar canal defeituoso, se houver.

### E2 — Ensaio estático (ganho, offset, linearidade) [R1 §static test]
1. Projeto próprio: XADC Wizard, DRP, modo contínuo, unipolar, canal VAUX6, averaging desligado, DCLK 100 MHz. Leitura via ILA ou display.
2. Gerador em DC; varrer 0,10 / 0,20 / … / 0,90 V (9 pontos), lendo simultaneamente o multímetro (valor verdadeiro) e o código médio de ≥ 256 amostras.
3. Regressão linear código × tensão → ganho (C1), offset (C2); resíduos → INL grosseira (C3).
4. Gravar ganho e offset como constantes de calibração (registradores na FPGA).

### E3 — Histograma (ruído e DNL) [R1 §histogram test]
1. Entrada DC fixa em 0,5 V; capturar ≥ 4096 amostras via ILA; exportar CSV.
2. Histograma de códigos: σ em LSB (C4). Se σ > critério, investigar na ordem: laço de terra do retorno, carga do gerador (High-Z), C33–C36 ausentes, ripple do trilho de 3,3 V.
3. Opcional (DNL por código): senoide levemente sobrecarregando a faixa e histograma senoidal conforme [R1] — não requer referência DC precisa.

### E4 — Ensaio dinâmico (SINAD/THD/ENOB) [R1 §sine-wave test]
1. Senoide 1 kHz, 0,8 Vpp, offset 0,5 V. Preferir amostragem coerente (nº inteiro e primo de ciclos no bloco); caso o gerador não trave fase com o DCLK, janela Blackman-Harris.
2. Capturar bloco de 4096–16384 amostras (ILA com trigger em EOC — nunca no clock), exportar, FFT no MATLAB → SINAD, THD, ENOB (C5).
3. **Declarar limitação:** THD típica de gerador de bancada (−55 a −65 dBc) < exigência de 12 bits (74 dB); harmônicas observadas pertencem majoritariamente à fonte. Mitigação: filtro passivo entre gerador e ADC, ou aceitar E4 como caracterização qualitativa com C5 conservador.

### E5 — Temporização (modo event)
1. Reconfigurar o wizard para modo event; convst_in gerado por contador (ex.: 100 kHz a partir de 100 MHz, conforme fluxo do tutorial VHDL de referência).
2. ILA em convst/EOC/dado: medir latência conversão+leitura (C6) e jitter do disparo.
3. Verificar comportamento na fronteira: convst durante conversão em andamento (deve ser ignorado, sem corromper dado).

### E6 — Verificação da lógica por simulação (pré-requisito de E2–E5)
1. Testbench comportamental com a primitiva XADC e SIM_MONITOR_FILE (arquivo texto tempo/tensão) reproduzindo a senoide de E4.
2. Verificar a FSM de leitura DRP contra o estímulo conhecido antes de qualquer ensaio em hardware.

### E7 — Ensaio integrado emulando o LESR (aceitação da cadeia)
1. Inserir o condicionador (diff-amp + bias 0,5 V) entre gerador e JXADC.
2. Gerador: offset 2,5 V, amplitude 1,25 Vpp — réplica elétrica exata da saída do LESR 25-NP com ±25 A senoidais [R7].
3. Repetir E2 (estático, agora em tensões de 1,875–3,125 V na entrada do condicionador) e E3.
4. Converter resultados para ampères pela função de transferência completa; verificar C7.
5. **Prova:** cadeia analógica inteira validada antes de energizar o inversor. No hardware real, substitui-se apenas o gerador pelo sensor.

## 5. Registro de resultados

Para cada ensaio: data, versão do bitstream (hash git), instrumento e incerteza, condições (temperatura ambiente, trilho 3,3 V medido), dados brutos (CSV), resultado × critério (C1–C7), veredito. Rastreabilidade requisito→ensaio→evidência no padrão já usado nos WI da MECSW.

## 6. Ordem de execução e dependências

E6 → E0 → E1 → E2 → E3 → E4 → E5 → E7. Cada ensaio só inicia com o anterior aprovado; falha em ensaio N com N−1 aprovado localiza o defeito na camada adicionada por N.

## 7. Limitações declaradas

(a) Estímulo em malha aberta: nada aqui valida estabilidade ou desempenho do controle; (b) pureza espectral do gerador limita E4 (ver §4/E4); (c) ensaios a temperatura ambiente — deriva térmica do condicionador não coberta; (d) dv/dt real do inversor não emulado (coberto apenas indiretamente pela rejeição de modo comum medida em E7).

## 8. Encaixe na hierarquia de validação da dissertação

Esta metodologia é o degrau "PIL/estímulo controlado" da escada MIL → SIL → PIL → HIL → P-HIL. Suas limitações (§7) são, item a item, a justificativa dos degraus seguintes da plataforma.

## 9. Perguntas ao orientador

**Sobre critérios (definem C1–C7):**
- P1. Qual erro de corrente (% de I_span ou mA) é aceitável na malha de corrente para que a comparação FCS-MPC × GPC não seja contaminada pela medição? Esse número dimensiona C4/C7 — hoje assumi 0,5%.
- P2. O senhor considera 12 bits/ENOB ≥ 10 suficientes para o XADC no papel de supervisão (DC-link, temperatura), mantendo o AD7367-5 nas correntes — ou prefere que eu caracterize o XADC também como backup das correntes (o que elevaria C5)?
- P3. Há requisito de banda mínima da cadeia de medição derivado do T_s do MPC que devo transformar em critério formal (hoje só meço latência em C6)?

**Sobre método:**
- P4. Para o E4, vale investir no filtro passivo anti-harmônicas do gerador, ou aceitamos a caracterização qualitativa com limitação declarada? (Custo ~1 tarde vs. rigor do capítulo.)
- P5. O laboratório dispõe de multímetro 5½ dígitos e/ou calibrador DC? Sem ele, C3 (INL) fica limitado pelo instrumento — reporto como "não avaliado" ou uso o histograma senoidal do E3 como substituto?
- P6. Devo estender E7 com varredura térmica (soprador/câmara) para capturar a deriva do condicionador, ou isso fica como trabalho futuro declarado?

**Sobre escopo da dissertação:**
- P7. Esta metodologia entra como seção do capítulo de hardware ou como apêndice de V&V? Pergunto porque o formato IEEE 1241 + rastreabilidade pode virar contribuição secundária do trabalho (metodologia de validação de aquisição para P-HIL open-source).
- P8. Para a plataforma open-source prometida à UFSC: os scripts de E3/E4 (captura ILA→CSV→MATLAB) devem ser entregues como parte do repositório? Isso muda o quanto os automatizo agora.

## 10. Entendendo o Hardware: O Conector JXADC e o XADC
A Basys 3 possui um conector Pmod especial, identificado como JXADC, que é diretamente conectado ao conversor analógico-digital (XADC) do FPGA Artix-7. Este conector oferece quatro pares diferenciais de entrada analógica.

Canais e Pinos: A correspondência entre os pares do conector e os canais do XADC é a seguinte:

Par 1 (Pino 1 = P, Pino 7 = N): Canal XADC AD6
Par 2 (Pino 2 = P, Pino 8 = N): Canal XADC AD14
Par 3 (Pino 3 = P, Pino 9 = N): Canal XADC AD7
Par 4 (Pino 4 = P, Pino 10 = N): Canal XADC AD15

11. Preparando o Gerador de Sinais
Nível de Tensão: O XADC da Basys 3, quando configurado em modo unipolar, mede tensões na faixa de 0 a 1 Volt. Portanto, configure o gerador de sinais para produzir uma onda, por exemplo, senoidal ou triangular, com amplitude entre 0V e 1V.

Conexão: Você precisará de um cabo ou ponta de prova para conectar a saída do gerador aos pinos do conector JXADC.

12. Conectando o Gerador ao JXADC
Para um teste inicial, a configuração mais simples é usar uma entrada single-ended (ou assimétrica). Neste modo, você conecta o sinal a um dos pinos "P" (positivo) e o terra (GND) ao pino "N" (negativo) correspondente.

Exemplo de Conexão:

Conecte a saída do gerador de sinais ao pino 1 (P) do JXADC (Canal AD6).

Conecte o terra (GND) do gerador de sinais ao pino 7 (N) do JXADC.

Importante: Aterrar todos os pinos não utilizados é uma boa prática para reduzir ruído e evitar acoplamentos indesejados.

13. Usando o Projeto de Demonstração (XADC Demo) - O Caminho Mais Rápido
A Digilent oferece um projeto de demonstração pronto que facilita muito o teste.

Baixe o Projeto: Acesse o repositório oficial no GitHub: https://github.com/Digilent/Basys-3-XADC. Na página de "Releases" do projeto, baixe o arquivo ZIP da versão mais recente.

Abra no Vivado: Extraia o arquivo ZIP e abra o projeto no Vivado. O arquivo do projeto (XADCdemo.xpr) está na pasta vivado_proj.

Programe a FPGA: Conecte sua Basys 3 ao computador via cabo MicroUSB e programe a FPGA com o arquivo bitstream gerado pelo projeto.

Visualize o Resultado:

A tensão no canal selecionado será exibida nos dois displays de sete segmentos.

Os 16 LEDs acenderão progressivamente da direita para a esquerda conforme a tensão aumenta.

Use as chaves SW0 e SW1 para alternar entre os quatro canais do XADC.

14. Criando Seu Próprio Projeto (Alternativa)
Se preferir criar seu próprio projeto do zero, você precisará instanciar o núcleo IP do XADC (XADC Wizard) no Vivado e configurá-lo para usar os pinos auxiliares conectados ao JXADC. Consulte o documento da Xilinx "7 Series FPGAs and Zynq-7000 All Programmable SoC XADC Dual 12-Bit 1 MSPS Analog-to-Digital Converter" para obter detalhes sobre a interface DRP (Dynamic Reconfiguration Port).

15. Dicas Adicionais e Considerações
Filtros Anti-Aliasing: O conector JXADC possui um layout com filtros anti-aliasing parciais. Os capacitores (C33-C36) não são soldados de fábrica, mas você pode adicioná-los manualmente se desejar um filtro mais robusto.

Uso dos Pinos: Embora sejam projetados para sinais analógicos, os pinos do JXADC também podem ser usados como I/O digitais (GPIO). No entanto, o roteamento das trilhas é otimizado para reduzir ruído analógico, o que pode limitar a velocidade para sinais digitais.

Resolução: O XADC é um conversor de 12 bits com taxa de amostragem de até 1 MSPS (1 milhão de amostras por segundo). Para uma faixa de 0 a 1V, a resolução é de aproximadamente 244 µV por bit (1V / 4096).


https://www.unilim.fr/pages_perso/vahid.meghdadi-neyshabouri/XADCinBasys3.html
