//*******************************************************************
//     THIS PROGRAM IS CONFIDENTIAL AND PROPRIETARY TO POWERSIM INC.,
//     AND MAY NOT BE REPRODUCED, PUBLISHED OR DISCLOSED TO OTHERS
//     WITHOUT COMPANY AUTHORIZATION.
//     COPYRIGHT (c) POWERSIM INC. 2006-2014
//     THIS WORK IS UNPUBLISHED.
//*******************************************************************
// Filename: PS_bios.h for F2833x

//#define	SYS_CLOCK	150	// 150MHz
#define	MAX_ADC_VOLT	3.0		// maximum Adc input voltage
#define	NULL	(0)
#ifndef DSP28_DATA_TYPES
#define DSP28_DATA_TYPES
typedef int                int16;
typedef long               int32;
typedef long long          int64;
typedef unsigned int       Uint16;
typedef unsigned long      Uint32;
typedef unsigned long long Uint64;
typedef float              float32;
typedef long double        float64;
#endif
typedef void (*IntrFunc)(void);

extern	const   Uint16	PSD_CpuClock;	// CPu clock, unit: MHz

#define	PSC_SysTimerNS(a)	((Uint32)((a) * PSD_CpuClock * 0.001))
#define	PSC_SysTimerUS(a)	((Uint32)PSD_CpuClock * (a))
#define	PSC_SysTimerMS(a)	(PSD_CpuClock * (1000L * (a)))
#define	PSC_SysTimerSec(a)	(PSD_CpuClock * (1000000L * (Uint32)(a)))
#define PSC_SysToUS(a)		((Uint32)(a) / PSD_CpuClock)

void PS_SysInit(Uint16 nExternClk, Uint16 nPllTimes);

// Timer
void PS_InitTimer(int timerNo, Uint32 interval);
void PS_SetTimerIntrVector(int timerNo, IntrFunc vec);
Uint32 PS_GetSysTimer(void);
unsigned long long PS_GetBigTime(void);

#define	PS_EntryTimer1Intr()
#define	PS_ExitTimer1Intr()
#define	PS_EntryTimer2Intr()
#define	PS_ExitTimer2Intr()

// Encoder
void PS_InitEncoder(int encoderNo, int bIndex, int bStrobe, int bReverse, int bZChgPolarity, int bSChgPolarity, Uint32 nResolution);
void PS_SetEncoderIntrVector(int encoderNo, int bIndex, int bStrobe, int trigEdge, IntrFunc vec);
void PS_EncoderEnableIntr(int encoderNo, int bEnable, int bIndex, int bStrobe);
void PS_InitEncIndexStrobeLatch(int encoderNo, int nIndexStrobeType);
Uint32 PS_EncoderFirstIndexPos(int encoderNo, int resetFlag);
Uint32 PS_EncoderCurIndexPos(int encoderNo, int resetFlag);
Uint32 PS_EncoderStrobePos(int encoderNo);
Uint32 PS_GetEncoder1Count(void);
Uint32 PS_GetEncoder2Count(void);
Uint32 PS_GetEncoder1StrobePos(void);
Uint32 PS_GetEncoder2StrobePos(void);
Uint32 PS_GetEncoder1IndexPos(void);
Uint32 PS_GetEncoder2IndexPos(void);
Uint16 PS_IsEncoder1IntrStrobe(void);
Uint16 PS_IsEncoder1IntrIndex(void);
Uint16 PS_IsEncoder2IntrStrobe(void);
Uint16 PS_IsEncoder2IntrIndex(void);
#define	PS_EntryEncoder0Intr()
#define	PS_EntryEncoder1Intr()
void PS_ExitEncoder1Intr(void);
void PS_ExitEncoder2Intr(void);

// Counter (use same device as encoder)
void PS_InitCounter(int cntNo);
Uint32 PS_GetCounter1Cnt(void);
Uint32 PS_GetCounter2Cnt(void);

