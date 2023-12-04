.global _start
.equ SSD0_3	, 	0xff200020
.equ SSD4_5	, 	0xff200030

_start:
	mov 	r0, #123
	bl  	_divide_by_ten
	bl 	_get_SSD_digit
	mov	r4, r2
	bl	_display_SSD_set1
	
_finish:
	bal 	_finish

_clear_SSD:
	push	{r4,lr}
	mov	r4, #0
	bl	_display_SSD_set1
	bl	_display_SSD_set2
	pop	{lr,r4}
	bx	lr

_display_SSD_set1:
	push 	{r1}
	ldr 	r1, =SSD0_3
	str 	r4, [r1]
	pop 	{r1}
	bx 	lr
	
_display_SSD_set2:
	push 	{r1}
	ldr 	r1, =SSD4_5
	str 	r4, [r1]
	pop 	{r1}
	bx 	lr

/*
 * This function will take a number in r0, 
 * divide it by 10 and put the remainder in 
 * r1, quotient in r0.
 *
 * Algorithm:
 *	1. Pushes r3 and lr to stack
 *	2. Sets r1 ato zero.
 *	3. Sets r3 to 32, because we're dividing a
 *		32 bit number. r3 is the loop counter.
 *	4. In a loop running 32 times,
 *		a. Left shifts the MSB of r0 to LSB of r1.
 *		b. Add 1 to r0.
 *		c. Subtract 10 from r1.
 *		d. If the result is negative, add the 10 
 *			back and subtract 1 from r0.
 */
_divide_by_ten:
	push 	{r3,lr}
	mov		r1, #0
	mov 	r3, #32
	dbt_loop:
		lsl 	r1, #1
		lsls 	r0, #1
		addcs 	r1, #1
		
		add	r0, #1
		
		subs 	r1, #10
		blmi	dbt_neg_flag_set
		subs 	r3, #1
		bne 	dbt_loop
	pop 	{lr,r3}
	bx	lr
		dbt_neg_flag_set:
			addmi	r1, #10
			sub	r0, #1
			bx	lr

/*
 * Takes the digit in r1 and outputs the corresponding
 * number which represents the digit in r1 for a seven
 * segment display into r2.
 */
_get_SSD_digit:
	push 	{r3}
	ldr	r2, =_ssd_digit_map
	lsl	r3, r1, #2
	ldr	r2, [r2,r3]
	pop	{r3}
	bx	lr

.data
	
_ssd_digit_map:
	.word 0x3f, 0x6, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x7, 0x7f, 0x6f
