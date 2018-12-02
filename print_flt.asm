; 2009/08/17 Josef Kubin
;
; asmsyntax=pic18

#include <p18cxxx.inc>

; functions to print floating point numbers (IEEE754)
; -single precision
; -single precision with extended mantissa

; typedef struct {
; 	unsigned char mant[5];
; 	float val;
; } extsingle_t;
;
; void print_xflt(char *bfr, extsingle_t *num, unsigned int format);
; void print_flt_to_bcd(char *bfr, float *num, unsigned int format);
; void print_flt(char *bfr, float *num, unsigned int format);
;
; format |INTEG_W|TOTAL_W| ---> |000IIIII|000WWWWW|
; see format.h

#define TOTAL_W		0x00
#define INTEG_W		0x01
#define PTRL		0x02
#define PTRH		0x03
#define BFRL		0x04
#define BFRH		0x05
#define FRAMEL		0x06
#define FRAMEH		0x07
#define FLAGS		0x08	; Keep address!
#define FRACW		0x09
#define INTW		0x0a
#define INTWS		0x0b
#define OFFSET		0x0c
#define COUNTER		0x0d
#define EXP		0x0e
#define SPACES		0x0f
#define FLOAT0		0x10
#define FLOAT1		0x11
#define FLOAT2		0x12
#define FLOAT3		0x13
#define FLOAT4		0x14
#define FLOAT5		0x15
#define FLOAT6		0x16
#define FLOAT7		0x17
#define FBCD0		0x18
#define FBCD1		0x19
#define FBCD2		0x1a
#define FBCD3		0x1b
#define FBCD4		0x1c
#define FBCD5		0x1d
#define FBCD6		0x1e
#define FBCD7		0x1f
#define IBCD0		0x20
#define IBCD1		0x21
#define IBCD2		0x22
#define IBCD3		0x23
#define IBCD4		0x24
#define IBCD5		0x25
#define IBCD6		0x26
#define IBCD7		0x27
#define IBCD8		0x28
#define IBCD9		0x29
#define TMP		0x2a

; FLAGS
#define NEG		0x0	; Keep it 0x0!
#define NAN		0x1

#define DECIMAL_POINT	'.'
;#define DECIMAL_POINT	','

#define MAX_EXP		194	; 126 + 67 + 1
#define MAX_INT_WIDTH	20

	extern	_bin_to_bcd
	extern	_find_width
	extern	_memset
	extern	_print_bcd
	global	cp_extended
	global	print_flt
	global	print_flt_to_bcd
	global	print_xflt
	radix	dec

	code

print_flt
	rcall	init

	movsf	[PTRL], FSR0L
	movsf	[PTRH], FSR0H

	addfsr	2, FLOAT5
	rcall	cp_single
	movwf	[TMP]

	; convert IEEE 754 number to unpacked float format
	; |eeee eeee|1mmm mmmm|mmmm mmmm|mmmm mmmm|
	bcf	STATUS, C
	rlcf	[FLOAT7], F
	rlcf	[TMP], F

	bz	print_zero

	; save sign flag, if present
	rlcf	[FLAGS], F

	rcall	bound_tst
	bnc	mant_flt
	rcall	print_err
	bra	exit

mant_flt
	rcall	process_mant

print_zero
	rcall	auto_fmt

	bra	exit

print_flt_to_bcd
	rcall	init

	movsf	[PTRL], FSR0L
	movsf	[PTRH], FSR0H

	addfsr	2, FLOAT5

	rcall	cp_single
	movwf	[TMP]

	; convert IEEE 754 number to unpacked float format
	; |eeee eeee|1mmm mmmm|mmmm mmmm|mmmm mmmm|
	bcf	STATUS, C
	rlcf	[FLOAT7], F
	rlcf	[TMP], F

	bz	zero_bcd

	rcall	bound_tst
	bnc	mant_bcd

	rcall	ptr_to_bfr

	; print BCD max
	movlw	0x99
	movwf	POSTINC0
	movwf	POSTINC0
	movwf	POSTINC0
	movwf	POSTINC0

	bra	exit

mant_bcd
	rcall	process_mant

	decf	[INTEG_W], W
	subwf	[TOTAL_W], W
	movwf	[FRACW]

	rcall	decode_frac

	rcall	round_params

	rcall	round

zero_bcd
	rcall	ptr_to_bfr

	bcf	STATUS, C
	rrcf	[INTEG_W], W
	addlw	FBCD4
	addwf	FSR2L, F
	movlw	0
	addwfc	FSR2H, F

