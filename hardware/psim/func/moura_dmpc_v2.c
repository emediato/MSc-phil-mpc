#include <math.h>

/* ============================================================
   DMPC PMSM/IPMSM
   Implementacao para PSIM Simplified C

   Base:
   - Moura (DMPC)
   - Predicao k+2
   - Euler Forward
   - Funcao custo L1

   Adaptacao:
   - IPMSM (Ld != Lq)

   ============================================================ */

#define Ts      1.0e-4
#define VDC     500.0

#define RS      1.3
#define LD      8.9e-3
#define LQ      17.2e-3
#define PSI_PM  0.1819

#define POLES   4.0

#define IS_MAX  20.0

/* ------------------------------------------------------------
   Vetores do inversor
   ------------------------------------------------------------ */

static const int Svec[3][8] =
{
    {0,1,1,0,0,0,1,1},
    {0,0,1,1,1,0,0,1},
    {0,0,0,0,1,1,1,1}
};

/* ------------------------------------------------------------
   Variaveis persistentes
   ------------------------------------------------------------ */

static double valpha_apl = 0.0;
static double vbeta_apl  = 0.0;

static double idref_h[3] = {0.0,0.0,0.0};
static double iqref_h[3] = {0.0,0.0,0.0};

static double w_km1 = 0.0;

static int init_flag = 0;

/* ============================================================
   ENTRADAS
   ============================================================ */

double id_ref = x1;
double iq_ref = x2;

double id     = x3;
double iq     = x4;

double theta  = x5;
double w_k    = x6;

/* ============================================================
   INICIALIZACAO
   ============================================================ */

if(!init_flag)
{
    idref_h[0] = id_ref;
    idref_h[1] = id_ref;
    idref_h[2] = id_ref;

    iqref_h[0] = iq_ref;
    iqref_h[1] = iq_ref;
    iqref_h[2] = iq_ref;

    w_km1 = w_k;

    init_flag = 1;
}

/* ============================================================
   Eq. (60)

   w(k+1)=2w(k)-w(k-1)

   ============================================================ */

double w_k1 =
2.0*w_k
-
w_km1;

/* ============================================================
   Historico referencias
   ============================================================ */

idref_h[2] = idref_h[1];
idref_h[1] = idref_h[0];
idref_h[0] = id_ref;

iqref_h[2] = iqref_h[1];
iqref_h[1] = iqref_h[0];
iqref_h[0] = iq_ref;

/* ============================================================
   Eq. (62)

   iref(k+2)
   =
   3iref(k)
   -
   3iref(k-1)
   +
   iref(k-2)

   ============================================================ */

double idref_k2 =
3.0*idref_h[0]
-
3.0*idref_h[1]
+
idref_h[2];

double iqref_k2 =
3.0*iqref_h[0]
-
3.0*iqref_h[1]
+
iqref_h[2];

/* ============================================================
   Tensao aplicada no periodo anterior

   abc -> dq

   ============================================================ */

double c0 = cos(theta);
double s0 = sin(theta);

double vd_k =
 c0*valpha_apl
+
 s0*vbeta_apl;

double vq_k =
-c0*0.0
-s0*valpha_apl
+
c0*vbeta_apl;

/* ============================================================
   Eq. PMSM

   did/dt =
   (-Rs*id + vd + wLq iq)/Ld

   diq/dt =
   (-Rs*iq - wLd id - wPsi + vq)/Lq

   Predicao k+1

   ============================================================ */

double id1 =
id
+
Ts*
(
   -RS*id
   +
   vd_k
   +
   w_k*LQ*iq
)
/
LD;

double iq1 =
iq
+
Ts*
(
   -RS*iq
   -
   w_k*LD*id
   -
   w_k*PSI_PM
   +
   vq_k
)
/
LQ;

/* ============================================================
   Angulo futuro

   theta(k+1)

   ============================================================ */

double theta1 =
theta
+
w_k*Ts;

double c1 = cos(theta1);
double s1 = sin(theta1);

/* ============================================================
   Busca exaustiva dos vetores

   ============================================================ */

double g_min = 1.0e30;

int j_opt = 0;

double Te_opt = 0.0;

int j;

for(j=0;j<8;j++)
{
   double Sa = (double)Svec[0][j];
   double Sb = (double)Svec[1][j];
   double Sc = (double)Svec[2][j];

   /* ---------------------------------------------------------
      Vetor alpha-beta
      --------------------------------------------------------- */

   double valpha =
      (2.0/3.0)
      *
      VDC
      *
      (
      Sa
      -
      0.5*Sb
      -
      0.5*Sc
      );

   double vbeta =
      (2.0/3.0)
      *
      VDC
      *
      0.86602540378
      *
      (
      Sb
      -
      Sc
      );

   /* ---------------------------------------------------------
      dq(k+1)
      --------------------------------------------------------- */

   double vd1 =
      c1*valpha
      +
      s1*vbeta;

   double vq1 =
     -s1*valpha
      +
      c1*vbeta;

   /* =========================================================
      Eq. (56) e Eq. (57)

      Predicao k+2

      ========================================================= */

   double id2 =
      id1
      +
      Ts*
      (
        -RS*id1
        +
        vd1
        +
        w_k1*LQ*iq1
      )
      /
      LD;

   double iq2 =
      iq1
      +
      Ts*
      (
        -RS*iq1
        -
        w_k1*LD*id1
        -
        w_k1*PSI_PM
        +
        vq1
      )
      /
      LQ;

   /* =========================================================
      Torque IPMSM

      Te=
      3/2 p
      (
        Psi iq
        +
        (Ld-Lq)id iq
      )
      ========================================================= */

   double Te_pred =
      1.5
      *
      POLES
      *
      (
         PSI_PM*iq2
         +
         (LD-LQ)*id2*iq2
      );

   /* =========================================================
      Erros

      ========================================================= */

   double err_d =
      idref_k2
      -
      id2;

   double err_q =
      iqref_k2
      -
      iq2;

   /* =========================================================
      Eq. (61)

      gc=|ed|+|eq|

      ========================================================= */

   double cost_i =
      fabs(err_d)
      +
      fabs(err_q);

   /* =========================================================
      Restricao corrente

      is=sqrt(id²+iq²)

      ========================================================= */

   double is_mag =
      sqrt
      (
         id2*id2
         +
         iq2*iq2
      );

   double cost_limit = 0.0;

   if(is_mag > IS_MAX)
   {
      cost_limit =
      1e12;
   }

   double gc =
   cost_i
   +
   cost_limit;

   if(gc < g_min)
   {
      g_min = gc;

      j_opt = j;

      Te_opt = Te_pred;

      valpha_apl = valpha;
      vbeta_apl  = vbeta;
   }
}

/* ============================================================
   SAIDAS
   ============================================================ */

y1 = (double)Svec[0][j_opt];
y2 = (double)Svec[1][j_opt];
y3 = (double)Svec[2][j_opt];

y4 = (double)j_opt;

y5 = Te_opt;

/* ============================================================
   Atualizacao memorias

   ============================================================ */

w_km1 = w_k;
