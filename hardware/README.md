## project

https://www.ianjohnston.com/index.php/projects/project-017-electronic-constant-current-dummy-load-v2-0


## SPICE

https://github.com/kicad-spice-library/KiCad-Spice-Library/tree/master/Models
https://github.com/eduardobehr/Kicad-Simulation-library
https://github.com/analogdevicesinc/hdl/tree/main/projects

https://github.com/rastrocchia46/eddy-current-brake-power-module/blob/main/images/Block%20Diagram.png

6n137-1767489
DM74LS245N
Infineon-AN2018-35_EVAL-M1-IM818-A_User_Manual-UM-v01_01-EN
Infineon-CIPOS_Mini_Inverter_module_reference_board_type3_for_3-shunt_resistor-ApplicationNotes-v01_11-EN
Infineon-CIPOS_Mini_Technical_description-ApplicationNotes-v02_50-EN
Infineon-IGCM20F60GA-DS-v02_09-EN

Os componentes eletrônicos identificáveis pelos nomes mostrados são:

6N137 — Optoacoplador de alta velocidade.
DM74LS245N — Transceptor/buffer octal bidirecional TTL.
EVAL-M1-IM818-A — Placa de avaliação da Infineon baseada em módulo inversor CIPOS™ Mini.
IGCM20F60GA — Módulo IPM (Intelligent Power Module) CIPOS™ Mini da Infineon.


IGCM20F60GA

Dual In-Line Intelligent Power Module
3Φ -bridge 600V / 20A
Features
Fully isolated Dual In-Line molded module
 Reverse conducting IGBTs with monolithic body
diode
 Rugged SOI gate driver technology with stability
against transient and negative voltage
 Allowable negative VS potential up to -11V for
signal transmission at VBS=15V
 Integrated bootstrap functionality
 Over current shutdown
 Temperature monitor
 Under-voltage lockout at all channels
 Low side emitter pins accessible for all phase
current monitoring (open emitter)
 Cross-conduction prevention
 All of 6 switches turn off during protection
 Lead-free terminal plating; RoHS compliant


AN2016-12 Application Note
Control Integrated POwer System (CIPOS™)
Inverter IPM Reference Board Type 3 for 3-Shunt Resistor
About this document
Scope and Purpose
The scope of this application note is to describe the product reference board of the CIPOS™ Mini inverter
IPM and the basic requirements for operating the product in a recommended mode. Environmental
conditions were considered in the design of the reference board. The design was tested as described in this
document but not qualified regarding safety requirements or manufacturing and operation over the whole
operating temperature range or lifetime. The boards provided by Infineon are subject to functional testing
only.
Reference boards are not subject to the same procedures as regular products regarding Returned Material
Analysis (RMA), Process Change notification (PCN) and Product Discontinuation (PD). Reference boards are
intended to be used under laboratory conditions by specialists only

6N137
High Speed Optocoupler, Single and Dual, 10 MBd
DESCRIPTION
The 6N137, VO2601, and VO2611 are single channel
10 MBd optocouplers utilizing a high efficient input LED
coupled with an integrated optical photodiode IC detector.
The detector has an open drain NMOS-transistor output,
providing less leakage compared to an open collector
Schottky clamped transistor output. The VO2630, VO2631,
and VO4661 are dual channel 10 MBd optocouplers. For the
single channel type, an enable function on pin 7 allows the
detector to be strobed. The internal shield provides a
guaranteed common mode transient immunity of 5 kV/μs for
the VO2601 and VO2631 and 15 kV/μs for the VO2611 and
VO4661. The use of a 0.1 μF bypass capacitor connected
between pin 5 and 8 is recommended.


AN2018-35 EVAL-M1-IM818-A User Manual
EVAL-M1-IM818-A User Manual
iMOTION™ Modular Application Design Kit
About this document
Scope and purpose
This application note provides an overview of the evaluation board EVAL-M1-IM818-A including its main
features, key data, pin assignments and mechanical dimensions.
EVAL-M1-IM818-A is a complete evaluation board including a 3-phase CIPOS™ Maxi Intelligent Power Module
(IPM) for motor drive application. In combination with control-boards equipped with the M1 20pin interface
connector, like EVAL-M1-101T or EVAL-M1-099M, it features and demonstrates Infineon’s CIPOS™ Maxi IPM
technology for motor drive.
The evaluation board EVAL-M1-IM818-A was developed to support customers during their first steps
designing applications with CIPOS™ Maxi IPM.
CIPOS™ Maxi IPM in this board is IM818-MCC which has three phase inverter with 1200V TRENCHSTOP™
IGBTs and Emitter Controlled diodes are combined with an optimized 6-channel SOI gate driver. It is
Optimized to industrial applications like Ventilation and Air Conditioning


DM74LS245
3-STATE Octal Bus Transceiver
General Description
These octal bus transceivers are designed for asynchronous
two-way communication between data buses. The
control function implementation minimizes external timing
requirements.
The device allows data transmission from the A Bus to the
B Bus or from the B Bus to the A Bus depending upon the
logic level at the direction control (DIR) input. The enable
input (G) can be used to disable the device so that the
buses are effectively isolated.


5CGXFC7D6F31A7N




                FPGA
                  │
        ┌─────────┼─────────┐
        │         │         │
      PWM_U     PWM_V     PWM_W
        │         │         │
        └──── DM74LS245 ────┘
                  │
             6 x 6N137
                  │
           IGCM20F60GA
                  │
        U ─────── Motor
        V ─────── Motor
        W ─────── Motor