;copy_4B
	movff	POSTINC2, POSTINC0
	movff	POSTINC2, POSTINC0
	movff	POSTINC2, POSTINC0
	movff	POSTINC2, POSTINC0

	bra	exit

print_xflt
	rcall	init

	movsf	[PTRL], FSR0L
	movsf	[PTRH], FSR0H

	rcall	cp_extended
	movwf	[TMP]

	; convert IEEE 754 number to unpacked float format
	; |eeee eeee|1mmm mmmm|mmmm mmmm|mmmm mmmm|
	bcf	STATUS, C
	rlcf	[FLOAT7], F
	rlcf	[TMP], F

	bz	explicit_int_width_tst

	; save sign flag, if present
	rlcf	[FLAGS], F

	rcall	bound_tst
	bnc	mant_ext
	rcall	print_err
	bra	exit

mant_ext
	rcall	process_mant

explicit_int_width_tst
	tstfsz	[INTEG_W]
	bra	expl_fmt_ext
	rcall	auto_fmt
	bra	exit

cp_extended
	addfsr	2, FLOAT0

	movff	POSTINC0, POSTINC2
	movff	POSTINC0, POSTINC2
	movff	POSTINC0, POSTINC2
	movff	POSTINC0, POSTINC2
	movff	POSTINC0, POSTINC2
cp_single
	movff	POSTINC0, POSTINC2
	movff	POSTINC0, POSTINC2
	movff	POSTINC0, POSTINC2
	movf	POSTINC0, W

	subfsr	2, FBCD0
	return

bound_tst
	; NaN or Inf test
	incf	[TMP], W
	bnz	oversize_tst
	bsf	[FLAGS], NAN
	return

oversize_tst
	movlw	MAX_EXP
	subwf	[TMP], W
	return

print_err
	rcall	ptr_to_bfr

	movlw	'?'	; Not A Number
	btfss	[FLAGS], NAN
	movlw	'#'	; other error
err_mark
	movwf	POSTINC0
	decfsz	[TOTAL_W], F
	bra	err_mark
	return

ptr_to_bfr
	movsf	[BFRL], FSR0L
	movsf	[BFRH], FSR0H
	return

init
	movff	FSR2L, POSTINC1
	movff	FSR2H, POSTINC1
	movff	FSR1L, FSR2L
	movff	FSR1H, FSR2H
	subfsr	2, FRAMEH + 1
	addfsr	1, TMP - FRAMEH - 1

	movf	[TOTAL_W], W
	bz	zero_width

	movlw	FLAGS
	rcall	set_fsr0

	movlw	TMP - FLAGS
	movwf	PRODL
	movlw	0

	rcall	_memset

save_frame_ptr
	movff	FSR2L, PCLATH
	movff	FSR2H, PCLATU
	return

zero_width
	pop
	bra	exit

expl_fmt_ext
	rcall	explicit_fmt
exit
	subfsr	1, TMP - FRAMEH
	movff	POSTDEC1, FSR2H
	movff	INDF1, FSR2L
	return

process_mant
	bsf	STATUS, C
	rrcf	[FLOAT7], F

	movlw	126
	subwf	[TMP], F
	btfsc	STATUS, Z
	return
	bc	int_to_bcd

	movlw	FLOAT7
	rcall	set_fsr0

	negf	[TMP]
	movf	[TMP], W

shift8
	bcf	STATUS, C
	rrcf	POSTDEC0, F
	rrcf	POSTDEC0, F
	rrcf	POSTDEC0, F
	rrcf	POSTDEC0, F
	rrcf	POSTDEC0, F
	rrcf	POSTDEC0, F
	rrcf	POSTDEC0, F
	rrcf	POSTDEC0, F
	addfsr	0, 8
	decfsz	WREG, F
	bra	shift8

	subfsr  0, 7
	btfss	STATUS, C
	return

;round_proc
	movlw	0
	incf    POSTINC0, F
	addwfc	POSTINC0, F
	addwfc	POSTINC0, F
	addwfc	POSTINC0, F
	addwfc	POSTINC0, F
	addwfc	POSTINC0, F
	addwfc	POSTINC0, F
	addwfc	INDF0, F
	return

int_part
	rlcf	[FLOAT0], F
	rlcf	[FLOAT1], F
	rlcf	[FLOAT2], F
	rlcf	[FLOAT3], F
	rlcf	[FLOAT4], F
	rlcf	[FLOAT5], F
	rlcf	[FLOAT6], F
	rlcf	[FLOAT7], F
	movf	[IBCD0], W
	addwfc	[IBCD0], W
	daw
	movwf	[IBCD0]
	movf	[IBCD1], W
	addwfc	[IBCD1], W
	daw
	movwf	[IBCD1]
	movf	[IBCD2], W
	addwfc	[IBCD2], W
	daw
	movwf	[IBCD2]
	movf	[IBCD3], W
	addwfc	[IBCD3], W
	daw
	movwf	[IBCD3]
	return

