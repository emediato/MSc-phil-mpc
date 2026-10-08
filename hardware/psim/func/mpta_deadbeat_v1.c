#include <math.h>

// ============================================================================
// Simplified C Block - Deadbeat MPC de 2 Passos (Horizonte k+2) com MTPA
// Entradas: x1 (Não usada/id_ext), x2 (iq_ref), x3 (id_med), x4 (iq_med)
// Saídas:   y1 (Vdref), y2 (Vqref)
// ============================================================================

// --- Parâmetros Físicos do Motor (IPMSM) ---
static const double Rs       = 1.3;          // Resistência estatórica (Ohms)
static const double Ld       = 8.9e-3;       // Indutância eixo d (H)
static const double Lq       = 17.2e-3;      // Indutância eixo q (H)
static const double Lambda_p = 0.1819;       // Fluxo dos ímãs (Wb)

// --- Tempo de Amostragem ---
static const double Ts       = 0.0001;       // Ts = 1/10000 s (100 us)

// --- Velocidade Elétrica Fixa (1200 RPM) ---
static const double omega_e  = 376.99111843077518; // rad/s

// --- Memória das Tensões Calculadas no Ciclo Anterior (Atuais no PWM) ---
static double Vd_k = 0.0;
static double Vq_k = 0.0;

// --- Declaração de Variáveis Locais (Padrão ANSI C / SimCoder) ---
double iq_ref;
double id_ref;
double id_k1;
double iq_k1;
double DeltaL;
double A;

// ----------------------------------------------------------------------------
// PASSO 0: Cálculo do MTPA (Maximum Torque Per Ampere)
// ----------------------------------------------------------------------------
iq_ref = x2;
DeltaL = Lq - Ld;

/* Para motores com relutância (Lq > Ld), calcula a corrente id negativa ótima */
if (DeltaL > 1.0e-6) {
    A = Lambda_p / (2.0 * DeltaL);
    id_ref = A - sqrt(A * A + iq_ref * iq_ref);
} else {
    id_ref = 0.0; /* Caso Lq == Ld (Motor de ímãs de superfície / SPM) */
}

// ----------------------------------------------------------------------------
// PASSO 1: Predição do Estado no Instante k+1
// Usa as medições atuais x3=id(k), x4=iq(k) e as tensões Vd_k, Vq_k ativas no PWM
// ----------------------------------------------------------------------------
id_k1 = x3 + (Ts / Ld) * (Vd_k - Rs * x3 + omega_e * Lq * x4);
iq_k1 = x4 + (Ts / Lq) * (Vq_k - Rs * x4 - omega_e * Ld * x3 - omega_e * Lambda_p);

// ----------------------------------------------------------------------------
// PASSO 2: Cálculo da Tensão a ser Aplicada no Instante k+1 para atingir a Ref em k+2
// ----------------------------------------------------------------------------
y1 = Rs * id_k1 - omega_e * Lq * iq_k1 + (Ld / Ts) * (id_ref - id_k1);
y2 = Rs * iq_k1 + omega_e * Ld * id_k1 + omega_e * Lambda_p + (Lq / Ts) * (iq_ref - iq_k1);

// ----------------------------------------------------------------------------
// PASSO 3: Atualização das variáveis de memória para o próximo ciclo de amostragem
// ----------------------------------------------------------------------------
Vd_k = y1;
Vq_k = y2;
