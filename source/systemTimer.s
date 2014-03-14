/******************************************************************************
*	systemTimer.s
*	 by Alex Chadwick
*
*	A sample assembly code implementation of the OK04 operating system.
*	See main.s for details.
*
*	systemTime.s contains the code that interacts with the system timer.
******************************************************************************/

/*
* The system timer runs at 1MHz, and just counts always. Thus we can deduce
* timings by measuring the difference between two readings.
*/


/*
* GetSystemTimerBase returns the base address of the System Timer region as a
* physical address in register r0.
* C++ Signature: void* GetSystemTimerBase()
*/
.globl GetSystemTimerBase
GetSystemTimerBase: 
	ldr r0,=0x20003000
	mov pc,lr

.globl GetInterruptBase
GetInterruptBase: 
	ldr r0,=0x2000B000 @200 pending;218 enable basic irq;224 disable basic irq
	mov pc,lr

.globl DisableBasicIRQ
DisableBasicIRQ: 
	ldr r0,=0x2000B000
@	ldr r1, [r0,#0x224]
	mov r1, #0
	str r1, [r0,#0x224]
	mov pc,lr
.globl EnableBasicIRQ
EnableBasicIRQ: 
	ldr r0,=0x2000B000
	ldr r1, [r0,#0x218]
	orr r1, r1, #1
	str r1, [r0,#0x218]
	mov pc, lr

/*
* GetTimeStamp gets the current timestamp of the system timer, and returns it
* in registers r0 and r1, with r1 being the most significant 32 bits.
* C++ Signature: u64 GetTimeStamp()
*/
.globl GetTimeStamp
GetTimeStamp:
	push {lr}
	bl GetSystemTimerBase
	ldrd r0,r1,[r0,#4]
	pop {pc}

.globl SetTimer
SetTimer:
	push {lr}
	mov r2, r0
	bl GetInterruptBase
	str r2,[r0,#0x400] @ load timer value
	str r2,[r0,#0x418] @ reload timer value
	
@	bl GetSystemTimerBase
@	ldrd r0,r1,[r0,#4]
@	add r2, r0, r2
@	str r2,[r0,#0x10] @ load timer value
	pop {pc}

.globl EnableTimerInterrupt
EnableTimerInterrupt:
	push {lr}
	bl GetInterruptBase
	ldr r1, =0x3E00a0
	str r1,[r0,#0x408] @ reset control register and enable interrupt

	mov r1, #1 @Enable basic Interrupt
	str r1,[r0,#0x218]

	pop {pc}

.globl EnableIRQ
EnableIRQ:
	mrs r1, cpsr
	bic r1, r1, #0x80
	msr cpsr_c, r1
	mov pc,lr
.globl DisableIRQ
DisableIRQ:
	mrs r1, cpsr
	orr r1, r1, #0xc0
	msr cpsr_c, r1
	mov pc,lr

.globl InterruptHandler
InterruptHandler:
	sub r14,r14,#4
	stmfd sp!, {r0-r3, r12, r14}
	bl DisableIRQ
	bl GetInterruptBase
	ldr r1, [r0, #0x200]
	tst r1, #0x00000001
beq fin$
	ldr r2,[r0, #0x414]
	cmp r2, #1
	bleq timer_isr

fin$:
	bl EnableIRQ
	ldmfd sp!, {r0-r3, r12, r15}^

/*
* Wait waits at least a specified number of microseconds before returning.
* The duration to wait is given in r0.
* C++ Signature: void Wait(u32 delayInMicroSeconds)
*/
.globl Wait
Wait:
	delay .req r2
	mov delay,r0
	push {lr}
	bl GetTimeStamp
	start .req r3
	mov start,r0

	loop$:
		bl GetTimeStamp
		elapsed .req r1
		sub elapsed,r0,start
		cmp elapsed,delay
		.unreq elapsed
		bls loop$
		
	.unreq delay
	.unreq start
	pop {pc}




