		.orig x3000
;
; A program that receives multi-digit input and prompts user
; to select an operation. This program simulates a calculator
; on the LC-3 machines.
;
; subroutines and labels are Upper Camel Case
; variables and data variables are in lowers_snake_case
;

;------------------------MAIN PROGRAM---------------------------------

; MAIN program variables

input_1		.stringz	"Enter first operand: "
input_2		.stringz	"\nEnter second operand: "
input_3		.stringz	"\n\nSelect operation: ADD[1] SUB[2] MUL[3] DIV[4] or QUIT[0]\n"
invalid_input	.stringz	"Error! Must enter a number [0-4]"

;
; Call user input for operands
;
		lea r0, input_1
		puts
		lea r1, OP_1		; load the array of first op
		JSR OperandInput	; call for input and store into the OP_1 array

		lea r0, input_2
		puts
		lea r1, OP_2		; load op2 as parameter
		JSR OperandInput	; call for input for op2
		BR #2			; skip the warning below

;
; Call user input for operation 
;

InvalidInput
		lea r0, invalid_input	; only displays if user inputs are invalid
		puts

		lea r1, OP_1
		JSR ArrayToInt

		add r1, r2, #0
		lea r2, OP_2
		JSR IntToArray

OperationInput	lea r0, input_3		; prompt user for operation
		puts	
		
		getc
		ld r3, minus_ASCII
		add r2, r0, r3		; get int value of input (r2)
		BRz ProgramEnd		; check if input is [0] ... QUIT

		BRn InvalidInput	; check if user inputed value <0
		add r3, r2, #-4	
		BRp InvalidInput	; check if user inputed value >4		

;
; Perform the called Operation 
;
		JSR ClearResult		; clear result from last operation
		
		add r3,	r2, #-1		; if input is 1 [add], Add
		BRnp #1
		JSR _ADD
		
		add r3, r2, #-2		; if input is 2 [sub], Sub
		BRnp #1
		JSR _SUB

		add r3, r2, #-3		; if input is 3 [mul], Multiply
		BRnp #1
		JSR _MUL

		add r3, r2, #-4		; if input is 4 [div], Divide
		BRnp #1
		JSR _DIV		

		
;
; Print the result and restart the prgram
;	

PrintResult	
		lea r1, OP_1	
		and r3, r3, #0
		add r3, r3, #2
		JSR DisplayNumber	; print 1st operant

		ld r0, OP_SIGN		
		out			; print op sign

		lea r1, OP_2		
		and r3, r3, #0
		add r3, r3, #2
		JSR DisplayNumber	; print 2nd operant

		lea r0, eql_sign		
		puts			; print eql sign

		lea r1, RESULT
		and r3, r3, #0
		add r3, r3, #5
		JSR DisplayNumber	; print asnwer

		BR OperationInput

ProgramEnd			
		
			HALT    
		 ; !!! END OF PROGRAM !!!   

;------------------------------------------------------------------------------------------------
;					VARIABLES
;-------------------------------------------------------------------------------------------------

OP_1   		.fill		#0		; 100's place
		.fill 		#0		;  10's place
		.fill		#0		;   1's place
	
OP_2		.fill		#0
		.fill		#0
		.fill		#0

OP_SIGN		.fill		x00		; hex key representing current operation (for display)

RESULT		.fill		#0		; 100,000's place
		.fill		#0		;  10,000's place
		.fill		#0		;   1,000's place
		.fill		#0		;     100's place
		.fill		#0		;      10's place
		.fill		#0		;	1's place

eql_sign	.stringz	" = "

minus_ASCII 	.fill 		x-30
plus_ASCII 	.fill 		x30

;-------------------------------------------------------------------------------------------------
;		          		 SUBROUTINES
;-------------------------------------------------------------------------------------------------


; ---------------- PROMPT FOR USER INPUT ---------------------
; r1= array address(ptr)	r6= location of JSR (addr. to return to)

