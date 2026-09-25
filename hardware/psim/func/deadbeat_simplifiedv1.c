#include <math.h>

// Parâmetros do PMSM (Baseado na imagem do PSIM)
#define RS       1.3        // Resistência do estator (Ohms)
#define LS       0.0089     // Indutância do estator (Henries) - Ld = Lq = 8.9mH
#define TS       1.0e-4     // Período de amostragem (s) -> 10 kHz
#define LAMBDA_PM 0.0909    // Fluxo dos ímãs permanentes (Wb) - Calculado abaixo

// --- Atribuição das Entradas (Variáveis nativas do PSIM) ---
double ia     = x1; // Entrada 1: Ia (A)
double ib     = x2; // Entrada 2: Ib (A)
double ic     = x3; // Entrada 3: Ic (A)
double Iq_ref = x4; // Entrada 4: Iq_ref (A) - Corrente de torque desejada
double Vdc    = x5; // Entrada 5: Tensão do barramento CC (V)
double theta  = x6; // Entrada 6: Ângulo elétrico do rotor (rad) [0 a 2*PI]
double omega_e= x7; // Entrada 7: Velocidade angular elétrica (rad/s) -> NOVO! Necessário para back-EMF

// 1. Transformada de Clarke (abc -> alpha/beta)
double i_alpha = ia;
double i_beta  = (ib - ic) / 1.732050807568877; // (ib - ic) / sqrt(3)

// 2. Correntes de referência sincronizadas com o eixo q (torque)
// Para PMSM, a referência de torque é alinhada com o eixo q (theta + 90 graus)
double i_alpha_ref = -Iq_ref * sin(theta); 
double i_beta_ref  =  Iq_ref * cos(theta);

// 3. Cálculo da Back-EMF (Força Contra-Eletromotriz)
// e_alpha = -lambda_pm * omega_e * sin(theta)
// e_beta  =  lambda_pm * omega_e * cos(theta)
double e_alpha = -LAMBDA_PM * omega_e * sin(theta);
double e_beta  =  LAMBDA_PM * omega_e * cos(theta);

// 4. Modelo Preditivo Deadbeat com Compensação de Back-EMF
// v*(k) = R*i(k) + (L/Ts)*(i*(k+1) - i(k)) + e(k)
double v_alpha_req = RS * i_alpha + (LS / TS) * (i_alpha_ref - i_alpha) + e_alpha;
double v_beta_req  = RS * i_beta  + (LS / TS) * (i_beta_ref  - i_beta)  + e_beta;

// 5. Transformada de Clarke Inversa (alpha/beta -> abc)
double va_req = v_alpha_req;
double vb_req = -0.5 * v_alpha_req + 0.8660254037844386 * v_beta_req;
double vc_req = -0.5 * v_alpha_req - 0.8660254037844386 * v_beta_req;

// 6. Conversão para Duty Cycle [0, 1] (Modulação Senoidal Pura - SPWM)
if (Vdc <= 0.0) Vdc = 1.0; // Proteção contra divisão por zero

double da = 0.5 + (va_req / Vdc);
double db = 0.5 + (vb_req / Vdc);
double dc = 0.5 + (vc_req / Vdc);

// Saturação de segurança entre 0 e 1
if (da > 1.0) da = 1.0; else if (da < 0.0) da = 0.0;
if (db > 1.0) db = 1.0; else if (db < 0.0) db = 0.0;
if (dc > 1.0) dc = 1.0; else if (dc < 0.0) dc = 0.0;

// --- Atribuição das Saídas (Variáveis nativas do PSIM) ---
y1 = da; // Saída 1: Duty Cycle Fase A
y2 = db; // Saída 2: Duty Cycle Fase B
y3 = dc; // Saída 3: Duty Cycle Fase C

// --- Sinais de Depuração no Plano Alfa/Beta ---
y4 = i_alpha;
y5 = i_alpha_ref;
y6 = i_beta;
y7 = i_beta_ref;
