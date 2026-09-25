#include <math.h>

// Parâmetros do PMSM (Baseado na imagem do PSIM)
#define RS        1.3        // Resistência do estator (Ohms)
#define LD        0.0089     // Indutância eixo d (H)
#define LQ        0.0089     // Indutância eixo q (H)
#define TS        1.0e-4     // Período de amostragem (s)
#define LAMBDA_PM 0.0909     // Fluxo dos ímãs (Wb) - Calculado anteriormente

// --- Atribuição das Entradas (Variáveis nativas do PSIM) ---
double ia      = x1; // Entrada 1: ia (A)
double ib      = x2; // Entrada 2: ib (A)
double ic      = x3; // Entrada 3: ic (A)
double id_ref  = x4; // Entrada 4: id_ref (A) - Geralmente 0
double iq_ref  = x5; // Entrada 5: iq_ref (A) - Corrente de torque
double theta   = x6; // Entrada 6: Ângulo elétrico (rad)
double omega_e = x7; // Entrada 7: Velocidade elétrica (rad/s)

// 1. Transformada de Clarke (abc -> alpha/beta)
// O eixo alpha é alinhado com a Fase A
double i_alpha = ia;
double i_beta  = (ib - ic) / 1.732050807568877; // (ib - ic) / sqrt(3)

// 2. Transformada de Park (alpha/beta -> dq)
// Alinhamento padrão: eixo d com o eixo do ímã
double sin_theta = sin(theta);
double cos_theta = cos(theta);

double id_meas =  i_alpha * cos_theta + i_beta * sin_theta;
double iq_meas = -i_alpha * sin_theta + i_beta * cos_theta;

// 3. Controle Deadbeat em dq (Cálculo das tensões de referência)
// Equação: v*(k) = R*i(k) + (L/Ts)*(i*(k+1) - i(k)) + Termos de Desacoplamento + Back-EMF
// Para Ld = Lq = Ls, os termos de desacoplamento são simplificados.

double vd_req = RS * id_meas + (LD / TS) * (id_ref - id_meas) - omega_e * LQ * iq_meas;

double vq_req = RS * iq_meas + (LQ / TS) * (iq_ref - iq_meas) + omega_e * LD * id_meas + omega_e * LAMBDA_PM;

// --- Atribuição das Saídas (Variáveis nativas do PSIM) ---
y1 = vd_req; // Saída 1: Tensão de referência eixo d (V)
y2 = vq_req; // Saída 2: Tensão de referência eixo q (V)

// --- Sinais de Depuração ---
y3 = id_meas; // Corrente medida eixo d
y4 = iq_meas; // Corrente medida eixo q
y5 = id_ref;  // Referência eixo d
y6 = iq_ref;  // Referência eixo q