// PWM: 3 phrase
typedef	enum {ePwmNoAdc, ePwmTrigAdc, ePwmTrigAdc0, ePwmTrigAdc1, ePwmIntrAdc, ePwmIntrAdc0, ePwmIntrAdc1} PST_PwmAdcAct;
typedef	enum {eTZHighImpedance = 0, eTZForceHigh = 1, eTZForceLow = 2, eTZNoChange = 3, eTzBothHigh = 4, eTzBothLow = 5} PST_PwmTZOut;
typedef enum {eTzAllDisable, eTzDisable, eTzEnOneShot, eTzEnCbc} PST_PwmTzType;
void PS_InitPwm3ph(Uint16 pwmNo, Uint16 carrierType, float frequence, float deadBand);
void PS_SetPwm3ph1AdcIntr( PST_PwmAdcAct nAdcIntr, Uint16 tmIntr, float posTrig);
void PS_SetPwm3ph1TripZone(Uint16 tZoneNo, PST_PwmTzType tzType);
void PS_SetPwm3ph1TzAct(PST_PwmTZOut outType);
#define PS_SetPwm3ph1TZVector(vec) PS_SetPwmTZVector(1, vec)
void PS_SetPwm3ph1UvwSL(float uRate, float vRate, float wRate);
void PS_SetPwm3ph1UvwSH(float uRate, float vRate, float wRate);
void PS_StartPwm3ph1(void);
void PS_StopPwm3ph1(void);
void PS_SetPwm3ph1Vector(PST_PwmAdcAct nAdcIntr, IntrFunc vec);
#define	PS_EntryPwm3ph1Intr()
void PS_ExitPwm3ph1Intr(void);
void PS_ExitPwm3ph1Normal(void);
void PS_ExitPwm3ph1Adc1Trig(void);
void PS_ExitPwm3ph1Adc2Trig(void);
void PS_ExitPwm3ph1Adc1Intr(void);
void PS_ExitPwm3ph1Adc2Intr(void);
void PS_ExitPwm3ph1General(void);
void PS_ExitPwm3ph1TZoneIntr(void);
void PS_ExitPwm3ph1TZoneIntrClrCbc(void);
void PS_ExitPwm3ph1TZoneIntrClrOsht(void);

void PS_SetPwm3ph2AdcIntr( PST_PwmAdcAct nAdcIntr, Uint16 tmIntr, float posTrig);
void PS_SetPwm3ph1TripZone(Uint16 tZoneNo, PST_PwmTzType tzType);
void PS_SetPwm3ph2TzAct(PST_PwmTZOut outType);
#define PS_SetPwm3ph2TZVector(vec) PS_SetPwmTZVector(4, vec)
void PS_SetPwm3phPeakOffset(Uint16 pwmNo, float peakVal, float offsetVal, float reciprocal);
void PS_SetPwm3ph2UvwSL(float uRate, float vRate, float wRate);
void PS_SetPwm3ph2UvwSH(float uRate, float vRate, float wRate);
void PS_StartPwm3ph2(void);
void PS_StopPwm3ph2(void);
void PS_SetPwm3ph2Vector(PST_PwmAdcAct nAdcIntr, IntrFunc vec);
#define	PS_EntryPwm3ph2Intr()
//void PS_ExitInverter1Intr(void);
void PS_ExitPwm3ph2Normal(void);
void PS_ExitPwm3ph2Adc1Trig(void);
void PS_ExitPwm3ph2Adc2Trig(void);
void PS_ExitPwm3ph2Adc1Intr(void);
void PS_ExitPwm3ph2Adc2Intr(void);
void PS_ExitPwm3ph2General(void);
void PS_ExitPwm3ph2TZoneIntr(void);
void PS_ExitPwm3ph2TZoneIntrClrCbc(void);
void PS_ExitPwm3ph2TZoneIntrClrOsht(void);
#define PS_Is3Pwm1OneShotTZ()	PS_IsPwm1OneShotTZ()
#define PS_Is3Pwm2OneShotTZ()	PS_IsPwm4OneShotTZ()


