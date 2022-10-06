;
; A program that receives multi-digit input and prompts user
; to select an operation. This program simulates a calculator
; on the LC-3 machines. Users can ADD, SUB, MUL, or DIV two 3-digit number.
;
; subroutines and labels are Upper Camel Case
; variables and data variables are in lowers_snake_case
;
; @author Walid Harkous
;
; @name	LC-3 Calculator v1.0

;------------------------MAIN PROGRAM---------------------------------

			.ORIG x3000

; MAIN program variables prompts

input_1		.stringz	"Enter first operand: "
input_2		.stringz	"\nEnter second operand: "
input_3		.stringz	"\n\nSelect operation: ADD[1] SUB[2] MUL[3] DIV[4] or Enter New Operands[0]\n"
invalid_input	.stringz	"Error! Must enter a number [0-4]"


ProgramStart
;
; Call user input for OPERANDS
;

		lea r0, input_1
		puts
		lea r1, OP_1		; load the array of first op
		and r6, r6, #0
		add r6, r6, #3		; set counter param to 3 (operand is stored as 3-digit)
		
		JSR ClearArray
		JSR OperandInput	; call for input and store into the OP_1 array

		lea r0, input_2
		puts
		lea r1, OP_2		; load op2 as parameter
		and r6, r6, #0
		add r6, r6, #3

		JSR ClearArray
		JSR OperandInput	; call for input for op2
		BR #2			; skip the warning below

;
; Call user input for operation 
;

InvalidInput
		lea r0, invalid_input	; only displays if user inputs are invalid
		puts

OperationInput	lea r0, input_3		; prompt user for operation
		puts	
		
		getc
		ld r3, minus_ASCII
		add r5, r0, r3		; get int value of input (r5)
		BRz ProgramStart	; check if input is [0] ... RESTART

		BRn InvalidInput	; check if user inputed value <0
		add r3, r5, #-4	
		BRp InvalidInput	; check if user inputed value >4		

;
; Convert to int
;
		lea r1, RESULT
		and r6, r6, #0
		add r6, r6, #6		; set counter to 6 (result has 6-digits)
		JSR ClearArray		; clear result from last operation

		lea r1, OP_1
		JSR ArrayToInt		; convert first operand to int
		add r6, r2, #0		; temporarily store int op1 in r6
		lea r1, OP_2
		JSR ArrayToInt		; R2 now has int op2		(R2 = second op)
		add r1, r6, #0		; add int op1 back into r1	(R1 = first op)

;
; Perform the called Operation 
;		
		add r3,	r5, #-1		; if input is 1 [add], Add
		BRnp #1
		JSR _ADD
		
		add r3, r5, #-2		; if input is 2 [sub], Sub
		BRnp #1
		JSR _SUB

		add r3, r5, #-3		; if input is 3 [mul], Multiply
		BRnp #1
		JSR _MUL

		add r3, r5, #-4		; if input is 4 [div], Divide
		BRnp #1
		JSR _DIV

;
; store int result as array then display

PrintResult	
		add r1, r3, #0		; load int result into r1
		lea r2, RESULT		; load address where int will be stored
		JSR IntToArray		; store the int result into an array to display

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

		and r3, r3, #0
		add r3, r3, #5
		lea r1, RESULT
		JSR DisplayNumber	; print asnwer

		add r1, r6, #0		; load int remainder into r1
		BRz #8			; a 'zero' means we did divison and have a remainder to display
		lea r2, REMAINDER	; load address where int will be stored
		JSR IntToArray		; store the int remainder into an array to display

		lea r0, RemainderMsg
		puts
		lea r1, REMAINDER
		and r3, r3, #0
		add r3, r3, #5
		JSR DisplayNumber

		BR OperationInput	; this will always loop and wont break unless user inputs '0'

ProgramEnd			
			HALT    

; these variables are shared between the subroutines and main program so they need to be in the middle
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

REMAINDER	.fill		#0
		.fill		#0
		.fill		#0
		.fill		#0
		.fill		#0
		.fill		#0

eql_sign	.stringz	" = "

RemainderMsg	.stringz	" R: "		; to display remainder when dividing
minus_ASCII 	.fill 		x-30
plus_ASCII 	.fill 		x30
add_Msg		.stringz	"[1] : "
sub_Msg		.stringz	"[2] : "
mul_Msg		.stringz	"[3] : "
div_Msg		.stringz	"[4] : "

;-------------------------------------------------------------------------------------------------
;		          		 SUBROUTINES
;-------------------------------------------------------------------------------------------------


; ---------------------------------------------
; 		PROMPT FOR USER INPUT
;----------------------------------------------
;
; prompts user to input 0-3 digit number 
; and stores in memory as an array
;
; r1= operand array address(ptr)	r6= location of JSR (addr. to return to)


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

; --------------------------------------------------------------------
; 			ADD SUBROUTINE
;----------------------------------------------------------------------
;
; Add two 0-3 digit numbers (This literaly just uses the add command)
; There is no need to account for integer overflow as min=0 and max=1998
;
; R1 = X	R2 = Y	 	R3 = (X + Y)

