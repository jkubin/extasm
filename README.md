# EXTASM
PIC18 library written in EXTended ASM instruction set (better stack utilisation).
The original Microchip PIC18 MCU library has slow and huge numeric print functions.
I wrote several functions in ASM because of speed, size and simplicity.

## The following example prints floating point number to a buffer (8 char width):
```
char bfr[100];
float flt;

flt = 1.234567;
print_flt(bfr, &flt, 8);
/* bfr[] = "1.234567" */

flt = 12.34567;
print_flt(bfr, &flt, 8);

flt = 123.4567;
print_flt(bfr, &flt, 8);
...
```

## If you know IEEE 754, the following example is for you (8B mantissa):
```
char bfr[100];
extsingle_t xflt;

xflt.val = 1.234567;
xflt.mant[4] = 0xab;
xflt.mant[3] = 0xcd;
xflt.mant[2] = 0xef;
xflt.mant[1] = 0x01;
xflt.mant[0] = 0x23;

print_xflt(bfr, &xflt, 20);
/* bfr[] = "1.234567126168137531" */
...
```

## The following example prints integers with various width to a buffer (JSON):
```
unsigned long num;
char bfr[100];
char *ptr;

num = 12;
ptr = bfr;
*ptr++ = '[';

print_uint32(ptr, &num, 0);
ptr = (char *)FSR0;

*ptr++ = ',';
num = 12345;

print_uint32(ptr, &num, 0);
ptr = (char *)FSR0;

*ptr++ = ',';
num = 123;

print_uint32(ptr, &num, 0);
ptr = (char *)FSR0;

*ptr++ = ']';
*ptr = 0;

/* bfr[] = "[12,12345,123]" */
```

## If you love ASM and you know what are you doing, try the following code:
```
num = 12;

FSR0 = (unsigned)bfr;
POSTINC0 = '[';
print_uint32((char *)FSR0, &num, 0);
POSTINC0 = ',';

num = 12345;

print_uint32((char *)FSR0, &num, 0);
POSTINC0 = ',';

num = 123;

print_uint32((char *)FSR0, &num, 0);
POSTINC0 = ']';
POSTINC0 = 0;

/* bfr[] = "[12,12345,123]" */
```
## Simple, isn't it?
### Contact (Base64): bTR1bml4QGdtYWlsLmNvbQ
