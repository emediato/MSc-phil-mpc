# matlab

https://www.mathworks.com/help/mcb/gs/foc-pmsm-using-mcb-blocks-fpga-hardware.html

https://www.mathworks.com/help/mcb/gs/examples-supporting-trenz-xilinx-zynq.html

https://www.mathworks.com/help/hdlcoder/ug/run-hdl-workflow-as-a-script.html

mathworks.com/help/hdlcoder/simscape-to-hdl.html

https://www.mathworks.com/help/ecoder/xilinxzynq7000ec/ug/field-oriented-control-of-a-permanent-magnet-synchronous-machine.html
https://www.mathworks.com/help/hdlcoder/ug/field-oriented-control-of-a-permanent-magnet-synchronous-machine.html
https://www.mathworks.com/help/hdlcoder/modeling-hierarchy-and-synchronous-hardware-behavior.html?s_tid=CRUX_lftnav
https://www.mathworks.com/help/mcb/gs/field-oriented-control-pmsm-using-hardware-in-the-loop-hil-simulation.html
https://www.mathworks.com/help/hdlcoder/ug/single-precision-field-oriented-control-pmsm-model.html

https://www.mathworks.com/help/hdlcoder/ug/using-ip-core-generation-from-matlab.html

#### youtube 
FOC https://www.youtube.com/watch?v=rhNmGbd2unQ
FIR Filter https://www.youtube.com/watch?v=Tz9c8cNTlxs
FIR IP Filter https://www.youtube.com/watch?v=yS5MsFkwzyU


#### quadprog
https://www.mathworks.com/help/optim/ug/code-generation-in-quadprog.html
https://web.cecs.pdx.edu/~tymerski/ece452/Qp-quadprog.pdf

https://www.mathworks.com/matlabcentral/answers/512369-how-can-i-use-quadprog-in-simulink

https://www.researchgate.net/post/MPC_based_on_MATLAB_Simulink_In_operation_quadprog_function_is_not_supported_by_external_generated_code_How_to_so_solve
https://www.mathworks.com/matlabcentral/answers/676568-can-vpasolver-work-in-simulink-model

## simulink

https://www.researchgate.net/post/How_to_generate_PWM_signal_for_220_volts_Vin_voltage


# VHDL 
https://github.com/Digilent/Basys3/blob/master/Resources/XDC/Basys3_Master.xdc

article: FPGA-Based HIL Emulation of Power Electronics Circuit Using Device-Level Behavioral Modeling


https://class.ece.iastate.edu/cpre488/resources/VHDL_Common_Mistakes_S2025.pdf

https://www.keysight.com/br/pt/product/EL34243A/dc-electronic-load-dual-input-2x-150v-60a-300w-lan-usb.html



 o HDL Coder não suporta diretamente os blocos do Simscape Electrical Specialized Power Systems (o antigo SimPowerSystems). 
 
 Você não pega um modelo de conversor com aqueles blocos e gera VHDL. O que existe é uma ferramenta intermediária — o Simscape HDL Workflow Advisor — que converte a rede física do Simscape numa representação em espaço de estados (um implementation model em Simulink), e é desse modelo derivado que o HDL Coder gera o VHDL. 
 
 O suporte de FPGA a partir do Simscape Electrical existe desde a release R2018b. Essa conversão para espaço de estados é exatamente o que torna o modelo de conversor sintetizável — e é o que a maioria das pessoas não sabe ao tentar o fluxo pela primeira vez.
Documentação canônica (comece por aqui)


O hub do fluxo é a página "Simscape Hardware-in-the-Loop Workflow" (mathworks.com/help/hdlcoder/simscape-to-hdl.html). 

Ela organiza tudo: depois de gerar o implementation model HDL, você usa o HDL Coder para gerar o código e implantar via HDL Workflow Advisor, e lista os exemplos de aplicação (retificador de meia-onda para Speedgoat, particionamento de rede, ajuste de parâmetros em tempo de execução, e o drive PMSM trifásico por Dynamic Switch Approximation).


O tutorial de entrada é "Generate HDL Code Using the Simscape HDL Workflow Advisor" (mathworks.com/help/simscape/ug/generate-hdl-code-using-the-simscape-hdl-workflow-advisor.html). 

Ele usa um retificador de ponte de onda completa e mostra o ciclo inteiro: o advisor converte o modelo Simscape num implementation model que o HDL Coder consome, com o benefício de aproveitar a modelagem física do Simscape e a reconfigurabilidade e paralelismo do FPGA para simular a implementação HDL em tempo real com HIL. 

Ao final, ele salva o código gerado num arquivo chamado HDL_Subsystem_tc.vhd e gera relatórios de rastreabilidade e de utilização de recursos — este último é o que te dá o consumo de recursos para o seu orçamento de FPGA.


Comandos-chave para achar tudo na sua instalação: sschdladvisor(modelo) abre o advisor do Simscape; sschdl.generateOptimizedModel gera o modelo otimizado; hdladvisor abre o Workflow Advisor de um subsistema; hdlsetup configura o HDL Coder; makehdl gera o código.

