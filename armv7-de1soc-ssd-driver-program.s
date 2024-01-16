.global _start

//SSD addresses.
.equ SSD0_3, 0xff200020
.equ SSD4_5, 0xff200030

//just a random number to display.
.equ number, 6258

.equ delay_count, 10000000

_start:
	//clear all register.
	mov sp, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	mov r4, #0
	mov r5, #0

	//clear SSDs
	bl _clear_SSD

	//load number into r0.
	ldr r0, =number

	//display it on SSD.
	bl _display
	
_finish:
	bal _finish

/*
 * Take the number in r0 and display
 * on the SSD.
 *
 * r2 is where current digit's SSD value is stored.
 * r4 is the left shift counter used to shift value in r2.
 * r5 is the digit counter
 *
 * 1. Store r1 thru r5 and link register in stack.
 * 2. Clear r2 thru r4. Store 4 in r5 (1st 4 SSDs).
 * 3. In a loop display LS 4 digits on 1st SSD set.
 * 4. Store 3 in r5 (2nd 2 SSDs).
 * 5. In a loop display LS 2 digits on 2nd SSD set.
 */
_display:
	push {r1,r2,r3,r4,r5,lr}
	mov r2, #0
	mov r3, #0
	mov r4, #0
	mov r5, #4
	display_loop_1:
		bl _divide_by_ten
		bl 	_get_SSD_digit
		lsl r2, r4
		orr r3, r2, r3
		bl	_display_SSD_set1
		subs r0, #0
		popeq {lr,r5,r4,r3,r2,r1}
		bxeq lr
		add r4, #8
		subs r5, #1
		bne display_loop_1
	mov r2, #0
	mov r3, #0
	mov r4, #0
	mov r5, #3
	display_loop_2:
		bl _divide_by_ten
		bl 	_get_SSD_digit
		lsl r2, r4
		orr r3, r2, r3
		bl	_display_SSD_set2
		subs r0, #0
		popeq {lr,r5,r4,r3,r2,r1}
		bxeq lr
		add r4, #8
		subs r5, #1
		bne display_loop_2
	pop {lr,r5,r4,r3,r2,r1}
	bx lr

/*
 * Clears both SSDs.
 *
 * Algorithm:
 *  1. Store contents of r3 and the link register in stack.
 *  2. Clear r3.
 *  3. Call SSD display function for SSD1 & SSD2.
 *  4. Restore contents of link register and r3.
 *  5. Return.
 */
_clear_SSD:
	push {r3,lr}
	mov	r3, #0
	bl _display_SSD_set1
	bl _display_SSD_set2
	pop {lr,r3}
	bx lr

_delay:
	push {r0}
	ldr r0, =delay_count
	delay_loop:
		subs r0, #1
		bne delay_loop
	pop {r0}
	bx lr

/*
 * Display contents of r3 in SSD set 1.
 * 
 * Algorithm:
 *  1. Store contents of r1 in stack.
 *  2. Load SSD1's address in r1.
 *  3. Store the contents of r3 in the address 
 *     pointed by r1 (the address of SSD1).
 *  4. Restore contents of r1.
 *  5. Return.
 */
_display_SSD_set1:
	push {r1}
	ldr r1, =SSD0_3
	str r3, [r1]
	pop {r1}
	bx 	lr
	
/*
 * Display contents of r3 in SSD set 2.
 * 
 * Algorithm: Same as SSD1, except SSD address.
 */
_display_SSD_set2:
	push {r1}
	ldr r1, =SSD4_5
	str r3, [r1]
	pop {r1}
	bx lr

/*
 * Divide number in r0 by 10, put quotient in
 * r0 and remainder in r1.
 *
 * Algorithm:
 *	1. Store contents of r3 and lr in stack.
 *	2. Clear r1.
 *	3. Set r3 (our loop counter) to 32, because 
 *     we're dividing a 32 bit number.
 *	4. In a loop running 32 times,
 *		a. Left shifts the MSB of r0 to LSB of r1.
 *		b. Add 1 to r0. (building the quotient)
 *		c. Subtract 10 from r1.
 *		d. If the result is negative, add the 10 
 *			back and subtract 1 from r0. (reversing step b and c).
 */
_divide_by_ten:
	push {r3,lr}
	mov r1, #0
	mov r3, #32
	dbt_loop:
		lsl r1, #1
		lsls r0, #1
		addcs r1, #1
		
		add	r0, #1
		
		subs r1, #10
		blmi dbt_neg_flag_set
		subs r3, #1
		bne dbt_loop
	pop {lr,r3}
	bx lr
		dbt_neg_flag_set:
			add r1, #10
			sub	r0, #1
			bx	lr

/*
 * Takes the digit in r1 and outputs the corresponding
 * number which represents the digit in r1 for a seven
 * segment display into r2.
 * 
 * Algorithm:
 *  1. Store contents of r3 in stack.
 *  2. Load the address of the SSD digit map into r2.
 *  3. The SSD mapped value for the digit in r1 is in 
 *     the SSD digit map at an offset given by the digit 
 *     itself. The offset is obtained by multiplying the
 *     digit by 4 (because the values in the map is stored
 *     4 bytes apart from one another). So we left shift
 *     the value in r1 twice (aka multiply by 4) and store
 *     this value in r3, which is the offset.
 *  4. We load the value in the map at the offset into r2.
 *     we now have the SSD mapped value for the digit in r1,
 *     in r2.
 *  5. Restore contents back to r3.
 *  6. Return
 */
_get_SSD_digit:
	push {r3}
	ldr	r2, =_ssd_digit_map
	lsl	r3, r1, #2
	ldr	r2, [r2,r3]
	pop	{r3}
	bx lr

.data
	
/*
 * SSD value map for decimal digits from 0 to 9 in sequence.
 */
_ssd_digit_map:
	.word 0x3f, 0x6, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f
	       //0   //1  //2   //3   //4   //5   //6   //7   //8   //9
