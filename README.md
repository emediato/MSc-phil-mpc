# MSc-phil-mpc
P-HIL Motor Development for Master of Science In Engineering


# CRONOGRAMA

### Mês 1 — Fundamentação e disparo de compras (Etapa 1)
Semana 1: Estruturar a revisão. Levantar e organizar a base sobre P-HIL (estabilidade da interface, métodos de interface IDEAL/ITM/DIM, atrasos de loop). Disparar levantamento de componentes e iniciar cotações — esta é a ação crítica da semana.
Semana 2: Revisão de FCS-MPC (função custo, horizonte, modelo de predição da carga RL com fcem). Fechar lista de compras de itens com lead time longo (FPGA board, gate drivers, SiC, amplificador) e emitir pedidos.
Semana 3: Revisão de CCS-GPC (modelo CARIMA, equação Diofantina, ponderação, restrições). Mapear como os requisitos MIL-STD-704F / DO-160G se traduzem em métricas mensuráveis (transientes de tensão, distorção, faixa de frequência).
Semana 4: Modelagem matemática da carga indutiva variável (RL + fcem) e do conversor. Fechar a fundamentação da Parte 1 da dissertação em rascunho.

### Mês 2 — Modelo e simulação offline (transição Etapa 1 → 2)
Semana 5: Implementar em MATLAB/Simulink o modelo da planta e o emulador de carga P-HIL (medir tensão → calcular corrente em tempo real).
Semana 6: Implementar FCS-MPC em simulação. Validar resposta transitória e regime permanente contra a teoria.
Semana 7: Implementar CCS-GPC em simulação nas mesmas condições. Primeira comparação offline FCS-MPC vs GPC.
Semana 8: Definir métricas formais (THD, tempo de acomodação, erro RMS, esforço de chaveamento, custo computacional estimado em ciclos). Congelar o protocolo de comparação que será usado igual nas duas etapas seguintes.


### Mês 3 — Desenvolvimento FPGA (Etapa 2, parte 1)
Semana 9: Arquitetura do hardware digital. Definir formato numérico (ponto fixo vs ponto flutuante), pipeline, e particionamento do algoritmo. Decisão de quanto vai para FPGA vs processador.
Semana 10: Implementar o modelo de predição da carga em RTL. Testbench e verificação numérica contra o MATLAB (bit-accuracy aceitável).
Semana 11: Implementar o núcleo do FCS-MPC na FPGA (avaliação da função custo sobre os estados de chaveamento). Verificar latência e timing closure.
Semana 12: Implementar GPC na FPGA — atenção ao custo das operações matriciais. Avaliar se cabe em recursos e timing; aqui é comum precisar de simplificação (solução explícita, pré-computação).


Mês 4 — Validação HIL (Etapa 2, parte 2)
Semana 13: Montar o setup HIL (FPGA emulando carga ↔ FPGA do controlador, ou planta no simulador em tempo real). Validar a malha de processamento de sinais end-to-end.
Semana 14: Validar FCS-MPC em HIL. Coletar dados de transitório e regime permanente.
Semana 15: Validar GPC em HIL nas mesmas condições. Coletar dataset comparável.
Semana 16: Comparação sistemática FCS-MPC vs GPC em HIL. Marco: neste ponto o mestrado já tem resultado defensável mesmo se a etapa experimental falhar. Escrever a Parte 2 (resultados HIL).
Mês 5 — Bancada experimental (Etapa 3, parte 1)
Semana 17: Receber/conferir hardware, montar e testar PCB do conversor e estágio de potência em baixa tensão. Validar gate drivers e proteções isoladamente.
Semana 18: Integrar FPGA ↔ conversor. Testes em malha aberta com carga resistiva simples antes de fechar a malha.
Semana 19: Fechar a malha com FCS-MPC em bancada, potência reduzida. Depuração de ruído, medição, sincronismo ADC.
Semana 20: Subir potência gradualmente e introduzir a carga indutivo-resistiva real / amplificador P-HIL. Caracterizar comportamento.
Mês 6 — Experimentos finais e dissertação (Etapa 3, parte 2 + fechamento)
Semana 21: Experimentos FCS-MPC completos sob cargas dinâmicas e variações paramétricas (robustez).


