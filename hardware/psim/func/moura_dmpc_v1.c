#include <math.h>

#define Ts       1.0e-4     /* tem de coincidir com a taxa dos ZOH */
#define VDC      500.0

/* ================= CONFIGURACAO =================
Replica Moura : MAQ_IPMSM 0, CUSTO_ABS 1, N_VET 7, LAMBDA_U 0.0, BARREIRA_DURA 1, USA_W_MED 1, LAGR_K2 0

Seu caso atual: MAQ_IPMSM 1, CUSTO_ABS 0, N_VET 8, LAMBDA_U 0.03,
                   BARREIRA_DURA 0, USA_W_MED 0, LAGR_K2 0          */


#define MAQ_IPMSM       1
#define MODELO_SALIENTE 1
#define CUSTO_ABS       0
#define N_VET           8
#define BARREIRA_DURA   0
#define USA_W_MED       0
#define LAGR_K2         0

#define LAMBDA_I   1.0
#define LAMBDA_U   0.0 // teste inicial 
#define LAMBDA_IS  0.0
#define W_FIXA     376.99111843077518
/* ============================================================
   Eq. (60) velocidade
   w(k+1)=2w(k)-w(k-1)
   ============================================================ */
static const int Svec[3][8] = {
    {0, 1, 1, 0, 0, 0, 1, 1},
    {0, 0, 1, 1, 1, 0, 0, 1},
    {0, 0, 0, 0, 1, 1, 1, 1}
};

static double valpha_apl = 0.0, vbeta_apl = 0.0;
static double idref_h[3] = {0.0, 0.0, 0.0};
static double iqref_h[3] = {0.0, 0.0, 0.0};
static double Sa_prev = 0.0, Sb_prev = 0.0, Sc_prev = 0.0;
static double w_km1 = 0.0;
static int    init_flag = 0;
/* ============================================================
Eq. (62)
iref(k+2) = 3*iref(k) - 3*iref(k-1) + iref(k-2)
   ============================================================ */
/* ---- Entradas ---- */
double id_ref = x1;
double iq_ref = x2;
double id     = x3;
double iq     = x4;
double thetar = x5;
double w_med  = x6;      /* bloco com 6 entradas; senao use: = W_FIXA; */
double w_med = W_FIXA;

/* ---- Parametros da planta ---- */
double RS, LD_M, LQ_M, PSI_M, IS_MAX;
if (MAQ_IPMSM) {
    RS = 1.3;   LD_M = 8.9e-3;  LQ_M = 17.2e-3; PSI_M = 0.1819; IS_MAX = 20.0;
} else {
    RS = 1.3;   LD_M = 8.9e-3;  LQ_M = 8.9e-3; PSI_M = 0.1819; IS_MAX = 20.0; // tiago com mesmo ld
    //RS = 2.875; LD_M = 8.35e-3; LQ_M = 8.35e-3; PSI_M = 0.175;  IS_MAX = 15.0; // moura
}

/* ---- Indutancias do PREDITOR ---- */
double LD, LQ;
if (MODELO_SALIENTE) {
    LD = LD_M; LQ = LQ_M;
} else {
    LD = 0.5 * (LD_M + LQ_M); LQ = LD;
}

/* ---- Velocidade ---- */
double w_k;
if (USA_W_MED) w_k = w_med;
else           w_k = W_FIXA;

if (!init_flag) {
    idref_h[0] = id_ref; idref_h[1] = id_ref; idref_h[2] = id_ref;
    iqref_h[0] = iq_ref; iqref_h[1] = iq_ref; iqref_h[2] = iq_ref;
    Sa_prev = 0.0; Sb_prev = 0.0; Sc_prev = 0.0;
    w_km1 = w_k;
    init_flag = 1;
}

double w_k1;
if (USA_W_MED) w_k1 = 2.0 * w_k - w_km1;
else           w_k1 = w_k;

/* ---- (1) Referencias ---- */
idref_h[2] = idref_h[1]; idref_h[1] = idref_h[0]; idref_h[0] = id_ref;
iqref_h[2] = iqref_h[1]; iqref_h[1] = iqref_h[0]; iqref_h[0] = iq_ref;

