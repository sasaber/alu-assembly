.include "./cs47_proj_macro.asm"
.include "./cs47_common_macro.asm"

.text
.globl au_logical
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_logical:

	# uses a2
	addi	$sp, $sp, -16
	sw	$fp, 16($sp)
	sw	$ra, 12($sp)
	sw	$a2,  8($sp)
	addi	$fp, $sp, 16 
	# TBD: Complete it
	# check the operation code 
	# if '+', add
	# if '-', sub
	beq 	$a2, '+', add_logical
	beq	$a2, '-', sub_logical
	beq 	$a2, '*', mul_signed_logical
	beq	$a2, '/', div_signed_logical
	j 	au_logical_end
add_logical:

	li	$a2, 0x00000000
	jal 	add_sub_logical
	j	au_logical_end
sub_logical:

	li	$a2, 0xFFFFFFFF
	jal	add_sub_logical
	j	au_logical_end
mul_signed_logical:
	jal	mul_signed
	j	au_logical_end
div_signed_logical:
	jal	div_signed
au_logical_end:
	lw	$fp, 16($sp)
	lw	$ra, 12($sp)
	lw	$a2,  8($sp)
	addi	$sp, $sp, 16
	
	jr 	$ra
	
add_sub_logical:

	# Caller RTE store 
	# uses $s0, $a1
	# store RTE - 4 * 4 = 16 bytes
	addi	$sp, $sp, -20
	sw	$fp, 20($sp)
	sw	$ra, 16($sp)
	sw	$s0, 12($sp)
	sw	$a1,  8($sp)
	addi	$fp, $sp, 20
	# begin
	li	$t0, 0x0		# I = 0
	li	$s0, 0x0		# S = 0	
	#li	$t1, 0x5
	extract_nth_bit($t1, $a2, $t0)	# C = $a2[0]

	beq 	$t1, 0x0, add_step 
	nor 	$a1, $a1, $0		# $a1 = ~$a1
add_step:
	# if I == 32, jump to end
	beq 	$t0, 0x20, add_sub_logical_end
	extract_nth_bit($t2, $a0, $t0)	# $a0[I]
	extract_nth_bit($t3, $a1, $t0)	# $a1[I]
	# Y = CI XOR (A XOR B)
	xor 	$t4, $t2, $t3		# (A XOR B) ---> $t4 = $a0[I] XOR $a1[I]
	xor	$t5, $t1, $t4		# $t5 = C XOR $t4
	# CO = CI.(A XOR B) + A.B
	and	$t6, $t1, $t4		# $t6 = C.($t4)
	and	$t7, $t2, $t3		# $t7 = $t2.$t3
	or	$t1, $t6, $t7		# update C to CO
	# S[I] = Y
	insert_to_nth_bit($s0, $t0, $t5, $t8)	
	# I = I + 1
	addi	$t0, $t0, 0x1		
	j 	add_step
add_sub_logical_end:
	# Caller RTE restore (TBD) 
	move 	$v0, $s0
	move 	$v1, $t1
	
	lw	$fp, 20($sp)
	lw	$ra, 16($sp)
	lw	$s0, 12($sp)
	lw	$a1,  8($sp)
	addi	$sp, $sp, 20
	# Return to Caller
	
	jr	$ra

# $a0: MCND, $a1: MULTIPLIER
mul_unsigned:
# s0 - $s3, $a0, $a1
	addi	$sp, $sp, -40
	sw	$fp, 40($sp)
	sw	$ra, 36($sp)
	sw	$s0, 32($sp)
	sw	$s1, 28($sp)
	sw	$s2, 24($sp)
	sw	$s3, 20($sp)
	sw	$a0, 16($sp)
	sw	$a1, 12($sp)
	sw	$a2,  8($sp)
	addi	$fp, $sp, 40
	
	li 	$s0, 0x0	# I = 0
	li 	$s1, 0x0	# H = 0
	la	$s2, 0($a1)	# L = Multiplier
	la	$s3, 0($a0)	# M = MCND
while_loop:
	extract_nth_bit($t4, $t2, $zero)	# initial R
	la	$t5, 0($a0) 			# $t5 = MCND
	la	$a0, 0($t4)			# $a0 = R initial
	jal  	bit_replicator
	la	$t4, 0($v0)			# R final
	and	$t7, $t3, $t4			# X = M & R
	la	$a0, 0($s1)			# a0 = H
	la 	$a1, 0($t7)			# a1 = X
	li	$a2, '+'
	jal	au_logical			# v0 is the sum
	la	$s1, 0($v0)			# H = H + X
	li	$t6, 0x1
	li	$t4, 0x1f			# 31 in decimal
	srlv 	$s2, $s2, $t6			# L = L >> 1
	extract_nth_bit($t8, $s1, $zero) 	# H[0] = $t8
	insert_to_nth_bit($s2, $t4, $t8, $t9)	# L[31] = H[0]
	srlv 	$s1, $s1, $t6			# H = H >> 1
	addi	$s0, $s0, 0x1			# I = I + 1
	beq	$s0, 0x20, mul_unsigned_end	# if I == 32
	j	while_loop			# else
