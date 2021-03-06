		AREA	MAIN_CODE, CODE, READONLY
		GET		LPC213x.s
		
		ENTRY
__main
__use_two_region_memory
		EXPORT			__main
		EXPORT			__use_two_region_memory
		
CURRENT_DIG RN 12
DIGIT_0 RN 8
DIGIT_1 RN 9
DIGIT_2 RN 10
DIGIT_3 RN 11
		
		LDR R0, =0x000F0000
		LDR R1, =IO0DIR
		STR R0, [R1]
		
		LDR R0, =0x00FF0000
		LDR R1, =IO1DIR
		STR R0, [R1]
		
		LDR R0, =0
		LDR R1, =0
		
		LDR CURRENT_DIG, =0
		LDR DIGIT_0, =0
		LDR DIGIT_1, =0
		LDR DIGIT_2, =0
		LDR DIGIT_3, =0
		
main_loop
		
		LDR R5, =0x000F0000
		LDR R6, =IO0CLR
		STR R5, [R6]
		
		LDR R5, =0x80000
		LSR R5, CURRENT_DIG
		LDR R6, =IO0PIN
		STR R5, [R6]
		
		CMP CURRENT_DIG, #0
		BNE C1
		MOV R6, DIGIT_0
		B CHANGING

C1
		CMP CURRENT_DIG, #1
		BNE C2
		MOV R6, DIGIT_1
		B CHANGING

C2
		CMP CURRENT_DIG, #2
		BNE C3
		MOV R6, DIGIT_2
		B CHANGING

C3
		MOV R6, DIGIT_3

CHANGING
		
		ADR R5, SevenSegTable
		ADD R5, R6
		LDRB R6, [R5]
		
		LDR R5, =IO1PIN
		LSL R6, #0x10
		STR R6, [R5]
		
		CMP CURRENT_DIG, #0x3
		BNE INC_DIGIT
		
		LDR R6, =1
		ADD DIGIT_0, R6
		CMP DIGIT_0, #0xA
		BNE INC_DIGIT
		
		LDR DIGIT_0, =0
		ADD DIGIT_1, R6
		CMP DIGIT_1, #0xA
		BNE INC_DIGIT
		
		LDR DIGIT_1, =0
		ADD DIGIT_2, R6
		CMP DIGIT_2, #0xA
		BNE INC_DIGIT
		
		LDR DIGIT_2, =0
		ADD DIGIT_3, R6
		CMP DIGIT_3, #0xA
		BNE INC_DIGIT
		
		LDR DIGIT_3, =0
		
		
INC_DIGIT		
		
		LDR R6, =1
		LDR R5, =0x4
		ADD CURRENT_DIG, R6
		CMP CURRENT_DIG, #0x4
		EOREQ CURRENT_DIG, R5
		
		LDR R0, =5
		BL DelayInMs
		
		b				main_loop


	ALIGN
DelayInMs
	LDR R2, =15001
	LDR R1,	=1
	
	MUL R0, R2, R0
	
DELAY
	SUBS R0, R1
	BNE DELAY
	
	BX LR
	

SevenSegTable DCB  0x3f,0x06,0x5B,0x4F,0x66,0x6d,0x7D,0x07,0x7f,0x6f

		END