// Single PWM
typedef	enum {PWM_NO_OUTPUT, PWM_POSI_ONLY, PWM_NEGA_ONLY, PWM_TWO_OUT} PST_PwmOutDef;
void PS_InitPwm(Uint16 pwmNo, Uint16 carrierType, float frequence, float deadBand, PST_PwmOutDef outType, Uint16 nUseHrpwm);
void PS_InitPwmPhase(Uint16 pwmNo, float phaseDelay);
void PS_SetPwmTripZone(Uint16 pwmNo, Uint16 tZoneNo, PST_PwmTzType tzType);
void PS_SetPwmTzAct(Uint16 pwmNo, PST_PwmTZOut outType);
void PS_SetPwmTZVector(Uint16 pwmNo, IntrFunc vec);
void PS_SetPwmPeakOffset(Uint16 pwmNo, float peakVal, float offsetVal, float reciprocal);
void PS_SetPwmRateSL(Uint16 index, float rate);
void PS_SetPwmRateSH(Uint16 index, float rate);
#define PS_SetPwm1RateSL(rate) PS_SetPwmRateSL(0, rate)
#define PS_SetPwm1RateSH(rate) PS_SetPwmRateSH(0, rate)
#define PS_SetPwm2RateSL(rate) PS_SetPwmRateSL(1, rate)
#define PS_SetPwm2RateSH(rate) PS_SetPwmRateSH(1, rate)
#define PS_SetPwm3RateSL(rate) PS_SetPwmRateSL(2, rate)
#define PS_SetPwm3RateSH(rate) PS_SetPwmRateSH(2, rate)
#define PS_SetPwm4RateSL(rate) PS_SetPwmRateSL(3, rate)
#define PS_SetPwm4RateSH(rate) PS_SetPwmRateSH(3, rate)
#define PS_SetPwm5RateSL(rate) PS_SetPwmRateSL(4, rate)
#define PS_SetPwm5RateSH(rate) PS_SetPwmRateSH(4, rate)
#define PS_SetPwm6RateSL(rate) PS_SetPwmRateSL(5, rate)
#define PS_SetPwm6RateSH(rate) PS_SetPwmRateSH(5, rate)
void PS_StartPwm(Uint16 pwmNo);
void PS_StopPwm(Uint16 pwmNo);
void PS_SetPwmIntrType(Uint16 pwmNo, PST_PwmAdcAct nAdcIntr, Uint16 tmIntr, float posTrig);
void PS_SetPwmVector(Uint16 pwmNo, PST_PwmAdcAct nAdcIntr, IntrFunc vec);
#define	PS_EntryPwmIntr(pwmNo)
void PS_EnableMasterPhase(Uint16 pwmNo);
void PS_EnableSlavePhase(Uint16 pwmNo, float phaseShifted);
#define	PS_DisablePhaseShift(pwmNo) PS_EnableMasterPhase(Uint16 pwmNo)
#define	PS_PwmSetPhase(pwmNo, phaseShifted) PS_EnableSlavePhase(pwmNo, phaseShifted)

void PS_ExitPwmNormal(Uint16 pwmNo);
void PS_ExitPwmAdc1Trig(Uint16 pwmNo);
void PS_ExitPwmAdc2Trig(Uint16 pwmNo);
void PS_ExitPwmAdc1Intr(void);
void PS_ExitPwmAdc2Intr(void);
void PS_ExitPwmGeneral(Uint16 pwmNo);
void PS_ExitPwm1General(void);
void PS_ExitPwm2General(void);
void PS_ExitPwm3General(void);
void PS_ExitPwm4General(void);
void PS_ExitPwm5General(void);
void PS_ExitPwm6General(void);
void PS_ExitTZoneIntr(void);
void PS_ExitTZoneIntrClrCbc(Uint16 pwmNo);
void PS_ExitTZoneIntrClrOsht(Uint16 pwmNo);
int PS_IsPwm1OneShotTZ(void);
int PS_IsPwm2OneShotTZ(void);
int PS_IsPwm3OneShotTZ(void);
int PS_IsPwm4OneShotTZ(void);
int PS_IsPwm5OneShotTZ(void);
int PS_IsPwm6OneShotTZ(void);