mul_unsigned_end:
	#print_reg_int($s2)
	move 	$v0, $s2
	move 	$v1, $s1
	#mtlo	$v0
	#mthi	$v1
	
	lw	$fp, 40($sp)
	lw	$ra, 36($sp)
	lw	$s0, 32($sp)
	lw	$s1, 28($sp)
	lw	$s2, 24($sp)
	lw	$s3, 20($sp)
	lw	$a0, 16($sp)
	lw	$a1, 12($sp)
	lw	$a2,  8($sp)
	addi	$sp, $sp, 40
	
	jr	$ra
	
mul_signed:
	addi	$sp, $sp, -32
	sw	$fp, 32($sp)
	sw	$ra, 28($sp)
	sw	$s4, 24($sp)
	sw	$s5, 20($sp)
	sw	$s6, 16($sp)
	sw	$a0, 12($sp)
	sw	$a1,  8($sp)
	addi	$fp, $sp, 32

	la	$s4, 0($a0)	# N1 initial
	la	$s5, 0($a1)	# N2 initial
	jal	twos_complement_if_neg	# for N1
	la	$t0, 0($v0)	# new N1
	la	$a0, 0($a1) 	# prep work
	jal	twos_complement_if_neg	# for N2
	la 	$a1, 0($v0)	# new N2
	la	$a0, 0($t0)
	jal	mul_unsigned	# Rhi -> v1 and Rlo -> v0
	addi	$t7, $zero, 31	
	extract_nth_bit($t9, $s4, $t7)	# a0[31]
	extract_nth_bit($t8, $s5, $t7)  # a1[31]
	xor 	$s6, $t9, $t8		# S
	bne	$s6, 1, mul_signed_end
	move	$a0, $v0	# a0 = Rlo
	move 	$a1, $v1	# a1 = Rhi
	jal	twos_complement_64bit
	
mul_signed_end:
	# restore
	lw	$fp, 32($sp)
	lw	$ra, 28($sp)
	lw	$s4, 24($sp)
	lw	$s5, 20($sp)
	lw	$s6, 16($sp)
	lw	$a0, 12($sp)
	lw	$a1,  8($sp)
	addi	$sp, $sp, 32
	
	jr 	$ra

# $a0 is the number of which we are computing the complement
twos_complement_if_neg:
	addi 	$sp, $sp, -16
	sw	$fp, 16($sp)
	sw	$ra, 12($sp)
	sw	$a0,  8($sp)
	addi	$fp, $sp, 16 
	# blt 	$a0, 0x0, twos_complement
	# because if we blt, we're not treating it as a procedure 
	subi 	$a0, $zero, 25
	bge 	$a0, 0x0, twos_complement_if_neg_end
	jal	twos_complement
twos_complement_if_neg_end:

	lw	$fp, 16($sp)
	lw	$ra, 12($sp)
	lw	$a0,  8($sp)
	addi	$sp, $sp, 16

	jr	$ra

# $a0 is the number of which we are computing the complement	
twos_complement:

	addi	$sp, $sp, -24
	sw	$fp, 24($sp)
	sw	$ra, 20($sp)
	sw	$a0, 16($sp)
	sw	$a1, 12($sp)
	sw	$a2,  8($sp)
	addi	$fp, $sp, 24

	nor	$a0, $a0, $zero		# $a0 = ~$a0
	addi 	$a1, $zero, 1		# $a1 = 1
	li	$a2, '+'
	jal	au_logical		# adding ~$a0 and 1

	lw	$fp, 24($sp)
	lw	$ra, 20($sp)
	lw	$a0, 16($sp)
	lw	$a1, 12($sp)
	lw	$a2,  8($sp)
	addi	$sp, $sp, 24
	
	jr	$ra

bit_replicator:
	addi	$sp, $sp, -16
	sw	$fp, 16($sp)
	sw	$ra, 12($sp)
	sw	$a0,  8($sp)
	addi	$fp, $sp, 16
		
	beq 	$a0, 0x0, replicate_zero
	li	$t0, 0xFFFFFFFF		# if !zero
	j	bit_replicator_end
replicate_zero:
	li	$t0, 0x00000000		# else
bit_replicator_end:
	move $v0, $t0			# return value
	
	lw	$fp, 16($sp)
	lw	$ra, 12($sp)
	lw	$a0,  8($sp)
	addi	$sp, $sp, 16
	
	jr	$ra

