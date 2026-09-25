/*  psim_open_loop_test_no_t.c
 *
 *  Teste de malha aberta da IPMSM — PSIM Simplified C Block.
 *  Versao sem nenhum simbolo de relogio de simulacao, compativel com
 *  SimCoder.
 *
 *  Nenhum controlador. Nenhum PI, nenhum MPC, nenhum integrador de controle.
 *  Aplica uma tensao dq CONSTANTE e deixa a maquina encontrar o seu regime
 *  permanente, que e' previsivel no papel.
 *
 *  Maquina: BUSARELLO et al., IEEE Access v.13, p.89524, 2025, Caso 1.
 *  Rs = 1.3 ohm, Ld = 8.9 mH, Lq = 17.2 mH, lambda = 0.1819 Wb, P = 6.
 *
 *
 *  ** POR QUE ESTA VERSAO EXISTE **
 *
 *  O erro #3006 do SimCoder nao depende do arquivo, e sim do ESQUEMATICO.
 *  Enquanto houver um elemento de hardware target no esquematico -- o bloco
 *  ADC F28335, por exemplo -- o PSIM coloca o projeto inteiro em modo de
 *  geracao de codigo e proibe os simbolos de tempo de simulacao em TODOS os C blocks e blocos
 *  de funcao matematica, mesmo quando voce so' quer simular. Num DSP nao
 *  existe relogio de simulacao, entao o SimCoder nao teria o que gerar.
 *
 *  Sem acesso ao relogio, o bloco nao tem como se agendar sozinho. Quem define a taxa de
 *  execucao passa a ser o esquematico:
 *
 *      COM ZOH nas entradas  -> o bloco roda uma vez por periodo do ZOH
 *      SEM ZOH nas entradas  -> o bloco roda a cada passo de simulacao
 *
 *  O segundo caso quebra qualquer coisa com memoria entre chamadas. Aqui
 *  quebraria a predicao: ela seria feita para um passo de simulacao a
 *  frente e comparada como se fosse um periodo de controle a frente.
 *
 *  Por isso TODAS as quatro entradas precisam de ZOH, todas na mesma
 *  frequencia, igual a 1/p_Ts. A saida out[4] existe para voce conferir que
 *  isso de fato aconteceu -- ver abaixo.
 *
 *
 *  ** INTERFACE: 4 entradas, 5 saidas **
 *
 *    in[0] = id      [A]            out[0] = vd* [V]  -> bloco dq->abc
 *    in[1] = iq      [A]            out[1] = vq* [V]  -> bloco dq->abc
 *    in[2] = w       [rad/s ELET]   out[2] = iq previsto [A]
 *    in[3] = theta   [rad ELET]     out[3] = erro de predicao de iq [A]
 *                                   out[4] = contador de chamadas
 *
 *  Entradas 0 e 1 vem do bloco de conversao abc->dq. Entrada 2 e' velocidade
 *  ELETRICA, o no' depois do ganho de pares de polos, nao Wm_sim. Entrada 3
 *  e' o mesmo theta que alimenta as duas conversoes.
 *
 *  Saidas 0 e 1 vao para o bloco dq->abc e de la' para o modulador, sem
 *  nada no meio.
 *
 *
 *  ** CONFERINDO A TAXA DE EXECUCAO: out[4] **
 *
 *  out[4] e' um contador de chamadas, ou seja, uma rampa de inclinacao
 *  exatamente 1/Ts. Ele e' o unico jeito de medir a taxa por dentro,
 *  ja' que o relogio de simulacao nao esta' disponivel.
 *
 *      com ZOH de 10 kHz, deve marcar 10000 apos 1 s de simulacao
 *
 *  Se marcar muito mais -- 1e6 com passo de 1 us, por exemplo -- o ZOH nao
 *  esta' atuando e o bloco roda a cada passo de simulacao. Confira essa
 *  saida ANTES de olhar qualquer forma de onda de corrente: enquanto ela
 *  estiver errada, nada mais faz sentido.
 *
 *
 *  ** COMO USAR **
 *
 *  Substitua o eixo por uma FONTE DE VELOCIDADE fixa em 209.44 rad/s
 *  mecanicos, que sao 2000 rpm. Sem controlador de corrente nada limita o
 *  torque, e com fonte de torque a maquina acelera ate a FEM encostar no
 *  barramento.
 *
 *  A tensao de regime que produz um dado ponto de operacao sai das Eqs. (1)
 *  e (2) do artigo, com as derivadas zeradas:
 *
 *      vd = Rs*id - w*Lq*iq
 *      vq = Rs*iq + w*Ld*id + w*lambda
 *
 *  Para id = 0 e iq = 14.78 A a w = 628.32 rad/s eletricos, que e' o ponto
 *  da Fig. 17 do artigo com 10 N.m mais o atrito viscoso:
 *
 *      vd = -628.32*0.0172*14.78          = -159.7 V
 *      vq = 1.3*14.78 + 628.32*0.1819     = +133.5 V
 *
 *  Repare que manter id em ZERO custa 160 V no eixo d. Essa tensao nao
 *  produz corrente nenhuma ali: existe so' para cancelar o acoplamento
 *  cruzado -w*Lq*iq. E' o termo de feedforward da Eq. (6) visto de fora, e
 *  vale mais do que a propria FEM.
 *
 *
 *  ** O QUE OBSERVAR **
 *
 *  id e iq devem estabilizar em 0 e 14.78 A, com ripple de comutacao em
 *  torno, dentro de uns 5 % -- o modelo ignora tempo morto e queda nos
 *  semicondutores.
 *
 *      iq certo e id longe de zero    -> Lq errado, ou velocidade eletrica
 *                                        errada por um fator
 *      os dois trocados               -> referencial 90 graus fora,
 *                                        convencao de Park
 *      correntes girando              -> theta nao travado no rotor
 *      correntes divergindo           -> sinal invertido, ou modulador
 *                                        saturando (|v| = 208 V de 250 V)
 *
 *  ia deve ser senoidal de PICO 14.78 A e 100 Hz. Pico, nao eficaz: a
 *  Clarke da Eq. (12) e' invariante em amplitude, entao |i_dq| E' o pico de
 *  fase. O eficaz equivalente vale 10.45 A.
 *
 *  Plote ia e theta juntos: um ciclo de ia tem que caber exatamente em uma
 *  volta de theta, porque com id = 0 vale ia = -iq*sin(theta).
 *
 *  out[2] e out[3] trazem a corrente PREVISTA pelo modelo discreto para
 *  este instante, calculada no instante anterior. Sobreponha out[2] com
 *  in[1]: as curvas devem ficar praticamente em cima uma da outra.
 *
 *  Este e' o teste que valida o MPC antes de existir MPC. O preditivo
 *  inteiro se apoia nessa predicao, e se ela erra nenhum ajuste de funcao
 *  custo conserta. Erro da ordem do ripple e' normal. Erro proporcional a
 *  corrente aponta indutancia errada; proporcional a velocidade aponta
 *  lambda errado ou velocidade na unidade errada.
 */