int PS_InitFuncPwm(Uint16 pwmNo, int mode, float frequence);
void PS_SetFuncPwmIntrType(Uint16 pwmNo, PST_PwmAdcAct nAdcIntr, Uint16 tmIntr, Uint16 posTrig);
void PS_SetFuncPwmRate(Uint16 pwmNo, float rateA, float rateB);
void PS_SetFuncPwm1Rate(float rateA, float rateB);
void PS_SetFuncPwm2Rate(float rateA, float rateB);
void PS_SetFuncPwm3Rate(float rateA, float rateB);
void PS_SetFuncPwm4Rate(float rateA, float rateB);
void PS_SetFuncPwm5Rate(float rateA, float rateB);
void PS_SetFuncPwm6Rate(float rateA, float rateB);

// Capture PWM
void PS_InitCapPwm(Uint16 pwmNo, Uint16 pinNo, float frequence, Uint16 stopStatus, Uint16 isStartLow);
void PS_InitCapPwmPhase(Uint16 pwmNo, float phaseDelay);
void PS_SetCapPwmPeakOffset(Uint16 pwmNo, float peakVal, float offsetVal, float reciprocal);
void PS_SetCapPwmIntrVector(int pwmNo, IntrFunc vec);
void PS_SetCapPwmRate(int pwmNo, float rate);
#define PS_SetCapPwm1Rate(rate) PS_SetCapPwmRate(1, rate)
#define PS_SetCapPwm2Rate(rate) PS_SetCapPwmRate(2, rate)
#define PS_SetCapPwm3Rate(rate) PS_SetCapPwmRate(3, rate)
#define PS_SetCapPwm4Rate(rate) PS_SetCapPwmRate(4, rate)
#define PS_SetCapPwm5Rate(rate) PS_SetCapPwmRate(5, rate)
#define PS_SetCapPwm6Rate(rate) PS_SetCapPwmRate(6, rate)
void PS_StartCapPwm(Uint16 pwmNo);
void PS_StopCapPwm(Uint16 pwmNo);
void PS_CapPwmSetPhase(Uint16 pwmNo, float phaseShifted);
void PS_CapPwmTrigSync(int pwmNo);
void PS_CapPwmRun(int pwmNo);

// ADC
typedef enum {eAdcNotUse = 0, eAdc0Intr, eAdc1Intr, eAdcCascade} PST_AdcIntrType;
void PS_ResetAdcConvSeq(void);
void PS_SetAdcConvSeq(PST_AdcIntrType type, Uint16 nChnNo, Uint16 nSocNo);
void PS_AdcInit(Uint16 bTrigerByPwm, Uint16 bContRun);
void PS_SetAdcIntrVector(PST_AdcIntrType type, IntrFunc vec);
int PS_IsAdcGrpAReady(void);
int PS_IsAdcGrpBReady(void);
void PS_WaitAdcGrpAReady(void);
void PS_WaitAdcGrpBReady(void);

#define	PSM_QualGpio0_7		1
#define PSM_QualGpio8_15	2
#define PSM_QualGpio16_23	4
#define PSM_QualGpio24_31	8
#define PSM_QualGpio32_39	16
#define PSM_QualGpio40_47	32
#define PSM_QualGpio48_55	64
#define PSM_QualGpio56_63	128
#define	PSM_QualGpioAll		255
void PS_SetInSigSampleTime(Uint16 nSigGrp, Uint32 nSampleTime);

// Digital Input
// Customer can specify any bit in GPIOA and/or GPIOB as external interrupt source
#define	TELL_GPIO
#ifdef	TELL_GPIO
void PS_SpecifyUsedDin(int16 *pAry);
#endif
void PS_InitDigitIn(Uint16 chnNo, Uint16 tmInSigSteady);
Uint16 PS_SetExtIntrVector(Uint16 chnNo, Uint16 intrNo, int trigerEdge, IntrFunc vec);
Uint16 PS_GetDigitInValue(Uint16 chnNo);
//void PS_SetDinTrigEdge(Uint16 intrNo, int trigerEdge);
Uint32 PS_GetDigitInA(void);
Uint32 PS_GetDigitInB(void);
Uint32 PS_GetDigitInC(void);
void PS_ExitExtIntrFirst2(void);
void PS_ExitExtIntrOther(void);

