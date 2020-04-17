 ;### MACROS & defs (.equ)###

 .def CurrentThread=R20
 .def ThreadA_LSB=R19
 .def ThreadA_MSB=R18
 .def ThreadB_LSB=R17
 .def ThreadB_MSB=R16

.MACRO LOAD_CONST  
 ldi  @0,low(@2)
 ldi  @1,high(@2)
.ENDMACRO 

/*** Display ***/
.equ DigitsPort = PORTB
.equ SegmentsPort  = PORTD
.equ DisplayRefreshPeriod = 20

.MACRO SET_DIGIT  
LDI R16,0x10>>@0
OUT DigitsPort, R16
mov R16,Dig_@0
rcall DigitTo7segCode
OUT SegmentsPort, R16
LDI R16,low(DisplayRefreshPeriod/4)
LDI R17,high(DisplayRefreshPeriod/4)
rcall DealyInMs
.ENDMACRO 

; ### GLOBAL VARIABLES ###

.def PulseEdgeCtrL=R0
.def PulseEdgeCtrH=R1

.def Dig_0=R2
.def Dig_1=R3
.def Dig_2=R4
.def Dig_3=R5

; ### INTERRUPT VECTORS ###
.cseg		     ; segment pamiêci kodu programu 

.org	 0      rjmp	_main	 ; skok do programu g³ównego
.org OC1Aaddr	rjmp _Timer_ISR

/*
.org PCIBaddr   rjmp _ExtInt_ISR ; skok do procedury obs³ugi przerwania zenetrznego 

; ### INTERRUPT SEERVICE ROUTINES ###

_ExtInt_ISR: 	 ; procedura obs³ugi przerwania zewnetrznego

        push R16
	    in R16,SREG
	    push R16
 
		ldi R16,1
		add PulseEdgeCtrL,R16
		clr R16
		adc PulseEdgeCtrH,R16
       
	    pop R16
	    out SREG,R16
        pop R16

		reti   ; powrót z procedury obs³ugi przerwania (reti zamiast ret)      
*/
_Timer_ISR:
	PUSH R25
	IN R25, SREG
	CPI CurrentThread, $1
	BRNE InitA
	BREQ InitB

	INITA:
		OUT SREG, R25
		POP R25
		POP ThreadA_MSB
		POP ThreadA_LSB
	RJMP START

	INITB:
		OUT SREG, R25
		POP R25
		POP ThreadB_MSB
		POP ThreadB_LSB
	

	Start:	
	PUSH R25
	IN R25, SREG

	INC CurrentThread
	ANDI CurrentThread, $1
	CPI CurrentThread, $1
	BRNE BackToA
	BREQ BackToB

	BackToA:
		OUT SREG, R25
		POP R25
		PUSH ThreadA_LSB
		PUSH ThreadA_MSB
	RJMP Returning

	BackToB:
		OUT SREG, R25
		POP R25
		PUSH ThreadB_LSB
		PUSH ThreadB_MSB
	RJMP Returning

	Returning:
		reti

; ### MAIN PROGAM ###

_main: 

            // *** Ext. ints ***
			/*
			ldi R16,(1<<PCIE0) ; enable PCINT7..0
			out GIMSK,R16

			ldi R16,(1<<PCINT0) ; unmask PCINT0
			out PCMSK0,R16
			*/
			; *** Timer1 ***
			;.equ TimerPeriodConst=31250

			ldi R16, 9 ; prescaler 256 & ctc mode
			out TCCR1B,R16

			ldi R16,high(0); 
			out OCR1AH,R16

			ldi R16,low(100) 
			out OCR1AL,R16 

			ldi R16,1<<OCIE1A ; interrupt on match
			out TIMSK,R16 
			
			// *** Display ***

			// Ports
			LDI R16,0x1E
			OUT DDRB,R16

			LDI R16,0xFF
			OUT DDRD,R16

			LDI R16, 0b00111111
			OUT SegmentsPort, R16
		

			CLR CurrentThread

			LDI ThreadB_LSB, LOW(ThreadB)
			LDI ThreadB_MSB, High(ThreadB)

			LDI R25, 0b00010000
			MOV R10, R25
			LDI R25, 0b00001000
			MOV R11, R25

			CLR R25

			LDI R21, LOW(80000000)
			LDI R22, High(80000000)
			LDI R23, LOW(40000000)
			LDI R24, High(40000000)

			// --- globalne odblokowanie przerwañ
            sei

			// 
	    ThreadA:   
			
			EOR R25, R10
			OUT DigitsPort, R25

			mov  R26,R21 
			mov  R27,R22                  
		 LA: 	
            SBIW  R26:R27,1 
			BRNE  LA

		RJMP ThreadA

		ThreadB:   
			
			EOR R25, R11
			OUT DigitsPort, R25

			mov  R28,R23 
			mov  R29,R24                  
		 LB: 	
            SBIW  R28:R29,1 
			BRNE  LB

		RJMP ThreadB

