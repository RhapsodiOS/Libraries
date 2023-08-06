;;;;
;; Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
;;
;; @APPLE_LICENSE_HEADER_START@
;; 
;; "Portions Copyright (c) 1999 Apple Computer, Inc.  All Rights
;; Reserved.  This file contains Original Code and/or Modifications of
;; Original Code as defined in and that are subject to the Apple Public
;; Source License Version 1.0 (the 'License').  You may not use this file
;; except in compliance with the License.  Please obtain a copy of the
;; License at http://www.apple.com/publicsource and read it before using
;; this file.
;; 
;; The Original Code and all software distributed under the License are
;; distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
;; EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
;; INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
;; License for the specific language governing rights and limitations
;; under the License."
;; 
;; @APPLE_LICENSE_HEADER_END@
;;;;
; ************************************************************************
; *                                                                      *
; *    MACRO DEFINITIONS                                                 *
; *                                                                      *
; ************************************************************************
;
; This program originally available on the Motorola DSP bulletin board.
; It is provided under a DISCLAMER OF WARRANTY available from
; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
; 
; Radix 2, In-Place, Decimation-In-Time FFT
; (using DSP56001 Y Data ROM sine-cosine tables).
; 
; Last Update 08 Aug 86   Version 1.0
;
fftr2d	macro	points,data,coef,table
fftr2d	ident	1,0
;
; Radix 2 Decimation in Time In-Place Fast Fourier Transform Routine
;
;    Complex input and output data
;        Real data in X memory
;        Imaginary data in Y memory
;    Normally ordered input data
;    Bit reversed output data
;	Coefficient lookup table
;        Full cycle sinewave in Y memory
;	Coefficient table can be generated by "sinewave" macro.
;
;	This FFT version can directly use the sinewave table stored
;	in the DSP56001 Y Data ROM for up to 256 point complex FFTs.
;
; Macro Call - fftr2d   points,data,coef,table
;
;	points     number of points (2-32768, power of 2)
;	data       starting address of data buffer
;	coef	   starting address of sinewave table
;	table      size of sinewave table
;
; Alters Data ALU Registers
;	x1	x0	y1	y0
;	a2	a1	a0	a
;	b2	b1	b0	b
;
; Alters Address Registers
;	r0	n0	m0
;	r1	n1	m1
;		n2
;
;	r4	n4	m4
;	r5	n5	m5
;	r6	n6	m6
;	r7	n7	m7
;
; Alters Program Control Registers
;	pc	sr
;
; Uses 6 locations on System Stack
;
; Latest Revision - August 8, 1986
;
	page
	move 	#points/2,n0	;initialize butterflies per group
	move	#1,n2		;initialize groups per pass
	move	#table/4,n6	;initialize C pointer offset
	move	n6,n7
	move	#0,m6		;initialize C address modifier for
				;reverse carry (bit-reversed) addressing
;
; Perform all FFT passes with triple nested DO loop
;
	do	#@cvi(@log(points)/@log(2)+0.5),_end_pass
	move	#data,r0	;initialize A input pointer
	move	r0,r4		;initialize A output pointer
	lua	(r0)+n0,r1	;initialize B input pointer
	move	#coef,r6	;initialize C input pointer
	lua	(r1)-,r5	;initialize B output pointer
	move	n0,n1		;initialize pointer offsets
	move	n0,n4
	move	n0,n5

	do	n2,_end_grp
	move	r6,r7		;get sine pointer
	move	x:(r1),x1	y:(r6)+n6,y0	;lookup sine value
	move	x:(r5),a	y:(r0),b	;preload data
	move	y:(r7+n7),x0		;lookup cosine value


	do	n0,_end_bfy	;Radix 2 DIT butterfly kernel
	mac	-x1,y0,b			y:(r1)+,y1
	macr	x0,y1,b		a,x:(r5)+	y:(r0),a
	subl	b,a		x:(r0),b	b,y:(r4)
	mac	x1,x0,b		x:(r0)+,a	a,y:(r5)
	macr	y1,y0,b		x:(r1),x1
	subl	b,a		b,x:(r4)+	y:(r0),b