// Digital Output
#ifdef	TELL_GPIO
void PS_SpecifyUsedDout(int16 *pAry);
#endif
void PS_InitDigitOut(Uint16 chnNo);
void PS_SetDigitOutValue(Uint16 chnNo, Uint16 val);
void PS_SetDigitOutValA(Uint32 val);
void PS_SetDigitOutValB(Uint32 val);
void PS_SetDigitOutValC(Uint32 val);
void PS_ClearDigitOutBitA(Uint32 bit);
void PS_ClearDigitOutBitB(Uint32 bit);
void PS_ClearDigitOutBitC(Uint32 bit);
void PS_SetDigitOutBitA(Uint32 bit);
void PS_SetDigitOutBitB(Uint32 bit);
void PS_SetDigitOutBitC(Uint32 bit);

void PS_StartStopPwmClock(int16 bStart);

// Sci communication
typedef union {
	float		dataFloat;
	Uint32		dataInt32;
} PST_Data;

typedef union {
	Uint16		all;
	struct {
		Uint16		nCount:8;
		Uint16		nSeqNo:8;
	} bit;
} PST_SeqNo;

typedef struct {
	PST_SeqNo	nSeqNo;
	PST_Data	data;
} PST_BufItem;

typedef	void (*PSD_ProcCmd)(PST_BufItem* pItem);

void PS_SciInit(Uint16 sciNo, Uint16 portNo, Uint32 speed, int16 parityBit,
		PST_BufItem* pTxBuf, int szBuf, PSD_ProcCmd	procItem);
void PS_SciSendInitStr(char* sInitStr);
int PS_SciSendItem(PST_BufItem* pItem);
void PS_SciClearSendBuf(void);
int PS_IsTxQueueEmpty(void);

typedef void (*CallSetChipSel)(void);
typedef void (*CallBackCmd)(void);
typedef void (*CallBackSync)(Uint16);
typedef struct {
	Uint16 		nLenCmd:5;
	Uint16		nReserve:8;
	Uint16      bIsInput:1;     // 1: Spi Input Element, 0: Spi Output
	Uint16      bPostRecv:1;    // 1: call post-receving function, 0: call schematic function
	Uint16		bDevSync:1;		// if call hardware synchronize function
} PST_SpiAttr;
typedef union {
	void*			pVoid;
	CallBackCmd		pBack;
	CallBackSync	pPost;
} PST_SpiFunc;

typedef struct {
//	PST_SpiCfg*		pArySpiCfg;
	Uint16			nBitShift;	// bits need to shift left when put a word to SPI TX Buf
									// it equals to 16 - Word Length
	Uint16			nClkFreq;		// SPI clock frequency
	Uint16			nClkCfg;		// clock config, 
	Uint16			nDelayCmd;		// dely in 2 commands, in ns
//	Uint16			nPinNo;			// pin setting data;
	Uint16*			pArySpiBbr;
	CallSetChipSel  pCallSetChipSel;// the address of chip select function
	CallBackSync	pArySyncOut;	// this is only called when data received.
} PST_SpiDev;

typedef	struct {
//	Uint16		nAryOffset;		// offset in both input buffer and output buffer
	PST_SpiAttr	objSpiSet;
	Uint16*		pArySendCmd;
	Uint16*		pAryRecvData;
//	CallBackCmd	CallbackSend;	// should be NULL if sending content is fixed
	PST_SpiFunc	CallbackRecv;	// should be NULL if discard receiving data
	CallBackCmd CallbackMaker;  // make a command or get result from receiving data
	Uint16		nSpiDev;		// Device Configuraton
//	CallBackCmd	CallBackIntr;	// Call interrupt function(not a real interrupt)
} PST_SpiIo;

