/*********************************************************************************
// This code is created by SimCoder Version 2024b12.251 for F2833x Hardware Target
//
// SimCoder is copyright by Powersim Inc., 2009-2021
//
// Date: November 19, 2026 12:36:27
**********************************************************************************/
#include	<math.h>
#include	"PS_bios.h"
typedef float DefaultType;
#define	GetCurTime() PS_GetSysTimer()
#define iif(a, b, c) ((a) ? (b) : (c))
#define	PWM_IN_CHECK	// To lower PWM value setting time, comment out this line if PWM duty cycle values are strictly limited in the range.






interrupt void Task();
interrupt void Task_1();


const Uint16 PSD_CpuClock = 150;  // MHz
extern	DefaultType	fGblglobal_id;
extern	DefaultType	fGblglobal_theta;
extern	DefaultType	fGblglobal_wm;
extern	DefaultType	fGblglobal_iq;
extern	DefaultType	fGblWm_ref;
extern	DefaultType	fGblP71;
extern	DefaultType	fGblSUM1;
extern	DefaultType	fGblId;
extern	DefaultType	fGblIq;
extern	DefaultType	fGblId_ref;
extern	DefaultType	fGblP60;
extern	DefaultType	fGblIq_ref;
extern	DefaultType	fGblV156;
extern	DefaultType	fGblV152;
extern	DefaultType	fGblV153;
extern	DefaultType	fGblV155;
extern	DefaultType	fGblValpha;
extern	DefaultType	fGblVbeta;

void FSetValCANAL_A();
void FSetValCANAL_B();
void FSetValCANAL_C();
void FSpiCmdSend0();

#define PS_AskDelayClk(delay, clkSpd) (((Uint32)(delay) + (Uint32)(500 / (clkSpd))) * 150 / 1000)
#define Csz_SPI_QUEUE		32	// SPI queue buffer size
#define Csz_SPI_DEVICES		1	// the number of all SPI devices
#define Cn_CANAL_A	0	// the index of sending command in PSA_SpiSendCmd.
#define SeqCn_CANAL_A	0	// the index of sending command in PSA_SpiInOut.
#define Cn_CANAL_B	1	// the index of sending command in PSA_SpiSendCmd.
#define SeqCn_CANAL_B	1	// the index of sending command in PSA_SpiInOut.
#define Cn_CANAL_C	2	// the index of sending command in PSA_SpiSendCmd.
#define SeqCn_CANAL_C	2	// the index of sending command in PSA_SpiInOut.

Uint16 PSA_SpiSendCmd[3] = {
	0x8000,		/* Cn_CANAL_A*/
	0xF9000,		/* Cn_CANAL_B*/
	0xA000 		/* Cn_CANAL_C*/
};

Uint16 PSA_SpiBBR[Csz_SPI_DEVICES * 2];
const PST_SpiDev PSA_SpiDev[Csz_SPI_DEVICES] = {
	{0, 20000, 2, (Uint16)PS_AskDelayClk(0, 20), &PSA_SpiBBR[0], NULL, NULL}};

const PST_SpiIo PSA_SpiInOut[] = {
	{{1, 0, 0, 0, 0}, &PSA_SpiSendCmd[Cn_CANAL_A],
		NULL, NULL, FSetValCANAL_A, 0},
	{{1, 0, 0, 0, 0}, &PSA_SpiSendCmd[Cn_CANAL_B],
		NULL, NULL, FSetValCANAL_B, 0},
	{{1, 0, 0, 0, 0}, &PSA_SpiSendCmd[Cn_CANAL_C],
		NULL, NULL, FSetValCANAL_C, 0}};

Uint16 PSA_SpiQueue[Csz_SPI_QUEUE];	// SPI queue buffer







