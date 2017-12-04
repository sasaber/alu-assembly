.include "./cs47_proj_macro.asm"
.text
.globl au_normal
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_normal:

	# Uses $s0, $s1
	# Store RTE - 4 * 4 = 16 bytes 
	addi	$sp, $sp, -16
	sw	$fp, 16($sp)
	sw	$ra, 12($sp)
	sw	$s0,  8($sp)

	addi	$fp, $sp, 16
	
	# TBD: Complete it
	beq 	$a2, '+', add_normal
	beq	$a2, '-', sub_normal
	beq	$a2, '*', mul_normal
	# Check for multiplication and division
add_normal:
	add 	$s0, $a0, $a1

	move	$v0, $s0 
	j 	alu_normal_end
sub_normal:
	sub 	$s0, $a0, $a1
	la	$v0, 0($s0)
	move	$v0, $s0 
	j	alu_normal_end
mul_normal:
	mult 	$a0, $a1
	mfhi 	$v1
	mflo	$v0	
	j 	alu_normal_end
div_normal:
	j	alu_normal_end
alu_normal_end:
	# Caller RTE restore (TBD)
	lw	$fp, 16($sp)
	lw	$ra, 12($sp)
	lw	$s0,  8($sp)

	addi	$sp, $sp, 16
	# Return to caller
	jr	$ra
	
