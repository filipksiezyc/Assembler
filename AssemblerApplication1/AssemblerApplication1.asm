
  
.MACRO LOAD_CONST
LDI @1,LOW(@2)
LDI @0,HIGH(@2)
.ENDMACRO 

.MACRO SET_DIGIT
PUSH	R16
PUSH	R20
MOV		R16, Dig@0
RCALL	DigitTo7segCode
OUT		SegmentsPort, R16
LDI		R20, ($02)<<@0
OUT		DigitsPort, R20
POP		R20
POP		R16
.ENDMACRO

.equ DigitsPort	=	PORTB
.equ SegmentsPort =	PORTD

.def PulseEdgeCtrL=R0
.def PulseEdgeCtrH=R1

.org 0			RJMP	Start
.org OC1Aaddr	RJMP	timer_isr
.org $0B		rjmp	_ExtInt_ISR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_ExtInt_ISR: 	
	push	R18
    push	R19 
	push	R20
	IN		R20, SREG

	LDI		R18, 1
	LDI		R19, 0
	ADD		R0, R18
	ADC		R1, R19

	OUT		SREG, R20
	POP		R20
	pop		R19
    pop		R18
reti  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
timer_isr:
	push	R16
    push	R17
    push	R18
    push	R19
	push	R20
	IN		R20, SREG

	MOV		R16, R0
	MOV		R17, R1
	LSR		R17
	ROR		R16
	RCALL NumberToDigits
	mov		Dig0, R16
	mov		Dig1, R17
	mov		Dig2, R18
	mov		Dig3, R19
	CLR		PulseEdgeCtrL
	CLR		PulseEdgeCtrH

	OUT		SREG, R20
	POP		R20
	pop		R19
    pop		R18
    pop		R17
    pop		R16
	reti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Table: .db 0x3f,0x06,0x5B,0x4F,0x66,0x6d,0x7D,0x07,0xff,0x6f
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Start:
	
	LDI		R17, 12
	OUT		TCCR1B, R17
	LDI		R17, 0
	OUT		TCCR1A, R17
	LDI		R17, $7A
	OUT		OCR1AH, R17
	LDI		R17, $11
	OUT		OCR1AL, R17
	LDI		R17, $C0
	OUT		TIMSK, R17

	LDI		R17, $20
	OUT		GIMSK, R17
	OUT		GIFR, R17
	LDI		R17, $01
	OUT		PCMSK, R17

	SEI

	CLR		PulseEdgeCtrL
	CLR		PulseEdgeCtrH

	LDI		R20, $30
	OUT		DDRB, R20
	LDI		R20, $FF
	OUT		DDRD, R20

	LOAD_CONST R17, R16, 0000
	RCALL NumberToDigits

	mov		Dig0, R16
	mov		Dig1, R17
	mov		Dig2, R18
	mov		Dig3, R19

	LOAD_CONST R17, R16, 5 ;f = 1/(n*T) n-ilosc liczb

	CLR		R28
	CLR		R29
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Main_Loop:

	;LOAD_CONST R17, R16, 5

	SET_DIGIT 0
	RCALL	DelayInMs
	SET_DIGIT 1
	RCALL	DelayInMs	
	SET_DIGIT 2
	RCALL	DelayInMs	
	SET_DIGIT 3
	RCALL	DelayInMs

	RJMP	Main_Loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DigitTo7segCode: //in-out r16
	PUSH	R30
	PUSH	R31
	PUSH	R20

	CLR		R20
	LDI		R30, Low(Table<<1) 
	LDI		R31, High(Table<<1)
	ADD		R30, R16
	ADC		R31, R20
	LPM		R16, Z

	POP		R20
	POP		R31
	POP		R30
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.DEF XL=R16 ; divident  
.DEF XH=R17 

.DEF YL=R18 ; divider
.DEF YH=R19 

; outputs

.DEF RL=R16 ; reminder 
.DEF RH=R17 

.DEF QL=R18 ; quotient
.DEF QH=R19 

; internal
.DEF QCtrL=R24
.DEF QCtrH=R25

Divide:
	PUSH	QCtrL ;save internal variables on stack
    PUSH	QCtrH
	CLR		QCtrL
	CLR		QCtrH
	
	CP		XL, YL
	CPC		XH, YH
	BRLO	_Divide_end

_Divide_loop:
	SUB		XL, YL
	SBC		XH,	YH
	ADIW	QCtrH:QCtrL, 1

	CP		XL, YL
	CPC		XH, YH
	BRSH	_Divide_loop

_Divide_end:
	MOV		QH, QCtrH
	MOV		QL, QCtrL

	POP		QCtrH ; pop internal variables from stack
	POP		QCtrL

	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.def Dig0=R22 ; Digits temps
.def Dig1=R23 ; 
.def Dig2=R24 ; 
.def Dig3=R25 ; 
;In 16-17  Out 16-19
NumberToDigits:

	push	Dig0
	push	Dig1
	push	Dig2
	push	Dig3

	LOAD_CONST R19, R18, 1000
	RCALL	Divide
	MOV		Dig0, R18

	LOAD_CONST R19, R18, 100
	RCALL	Divide
	MOV		Dig1, R18

	LOAD_CONST R19, R18, 10
	RCALL	Divide
	MOV		Dig2, R18

	MOV		Dig3, R16

	mov		R16,Dig0
	mov		R17,Dig1
	mov		R18,Dig2
	mov		R19,Dig3

	pop		Dig3
	pop		Dig2
	pop		Dig1
	pop		Dig0

	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DelayInMs:			//in R17:R16
	PUSH	R27
	PUSH	R26
	MOV		R27, R17
	MOV		R26, R16
DelayLoop:
	RCALL	DelayOneMs
	SBIW	R27:R26,1
	BRNE	DelayLoop

	POP		R26
	POP		R27
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DelayOneMs:	
	PUSH	R26
	PUSH	R27
	LDI		R27, $05 //starszy
	LDI		R26, $32 //mlodszy

Loop:
	SBIW	R27:R26,1
	NOP
 	BREQ	Loop_end
	RJMP	Loop

Loop_end:
	POP		R27
	POP		R26
	RET