OperandInput
		and r6, r6, #0
		add r6, r6, r7		; add the address of the subroutine call
					; we use TRAP calls which alter the addr stored in r7
; get one's place		
		getc
		add r2, r0, #-10 	; check if user entered 'Return' key
		BRz DONE
		
		putc
		ld r2, minus_ASCII
		add r0, r0, r2		; converting to integer
		add r1, r1, #2		; set pointer in array to last value
		str r0, r1, #0		; store in the array (backwards)
; get ten's place
		
		getc
		add r2, r0, #-10 	; check if user entered 'Return' key
		BRz DONE
		
		putc
		ld r2, minus_ASCII
		add r0, r0, r2		; converting to integer
		ldr r3, r1, #0		; load the previous value to be moved
		str r3, r1, #-1		; move the  one's place to the ten's (one up)
		str r0, r1, #0		; set one's place to current value

; get hundred's place

		getc
		add r2, r0, #-10 	; check if user entered 'Return' key
		BRz DONE

		putc
		ld r2, minus_ASCII
		add r0, r0, r2		; converting to integer
		str r3, r1, #-2		; move the prev. ten's place to the hundred's (one up)
		ldr r3, r1, #0		; load previous one's place
		str r3, r1, #-1		; move the prev. one's place to the ten's (one up)
		str r0, r1, #0		; set one's place to current value
		
		DONE
		add r7, r6, #0	
		RET

; -------------------------------------- ADD SUBROUTINE -------------------------------------------------
; NO PARAMS OR RETURN VALUE
add_sign	.fill		#43		; '+'				
							
_ADD
		lea r1, OP_SIGN
		ld r2, add_sign
		str r2, r1, #0
		lea r0, add_Msg
		puts

		and r4, r4, #0		; clear r4 and set to +2 for mem. location counter (OPERAND)
		add r4, r4, #2
		and r5, r5, #0		; clear r5 and set to +5 for mem. location counter (RESULT)
		add r5, r5, #5
		and r6, r6, #0		; r6 = the 'carry' unit (0 or 1) 
		
ADDLOOP	
;
; 1) load the digit in the current position from both OPs
;
		lea r0, OP_1
		add r0, r0, r4		; add decremented mem[OP] position
		ldr r1, r0, #0		; load the digit into r1 (from op_1)
		lea r0, OP_2
		add r0, r0, r4		; add decremented mem[OP] position
		ldr r2, r0, #0		; load the digit into r2 (from op_2)
		lea r3, RESULT
;
; 2) Add both digits and check if result is double digit
;		 
		add r1, r1, r2		; op_1 digit + op_2 digit	
		add r1, r1, r6		; r1 = the sum of one's place
		add r2, r1, #-10	; r2 used to check if sum>10
		BRzp #4			; if (result > 9 ) jump to instr.
		
		add r3, r3, r5		; add the pointer to the mem[result] location		
		str r1, r3, #0		; if (result < 10 ) -> store sum
		and r6, r6, #0		; carry unit = 0
		BR #4			; skip else instructions

		add r3, r3, r5		; add the pointer to the mem[result] location
		str r2, r3, #0		; if (result > 9 ) -> store sum-10
		and r6, r6, #0
		add r6, r6, #1		; carry unit = 1
;
; 3) set carry unit to 0/1 and decrement the current digit position
;		
		add r5, r5, #-1		; decrement result location pointer
		add r4, r4, #-1		; decrement operand pointers
		BRn #1			; Addition COMPLETE move to add carry unit to the end
		
		BR ADDLOOP
		
		lea r3, RESULT
		add r3, r3, r5		; move to position 4 (max pos when adding)
		str r6, r3, #0		; store the carry unit into the position 4

		lea r7, PrintResult	; OP is complete, go to print result
		RET

; ------------------------------ SUBTRACT SUBROUTINE ----------------------------------------
sub_sign	.fill		#45	; '-'
; no params or return value