typedef union {
	float		fVal;
	int32		nVal;
} PST_SpiVal;

//#define	PSC_SpiHwOutSync	32768
//#define	PSC_SpiSendEnd		65535

void PS_SpiInitBBR(const PST_SpiDev* pDev, int devSize);
void PS_SpiInit(const PST_SpiIo* spiIO, Uint16* pAryQueue, Uint16 lenQueue, Uint16 spiGrp);
Uint16 PS_SpiPutQue(Uint16 index);
Uint16 PS_GetCurCmdIndex(void);
void PS_SpiTransmitCheck(void);

#include "stdbool.h"

#define CAN_ERROR	0
#define CAN_SUCCESS	1
/* eCAN Message ID (MSGID) bit definitions */
struct PST_CanMsgID_Bits {        // bits  description
	Uint32 EXTMSGID_L :16;  // 0:15
	Uint32 EXTMSGID_H :2;   // 16:17
	Uint32 STDMSGID :11;    // 18:28
	Uint32 AAM :1;          // 29
	Uint32 AME :1;          // 30
	Uint32 IDE :1;          // 31
};

struct PST_eCanMsgID_Bits {        // bits  description
	Uint32 MsgID :29;    // 0:28
	Uint32 AAM :1;          // 29
	Uint32 AME :1;          // 30
	Uint32 IDE :1;          // 31
};

union PST_CanMsgID_Reg {
	struct PST_eCanMsgID_Bits ebit;
	struct PST_CanMsgID_Bits bit;
	Uint32 all;
};

/* eCAN Message Control Register (MSGCTRL) bit definitions */
struct PST_CanMsgCtrl_Bits {     // bits  description
	Uint32 DLC :4;          // 0:3
	Uint32 RTR :1;          // 4
	Uint32 rsvd1 :3;        // 7:5   reserved
	Uint32 TPL :5;          // 12:8
	Uint32 rsvd2 :3;        // 15:13 reserved
	Uint32 rsvd3 :16;       // 31:16 reserved
};

/* Allow access to the bit fields or entire register */
union PST_CanMsgCtrl_Reg {
	struct PST_CanMsgCtrl_Bits bit;
	Uint32 all;
};

union PST_CanMD_Reg {
	Uint32 MData[2];
	Uint64 MData64;
};

typedef struct {
	union PST_CanMsgID_Reg MSGID;
	union PST_CanMsgCtrl_Reg MSGCTRL;
	union PST_CanMD_Reg MD;
} PST_MBox;

typedef union {
	float fVal;
	int32 nVal;
} PST_Var;

typedef void TProcInCanMsg(PST_MBox* pBox);  //unpack function, provided by PSIM

typedef void TProcCanErr(Uint32 nErr);

typedef struct {
	Uint16 nSrcNo;  // 0: CANA, 1: CANB
	Uint32 nCanSpeed;
	Uint16 nDataOrder;	//0: MSB, 1: LSB
	Uint32 nErrMask;  // 1 means enable the error interrupt
	TProcInCanMsg* funCanMsg;
	TProcCanErr* funCanErr;
} PST_CanCfg;

typedef struct {
	int16 nStartMB;		// Start position of input mailbox for this mask
	Uint16 nNumMB;			// the number of input mailbox with same maskID
	Uint32 nMask;			// local mask
	Uint32 nMaskID;		// maskID
	Uint16 nPriority;		// priority level
	Uint16 nOverride;		// override flag
	bool nExtension;
} PST_CanInCfg;

int16 PS_CanInit(Uint16 RxPin, Uint16 TxPin, PST_CanCfg* pCanData);
int16 PS_CanInMailBoxInit(PST_CanCfg* pCanData, PST_CanInCfg* pCanInCfg);
int16 PS_CanOutMailBoxInit(PST_CanCfg* pCanData, Uint16 numOutMailbox);
int16 PS_CanTx(PST_CanCfg* pCanData, PST_MBox* pBox);

void PS_DelayUs(Uint32 tm);
void PS_DelayMs(Uint32 tm);

