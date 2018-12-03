# extasm
PIC18 library written in EXTended ASM instruction set (better stack utilisation).
The original Microchip PIC18 MCU library has slow and huge numeric print functions.
I have written several functions in ASM because of speed, size and simplicity.

## the following example prints floating point number to a buffer (8 char width):
```
char bfr[100];
float flt;

flt = 1.234567;
print_flt(bfr, &flt, 8);

flt = 12.34567;
print_flt(bfr, &flt, 8);

flt = 123.4567;
print_flt(bfr, &flt, 8);

...
```

## the following example prints integers with various width to a buffer (as JSON):
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
```

## if you love ASM and you know what are you doing, try the following code:
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
```
## Simple, isn't it?
# Beware of EXTASM, it could be dangerous and addictive!