twos_complement_64bit:
	addi	$sp, $sp, -24
	sw	$fp, 24($sp)
	sw	$ra, 20($sp)
	sw	$a0, 16($sp)
	sw	$a1, 12($sp)
	sw	$a2,  8($sp)
	addi	$fp, $sp, 24
	
	nor	$a0, $a0, $zero		# $a0 = ~$a0
	nor	$a1, $a1, $zero		# $a1 = ~$a1
	la	$t0, 0($a1)		# t0 = a1
	addi 	$a1, $zero, 1		# a1 = 1
	li	$a2, '+'
	jal	au_logical		# a0 + 1
	la	$t0, 0($v0)
	la	$a0, 0($v1) 
	li	$a2, '+'		
	jal	au_logical
	move 	$v1, $v0
	move	$v0, $t0
	
twos_complement_64bit_end:
	lw	$fp, 24($sp)
	lw	$ra, 20($sp)
	lw	$a0, 16($sp)
	lw	$a1, 12($sp)
	lw	$a2,  8($sp)
	addi	$sp, $sp, 24
	
	jr	$ra
	
div_unsigned:
	# s0 s1 a0, a2, 
	addi	$sp, $sp, -28
	sw	$fp, 28($sp)
	sw	$ra, 24($sp)
	sw	$a0, 20($sp)
	sw	$a2, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1,  8($sp)
	addi	$fp, $sp, 28
	
	li	$t0, 0x0	# t0 = I = 0
	li	$t1, 0x0	# t1 = R = 0
	la	$s0, 0($a0)	# original values
	la	$s1, 0($a1)
div_while_loop:
	li	$t3, 0x1	#t3 = 1
	sllv	$t1, $t1, $t3	# r << 1
	li 	$t3, 0x1f	# 31
	extract_nth_bit($t4, $a0, $t3)	# t4 = Q[31]
	insert_to_nth_bit($t1, $zero, $t4, $t5)
	li	$t3, 0x1
	sllv	$a0, $a0, $t3	# Q << 1
	la	$t6, 0($a0)
	la	$a0, 0($t1)	# move R tp a0
	li	$a2, '-'
	jal	au_logical
	la	$a0, 0($t6)
	la	$t5, 0($v0)	# S = R - D
	bge	$t5, $zero, intermediate_label
div_while_loop_continued:	
	addi	$t0, $t0, 0x1
	addi	$t3, $zero, 32
	beq	$t0, $t3, div_unsigned_end
	j	div_while_loop
intermediate_label:
	move	$t1, $t5	# R = S
	addi	$t3, $zero, 1 	# t3 = 1
	insert_to_nth_bit($a0, $zero, $t3, $t6)	# Q[0] = 1
	j	div_while_loop_continued
div_unsigned_end:
	move	$v0, $a0	#quotient
	move	$v1, $t1	#remainder
	
	lw	$fp, 28($sp)
	lw	$ra, 24($sp)
	lw	$a0, 20($sp)
	lw	$a2, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1,  8($sp)
	addi	$sp, $sp, 28
	jr	$ra


# SHOULD WE USE TWOS COMP 64 BIT like in mul signed
div_signed:

	# a0 a1 
	addi	$sp, $sp, -20
	sw	$fp, 20($sp)
	sw	$ra, 16($sp)
	sw	$a0, 12($sp)
	sw	$a1,  8($sp)
	addi	$fp, $sp, 20
	
	# begin
	la	$t0, 0($a0)	# a0 original
	la	$t1, 0($a1)	# a1 original
	jal	twos_complement_if_neg	# for a0
	la 	$t2, 0($v0)	# new N1
	la	$a0, 0($t1)
	jal	twos_complement_if_neg	# for a1
	la 	$a1, 0($v0)	# new N2
	la	$a0, 0($t2)	
	jal	div_unsigned
	la	$t2, 0($v0)	# Q
	la	$t3, 0($v1)	# R
	li	$t4, 0x1f
	extract_nth_bit($t5, $t0, $t4)	# a0[31]
	extract_nth_bit($t6, $t1, $t4)	# a1[31]
	xor	$t7, $t5, $t6	# S = a0[31] xor a1[31]
	la 	$a0, 0($t2)
	bne	$t7, 1, find_sign_of_R
	jal	twos_complement
	la	$t2, 0($v0)	# 2's complement of Q
find_sign_of_R:
	la	$t7, 0($t5)	# s = a0[31]
	bne	$t7, 1, div_signed_end
	la	$a0, 0($t3)
	jal	twos_complement
	la	$t3, 0($v0)	# 2's complement of R
div_signed_end:
	move	$v0, $t2
	move	$v1, $t3
	
	lw	$fp, 20($sp)
	lw	$ra, 16($sp)
	lw	$a0, 12($sp)
	lw	$a1,  8($sp)
	addi	$sp, $sp, 20
	
	jr	$ra