_end_bfy
	move	a,x:(r5)+n5	y:(r1)+n1,y1	;update A and B pointers
	move	x:(r0)+n0,x1	y:(r4)+n4,y1
_end_grp
	move	n0,b1
	lsr	b	n2,a1	;divide butterflies per group by two
	lsl	a	b1,n0	;multiply groups per pass by two
	move	a1,n2
_end_pass
	move	m0,m6		;all code assumes -1 in each m
	endm
		

; ************************************************************************
;
; This program originally available on the Motorola DSP bulletin board.
; It is provided under a DISCLAMER OF WARRANTY available from
; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
; 
; Full-Cycle Sinewave Table Generator Macro.
; 
; Last Update 25 Nov 86   Version 1.1
;
sinewave	macro	points
sinewave	ident	1,1
;
;	sinewave - macro to generate a full cycle sinewave table.
;		If points = 256 and sinewave is ORGed at Y:$100,
;		the sinewave table generated is identical to the
;		DSP56001 Y Data ROM contents.  Note that the base
;		address and memory space must be specified before
;		the macro is called.
;
;	points - number of points (1 - 65536)
;
; Latest revision - 25-Nov-86
;

freq1	equ	2.0*PI/@cvf(points)

count	set	0
	dup	points
sv	set	@sin(@cvf(count)*freq1)
	if 	(sv>=1.0)
sv	set	$7FFFFF
	endif
	dc	sv
count	set	count+1
	endm

	endm	;end of sinewave macro
		
		
		
; ************************************************************************
;
; This program originally available on the Motorola DSP bulletin board.
; It is provided under a DISCLAMER OF WARRANTY available from
; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
; 
; Sine-Cosine Table Generator for FFTs. 
; 
; Last Update 25 Nov 86   Version 1.2
;
sincosgen	macro	nfreq,coef,points
sincosgen	ident	1,2
;
;	sincosgen	- macro to generate sine and cosine coefficient
;			lookup tables 
;
;
;	points	-	number of points (<= nfreq)
;	coef	-	base address of sine/cosine table
;			cosine value in X memory
;			sine value in Y memory
;	nfreq	-	freq = 1/nfreq
;
; Latest revision - 25-Nov-86
;

freq2	equ	2.0*PI/@cvf(nfreq)

	org	x:coef
count	set	0
	dup	points
cv	set 	@cos(@cvf(count)*freq2)
	if 	(cv>=1.0)
cv	set	$7FFFFF
	endif
	dc	cv
count	set	count+1
	endm

	org	y:coef
count	set	0
	dup	points
sv	set	@sin(@cvf(count)*freq2)
	if 	(sv>=1.0)
sv	set	$7FFFFF
	endif
	dc	sv
count	set	count+1
	endm

	endm	;end of sincosgen macro
		
		

		
; ************************************************************************
;
;
; Sine-Cosine Table Generator for DCT/DST
; 
;
create_phasors	macro	nfreq,coef,points
create_phasors	ident	1,2
;
;	create_phasors	-	macro to generate sine and cosine coefficient
;			        lookup tables for DCT/DST 
;
;
;	points	-	number of points (<= nfreq)
;	coef	-	base address of sine/cosine table
;			cosine value in X memory
;			sine value in Y memory
;	nfreq	-	freq = 1/nfreq
;
; Latest revision - Oct 9-91
;

nz	equ	(PI/2.0)+(PI/@cvf(nfreq))	; frame offset

	org	x:coef
count	set	0
	dup	points
cv	set	@cos(@cvf(count)*nz)
	if 	(cv>=1.0)
cv	set	$7FFFFF
	endif
	dc	cv
count	set	count+1
	endm

	org	y:coef
count	set	0
	dup	points
	dc	@sin(@cvf(count)*nz)
count	set	count+1
	endm

	endm	;end of create_phasors macro

		
		
		
		
		