DefaultType	fGblglobal_id = 0;
DefaultType	fGblglobal_theta = 0;
DefaultType	fGblglobal_wm = 0;
DefaultType	fGblglobal_iq = 0;
PST_Data	fGblCANAL_A;
PST_Data	fGblCANAL_B;
PST_Data	fGblCANAL_C;
DefaultType	fGblWm_ref = 0;
DefaultType	fGblP71 = 0;
DefaultType	fGblSUM1 = 0;
DefaultType	fGblId = 0;
DefaultType	fGblIq = 0;
DefaultType	fGblId_ref = 0;
DefaultType	fGblP60 = 0;
DefaultType	fGblIq_ref = 0;
DefaultType	fGblV156 = 0;
DefaultType	fGblV152 = 0;
DefaultType	fGblV153 = 0;
DefaultType	fGblV155 = 0;
DefaultType	fGblValpha = 0;
DefaultType	fGblVbeta = 0;
interrupt void Task()
{
	DefaultType	fSUMP13, fC7, fP10, fZOH3, fSUMP11, fC1, fP1, fZOH1, fSUMP12;
	DefaultType	fC2, fP9, fZOH2;

	PS_MaskIntr(M__INT13);

	fZOH2 = fGblSUM1;
	fP9 = fZOH2 * (1.0/5.0);
	fC2 = 0;
	fSUMP12 = fP9 + fC2;
	{
		int32 _val = (int32)(fSUMP12 * (1 * 4096 / 3.3));
		_val = (_val < 0) ? 0 : ((_val >= 4096) ? 4096 - 1 : (Uint32)_val);
		fGblCANAL_A.dataInt32 = (Uint32)_val;
	}
	fZOH1 = fGblP71;
	fP1 = fZOH1;
	fC1 = 1.5;
	fSUMP11 = fP1 + fC1;
	{
		int32 _val = (int32)(fSUMP11 * (1 * 4096 / 3.3));
		_val = (_val < 0) ? 0 : ((_val >= 4096) ? 4096 - 1 : (Uint32)_val);
		fGblCANAL_B.dataInt32 = (Uint32)_val;
	}
	fZOH3 = fGblP60;
	fP10 = fZOH3;
	fC7 = 1.5;
	fSUMP13 = fP10 + fC7;
	{
		int32 _val = (int32)(fSUMP13 * (1 * 4096 / 3.3));
		_val = (_val < 0) ? 0 : ((_val >= 4096) ? 4096 - 1 : (Uint32)_val);
		fGblCANAL_C.dataInt32 = (Uint32)_val;
	}
	FSpiCmdSend0();
	PS_ExitTimer1Intr();
}