add_sign	.fill		#43		; '+'				
							
_ADD
		add r3, r2, r1		; this is literaly the 'algorithm' (X + Y)
		
		lea r1, OP_SIGN		; store '+' as global variable and display operation msg
		ld r2, add_sign
		str r2, r1, #0
		lea r0, add_Msg
		puts
		lea r7, PrintResult	; OP is complete, go to print result
		and r6, r6, #0		; set 'remainder' value to 0

		RET

; ----------------------------------------------------------------------------
; 			SUBTRACT SUBROUTINE
;-----------------------------------------------------------------------------
;
; Sub two 0-3 digit numbers (This also uses the add command)
; by taking the negation of the number being subtracted and adding.
; **Is also able to subtract into the negatives and displays the negative answer!
;
; R1 = X	R2 = Y	 	R3 = (X - Y)

sub_sign	.fill		#45	; '-'

_SUB	
		not r2, r2	
		add r2, r2, #1		; negate r2
		add r3, r1, r2		; X + (-Y)

		ld r2, sub_sign	
		lea r1, OP_SIGN		; update the global operation sign (for display)
		str r2, r1, #0	
		lea r0, sub_Msg
		puts	
		lea r7, PrintResult	; OP is complete, go to print result
		and r6, r6, #0		; set 'remainder' value to 0

		RET

; ---------------------------------------------------------------------------------
; 			MULTIPLY SUBROUTINE
;---------------------------------------------------------------------------------
;
; Multiply two 0-3 digit numbers. Loops Y times and adds X to itself 
; (X + X + X + ... X) {y times}
; CAUTION: ! integer overflow when result > 32,767 ! (works for expressions less than 181 x 181 )
;
; R1 = X	R2 = Y	 	R3 = (X * Y)

mul_sign	.fill		#120

_MUL		
		add r1, r1, #0
		BRz #4
		and r3, r3, #0		
		add r3, r3, r2		; add an iteration of Y
		add r1, r1, #-1		; decrement counter (X)
		BRp #-3
				
		lea r1, OP_SIGN
		ld r2, mul_sign		; update the global operation sign (for display)
		str r2, r1, #0
		lea r0, mul_Msg
		puts	
		lea r7, PrintResult	; OP is complete, go to print result
		and r6, r6, #0		; set 'remainder' value to 0		

		RET

; ----------------------------------------------------------------------------
; 			DIVIDE SUBROUTINE
;-----------------------------------------------------------------------------
;
; Divide two numbers by looping and subtract x-y until we reach 0 or (-)
; The number of iterations is the quotient and the remaining
; value of x is our remainder.
;
; R1 = X	R2 = Y	 --->	R3 = Quotient	R6 = Remainder (using r6 as the remainder variable)

div_sign	.fill		#47

_DIV				
		and r3, r3, #0		; clear r3 to count quotient
		not r2, r2
		add r2, r2, #1		; negate denominator
DivLoop		
		add r3, r3, #1		; r3++ (keep track of # of subtractions done)	
		add r1, r1, r2		; op1 - op2
		BRn NegativeResult
		BRz ZeroResult		 
		BRp DivLoop		; can still subtract (loop again)

;
; we subtracted too much and need to add back (but we have our answer)
;
NegativeResult	
		add r3, r3, #-1		; adding back 1 to quotient
		add r2, r2, #-1
		not r2, r2		; reversing the 2's complement
		add r1, r1, r2		; adding y back to x

;
; we have reached remainder 0. operation complete
;
ZeroResult	
		add r6, r1, #0		; put remainder into r6	
		lea r1, OP_SIGN
		ld r2, div_sign
		str r2, r1, #0
		lea r0, div_Msg		; update the global operation sign (for display)
		puts	
		lea r7, PrintResult	; OP is complete, go to print result
		
		RET

; ----------------------------------------------------
; 		SUBTRACT SINGLE DIGIT
;-----------------------------------------------------
; R1 = X	R2 = Y	    R1 = X - Y

SubSingleDigit
		not r2, r2
		add r2, r2, #1	; negate
		add r1, r2, r1	; operation (x-y)
		RET