// F2833x Registers
#define M__INT1  0x0001
#define M__INT2  0x0002
#define M__INT3  0x0004
#define M__INT4  0x0008
#define M__INT5  0x0010
#define M__INT6  0x0020
#define M__INT7  0x0040
#define M__INT8  0x0080
#define M__INT9  0x0100
#define M__INT10 0x0200
#define M__INT11 0x0400
#define M__INT12 0x0800
#define M__INT13 0x1000
#define M__INT14 0x2000

extern cregister volatile unsigned int IFR;
extern cregister volatile unsigned int IER;

#define  PS_EnableIntr()	asm(" clrc INTM")
#define  PS_DisableIntr()	asm(" setc INTM")
#define  PS_EnableDbgm()	asm(" clrc DBGM")
#define  PS_DisableDbgm()   asm(" setc DBGM")
#define  PS_EALLOW 			asm(" EALLOW")
#define  PS_EDIS   			asm(" EDIS")

inline void PS_MaskIntr(int curIntrLevel)
{
	IER &= (curIntrLevel - 1);
	asm(" nop");
	PS_EnableIntr();
}

#define CPU_PIEACK	(*(Uint16*)0xCE1)

#define ADC_RESULT(socNo) (*((Uint16*)0xB00 + socNo))   // Adc Mirror
inline Uint16 PSM_AdcGetValBySoc(Uint16 socNo)
{
    return ADC_RESULT(socNo);
}

// F2833x PWM registers, pwmNo: 1-6
#define PWM_TBCTL(pwmNo)	(*(Uint16*)((0x6800 - 0x40) + 0x40 * (pwmNo)))
#define PWM_TBPRD(pwmNo)	(*(Uint16*)((0x6805 - 0x40) + 0x40 * (pwmNo)))
#define PWM_CMPAHR(pwmNo)	(*(Uint16*)((0x6808 - 0x40) + 0x40 * (pwmNo)))
#define PWM_CMPA(pwmNo)		(*(Uint16*)((0x6809 - 0x40) + 0x40 * (pwmNo)))
#define PWM_CMPB(pwmNo)		(*(Uint16*)((0x680A - 0x40) + 0x40 * (pwmNo)))
#define PWM_TBPHS(pwmNo)	(*(Uint16*)((0x6803 - 0x40) + 0x40 * (pwmNo)))
#define	PWM_ETCLR(pwmNo)	(*(Uint16*)((0x681c - 0x40) + 0x40 * (pwmNo)))
#define	PWM_TZFLG(pwmNo)	(*(Uint16*)((0x6816 - 0x40) + 0x40 * (pwmNo)))
#define	PWM_TZCLR(pwmNo)	(*(Uint16*)((0x6817 - 0x40) + 0x40 * (pwmNo)))
// High resolution PWM
#define HRPWM_DISABLE   0   // disable high resolution functionality
#define HRPWM_NOCALIB   1   // enable high resolution functionality but without continuous calibration
#define HRPWM_CALIB     2   // enable high resolution functionality and with continuous calibration
#define PWM_HRCNFG(pwmNo)	(*(Uint32*)(0x6820 + 0x40 * (pwmNo - 1)))
// Clear PWM interrupt flag for next interrupt.
inline void PS_ExitPwmIntr(int pwmNo, int intrLevel)
{
	PWM_ETCLR(pwmNo) = 1;
	CPU_PIEACK = intrLevel;
}
inline void PS_ExitPwmTripIntr(int pwmNo, int intrLevel)
{
	PS_EALLOW;
	PWM_TZCLR(pwmNo) = (PWM_TZFLG(pwmNo) & 2) ? 0x7f : 0x7e;
	PS_EDIS;
	CPU_PIEACK = intrLevel;
}
inline void PS_ExitPwm3phTripIntr(int pwmNo, int intrLevel)	// pwmNo: 1, 2
{
	PS_EALLOW;
	if (PWM_TZFLG(pwmNo) & 2) {		// cycle-by-cycle
		PWM_TZCLR(pwmNo*3-2) = 0x7f;
		PWM_TZCLR(pwmNo*3-1) = 0x7f;
		PWM_TZCLR(pwmNo*3) = 0x7f;
	} else {						// one-shot
		PWM_TZCLR(pwmNo*3-2) = 0x7e;
		PWM_TZCLR(pwmNo*3-1) = 0x7e;
		PWM_TZCLR(pwmNo*3) = 0x7e;
	}
	PS_EDIS;
	CPU_PIEACK = intrLevel;
}


