# 2018/12/02 Josef Kubin
#
# PIC18 library written in EXTended ASM instruction set
#

MCU = 18f27j13
AS = MPASMWIN.exe
ASFLAGS =-q -y
AR = mplib.exe
OBJS = $(patsubst %.asm, %.o, $(wildcard *.asm))
PROJECT = $(notdir $(shell pwd)).lib

.SUFFIXES:


#:all	create all targets
.PHONY: all
all: $(PROJECT)

$(PROJECT): $(OBJS)
	$(AR) -c $@ $^ >&2-

%.o: %.asm
	-$(AS) -p$(MCU) $(ASFLAGS) $(MACROS) -l$*.lst -e$*.err -o$@ $< >&2-
	@if [ -s $*.err ]; then $(RM) $@; cat $*.err >&2; false; fi


#:cl/clean	removes generated files
.PHONY: clean cl
clean cl:
	$(RM) $(OBJS) $(PROJECT) *.{i,err,lst}


#:h/help	prints this text
.PHONY: help h
help h:
	@sed -n '/^#:/{s//\x1b[1;40;38;5;82mmk /;s/\t/\x1b[m /;p}' Makefile | sort	# ]]	<--- fix for m4
