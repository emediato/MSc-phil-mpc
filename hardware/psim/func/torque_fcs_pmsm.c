### Análise Técnica para PMSM
 1. **MTPA (Maximum Torque Per Ampere):**
   * **No seu código atual (L_d = L_q = 20.1\text{ mH}):** O motor é de ímãs superficiais (SPMSM). Como L_d = L_q, a parcela de torque relutante é zero. Para SPMSM, **a condição de MTPA é estritamente $i_d^* = 0$**.
   * **Para motores de ímãs internos (L_d \neq L_q / IPMSM):** Existe torque relutante. O i_d^* ótimo para maximizar o torque por ampère é negativo e calculado por:
     
 2. **Limitação de di/dt:**
   * **Na referência (di_{ref}/dt):** Limita a taxa de variação da corrente comandada entre amostras consecutivas (\Delta I_{max} = (di/dt)_{max} \cdot T_s), evitando sobressinais violentos de corrente.
   * **Na função de custo do FCS-MPC:** Penaliza vetores de tensão que provocam uma variação instantânea \Delta i / T_s superior ao limite desejado, reduzindo o estresse no estator e o ruído acústico.
### Código C Atualizado (PSIM Block)
```c
#include <math.h>

#ifndef TWO_PI
#define TWO_PI 6.283185307179586
#endif

/* --- PARÂMETROS DA MÁQUINA E DO SISTEMA --- */
#define LAMBDA_PM 0.5126f    /* Fluxo dos ímãs [Wb] */
#define TS        1.0e-4f    /* Período de amostragem [s] (10 kHz) */
#define RS        0.5f       /* Resistência do estator [Ohm] */
#define LD        20.1e-3f   /* Indutância d [H] */
#define LQ        20.1e-3f   /* Indutância q [H] */
#define VDC       250.0f     /* Tensão do barramento CC [V] */

/* --- CONSTANTES AUXILIARES --- */
#define SQRT3     1.732050807568877f
#define INV_SQRT3 0.5773502691896258f

/* --- LIMITAÇÕES E PESOS DA FUNÇÃO DE CUSTO --- */
#define LAMBDA_I   1.0f      /* Peso do erro de rastreamento de corrente */
#define LAMBDA_U   1.0f      /* Peso da penalização de chaveamento */
#define LAMBDA_DIDT 0.1f     /* Peso da penalização por excesso de di/dt */
#define DIDT_MAX   50000.0f  /* Limite máximo aceitável de di/dt [A/s] */

/* --- VARIÁVEIS ESTÁTICAS PARA RAMPA DE REFERÊNCIA --- */
static double id_ref_prev = 0.0;
static double iq_ref_prev = 0.0;

/* ============================================================================
 * ENTRADAS DO BLOCO (x1 a x9)
 * ============================================================================ */
double id_meas = x1;   /* Corrente medida no eixo d [A] */
double iq_meas = x2;   /* Corrente medida no eixo q [A] */
double id_in   = x3;   /* Referência de id externa [A] (ignorada se MTPA ativo) */
double iq_in   = x4;   /* Referência de iq desejada [A] */
double omega_e = x5;   /* Velocidade elétrica [rad/s] */
double theta_e = x6;   /* Ângulo elétrico [rad] */
double prevSa  = x7;   /* Estado da chave A no ciclo anterior (0 ou 1) */
double prevSb  = x8;   /* Estado da chave B no ciclo anterior (0 ou 1) */
double prevSc  = x9;   /* Estado da chave C no ciclo anterior (0 ou 1) */

/* ============================================================================
 * VARIÁVEIS LOCAIS
 * ============================================================================ */
double th, cos_th, sin_th;
double best_cost, best_Sa, best_Sb, best_Sc, best_id_pred, best_iq_pred;
double Sa_tab[8] = {0, 0, 0, 0, 1, 1, 1, 1};
double Sb_tab[8] = {0, 0, 1, 1, 0, 0, 1, 1};
double Sc_tab[8] = {0, 1, 0, 1, 0, 1, 0, 1};
int i;
double Sa, Sb, Sc, V_alpha, V_beta, Vd, Vq, id_pred, iq_pred, err_d, err_q, cost;

/* Variáveis para MTPA e Limitação de di/dt */
double id_mtpa, iq_target, id_target;
double max_delta_i, didt_d, didt_q, didt_cost;
double delta_L, L_diff_term;

/* ============================================================================
 * PASSO 1: CÁLCULO DO MTPA (MAXIMUM TORQUE PER AMPERE)
 * ============================================================================ */
iq_target = iq_in;
delta_L = LD - LQ;

if (fabs(delta_L) < 1.0e-6f) {
    /* SPMSM (Ld == Lq): O ponto MTPA é id = 0 */
    id_mtpa = 0.0;
} else {
    /* IPMSM (Ld != Lq): Cálculo da curva de MTPA em função de iq */
    L_diff_term = LAMBDA_PM / (2.0f * delta_L);
    id_mtpa = L_diff_term - sqrt(L_diff_term * L_diff_term + iq_target * iq_target);
}

id_target = id_mtpa;

/* ============================================================================
 * PASSO 2: LIMITAÇÃO DE di/dt NA REFERÊNCIA (RAMP LIMITER)
 * ============================================================================ */
max_delta_i = DIDT_MAX * TS;

/* Aplicação de limite de rampa em id_ref */
if ((id_target - id_ref_prev) > max_delta_i) {
    id_target = id_ref_prev + max_delta_i;
} else if ((id_target - id_ref_prev) < -max_delta_i) {
    id_target = id_ref_prev - max_delta_i;
}

/* Aplicação de limite de rampa em iq_ref */
if ((iq_target - iq_ref_prev) > max_delta_i) {
    iq_target = iq_ref_prev + max_delta_i;
} else if ((iq_target - iq_ref_prev) < -max_delta_i) {
    iq_target = iq_ref_prev - max_delta_i;
}

/* Atualização dos estados anteriores de referência */
id_ref_prev = id_target;
iq_ref_prev = iq_target;

/* ============================================================================
 * PASSO 3: NORMALIZAÇÃO DO ÂNGULO ELÉTRICO
 * ============================================================================ */
th = theta_e;
while (th >= TWO_PI) th -= TWO_PI;
while (th < 0.0)    th += TWO_PI;
cos_th = cos(th);
sin_th = sin(th);

/* ============================================================================
 * PASSO 4: FCS-MPC – AVALIAÇÃO DOS 8 VETORES COM PENALIZAÇÃO DE di/dt
 * ============================================================================ */
best_cost = 1e12;
best_Sa = 0; best_Sb = 0; best_Sc = 0;
best_id_pred = 0; best_iq_pred = 0;

for (i = 0; i < 8; i++) {
    Sa = Sa_tab[i];
    Sb = Sb_tab[i];
    Sc = Sc_tab[i];

    /* Tensões de fase -> Clarke (alpha-beta) */
    V_alpha = VDC * (2.0f / 3.0f) * (Sa - 0.5f * Sb - 0.5f * Sc);
    V_beta  = VDC * INV_SQRT3 * (Sb - Sc);

    /* Clarke -> Park (d-q) */
    Vd =  V_alpha * cos_th + V_beta * sin_th;
    Vq = -V_alpha * sin_th + V_beta * cos_th;

    /* Predição das correntes (Euler) */
    id_pred = id_meas + TS * (Vd - RS * id_meas + omega_e * LQ * iq_meas) / LD;
    iq_pred = iq_meas + TS * (Vq - RS * iq_meas - omega_e * LD * id_meas - omega_e * LAMBDA_PM) / LQ;

    /* Cálculo das taxas instantâneas di/dt decorrentes do vetor avaliado */
    didt_d = (id_pred - id_meas) / TS;
    didt_q = (iq_pred - iq_meas) / TS;

    /* Termo de custo por violação do limite de di/dt */
    didt_cost = 0.0;
    if (fabs(didt_d) > DIDT_MAX) {
        didt_cost += (fabs(didt_d) - DIDT_MAX) * (fabs(didt_d) - DIDT_MAX);
    }
    if (fabs(didt_q) > DIDT_MAX) {
        didt_cost += (fabs(didt_q) - DIDT_MAX) * (fabs(didt_q) - DIDT_MAX);
    }

    /* Função de custo multifuncional */
    err_d = id_target - id_pred;
    err_q = iq_target - iq_pred;

    cost = LAMBDA_I * (err_d * err_d + err_q * err_q)
         + LAMBDA_U * ((Sa - prevSa) * (Sa - prevSa)
                     + (Sb - prevSb) * (Sb - prevSb)
                     + (Sc - prevSc) * (Sc - prevSc))
         + LAMBDA_DIDT * didt_cost;

    if (cost < best_cost) {
        best_cost = cost;
        best_Sa = Sa;
        best_Sb = Sb;
        best_Sc = Sc;
        best_id_pred = id_pred;
        best_iq_pred = iq_pred;
    }
}

/* ============================================================================
 * SAÍDAS DO BLOCO (y1 a y5)
 * ============================================================================ */
y1 = best_Sa;       /* Estado da chave A (0/1) */
y2 = best_Sb;       /* Estado da chave B (0/1) */
y3 = best_Sc;       /* Estado da chave C (0/1) */
y4 = best_id_pred;  /* Corrente id predita [A] */
y5 = best_iq_pred;  /* Corrente iq predita [A] */

```
