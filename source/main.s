/******************************************************************************
*	main.s
*	 by Alex Chadwick
*
*	A sample assembly code implementation of the ok04 operating system, that 
*	simply turns the OK LED on and off repeatedly, synchronising using the 
*	system timer.
*	Sections changed since ok03.s are marked with NEW.
*
*	main.s contains the main operating system, and IVT code.
******************************************************************************/

/*
* .globl is a directive to our assembler, that tells it to export this symbol
* to the elf file. Convention dictates that the symbol _start is used for the 
* entry point, so this all has the net effect of setting the entry point here.
* Ultimately, this is useless as the elf itself is not used in the final 
* result, and so the entry point really doesn't matter, but it aids clarity,
* allows simulators to run the elf, and also stops us getting a linker warning
* about having no entry point. 
*/

.equ USR_Stack, 0x20000
.equ IRQ_Stack, 0x8000
.equ SVC_Stack, IRQ_Stack-128

.equ Usr32md, 0x10
.equ FIQ32md, 0x11
.equ IRQ32md, 0x12
.equ SVC32md, 0x13
.equ Abt32md, 0x17
.equ Und32md, 0x1b
.equ Sys32md, 0x1f
.equ NonInt , 0xc0

.section .init

.globl _start
	.func _start
_start:

/*
* Branch to the actual main code.
*/
b main

	.endfunc
/* ARM exception vector table. This is copied to address 0. See A2.6
 * "Exceptions" of the ARM Architecture Reference Manual. */
_vectors:
ldr pc, reset_addr /* Reset handler */
ldr pc, undef_addr	/* Undefined instruction handler */
ldr pc, swi_addr	/* Software interrupt handler */
ldr pc, prefetch_addr /* Prefetch abort handler */
ldr pc, abort_addr	/* Data abort handler */
ldr pc, reserved_addr /* Reserved */
ldr pc, irq_addr	/* IRQ (Interrupt request) handler */
ldr pc, fiq_addr	/* FIQ (Fast interrupt request) handler */

reset_addr: .word main
undef_addr: .word main
swi_addr: .word InterruptHandler
prefetch_addr: .word main
abort_addr: .word main
reserved_addr: .word main
irq_addr: .word InterruptHandler
fiq_addr: .word InterruptHandler

_endvectors:

/*
* This command tells the assembler to put this code with the rest.
*/
.section .text

/*
* main is what we shall call our main operating system method. It never 
* returns, and takes no parameters.
* C++ Signature: void main(void)
*/

main:

ldr r13, SVC_NewStack
mov r2, #NonInt|IRQ32md
msr cpsr_c, r2
ldr r13, IRQ_StackNew
mov r2, #Sys32md
msr cpsr_c, r2
ldr r13, USR_StackNew


SVC_NewStack: .word   SVC_Stack 
IRQ_StackNew: .word   IRQ_Stack 
USR_StackNew: .word   USR_Stack

/*
* Set the stack point to 0x8000.
*/
@mov sp,#0x8000

/* Copy the ARM exception table from .init section to address 0,
* including the absolute address table. Here we assume it is exactly
* 16 words. */
mov r0, #0
ldr r1, =_vectors
ldmia r1!, {r2-r9}
stmia r0!, {r2-r9}
ldmia r1!, {r2-r9}
stmia r0!, {r2-r9}

bl EnableIRQ
bl EnableTimerInterrupt
bl EnableBasicIRQ

mov r0, #0x10
lsl r0, r0, #2
bl SetTimer


/* 
* Setup the screen.
*/
	mov r0,#1280
	mov r1,#768
	mov r2,#16
	bl InitialiseFrameBuffer

/* 
* Check for a failed frame buffer.
*/
	teq r0,#0
	bne noError$
		

	error$:
		b error$

	noError$:

	fbInfoAddr .req r4
	mov fbInfoAddr,r0
	.unreq fbInfoAddr

/* NEW
* Let our drawing method know where we are drawing to.
*/
	bl SetGraphicsAddress

	mov r0,#0xf0
	bl SetForeColour

	x .req r4
	y .req r5
	pa .req r6
	pb .req r7
	balkenX .req r8
	counter .req r9
	counter_diff .req r10

	mov pa,#2
	mov pb,#5
	mov balkenX,#768
	
	mov x, #0
	mov y, #0

	pinNum .req r0
pinFunc .req r1
mov pinNum,#16
mov pinFunc,#1
bl SetGpioFunction

mov pinNum,#14
mov pinFunc,#0
bl SetGpioFunction
mov pinNum,#23
mov pinFunc,#0
bl SetGpioFunction
.unreq pinNum
.unreq pinFunc


@bl SetGpioPin23

mov r0,#0xff
lsl r0, #3
bl SetForeColour
mov r0, balkenX
bl DrawBalken

render$:

	mov r0,#0x00
	bl SetForeColour
	mov r0, x
	mov r1, y
	bl DrawBall

	cmp pa, #0
	ble pa_negatif$
	ldr r0, =1260
	cmp x, r0
	neggt pa, pa
	ldrgt x, =1260
	b pa_fin$
pa_negatif$:
	cmp x, #0
	neglt pa, pa
	movlt x, #0
pa_fin$:
add x, pa

cmp pb, #0
	ble pb_negatif$
	cmp y, #760
	neggt pb, pb
	movgt y, #760
	b pb_fin$
pb_negatif$:
	cmp y, #30
	negle pb, pb
	movle y, #30
pb_fin$:
add y, pb

	mov r0,#0xff
	bl SetForeColour
	mov r0, x
	mov r1, y
	bl DrawBall

warte$:
	ldr r0, add_cnt_interrupt
	ldr r0, [r0]
	cmp r0, counter
	beq warte$
	
	sub counter_diff, counter, r0
	lsr counter_diff, #1
	mov counter, r0

mov r0, #14
bl GetGpioValue
cmp r0, #0
beq andererichtung$

mov r0,#0x00
bl SetForeColour
mov r0, balkenX
bl DrawBalken

sub balkenX, #1
cmp balkenX, #0
ldreq r1, =1260
moveq balkenX, r1
mov r0,#0xff
lsl r0, #3
bl SetForeColour
mov r0, balkenX
bl DrawBalken

andererichtung$:
mov r0, #23
bl GetGpioValue
cmp r0, #0
beq render$

mov r0,#0x00
bl SetForeColour
mov r0, balkenX
bl DrawBalken

add balkenX, #1
ldreq r1, =1260
cmp balkenX, r1
moveq balkenX, #0
mov r0,#0xff
lsl r0, #3
bl SetForeColour
mov r0, balkenX
bl DrawBalken

	b render$

	.unreq x
	.unreq y

	.unreq balkenX
	.unreq counter_diff

/*
* Use our new SetGpio function to set GPIO 16 to low, causing the LED to turn 
* on.
*/


.globl timer_isr
timer_isr:
push {lr}

	ldr r1, add_cnt_interrupt
	ldr r0,[r1]
	add r0, r0, #1
@	and r0, r0, #1
	str r0, [r1]

	bl GetInterruptBase
	str r2,[r0,#0x40c] @ reset control register
	ldr r2, =0x00007000
	str r2,[r0,#0x400] @ load register
pop {pc}

/* Labels needed to access data */
add_cnt_interrupt : .word cnt_interrupt
add_cnt_interrupt_old : .word cnt_interrupt_old

.section .data

.balign 4
cnt_interrupt:     .word 0x0
cnt_interrupt_old: .word 0x0
