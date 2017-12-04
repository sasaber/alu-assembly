# Add you macro definition here - do not touch cs47_common_macro.asm"
#<------------------ MACRO DEFINITIONS ---------------------->#

# Macro to extract nth bit for operations
# $regD: contains 0x0 or 0x1 depending on nth bit being 0 or 1
# $regS: Source bit patten
# $regT: Bit position n(0-31)
.macro extract_nth_bit ($regD, $regS, $regT)
# right shift by $regT (the bit position) 
srlv  	$regD, $regS, $regT
# AND it with 0x1 then assign it to $regD
and 	$regD, $regD, 0x1
.end_macro 

# Macro to insert value into nth bit
# $regD: this is the bit pattern to which we are inserting
# $regS: value n, the position (0-31)
# $regT: contains 0x0 or 0x1 (bit value to insert)
# $maskReg: holds temporary mask
.macro insert_to_nth_bit($regD, $regS, $regT, $maskReg)
# prepare a mask in $maskReg by shifting 0x1 for $regS amount
li 	$t9, 0x1

sllv 	$maskReg, $t9, $regS
# then invert it
nor 	$maskReg, $maskReg, $0
# AND it with bit pattern for masking
and	$regD, $regD, $maskReg
# Shift left $regT by amount in $regS
sllv	$regT, $regT, $regS
# logically OR this resultant pattern to $regD to insert the bit at nth position
or	$regD, $regD, $regT
.end_macro