double idref_k2, iqref_k2;
if (LAGR_K2) {
    idref_k2 = 6.0*idref_h[0] - 8.0*idref_h[1] + 3.0*idref_h[2];
    iqref_k2 = 6.0*iqref_h[0] - 8.0*iqref_h[1] + 3.0*iqref_h[2];
} else {
    idref_k2 = 3.0*idref_h[0] - 3.0*idref_h[1] + idref_h[2];
    iqref_k2 = 3.0*iqref_h[0] - 3.0*iqref_h[1] + iqref_h[2];
}

/* ---- (2) Predicao k+1 ---- */
double c = cos(thetar);
double s = sin(thetar);
double vd_k =  c * valpha_apl + s * vbeta_apl;
double vq_k = -s * valpha_apl + c * vbeta_apl;

double ad  = 1.0 - Ts * RS / LD;
double aq  = 1.0 - Ts * RS / LQ;
double bd  = Ts / LD;
double bq  = Ts / LQ;
double kdq = LQ / LD;
double kqd = LD / LQ;
/* ============================================================
EQ. PMSM CONTINUA 
did/dt =(-Rs*id + vd + w*Lq*iq)/Ld

diq/dt = (-Rs*iq - w*Ld*id - w*psiPM + vq)/Lq
   ============================================================ */
double id1 = ad*id + Ts*w_k*kdq*iq + bd*vd_k;
// id1 = id + Ts * (-RS * id + vd_k + w_k * LQ * iq ) / LD;
double iq1 = aq*iq - Ts*w_k*kqd*id - bq*w_k*PSI_M + bq*vq_k;
// iq1 = iq + Ts * ( -RS * iq - w_k * LD * id - w_k * PSI_M + vq_k) / LQ;

/* ---- (3) Varredura ---- */
double thetar_k1 = thetar + w_k * Ts;
double c1 = cos(thetar_k1);
double s1 = sin(thetar_k1);

double g_min = 1.0e30;
int    j_opt = 0;
double valpha_opt = 0.0, vbeta_opt = 0.0, iq2_opt = 0.0;

int jj;
for (jj = 0; jj < N_VET; jj++) {
    double Sa_c = (double)Svec[0][jj];
    double Sb_c = (double)Svec[1][jj];
    double Sc_c = (double)Svec[2][jj];

    double va = VDC * (2.0/3.0) * (Sa_c - 0.5*Sb_c - 0.5*Sc_c);
    double vb = VDC * (2.0/3.0) * (0.8660254037844386 * (Sb_c - Sc_c));

    double vd1 =  c1*va + s1*vb;
    double vq1 = -s1*va + c1*vb;

    double id2 = ad*id1 + Ts*w_k1*kdq*iq1 + bd*vd1;
    double iq2 = aq*iq1 - Ts*w_k1*kqd*id1 - bq*w_k1*PSI_M + bq*vq1;

    double err_d = idref_k2 - id2;
    double err_q = iqref_k2 - iq2;
    double cost_i;
    if (CUSTO_ABS) cost_i = LAMBDA_I * (fabs(err_d) + fabs(err_q));
    else           cost_i = LAMBDA_I * (err_d*err_d + err_q*err_q);

    int n_sw = (int)fabs(Sa_c - Sa_prev) + (int)fabs(Sb_c - Sb_prev) + (int)fabs(Sc_c - Sc_prev);
    double cost_u = LAMBDA_U * (double)(n_sw * n_sw);

    double is_mag = sqrt(id2*id2 + iq2*iq2);
    double cost_is = 0.0;

    if (is_mag > IS_MAX) {
        double over = is_mag - IS_MAX;
        if (BARREIRA_DURA) cost_is = 1.0e12 + over;
        else               cost_is = LAMBDA_IS * over * over;
    }

    double gc = cost_i + cost_u + cost_is;
    if (gc < g_min) {
        g_min = gc; j_opt = jj;
        valpha_opt = va; vbeta_opt = vb; iq2_opt = iq2;
    }
}

/* ---- (4) Saidas e memorias ---- */
y1 = (double)Svec[0][j_opt];
y2 = (double)Svec[1][j_opt];
y3 = (double)Svec[2][j_opt];
y4 = (double)j_opt;
y5 = iq2_opt;

valpha_apl = valpha_opt;
vbeta_apl  = vbeta_opt;
Sa_prev = y1; Sb_prev = y2; Sc_prev = y3;
w_km1 = w_k;