interrupt void Task_1()
{
	DefaultType	fS5_2, fS5_1, fS5, fSUMP5, fMULT7, fP8, fMULT8, fSUMP4, fMULT6;
	DefaultType	fCOS_R3, fP68, fSUM34, fP73, fMULT39, fP74, fS4, fSUM9, fMULT5;
	DefaultType	fSIN_R3, fP67, fSUM33, fMULT38, fP72, fS3, fSUM8, fLIM4, fP11;
	DefaultType	fS6, fSUM7, fP15, fSUM3, fC3, fZOH26, fADC1, fC57, fSUMP2, fMULT4;
	DefaultType	fSIN_R2, fMULT3, fCOS_R2, fMULT2, fCOS_R1, fSUM32, fP7, fP6;
	DefaultType	fP5, fMULT1, fSIN_R1, fP22, fSUM10, fC12, fZOH7, fADC1_4, fSUM31;
	DefaultType	fP4, fP70, fP21, fSUM6, fC11, fZOH6, fADC1_3, fP3, fP62, fP17;
	DefaultType	fSUM5, fC6, fZOH5, fADC1_2, fP2, fP61, fP16, fSUM4, fC5, fZOH4;
	DefaultType	fADC1_1, fP66, fP63, fP18, fSUM11, fC4, fZOH27, fADC1_5;

	PS_MaskIntr(M__INT3);

	fADC1_5 = PSM_AdcGetValBySoc(5) * (1.0 * 3.0 / 4096); // Get DC value from ADC_A5.
	fADC1_1 = PSM_AdcGetValBySoc(1) * (1.0 * 3.0 / 4096); // Get DC value from ADC_A1.
	fADC1_2 = PSM_AdcGetValBySoc(2) * (1.0 * 3.0 / 4096); // Get DC value from ADC_A2.
	fADC1_3 = PSM_AdcGetValBySoc(3) * (1.0 * 3.0 / 4096); // Get DC value from ADC_A3.
	fADC1_4 = PSM_AdcGetValBySoc(4) * (1.0 * 3.0 / 4096); // Get DC value from ADC_A4.
	fADC1 = PSM_AdcGetValBySoc(0) * (1.0 * 3.0 / 4096); // Get DC value from ADC_A0.
	fZOH27 = fADC1_5;
	fC4 = 1.5;
	fSUM11 = fZOH27 - fC4;
	fP18 = fSUM11 * (5.0/1.5);
	fP63 = fP18 * 100;
	fP66 = fP63 * 0.004777070063694;
#ifdef	_DEBUG
	fGblWm_ref = fP66;
#endif
	fZOH4 = fADC1_1;
	fC5 = 1.5;
	fSUM4 = fZOH4 - fC5;
	fP16 = fSUM4 * (5.0/1.5);
	fP61 = fP16 * 10;
	fP2 = fP61 * (2.0/3.0);
	fZOH5 = fADC1_2;
	fC6 = 1.5;
	fSUM5 = fZOH5 - fC6;
	fP17 = fSUM5 * (5.0/1.5);
	fP62 = fP17 * 10;
	fP3 = fP62 * ((-1)/3.0);
	fZOH6 = fADC1_3;
	fC11 = 1.5;
	fSUM6 = fZOH6 - fC11;
	fP21 = fSUM6 * (5.0/1.5);
	fP70 = fP21 * 10;
	fP4 = fP70 * ((-1)/3.0);
	fSUM31 = fP2 * 1 + fP3 * 1 + fP4 * 1;
	fZOH7 = fADC1_4;
	fC12 = 1.5;
	fSUM10 = fZOH7 - fC12;
	fP22 = fSUM10 * (5.0/1.5);
	fGblP71 = fP22 * 20;
	fSIN_R1 = sin(fGblP71);
	fMULT1 = fSUM31 * fSIN_R1;
	fP5 = fP61 * 0;
	fP6 = fP62 * (1.0/sqrt(3.0));
	fP7 = fP70 * (-1)/sqrt(3.0);
	fSUM32 = fP5 * 1 + fP6 * 1 + fP7 * 1;
	fCOS_R1 = cos(fGblP71);
	fMULT2 = fSUM32 * fCOS_R1;
	fGblSUM1 = fMULT1 - fMULT2;
#ifdef	_DEBUG
	fGblId = fGblSUM1;
#endif
	fCOS_R2 = cos(fGblP71);
	fMULT3 = fSUM31 * fCOS_R2;
	fSIN_R2 = sin(fGblP71);
	fMULT4 = fSUM32 * fSIN_R2;
	fSUMP2 = fMULT3 + fMULT4;
#ifdef	_DEBUG
	fGblIq = fSUMP2;
#endif
	fC57 = 0;
#ifdef	_DEBUG
	fGblId_ref = fC57;
#endif
	fZOH26 = fADC1;
	fC3 = 1.5;
	fSUM3 = fZOH26 - fC3;
	fP15 = fSUM3 * (5.0/1.5);
	fGblP60 = fP15;
	fSUM7 = fP66 - fGblP60;
	{	// backward Euler
		static DefaultType out_A = 0.0;
		fS6 = out_A + (7.825405487670613/(0.1323*10000)) * fSUM7;
		fS6 = (fS6 < (-1000)) ? (-1000) : ((fS6 > 1000.0) ? 1000.0 : fS6);
		out_A = fS6;
		fS6 += 7.825405487670613 * fSUM7;
		fS6 = (fS6 < (-1000)) ? (-1000) : ((fS6 > 1000.0) ? 1000.0 : fS6);
	}
	fP11 = fS6;
	fLIM4 = (fP11 > 16) ? 16 : ((fP11 < (-16)) ? (-16) : fP11);
#ifdef	_DEBUG
	fGblIq_ref = fLIM4;
#endif
	fSUM8 = fC57 - fGblSUM1;
	{	// backward Euler
		static DefaultType out_A = 0.0;
		fS3 = out_A + (17.8/(0.0068*10000)) * fSUM8;
		fS3 = (fS3 < (-10000)) ? (-10000) : ((fS3 > 10000.0) ? 10000.0 : fS3);
		out_A = fS3;
		fS3 += 17.8 * fSUM8;
		fS3 = (fS3 < (-10000)) ? (-10000) : ((fS3 > 10000.0) ? 10000.0 : fS3);
	}
	fP72 = fSUMP2 * 0.0172;
	fMULT38 = fGblP60 * fP72;
	fSUM33 = fS3 - fMULT38;
	fP67 = fSUM33 * 0.0040;
	fSIN_R3 = sin(fGblP71);
	fMULT5 = fP67 * fSIN_R3;
	fSUM9 = fLIM4 - fSUMP2;
	{	// backward Euler
		static DefaultType out_A = 0.0;
		fS4 = out_A + (34.399999999999999/(0.0132*10000)) * fSUM9;
		fS4 = (fS4 < (-10000)) ? (-10000) : ((fS4 > 10000.0) ? 10000.0 : fS4);
		out_A = fS4;
		fS4 += 34.399999999999999 * fSUM9;
		fS4 = (fS4 < (-10000)) ? (-10000) : ((fS4 > 10000.0) ? 10000.0 : fS4);
	}
	fP74 = fGblSUM1 * 0.0089;
	fMULT39 = fGblP60 * fP74;
	fP73 = fGblP60 * 0.1819;
	fSUM34 = fS4 * 1 + fMULT39 * 1 + fP73 * 1;
	fP68 = fSUM34 * 0.0040;
	fCOS_R3 = cos(fGblP71);
	fMULT6 = fP68 * fCOS_R3;
	fSUMP4 = fMULT5 + fMULT6;
	fMULT8 = fP68 * fSIN_R3;
	fP8 = -fCOS_R3;
	fMULT7 = fP67 * fP8;
	fSUMP5 = fMULT8 + fMULT7;
	{
		DefaultType	a, b, c, vMin, vMax, temp;
		a = fSUMP4 * (1.0/1.7320508); // ab2uvw
		b = (-0.5 / 1.7320508) * fSUMP4 + (0.86602540 / 1.7320508) * fSUMP5;
		c = (-0.5 / 1.7320508) * fSUMP4 - (0.86602540 / 1.7320508) * fSUMP5;
		if (a > b) {
			vMin = b;
			vMax = a;
		} else {
			vMin = a;
			vMax = b;
		}
		if (c > vMax)
			vMax = c;
		if (c < vMin)
			vMin = c;
		temp = vMin + vMax;
		fS5 = 2*a - temp;
		fS5_1 = 2*b - temp;
		fS5_2 = 2*c - temp;
	}
#ifdef	_DEBUG
	fGblV156 = fS5;
#endif

#ifdef	_DEBUG
	fGblV152 = fP67;
#endif
#ifdef	_DEBUG
	fGblV153 = fP68;
#endif
#ifdef	_DEBUG
	fGblV155 = fSUMP4;
#endif
#ifdef	_DEBUG
	fGblValpha = fSUMP4;
#endif
#ifdef	_DEBUG
	fGblVbeta = fSUMP5;
#endif
	fGblglobal_id = fGblSUM1;
	fGblglobal_theta = fGblP71;
	fGblglobal_wm = fGblP60;
	fGblglobal_iq = fSUMP2;
	// Start of changing PWM1(3ph) registers
	// Set Duty Cycle of U
#ifdef PWM_IN_CHECK
	if (fS5 <= (-1)) {
		PWM_CMPA(1) = PWM_TBPRD(1);
	} else if (fS5 >= (2 + (-1))) {
		PWM_CMPA(1) = 0;
	} else {
#else   // PWM_IN_CHECK
	{
#endif
		DefaultType _val = ((2 + (-1)) - fS5) * (1.0/2);
		PWM_CMPA(1) = (int)(PWM_TBPRD(1)* _val);
	}
	// Set Duty Cycle of V
#ifdef PWM_IN_CHECK
	if (fS5_1 <= (-1)) {
		PWM_CMPA(1+1) = PWM_TBPRD(1);
	} else if (fS5_1 >= (2 + (-1))) {
		PWM_CMPA(1+1) = 0;
	} else {
#else   // PWM_IN_CHECK
	{
#endif
		DefaultType _val = ((2 + (-1)) - fS5_1) * (1.0/2);
		PWM_CMPA(1+1) = (int)(PWM_TBPRD(1) * _val);
	}
	// Set Duty Cycle of W
#ifdef PWM_IN_CHECK
	if (fS5_2 <= ((-1))) {
		PWM_CMPA(1+2) = PWM_TBPRD(1);
	} else if (fS5_2 >= (2 + (-1))) {
		PWM_CMPA(1+2) = 0;
	} else {
#else   // PWM_IN_CHECK
	{
#endif
		DefaultType _val = ((2 + (-1)) - fS5_2) * (1.0/2);
		PWM_CMPA(1+2) = (int)(PWM_TBPRD(1) * _val);
	}
	// End of changing PWM1(3ph) registers
	PS_ExitPwmIntr(1, M__INT3);
}

void FSetValCANAL_A()
{
	/* CANAL_A DataBits = 12 */
	PSA_SpiSendCmd[Cn_CANAL_A] &= ~0xfff;
	PSA_SpiSendCmd[Cn_CANAL_A] |= fGblCANAL_A.dataInt32 & 0xfff;
}
void FSetValCANAL_B()
{
	/* CANAL_B DataBits = 12 */
	PSA_SpiSendCmd[Cn_CANAL_B] &= ~0xfff;
	PSA_SpiSendCmd[Cn_CANAL_B] |= fGblCANAL_B.dataInt32 & 0xfff;
}
void FSetValCANAL_C()
{
	/* CANAL_C DataBits = 12 */
	PSA_SpiSendCmd[Cn_CANAL_C] &= ~0xfff;
	PSA_SpiSendCmd[Cn_CANAL_C] |= fGblCANAL_C.dataInt32 & 0xfff;
}
void FSpiCmdSend0()
{
	// send SPI command
	PS_SpiPutQue(SeqCn_CANAL_A);
	PS_SpiPutQue(SeqCn_CANAL_B);
	PS_SpiPutQue(SeqCn_CANAL_C);
}


void Initialize(void)
{
	PS_SysInit(30, 10);
	PS_StartStopPwmClock(0);	// Stop Pwm Clock
	PS_InitTimer(0, 0);
	PS_ResetAdcConvSeq();
	PS_SetAdcConvSeq(eAdcCascade, 0, 0);	// ADC-A0
	PS_SetAdcConvSeq(eAdcCascade, 1, 1);	// ADC-A1
	PS_SetAdcConvSeq(eAdcCascade, 2, 2);	// ADC-A2
	PS_SetAdcConvSeq(eAdcCascade, 3, 3);	// ADC-A3
	PS_SetAdcConvSeq(eAdcCascade, 4, 4);	// ADC-A4
	PS_SetAdcConvSeq(eAdcCascade, 5, 5);	// ADC-A5
	PS_AdcInit(0, !0);

	PS_InitPwm3ph(1, 3, 10000*1, (1.0E-6)*1.e6);	// pwmNo, waveType, frequency, deadtime
	PS_SetPwm3phPeakOffset(1, 2, (-1), 1.0/2);
	PS_SetPwm3ph1AdcIntr(ePwmNoAdc, 1, 0);
	PS_SetPwm3ph1Vector(ePwmNoAdc, Task_1);
	PS_SetPwm3ph1TzAct(eTZHighImpedance);
	PS_SetPwm3ph1UvwSL(0, 0, 0);
	PS_StartPwm3ph1();

	PS_SpiInitBBR(PSA_SpiDev, Csz_SPI_DEVICES);
	PS_SpiInit(PSA_SpiInOut, PSA_SpiQueue, Csz_SPI_QUEUE, 1);

	PS_InitTimer(1,7500L);
	PS_SetTimerIntrVector(1, Task);
	PS_StartStopPwmClock(2);	// Start Pwm Clock, start Timer1
}


void main()
{
	Initialize();
	PS_EnableIntr();   // Enable Global interrupt INTM
	PS_EnableDbgm();
	for (;;) {
		PS_SpiTransmitCheck();
	}
}