; ### SUBROUTINES ###

;*** NumberToDigits ***
;input : Number: R16-17
;output: Digits: R16-19
;internals: X_R,Y_R,Q_R,R_R - see _Divider

; internals

.def Dig0=R22 ; Digits temps
.def Dig1=R23 ; 
.def Dig2=R24 ; 
.def Dig3=R25 ; 

_NumberToDigits:

	push Dig0
	push Dig1
	push Dig2
	push Dig3

	; thousands 
	LOAD_CONST R18,R19,1000 ; divider
	rcall _Divide
	mov Dig3,R18       ; quotient - > digit

	; hundreads 
	LOAD_CONST R18,R19,100
	rcall _Divide
	mov Dig2,R18         

	; tens 
	LOAD_CONST R18,R19,10
	rcall _Divide
	mov Dig1,R18        

	; ones 
	mov Dig0,R16      ;reminder - > digit0

	; otput result
	mov R16,Dig0
	mov R17,Dig1
	mov R18,Dig2
	mov R19,Dig3

	pop Dig3
	pop Dig2
	pop Dig1
	pop Dig0

	ret

;*** Divide ***
; X/Y -> Qotient,Reminder
; Input/Output: R16-19, Internal R24-25

; inputs
.def XL=R16 ; divident  
.def XH=R17 

.def YL=R18 ; divider
.def YH=R19 

; outputs

.def RL=R16 ; reminder 
.def RH=R17 

.def QL=R18 ; quotient
.def QH=R19 

; internal
.def QCtrL=R24
.def QCtrH=R25

_Divide:push R24 ;save internal variables on stack
        push R25
		
		clr QCtrL ;clr QCtr 
		clr QCtrH

divloop:cp	XL,YL ;exit if X<Y
		cpc XH,YH
		brcs exit   

		sub	XL,YL ;X-=Y
		sbc XH,YH

		adiw  QCtrL:QCtrH,1 ; TmpCtr++

		rjmp divloop			

exit:	mov QL,QCtrL; QoutientCtr to Quotient (output)
		mov QH,QCtrH

		pop R25 ; pop internal variables from stack
		pop R24

		ret

// *** DigitTo7segCode ***
// In/Out - R16

Table: .db 0x3f,0x06,0x5B,0x4F,0x66,0x6d,0x7D,0x07,0xff,0x6f

DigitTo7segCode:

push R30
push R31

ldi R30, Low(Table<<1)  // inicjalizacja rejestru Z 
ldi R31, High(Table<<1)

add R30,R16 // Z + offset
clr R16
adc R31,R16

lpm R16, Z  // Odczyt Z

pop R31
pop R30

ret

// *** DelayInMs ***
// In: R16,R17
DealyInMs:  
            push R24
			push R25

            mov  R24,R16 
			mov  R25,R17                  
  L2: 		rcall OneMsLoop
            SBIW  R24:R25,1 
			BRNE  L2

			pop R25
			pop R24

			ret

// *** OneMsLoop ***
OneMsLoop:	
			push R24
			push R25 
			
			LOAD_CONST R24,R25,2000                    

L1:			SBIW R24:R25,1 
			BRNE L1

			pop R25
			pop R24

			ret