// F2833x ADC register
#define ADC_TRL2		(*(Uint16*)0x7101)
#define	ADC_ST			(*(Uint16*)0x7119)
// Clear ADC interrupt flag for next interrupt. intrNo: 1, 2
inline void PS_ExitAdcIntr(int intrNo, int intrLevel)
{
	ADC_TRL2 |= 1 << ((2 - intrNo) * 8 + 6);	// Set RST_SEQ1 / RST_SEQ2
	ADC_ST |= 1 << (intrNo + 3);	// Set INT_SEQ1_CLR / INT_SEQ2_CLR
	CPU_PIEACK = intrLevel;
}

#define	QEP_QCLR(encNo)		(*(Uint16*)(0x6B1A + 0x40 * (encNo - 1)))
// Clear eQEP interrupt flag for next interrupt. encNo: 1, 2
inline void PS_ExitEncoderIntr(int encNo, int intrLevel) {
	QEP_QCLR(encNo) = 0xffff;
	CPU_PIEACK = intrLevel;
}

// Clear externnal interrupt flag for next interrupt.
inline void PS_ExitExtIntr(int intrLevel)
{
	CPU_PIEACK = intrLevel;
}

// Capture
extern float PSK_CapTimeUnit;
Uint16 PS_InitCapture(int captureNo, int pinNo, int evtFilter, int askDelta);
void PS_CapSetIntrVector(Uint16 capNo, Uint16 intrFlag, IntrFunc vec);

#define CAPINTR_EVT1    2
#define CAPINTR_EVT2    4
#define ECAP_ECCTL1(capNo)      ((*(Uint16*)(0x6A14 - 0x20 + 0x20 * capNo)) & 1)    // ECCTL1.CAP1POL
#define ECAP_ECCLR(capNo)	    (*(Uint16*)(0x6A18 - 0x20 + 0x20 * capNo))
#define ECAP_ECFLG(capNo)       (*(Uint16*)(0x6A17 - 0x20 + 0x20 * capNo))
#define ECAP_CountCAP1(capNo)   (*(Uint32*)(0x6A04 - 0x20 + 0x20 * capNo))
#define ECAP_CountCAP2(capNo)   (*(Uint32*)(0x6A06 - 0x20 + 0x20 * capNo))
#define ECAP_ECEINT(capNo)      ((*(Uint16*)(0x6A16 - 0x20 + 0x20 * capNo)) & (CAPINTR_EVT1 | CAPINTR_EVT2))
// Clear eCAP interrupt flag for next interrupt.
inline void PS_ExitCapIntr(int capNo, int intrLevel) {
	ECAP_ECCLR(capNo) = 0xff;
	CPU_PIEACK = intrLevel;
}

inline int PSM_CapIsRising(int capNo)
{
    return (ECAP_ECEINT(capNo) == (CAPINTR_EVT1 | CAPINTR_EVT2)) ? ((ECAP_ECFLG(capNo) & CAPINTR_EVT1) >> 1) : !ECAP_ECCTL1(capNo);
}

inline Uint32 PSM_CapGetCount(int capNo)
{
    return (ECAP_ECFLG(capNo) & CAPINTR_EVT1) ? ECAP_CountCAP1(capNo) : ECAP_CountCAP2(capNo);
}

// F2833x CpuTimer counter(32bit), tmNo: 0-2
#define CPU_TMCNT(tmNo)		(*(Uint32*)(0x0C00 + 8 * (tmNo)))
#define CPU_TMPRD(tmNo)		(*(Uint32*)(0x0C02 + 8 * (tmNo)))