/*  SECAO A - DECLARACOES
 *  Cole no inicio da area de codigo do Simplified C Block.
 */

/* Parametros da maquina, Caso 1. Precisam ser IDENTICOS aos do bloco da
 * maquina no esquematico: o ensaio compara modelo contra planta.          */
static double p_Rs  = 1.3;          /* [ohm]                               */
static double p_Ld  = 0.0089;       /* [H]                                 */
static double p_Lq  = 0.0172;       /* [H]                                 */
static double p_lam = 0.1819;       /* [Wb]                                */

/* Periodo de amostragem. NAO agenda nada: quem agenda e' o ZOH das
 * entradas. Aqui ele entra so' como coeficiente da predicao, entao precisa
 * casar com a frequencia dos ZOH, senao a predicao erra proporcionalmente. */
static double p_Ts  = 1.0e-4;       /* [s]  100 us = 10 kHz                */

/* Tensao dq aplicada, para id = 0 e iq = 14.78 A a 2000 rpm.              */
static double p_vd  = -159.7;       /* [V]                                 */
static double p_vq  =  133.5;       /* [V]                                 */

/* Partida suave, em NUMERO DE CHAMADAS em vez de segundos, ja' que o
 * relogio de simulacao nao esta' disponivel. A 10 kHz, 500 chamadas sao 50 ms. Sem a rampa, o degrau de 160 V
 * sobre a maquina parada produz um pico de corrente que satura tudo e
 * esconde o regime permanente que se quer medir. Zero desabilita.         */
static double p_nramp = 500.0;

/* Estado */
static int    ini = 0;
static double ncall;                /* contador de chamadas                */
static double vd_out, vq_out;
static double iqp;                  /* iq previsto para AGORA              */
static double iqp_new;              /* iq previsto para a proxima chamada  */
static double iq_err;


/*  SECAO B - CORPO
 *  Executado uma vez por chamada. Com ZOH em todas as entradas, uma chamada
 *  equivale a um periodo de amostragem.
 */

double id, iq, w, th, ramp;

/*  B1. Inicializacao.  */
if (ini == 0) {
    ini = 1;
    ncall = 0.0;
    vd_out = 0.0;  vq_out = 0.0;
    iqp = 0.0;  iqp_new = 0.0;  iq_err = 0.0;
}

ncall = ncall + 1.0;

id = in[0];
iq = in[1];
w  = in[2];
th = in[3];

/*  B2. Erro da predicao feita na chamada anterior.
 *
 *  iqp_new foi calculado na chamada anterior como previsao para AGORA.
 *  Comparar com a medida atual mede o MODELO, nao o controlador.
 */
iqp = iqp_new;
iq_err = iq - iqp;

/*  B3. Rampa de partida, contada em chamadas.  */
if (p_nramp > 0.0 && ncall < p_nramp) {
    ramp = ncall / p_nramp;
} else {
    ramp = 1.0;
}

vd_out = p_vd * ramp;
vq_out = p_vq * ramp;

/*  B4. Predicao para a proxima amostra.
 *
 *  Modelo discreto por Euler progressivo, com indutancias separadas porque
 *  a maquina e' saliente, Lq/Ld = 1.93:
 *
 *      iq[k+1] = iq + (Ts/Lq) * (vq - Rs*iq - w*Ld*id - w*lambda)
 *
 *  E' a Eq. (1) do artigo discretizada. O mesmo modelo que o MPC usa para
 *  prever, escrito aqui sem nenhuma otimizacao em volta: se acerta neste
 *  ensaio, acerta no MPC.
 *
 *  A tensao usada e' a que esta' sendo aplicada agora, que e' a hipotese do
 *  modelo de Euler -- tensao constante ao longo do intervalo. Com modulador
 *  a hipotese vale para o valor medio no periodo.
 */
iqp_new = iq + (p_Ts / p_Lq) * (vq_out - p_Rs * iq - w * p_Ld * id
                                        - w * p_lam);

/*  B5. Saidas.  */
out[0] = vd_out;
out[1] = vq_out;
out[2] = iqp;
out[3] = iq_err;
out[4] = ncall;
