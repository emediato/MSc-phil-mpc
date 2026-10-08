#include <math.h>

// ============================================================================
// Simplified C Block - FCS-MPC / MP-DTC para PMSM (Preindl & Bolognani, 2013)
// Entradas: x1 (Te_ref), x2 (theta_e), x3 (id_med), x4 (iq_med), x5 (omega_e)
// Saídas:   y1 (Vd_opt), y2 (Vq_opt), y3 (Vector_Index)
// ============================================================================

// --- Parâmetros Físicos da Máquina PMSM (Tabela 1 do Artigo) ---
#define RS          0.636         /* Resistência do Estator [Ohm] */
#define LD          0.012         /* Indutância Eixo d [H] (12 mH) */
#define LQ          0.020         /* Indutância Eixo q [H] (20 mH) */
#define LAMBDA_P    0.088         /* Fluxo dos Ímãs Permanentes [Wb] */
#define POLES       5.0           /* Número de Pares de Polos (p = 5) */

// --- Parâmetros do Inversor e Amostragem ---
#define TS          0.0001        /* Tempo de Amostragem Ts = 100 us */
#define VDC         200.0         /* Tensão do Barramento DC [V] */
#define I_RATED     10.0          /* Corrente Nominal/Máxima Ir [A] */

// --- Pesos da Função de Custo (Tabela 1 do Artigo) ---
#define LAMBDA_T    1.0           /* Peso do Rastreamento de Torque (c_T) */
#define LAMBDA_A    0.1           /* Peso da Região de Atração MTPA (c_A) */
#define LAMBDA_L    10000.0       /* Peso das Restrições de Corrente/MTPA (c_L) */

// --- Memória das Tensões Aplicadas no Ciclo Anterior (k-1) ---
static double Vd_prev = 0.0;
static double Vq_prev = 0.0;

// --- Tabela dos 8 Estados de Comutação do Inversor Trifásico (2 níveis) ---
static const double SW_STATES[8][3] = {
    {0, 0, 0}, /* V0 */
    {1, 0, 0}, /* V1 */
    {1, 1, 0}, /* V2 */
    {0, 1, 0}, /* V3 */
    {0, 1, 1}, /* V4 */
    {0, 0, 1}, /* V5 */
    {1, 0, 1}, /* V6 */
    {1, 1, 1}  /* V7 */
};

// --- DECLARAÇÕES DE VARIÁVEIS LOCAIS (Compatibilidade ANSI C / PSIM) ---
double Te_ref, theta_e, id_meas, iq_meas, omega_e;
double id_k, iq_k;
double v_alpha, v_beta, vd_cand, vq_cand;
double id_pred, iq_pred, Te_pred;
double c_T, c_A, c_L1, c_L2, cost;
double min_cost;
double vd_opt, vq_opt;
int best_index, i;
double sa, sb, sc;
double i_mag, cond_mtpa, delta_L;

/* 1. Leitura das Entradas */
Te_ref   = x1; /* Torque de referência [Nm] */
theta_e  = x2; /* Ângulo elétrico do rotor [rad] */
id_meas  = x3; /* Corrente medida id [A] */
iq_meas  = x4; /* Corrente medida iq [A] */
omega_e  = x5; /* Velocidade elétrica [rad/s] */

delta_L = LD - LQ;

/* 2. COMPENSAÇÃO DE ATRASO (Predição de id(k) e iq(k) a partir do estado k-1) */
id_k = id_meas + (TS / LD) * (Vd_prev - RS * id_meas + omega_e * LQ * iq_meas);
iq_k = iq_meas + (TS / LQ) * (Vq_prev - RS * iq_meas - omega_e * LD * id_meas - omega_e * LAMBDA_P);

/* 3. AVALIAÇÃO DO CONJUNTO FINITO DE CONTROLE (FCS) - Loop sobre os 8 Vetores de Tensão */
min_cost   = 1.0e15;
best_index = 0;
vd_opt     = 0.0;
vq_opt     = 0.0;

for (i = 0; i < 8; i++) {
    /* 3.1. Mapeamento das chaves (a, b, c) para tensões alpha-beta */
    sa = SW_STATES[i][0];
    sb = SW_STATES[i][1];
    sc = SW_STATES[i][2];

    v_alpha = (2.0 / 3.0) * VDC * (sa - 0.5 * sb - 0.5 * sc);
    v_beta  = (2.0 / 3.0) * VDC * ((sqrt(3.0) / 2.0) * sb - (sqrt(3.0) / 2.0) * sc);

    /* 3.2. Transformação de Park para o referencial d-q */
    vd_cand =  v_alpha * cos(theta_e) + v_beta * sin(theta_e);
    vq_cand = -v_alpha * sin(theta_e) + v_beta * cos(theta_e);

    /* 3.3. Predição dos Estados no Instante k+1 */
    id_pred = id_k + (TS / LD) * (vd_cand - RS * id_k + omega_e * LQ * iq_k);
    iq_pred = iq_k + (TS / LQ) * (vq_cand - RS * iq_k - omega_e * LD * id_k - omega_e * LAMBDA_P);

    /* 3.4. Predição do Torque Eletromagnético (Equação 2 do Artigo) */
    Te_pred = 1.5 * POLES * (LAMBDA_P * iq_pred + delta_L * id_pred * iq_pred);

    /* 3.5. Cálculo dos Termos da Função de Custo (Seção III-C do Artigo) */
    
    // c_T: Rastreamento de Torque (Eq. 7)
    c_T = (Te_pred - Te_ref) * (Te_pred - Te_ref);

    // c_A: Região de Atração para Trajetória MTPA (Eq. 8)
    c_A = id_pred + (delta_L / LAMBDA_P) * (id_pred * id_pred - iq_pred * iq_pred);
    c_A = c_A * c_A;

    // c_L1: Limitação de Corrente Máxima (Eq. 9)
    i_mag = sqrt(id_pred * id_pred + iq_pred * iq_pred);
    if (i_mag > I_RATED) {
        c_L1 = (I_RATED - i_mag) * (I_RATED - i_mag);
    } else {
        c_L1 = 0.0;
    }

    // c_L2: Restrição da Região Correta da Curva MTPA (Eq. 10)
    cond_mtpa = 2.0 * (delta_L / LAMBDA_P) * id_pred + 1.0;
    if (cond_mtpa > 0.0) {
        c_L2 = cond_mtpa * cond_mtpa;
    } else {
        c_L2 = 0.0;
    }

    // Função de Custo Total (Eq. 11)
    cost = LAMBDA_T * c_T + LAMBDA_A * c_A + LAMBDA_L * (c_L1 + c_L2);

    /* 3.6. Seleção do Vetor de Menor Custo */
    if (cost < min_cost) {
        min_cost   = cost;
        best_index = i;
        vd_opt     = vd_cand;
        vq_opt     = vq_cand;
    }
}

/* 4. Atualização das Memórias para o Próximo Ciclo de Amostragem */
Vd_prev = vd_opt;
Vq_prev = vq_opt;

/* 5. Saídas do Bloco C */
y1 = vd_opt;         /* Tensão vd correspondente ao vetor ótimo */
y2 = vq_opt;         /* Tensão vq correspondente ao vetor ótimo */
y3 = (double)best_index; /* Índice do vetor ótimo selecionado (0 a 7) */