; ************************************************************************
;
;
; Window Table for xfc
; 
;
create_window	macro	points,coef
create_window	ident	1,2
;
;	create_window	-	macro to generate (sqrt)window table for xfc
;
;
;	points	-	number of points (2 - 32768, power of 2)
;	coef	-	base address of window table
;			even value in X memory
;			odd value in Y memory
;
; Latest revision - Oct 9-91
;

wscl	equ	PI/@cvf(points)		; window scale
woff	equ	PI/(2.0*@cvf(points))	; window offset

	org	x:coef
count	set	0
	dup	points/2
	dc	@sin((@cvf(count)*wscl)+woff)
count	set	count+2
	endm

	org	y:coef
count	set	1
	dup	points/2
	dc	@sin((@cvf(count)*wscl)+woff)
count	set	count+2
	endm

	endm	;end of create_window macro
		


; ************************************************************************
;
; Macro to extract bits (bi+3..bi) bi>0
; input x0 
; output in a1
; right shift table in X:rshft
; >$f in y0
getnib	macro	bi

	move	x:(rshft+bi),x1
	mpy	x0,x1,a
	and	y0,a
	endm	;end of get_nib



; ************************************************************************
;
; Macro to move block of L memory from buffer ib to ob
; size of the buffer nb
; uses x,r0,r1

blkl	macro	ib,ob,nb

	move	#ib,r0
	move	#ob,r1
	do	#nb,_end_blkl
	move	l:(r0)+,x
	move	x,l:(r1)+
_end_blkl

	endm	;end of blkl





; ************************************************************************
;
; readWordDMA dest - returns the next sample from input stream in register A1
; and if dest!=A, moves A to dest.
; When input buffer is empty, blocks until DMA is successful. 
; Must be called once for each sample in a sample-frame.  
; On return, the carry bit is set if there is no more input, and
; A1 is undefined. If A1 is valid, carry will be clear.
;
; Registers A, B and X0 are modified.
; Assumes R_DMA_IN is initially set to point to input buffer.
;
readWordDMA macro dest
	jsr getWordDMA
	if "dest"!='A'
	  move A,dest
	endif
	endm

	if SHORT_CIRCUIT

; readShortDMA dest - returns the next short from input stream in register A1
; and if dest!=A, moves A to dest. Assumes 16-bit DMA mode is in use
; which means the word needs to be left-shifted 8 bits in order to
; left-justify it.  (16-bit DMA uses RXM and RXL in the host interface.)
; Registers A, B, X0, and Y0 are modified.
; Otherwise readShortDMA is identical to readWordDMA.
;
readShortDMA macro dest
	jsr getWordDMA
	move A,X0 #>@pow(2,-16),Y0
	mpy X0,Y0,A
	move A0,A
	if "dest"!='A'
	  move A,dest
	endif
	endm

	endif

; asm_lgoto - (long version) assemble short absolute jump address in 4K case
; usage: asm_goto <JMP,Jxx,JSR,JSxx>,label
asm_lgoto macro op,addr
	if BUG56_VERSION||DEBUG_VERSION|DEBUG_DMA
	  op addr
	else
	  op <addr
	endif
	endm

jmp_stereo macro dest
	jset #1,x:<channels,dest	; jump if stereo case
	endm

jmp_mono macro dest
	jclr #1,x:<channels,dest	; jump if stereo case
	endm

jmp_chan0 macro dest
	jclr    #0,x:<chan,dest
	endm

jmp_chan1 macro dest
	jset    #0,x:<chan,dest
	endm

mask_host macro
	  ori #2,mr ; raise level to 2 (lock out host at level 1)
	  do #1,_loop
	   nop ; wait for pipeline to clear (need 8 cycles delay)
_loop
	  endm

unmask_host macro
	  andi #$FC,mr ; i1:i0 = 0
	  endm

set_io_bit macro bit,reg
	bset #m_\bit,x:<<m_\reg
	endm

clear_io_bit macro bit,reg
	bclr #m_\bit,x:m_\reg
	endm

mask_pio macro
	  clear_io_bit hrie,hcr
	  do #1,_loop
	   nop ; wait for pipeline to clear (need 8 cycles delay)
_loop
	  endm

unmask_pio macro
	  set_io_bit hrie,hcr
	  endm