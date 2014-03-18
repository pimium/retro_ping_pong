.globl getNewBallPos
	.func getNewBallPos
getNewBallPos:

	x .req r0
	y .req r1
	pa .req r2
	pb .req r3
	push {r4, lr}

	cmp pa, #0
	ble pa_negatif$
	ldr r4, =1260
	cmp x, r4
	neggt pa, pa
	ldrgt x, =1260
	b pa_fin$
pa_negatif$:
	cmp x, #0
	neglt pa, pa
	movlt x, #0
pa_fin$:
add x, x, pa

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
add y, y, pb

.unreq x
.unreq y
.unreq pa
.unreq pb
pop {r4,  pc}
.endfunc