Realimentações:
    Corrente ──► ADC
    Temperatura ─► ADC
    Barramento DC ─► ADC
    Fault/VFO ─► FPGA





Cuidados importantes com FPGA
1. Dead Time
Nunca permita que o transistor superior e inferior da mesma fase liguem simultaneamente.
O FPGA deve inserir dead time entre os PWMs complementares.
Valores típicos:

500 ns a 2 µs
ajustado conforme driver e IGBT

Sem dead time ocorre:

shoot-through
destruição do IPM
explosão do barramento DC

O IGCM20F60GA possui proteção contra cross-conduction, mas o projeto não deve depender exclusivamente dela. [infineon.com]

2. Isolação Galvânica
O FPGA deve permanecer isolado do barramento de potência.
Uso recomendado:
Plain TextFPGA │DM74LS245 │6N137 │IPMMostrar mais linhas
Funções:

proteção do FPGA
redução de ruído
aumento da imunidade EMC


3. Monitoramento de Falha
O pino de falha do IPM deve ser conectado ao FPGA.
Quando ocorrer:

sobrecorrente
UVLO
proteção interna

O FPGA deve:
Plain TextFAULT = 1→ Desabilitar PWM→ Abrir contato de potência→ Registrar evento→ Esperar reset manualMostrar mais linhas
O desligamento deve ocorrer em poucos microssegundos.

4. Medição de Corrente
O datasheet informa emissor acessível para monitoramento de corrente. [infineon.com]
Estrutura típica:
Plain TextShunt   │Amplificador   │ADC   │FPGAMostrar mais linhas
O FPGA pode implementar:

proteção instantânea
FOC
controle vetorial
observador sensorless


5. Medição do Barramento DC
Sempre monitorar:
Plain TextVdcMostrar mais linhas
Condições:
Plain TextVdc > limite máximo  → paradaVdc < limite mínimo → paradaMostrar mais linhas
A tensão do barramento entra no FPGA via ADC e divisor resistivo isolado.

Sequência segura de partida
Uma sequência típica é:
Plain Text1. Energizar FPGA2. Energizar fonte auxiliar3. Verificar ADCs4. Verificar sensores5. Verificar comunicação6. Verificar FAULT7. Liberar IPM8. Aplicar PWM mínimo9. Rampa de velocidadeMostrar mais linhas

Plano de testes recomendado
Teste 1 – FPGA isolado
Sem IPM conectado.
Verificar:

frequência PWM
dead time
duty cycle

Instrumentação:

osciloscópio

Resultados esperados:
Plain TextPWM_UPWM_VPWM_W120° elétricossem sobreposiçãoMostrar mais linhas

Teste 2 – FPGA + DM74LS245
Verificar:

atraso de propagação
níveis lógicos

Resultados:
Plain TextEntrada FPGA = Saída DM74LS245Mostrar mais linhas

Teste 3 – FPGA + 6N137
Verificar:

isolamento
integridade dos pulsos

Medições:

largura do pulso
atraso

Os três canais devem apresentar comportamento semelhante.

Teste 4 – IPM sem barramento de potência
Somente alimentação lógica.
Verificar:

enable
fault
UVLO

Não conectar motor.

Teste 5 – Barramento DC reduzido
Utilizar fonte CC limitada em corrente.
Por exemplo:
Plain Text24 V36 V48 VMostrar mais linhas
Nunca iniciar diretamente na tensão nominal.
Verificar:

corrente de repouso
resposta ao PWM
falhas


Teste 6 – Carga resistiva
Antes do motor.
Plain TextU ─ ResistênciaV ─ ResistênciaW ─ ResistênciaMostrar mais linhas
Observar:

forma de onda
simetria
aquecimento


Teste 7 – Motor desacoplado
Motor sem carga mecânica.
Monitorar:

corrente RMS
vibração
temperatura

Critério:
Plain Textcorrente baixatemperatura estávelMostrar mais linhas

Teste 8 – Proteção de sobrecorrente
Em laboratório controlado.
Simular:
Plain TextITRIPFAULT``Mostrar mais linhas
Verificar se:
Plain TextFAULT→ PWM OFF→ IPM OFF→ registro no FPGAMostrar mais linhas

Teste 9 – Proteção térmica
Simular elevação da leitura do NTC integrado. O módulo possui NTC para monitoramento térmico. [infineon.com], [manualzz.com]
Verificar:
Plain TextT > limite→ redução torque→ desligamentoMostrar mais linhas

Proteções adicionais recomendadas
Além do que existe no IPM:
Hardware

Fusível ultrarrápido
MOV na entrada
NTC de partida
TVS
EMI filter
Contator de emergência

FPGA

Watchdog
Timeout de ADC
Verificação de encoder
Sobretensão
Subtensão
Sobretemperatura
Sobrecorrente instantânea


Recursos interessantes para implementar no FPGA

SVPWM (Space Vector PWM)
FOC (Field Oriented Control)
Controle V/f
Soft-start
Sensorless observer
Capture de encoder incremental
Registro de falhas em memória
Interface UART/CAN/Ethernet para diagnóstico

Com essa arquitetura, o FPGA fica responsável pela inteligência do sistema, enquanto o IGCM20F60GA executa a comutação de potência com as proteções integradas do módulo. [infineon.com]