_SUB	

		and r4, r4, #0		; clear r4 and set to 2 for mem. location counter (OPERAND)
		add r4, r4, #2
		and r5, r5, #0		; clear r5 and set to 5 for mem. location counter (RESULT)
		add r5, r5, #5
		and r6, r6, #0		; r6 = the 'carry' unit (0 or 1) 
SUBLOOP
		lea r0, OP_1
		add r0, r0, r4		; add decremented mem[OP] position
		ldr r1, r0, #0		; load the digit into r1 (from op_1)
		lea r0, OP_2
		add r0, r0, r4		; add decremented mem[OP] position
		ldr r2, r0, #0		; load the digit into r2 (from op_2)
		add r2, r2, r6		; add the carry unit to the "bottom" number (if previous subtraction was a negative)
		lea r3, RESULT
		add r3, r3, r5		; update mem[result] pntr to next position

		JSR SubSingleDigit	; OP1 - OP2 => R1
	
		BRzp #5  		; if (result is positive) -> skip
		add r1, r1, #10		; add 10 to get to opposite number (positive)	
		str r1, r3, #0		; store result in result mem address
		and r6, r6, #0		
		add r6, r6, #1		; set carry unit to 1
		BR #2
		
		str r1,r3, #0		; else store the subtracted result in pntr
		and r6, r6, #0		; set carry unit to 0

		add r5, r5, #-1		; decrement result location pointer
		add r4, r4, #-1		; decrement mem pointers
		BRzp SUBLOOP		; Subtraction COMPLETE when counter=0, exit loop and check if result is negative
		
		add r6, r6, #0
		BRz PositiveResult	; if carry unit = 1, result is negative. if=0, result was positive and is correct
					; to fix this, we simply do: 1000-RESULT to get the opposite negative value
;
; Result is negative
; we need to fix:
;			
		ldr r1, r3, #2		; r1 now contains the 1's result operand
		BRz #4			; keep 0
		not r1, r1
		add r1, r1, #1		; negate r1
		add r1, r1, #10		; 10 - r1 = negative/opposite value
		str r1, r3, #2
		
		ldr r1, r3, #1		; r1 now contains the 10's result operand
		BRz #4			; keep 0
		not r1, r1
		add r1, r1, #1		; negate r1
		add r1, r1, #9		; 9 - r1 = negative/opposite value
		str r1, r3, #1
		
		ldr r1, r3, #0		; r1 now contains the 100's result operand		; keep 0
		not r1, r1
		add r1, r1, #1		; negate r1
		add r1, r1, #9		; 9 - r1 = negative/opposite value
		str r1, r3, #0
		
		ld r2, sub_sign	
		str r2, r3, #-3		; show the negative sign for negative #'s

PositiveResult	
		ld r2, sub_sign	
		lea r1, OP_SIGN		; update the global operation sign (for display)
		str r2, r1, #0	
		lea r0, sub_Msg
		puts	
		
		lea r7, PrintResult	; OP is complete, go to print result
		
		RET

; ---------------- MULTIPLY SUBROUTINE ---------------------
mul_sign	.fill		#120

_MUL		
		
		lea r1, OP_SIGN
		ld r2, mul_sign
		str r2, r1, #0

		; ------------------------
		; IMPLEMENTATION HERE !!!
		; ------------------------

		lea r0, mul_Msg
		puts	
		
		lea r7, PrintResult	; OP is complete, go to print result
		
		RET

; ---------------- DIVIDE SUBROUTINE -----------------------
div_sign	.fill		#47

_DIV		
		add r6, r7, #0	; save PC		

		lea r1, OP_SIGN
		ld r2, div_sign
		str r2, r1, #0

		; ------------------------
		; IMPLEMENTATION HERE !!!
		; ------------------------

		lea r0, div_Msg
		puts	
		
		add r7, r6, #0	; OP is complete, go to print result
		
		RET

;----------------- Subtract 1 Digit -------------------------
; R1 = X	R2 = Y	    R1 = X - Y