Plano de 6 meses (jul–dez 2026)
O plano roda em dois trilhos paralelos: Trilho A (controle/digital) e Trilho B (hardware). O Trilho B começa cedo só pela parte de compras e projeto, mesmo que a montagem seja mais tarde.
Mês 1 (julho) — Revisão dirigida, modelagem e disparo de compras
Semana 1: Travar as cinco decisões acima. Abrir BOM e cotações dos itens de lead time longo. Revisão focada do contexto MEA e dos surveys de MPC (não deixe a revisão virar bloco infinito — o suficiente para fundamentar e decidir).
Semana 2: Modelagem do conversor três-níveis + filtro + carga RL com fcem; discretização já pensando no ponto fixo de 12 bits alinhado ao XADC.
Semana 3: Modelagem da máquina no referencial dq com parâmetros aeronáuticos. Revisar a formulação do GPC (aqui o livro do seu orientador é central — ver toolkit) e do FCS-MPC.
Semana 4: Fechar o modelo discreto unificado planta+filtro+carga+máquina. Emitir os pedidos de compra.

Mês 2 (agosto) — Simulação dos controladores (adaptar o código existente no Simulink E HDL Coder)
Semana 5: Portar/adaptar o GPC (MATLAB) — irrestrito primeiro, depois restrito via quadprog. Validar contra a teoria.
Semana 6: Portar/adaptar o FCS-MPC (C, via S-function/MEX no Simulink). Validar.
Semana 7: Cenários de carga variável (degrau, rampa, carga não linear). Primeira comparação GPC vs FCS sob as métricas (MSE de corrente, THD, frequência média de chaveamento).
Semana 8: Congelar o protocolo de comparação (horizonte igual, mesmas métricas) — ele será reusado idêntico em CHIL e bancada. Implementar o modelo do emulador PHIL: medir tensão → calcular corrente pelo modelo → reproduzir corrente.

Mês 3 (setembro) — Geração de código e validação digital (CHIL)
Semana 9: Arquitetura digital: partição FPGA vs DSP/STM32, formato ponto fixo 12 bits, pipeline. Aqui roda o checkpoint de viabilidade do STM32 (cabe GPC-QP? se não, redireciona conforme decisão 2).
Semana 10: HDL Coder do GPC (MATLAB → VHDL) para a Basys3. Verificação bit-accurate contra o MATLAB e fechamento de timing/área dentro do orçamento de 90 DSPs.
Semana 11: HLS/Vitis do FCS-MPC (C → RTL), ou implementação no STM32. Medir latência por ciclo de controle.
Semana 12: CHIL — controlador embarcado ↔ planta simulada em tempo real. Validar a malha de processamento de sinais end-to-end.

Mês 4 (outubro) — Validação PHIL/CHIL e início do projeto de hardware
Semana 13: PHIL/CHIL com emulação de carga indutiva. Atenção à estabilidade de interface — carga indutiva é o caso mais sensível (Ren/Steurer no toolkit). Coletar dados de FCS e GPC.
Semana 14: Comparação digital sistemática FCS vs GPC (transitório e regime). Marco: neste ponto o mestrado já tem resultado defensável mesmo se a bancada atrasar.
Semana 15 (Trilho B): Projeto do estágio de potência — topologia três-níveis fechada, escolha IGBT/MOSFET por faixa de tensão/corrente, gate drivers isolados com proteção de sobrecorrente/tensão. Esquemático.
Semana 16 (Trilho B): Subsistema de aquisição — Hall isolado, divisor resistivo isolado, sensor de temperatura, condicionamento de sinais, interface FPGA/ADC. Esquemático.

Mês 5 (novembro) — PCB mixed-signal e fabricação
Semana 17: Layout da PCB mixed-signal — aterramento, planos, isolação primário/secundário, separação entre potência e digital. Seguir Ott / app notes da Analog Devices.
Semana 18: Revisão de layout (DRC, caminhos de retorno, decoupling, laços de gate curtos). Fechar os gerbers e enviar para fabricação.
Semana 19: Enquanto fabrica/chega: firmware/RTL de calibração, aquisição e proteção; escrever o plano de bring-up.
Semana 20: Receber a PCB, inspecionar e montar incrementalmente (alimentação, isolação, gate drivers em baixa tensão).

Mês 6 (dezembro) — Bring-up inicial, Parte 1 da dissertação e decisão
Semana 21: Bring-up — testar gate drivers, ADC e malha de medição isoladamente; malha aberta com carga resistiva em baixa tensão.
Semana 22: Primeiros testes em malha fechada (FCS) em potência reduzida. Depuração de ruído e sincronismo de ADC — é aqui que a PCB mixed-signal paga ou cobra.
Semana 23: Consolidar resultados (simulação + CHIL/PHIL + bring-up). Redigir a Parte 1 (fundamentação P-HIL) e a metodologia.
Semana 24: Buffer, revisão e reavaliação de escopo para 2027/1 (o que entra na validação em bancada plena). Reserve esta semana — algo sempre escorrega.

# Toolkit de referências por fase

Marco com número [n] as que já estão na sua bibliografia e escrevo por extenso as adições que recomendo.