int_to_bcd
	bcf	STATUS, C

tight_loop
	rcall	int_part
	dcfsnz	[TMP], F
	return
	andlw	0xc0
	bz	tight_loop

big_loop
	rcall	int_part
	movf	[IBCD4], W
	addwfc	[IBCD4], W
	daw
	movwf	[IBCD4]
	movf	[IBCD5], W
	addwfc	[IBCD5], W
	daw
	movwf	[IBCD5]
	movf	[IBCD6], W
	addwfc	[IBCD6], W
	daw
	movwf	[IBCD6]
	movf	[IBCD7], W
	addwfc	[IBCD7], W
	daw
	movwf	[IBCD7]
	movf	[IBCD8], W
	addwfc	[IBCD8], W
	daw
	movwf	[IBCD8]
	movf	[IBCD9], W
	addwfc	[IBCD9], W
	daw
	movwf	[IBCD9]
	decfsz	[TMP], F
	bra	big_loop
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

explicit_fmt
	; WXX_EXX
	movf	[INTEG_W], W
	subwf	[TOTAL_W], W
	bnc	expl_e_fmt

	decf	WREG
	movwf	[FRACW]

	; WXX_XX
	movf	[INTEG_W], W
	rcall	set_int_width

	rcall	decode_frac

print_dec_fmt
	rcall	print_prefix

	; set counter
	movf	[INTW], W
	movwf	PRODL

	rcall	set_int_ptr

	; int part
	rcall	_print_bcd

	; decimal point
	movf	[TOTAL_W], W
	subwf	[INTWS], W
	btfsc	STATUS, C
	return

	movf	[INTWS], W
	subwf	[TOTAL_W], F

	movlw	DECIMAL_POINT
	movwf	POSTINC0
	dcfsnz	[TOTAL_W], F
	return

	; frac part
	movsf	[TOTAL_W], PRODL
	movlw	FBCD7

	bra	_print_bcd

expl_e_fmt
	negf	WREG
	addlw	2
	movwf	[EXP]
	movf	[INTEG_W], W
	rcall	set_int_width

print_e_fmt
	rcall	print_prefix

	movf	[EXP], W
	subwf	[INTW], W
	movwf	PRODL

	; set FSR2 to IBCD
	movf	[INTW], W

	rcall	set_int_ptr

	; int part
	rcall	_print_bcd

	; exponent
	movlw	'E'
	movwf	POSTINC0

	movf	[EXP], W
	rcall	_bin_to_bcd
	movwf	[EXP]
	swapf	WREG
	andlw	0xf
	bz	ones_exp
	addlw	'0'
	movwf	POSTINC0
ones_exp
	movf	[EXP], W
	andlw	0xf
	addlw	'0'
	movwf	POSTINC0
	return

set_int_ptr
	movwf	[TMP]
	decf	WREG
	bcf	STATUS, C
	rrcf	WREG
	addlw	IBCD0
	return

set_int_width
	movwf	[INTW]
	movwf	[INTWS]
	btfsc	[FLAGS], NEG
	incf	[INTWS], F
	return

round_params
	movf	[FRACW], W
	movwf	[TMP]
	decf	WREG
	bcf	STATUS, C
	rrcf	WREG
	sublw	FBCD7

set_fsr0
	movff	FSR2L, FSR0L
	movff	FSR2H, FSR0H

	addwf	FSR0L, F
	movlw	0
	addwfc	FSR0H, F
	return

auto_fmt
	movlw	MAX_INT_WIDTH
	movwf	INDF1

	movlw	IBCD9
	rcall	set_fsr0

	rcall	_find_width

	movf	INDF1, W
	rcall	set_int_width

	; explicit EFormat (WXX_EXX)
	movf	[INTEG_W], W
	subwf	[TOTAL_W], W
	bnc	auto_e_fmt

	; automatic EFormat
	movf	[INTWS], W
	subwf	[TOTAL_W], W
	bnc	auto_e_fmt

	bz	round_ones

	; test decimal digits
	movf	[INTWS], W
	subwf	[INTEG_W], W
	bnc	decode_auto_fmt

	; WXX_XX
	movf	[INTEG_W], W
	subwf	[TOTAL_W], W
	movwf	[FRACW]

	; WXX_0
	btfsc	STATUS, Z
	incf	[FRACW], F

	rcall	decode_frac

	rcall	round_params

	rcall	round

	movf	[INTWS], W
	subwf	[INTEG_W], W

	btfsc	STATUS, C
	movwf	[SPACES]

	bra	print_dec_fmt