SubSingleDigit
		not r2, r2
		add r2, r2, #1	; negate
		add r1, r2, r1	; operation (x-y)
		RET

;------------------ DISPLAY MULTI-DIGIT (array) ---------------
; R1 = Operand mem. location	R3 = counter (how many times to loop)
;					[0-2] for displaying operand (3 digit)
;					[0-5] for displaying result (6 digit)

DisplayNumber		
		add r6, r7, #0		; temporarily store the return addr into r6
		ld r2, plus_ASCII
		not r3, r3
		add r3, r3, #1		; negate r3 (to subtract for check)
		and r4, r4, #0		; offset of position (ones place - thousands place)
LOOP
		add r0, r1, r4
		ldr r0, r0, #0
		add r5, r0, #-10	; check if value is integer and need to be converted
		BRzp #1
		add r0, r0, r2		; convert
		out			; print num[ position ]
		add r4, r4, #1
		add r5, r4, r3		; check if we reached r3 (end of multi-digit number)
		BRnz LOOP
		
		add r7, r6, #0		; set r7 to the previous return address
		RET

;------------------------- Array To Integer ----------------------------------------
; R1 = Source Array mem. location	R2 = Destination integer result
HUNDRED		.fill		#100

ArrayToInt
		ldr r3, r1, #0		; r3 now contains the 100's place
		ld r4, HUNDRED
		and r2, r2, #0		; clear r3 to count how many 100's
HundredsLoop
		add r2, r2, r4		; add 100 to total int
		add r3, r3, #-1		; decrement 100's place
		BRp HundredsLoop
	
		ldr r3, r1, #1		; r3 now contains the 10's place
TensLoop
		add r2, r2, #10		; add 10 to total int		
		add r3, r3, #-1		; decrement 10's place
		BRp TensLoop
		
		ldr r3, r1, #2		; r3 now contains the 1's place
		add r2, r2, r3		; add the one's place to the tens+hundreds

		RET

;----------------------Integer to Array ----------------------------------------
; R1 = Source Integer
; R2 = Destination Array 
NegativeHUNDRED		.fill		#-100

IntToArray
		and r3, r3, #0		; r3 to be used as counter (representing the integer digit)

		ld r4, NegativeHUNDRED
		ld r5, HUNDRED
HundredLoop
		add r3, r3, #1		; counter++
		add r1, r1, r4		; -100
		BRp HundredLoop
		BRn #2
		str r3, r2, #0		; if r1=0, we have nothing else to subtract, store digit and return
		BR LoopDone		

		add r1, r1, r5		; Subtracted too much, add 100 back
		add r3, r3, #-1		; counter--
		str r3, r2, #0
		and r3, r3, #0		; clear counter for the 10's place
TenLoop
		add r3, r3, #1
		add r1, r1, #-10	; -10
		BRp TenLoop
		BRn #2
		str r3, r2, #1
		BR LoopDone
	
		add r1, r1, #10
		add r3, r3, #-1
		str r3, r2, #1		; store counter (digit) into mem. array

		str r1, r2, #2		; the remaining number in r1 should be the single digit one's place
LoopDone
		RET

;--------------------- CLEAR RESULT ----------------------------------
; Removes all entries in the result array and reinitializes it with 0's for the next Operation
; R1 = RESULT mem. location

ZERO		.fill		x00

ClearResult
		lea r1, RESULT
		and r6, r6, #0		; counter
		add r6, r6, #6
		ld r5, ZERO
DeleteNext		
		str r5, r1, #0		; store int '0' into result array
		add r1, r1, #1		; increment the mem. location pointer
		add r6, r6, #-1		; decrement loop counter
		BRp DeleteNext
		
		RET

;----------------- VARIABLES -------------------------
add_Msg		.stringz	"[1] : "
sub_Msg		.stringz	"[2] : "
mul_Msg		.stringz	"[3] : "
div_Msg		.stringz	"[4] : "

.end