/*
 * 2018/12/02 Josef Kubin
 *
 * PIC18 library written in EXTended ASM instruction set
 */

#ifndef __EXTASM_H
#define __EXTASM_H

/* single precision float with wider mantissa (9B) */
typedef struct {
	unsigned char mant[5];
	float val;
} extsingle_t;

extern void print_xflt(char *bfr, extsingle_t *num, unsigned int format);

extern void print_flt(char *bfr, float *num, unsigned int format);
extern void print_flt_to_bcd(char *bfr, float *num, unsigned int format);
extern void print_uint8(char *bfr, unsigned char *num, unsigned char format);
extern void print_uint16(char *bfr, unsigned int *num, unsigned char format);
extern void print_uint24(char *bfr, unsigned short long *num, unsigned char format);
extern void print_uint32(char *bfr, unsigned long *num, unsigned char format);

extern unsigned char _bin_to_bcd(void);

#define bin_to_bcd(x)		(WREG = x, _bin_to_bcd())

#endif	/* __EXTASM_H */