; -------------------------------------------------------
; 		DISPLAY MULTI-DIGIT (array)
; ------------------------------------------------------
; Display a mutli-digit array into the console. If the bit is a integer, convert to ascii, 
; otherwise it will display the block as is (in the case that we have negative #)
;
; R1 = Operand mem. location	R3 = counter (How many times to loop)
;					[0-2] for displaying operand (3 digit)
;					[0-5] for displaying result (6 digit)

DisplayNumber		
		add r5, r7, #0		; temporarily store the return addr into r5
		
		not r3, r3
		add r3, r3, #1		; negate r3 (to subtract for check)
		and r4, r4, #0		; offset of position (ones place - thousands place)
LOOP
		add r0, r1, r4		; add counter to mem location
		ldr r0, r0, #0
		add r2, r0, -10
		BRzp #2			; if array[i] is a +/- sign (TO DISPLAY NEGATIVE ANSWERS)
		ld r2, plus_ASCII
		add r0, r0, r2		
		out			; print num[ position ]
		add r4, r4, #1
		add r0, r4, r3		; check if we reached r3 (end of multi-digit number)
		BRnz LOOP
		
		add r7, r5, #0		; set r7 to the previous return address
		RET

; ------------------------------------------------------------
; 			ARRAY TO INTEGER
;--------------------------------------------------------------
; Take an array that is assumed to be an integer representation and turn it into an int
;
; R1 = Source Array mem. location	R2 = Destination integer result

ArrayToInt
		and r2, r2, #0		; clear r2 to count how many 100's
		ldr r3, r1, #0		; r3 now contains the 100's place
		BRz #4			; go to tens if hundreds place is empty
		ld r4, Positive100
		
HundredsLoop
		add r2, r2, r4		; add 100 to total int
		add r3, r3, #-1		; decrement 100's place
		BRp HundredsLoop	
		
		ldr r3, r1, #1		; r3 now contains the 10's place
		BRz #3			; jump to ones place if tens place is empty
TensLoop
		add r2, r2, #10		; add 10 to total int		
		add r3, r3, #-1		; decrement 10's place
		BRp TensLoop
		
		ldr r3, r1, #2		; r3 now contains the 1's place
		add r2, r2, r3		; add the one's place to the tens+hundreds

		RET

; ------------------------------------------------------------------------------
; 				INTEGER TO ARRAY
;---------------------------------------------------------------------------------
; Works backwards to go from int and puts each digit place into the corresponding array location
; eg: array[#0] is the sign bit, array[#1] is the ten-thousand place, ... , array[#5] is the one's place
; *note: I could not get 6 digit to work as I had to subtract 100,000 which results in int overflow

; R1 = Source Integer (0-5 digit number)  
; R2 = Destination Array (6 blocks minimum)

Negative10K		.fill		#-10000
Negative1K		.fill		#-1000
Negative100		.fill		#-100
Positive100		.fill		#100
Positive1K		.fill		#1000
Positive10K		.fill		#10000

IntToArray

		add r1, r1, #0
		BRzp #4			; if negative, negate then store negative sign
		not r1, r1
		add r1, r1, #1
		ld r4, sub_sign
		str r4, r2, #0		; store the negative sign
		and r3, r3, #0		; r3 to be used as counter (representing the integer digit)
		ld r4, Negative10K
TenThousandLoop
		add r3, r3, #1		; counter++
		add r1, r1, r4		; -10,000
		BRp TenThousandLoop
		BRn #2
		str r3, r2, #1		; if r1=0, we have nothing else to subtract, store digit and return
		BR LoopDone		

		ld r4, Positive10K
		add r1, r1, r4		; Subtracted too much, add 1000 back
		add r3, r3, #-1		; counter--
		str r3, r2, #1
		and r3, r3, #0		; clear counter for the 1000's place
		ld r4, Negative1K
ThousandLoop
		add r3, r3, #1		; counter++
		add r1, r1, r4		; -1000
		BRp ThousandLoop
		BRn #2
		str r3, r2, #2		; if r1=0, we have nothing else to subtract, store digit and return
		BR LoopDone		

		ld r4, Positive1K
		add r1, r1, r4		; Subtracted too much, add 1000 back
		add r3, r3, #-1		; counter--
		str r3, r2, #2
		and r3, r3, #0		; clear counter for the 100's place
		ld r4, Negative100
HundredLoop
		add r3, r3, #1		; counter++
		add r1, r1, r4		; -100
		BRp HundredLoop
		BRn #2
		str r3, r2, #3		; if r1=0, we have nothing else to subtract, store digit and return
		BR LoopDone		

		ld r4, Positive100
		add r1, r1, r4		; Subtracted too much, add 100 back
		add r3, r3, #-1		; counter--
		str r3, r2, #3
		and r3, r3, #0		; clear counter for the 10's place
TenLoop
		add r3, r3, #1
		add r1, r1, #-10	; -10
		BRp TenLoop
		BRn #2
		str r3, r2, #4
		BR LoopDone
	
		add r1, r1, #10
		add r3, r3, #-1
		str r3, r2, #4		; store counter (digit) into mem. array

		str r1, r2, #5		; the remaining number in r1 should be the single digit one's place
LoopDone
		RET

; ---------------------------------------------
; 		CLEAR ARRAY
;----------------------------------------------
; Sets all of the array blocks with 0's for the next Operation
;
; R1 = array mem. location	R6 = Counter (3 for 3-digit or 6 for 6-digit number)

ZERO		.fill		#0	

ClearArray
		ld r2, ZERO
		add r3, r1, #0
DeleteNext		
		str r2, r3, #0		; store int '0' into result array
		add r3, r3, #1		; increment the mem. location pointer
		add r6, r6, #-1		; decrement loop counter
		BRp DeleteNext
		
		RET


.end