decode_auto_fmt
	; set frac parameters
	movf	[INTWS], W
	subwf	[TOTAL_W], W
	movwf	[FRACW]

	rcall	decode_frac

	rcall	round_params

	rcall	round

	bra	print_dec_fmt

auto_e_fmt
	negf	WREG
	addlw	2
	movwf	[EXP]

	; set round params
	decf	WREG
	movwf	[TMP]

	movlw	IBCD0
	rcall	set_fsr0
	bcf	STATUS, C
	rrcf	WREG
	addwf	FSR0L, F

	rcall	round

	; INTW > EXP
	incf	[EXP], W
	subwf	[INTW], W
	bc	set_prefix_spaces
	incf	[EXP], W
	rcall	set_int_width

set_prefix_spaces
	movf	[EXP], W
	subwf	[INTWS], W
	addlw	2
	subwf	[TOTAL_W], W

	; set prefix spaces
	btfsc	STATUS, C
	movwf	[SPACES]

	; if digit carry
	btfss	STATUS, C
	incf	[EXP], F

	bra	print_e_fmt

round_ones
	; decode FBCD7 only (FRACW = 1)
	incf	[FRACW], F

	rcall	decode_frac

	rcall	round_params

	rcall	round

	; width test
	movf	[INTWS], W
	subwf	[TOTAL_W], W
	bnc	auto_e_fmt

	bra	print_dec_fmt

round
	movlw	0x50
	btfss	[TMP], 0
	swapf	WREG

	; stopper
	clrf	[TMP]

	bcf	STATUS, C
round_loop
	addwfc	INDF0, W
	daw
	movwf	POSTINC0
	movlw	0
	bc	round_loop

	movf	[TMP], F
	bz	carry_tst

	; buffer overflow
	pop
	bra	print_err

carry_tst
	; test integer width after (possible) carry
	movlw	IBCD0
	rcall	set_fsr0
	decf	[INTW], W
	bcf	STATUS, C
	rrcf	WREG
	addwf	FSR0L, F
	movf	INDF0, W
	andlw	0xf0
	bnz	even_tst

	; odd test
	btfsc	[INTW], 0
	return
	bra	add_digit

even_tst
	btfss	[INTW], 0
	return
add_digit
	incf	[INTW], F
	incf	[INTWS], F
	return

print_prefix
	rcall	ptr_to_bfr

	; write prefix spaces
	movf	[SPACES], W
	bz	print_sign

	movwf	[TMP]
	movlw	' '
space_prefix
	movwf	POSTINC0
	decf	[TOTAL_W], F
	decfsz	[TMP], F
	bra	space_prefix

print_sign
	movlw	'-'
	btfsc	[FLAGS], NEG
	movwf	POSTINC0
	return

decode_frac
	incf	[FRACW], W
	movwf	[COUNTER]
	bcf	STATUS, C
	rrcf	[COUNTER], F
	bz	zero_frac

	movlw	FLOAT0
	rcall	set_fsr0

	; skip frac decoding if no frac part
;mantissa_zero_test
	movf	POSTINC0, W
	iorwf	POSTINC0, W
	iorwf	POSTINC0, W
	iorwf	POSTINC0, W
	iorwf	POSTINC0, W
	iorwf	POSTINC0, W
	iorwf	POSTINC0, W
	iorwf	POSTINC0, W

	bz	zero_frac

	subfsr	0, 8

	; set FBCD offset
	movlw	FBCD7 + 1
	movwf	[OFFSET]
decode_frac_loop
	decf	[OFFSET], F

	; centuple of frac
	movlw	8
	movwf	INDF1

	clrf	TABLAT
	bcf	STATUS, C
centuple_loop
	movlw	100
	mulwf	INDF0
	movff	PRODL, INDF0

	; add previous carry
	movf	TABLAT, W
	addwfc	POSTINC0, F
	movlw	0
	addwfc	PRODH, W
	movwf	TABLAT
	decfsz	INDF1, F
	bra	centuple_loop

	subfsr	0, 8

	rcall	_bin_to_bcd
	movwf	[TMP]

	movf	[OFFSET], W
	movsf	[TMP], PLUSW2

	decfsz	[COUNTER], F
	bra	decode_frac_loop
zero_frac
	return
	end