Contexto MEA e justificativa: [0], [13] Buticchi, [23] Schefer, [26] Nuzzo.
Fundamentação de MPC (survey): [4] Cortés et al., [25] Vazquez et al. "Advances and Trends", [3] Kouro et al.

Modelagem da máquina e do conversor três-níveis: para o modelo da máquina, a referência canônica é Krause, Wasynczuk, Sudhoff & Pekarek — Analysis of Electric Machinery and Drive Systems (IEEE Press/Wiley), que tem o tratamento de referencial dq e os capítulos de PMSM/relutância. Para o NPC três-níveis, [7] Norambuena e [20] Geyer/Mastellone.

FCS-MPC (teoria): [1] Rodríguez & Cortés (livro), [3] Kouro, [5] Papafotiou, [6] Preindl/Bolognani (PMSM), [8] Holtz, [21] Zhang/Yang (sem fatores de peso), [22] Ahmed (FCS vs deadbeat em PMSM).
GPC (teoria) — adição estratégica: [12] Maciejowski já cobre restrições, mas como seu orientador é o Normey-Rico, vale ancorar a formulação nos livros dele e do Camacho: Camacho & Bordons — Model Predictive Control (Springer) e, sobretudo, Normey-Rico & Camacho — Control of Dead-time Processes (Springer, 2007). Este último sustenta diretamente a sua afirmação na justificativa sobre compensação de atrasos de transporte do hardware digital no preditivo — é o elo teórico que falta citar.

Emulação de carga / P-HIL (modelagem): [14] Meyer (dSPACE, sua principal), [24] Bracker/Dolle (cargas indutivas), [18] Chang et al. (muito pertinente: controle de corrente em malha fechada com feedforward de tensão em emulador de PMSM, que é exatamente o seu amplificador controlado em corrente), [27] Amitkumar (emulador P-HIL para drives de transporte), [28] Vodyakho (emulador de máquina de indução). 

Adições para estabilidade de interface — críticas para carga indutiva: Lauss, Faruque, Schoder, Dufour, Viehweider & Langston — "Characteristics and Design of PHIL Simulations for Electrical Power Systems," IEEE Trans. Ind. Electron. 63(1), 2016, e Ren, Steurer & Baldwin — "Improve the Stability and the Accuracy of PHIL Simulation by Selecting Appropriate Interface Algorithms," IEEE Trans. Ind. Appl. 44(4), 2008.

Geração de código (HDL Coder / HLS): [2] Dorfling/Mouton/Geyer/Karamanakos é FCS-MPC com sphere decoding em FPGA, e [19] Wang/Jiao/Xue é CCS-MPC para PMSM em FPGA — praticamente o seu problema dos dois lados. Adições de método: Corradini, Maksimović, Mattavelli & Zane — Digital Control of High-Frequency Switched-Mode Power Converters (Wiley/IEEE, 2015), com exemplos em VHDL/Verilog e MATLAB; o artigo "Easy and Straightforward FPGA Implementation of MPC Using HDL Coder" (MDPI Electronics, 2025), que é um caso de estudo do seu fluxo (passo de até 32 ns); e a documentação do HDL Coder + o exemplo "FOC of PMSM Using FPGA" da MathWorks.

Hardware — dispositivos e PCB mixed-signal: [15] Cooper (SiC), [16] Kim/Bae/Suh (IGBT vs MOSFET em BLDC), [17] Rashid. Adições para o layout: Ott — Electromagnetic Compatibility Engineering (Wiley, 2009) (tem capítulo de layout mixed-signal e cobre drives + fontes chaveadas), Johnson & Graham — High-Speed Digital Design (Prentice-Hall, 1993), e as application notes de aterramento mixed-signal da Analog Devices.

Uma observação de fundo: a Basys3 é excelente para prototipagem, mas é uma placa de FPGA "nua" — sem front-end analógico de potência. A interface ADC/isolação/gate driver é justamente a sua tarefa de PCB, e o XADC (1 MSPS, 12 bits) pode ser apertado para amostragem simultânea das correntes de fase; avalie ADCs externos de amostragem simultânea já no esquemático da semana 16.


Semana 22: Experimentos GPC nas mesmas condições. Coletar dataset experimental comparável.
Semana 23: Comparação experimental final + verificação contra requisitos MIL-STD-704F / DO-160G mapeados na semana 3.
Semana 24: Consolidar todos os resultados (simulação, HIL, experimental). Escrever capítulo de resultados e discussão.
Semana 25: Escrever conclusão, seção de seleção de componentes/drivers, e revisar a dissertação inteira.
Semana 26: Buffer / revisão final / preparação de defesa. Reserve esta semana — algo sempre escorrega.
