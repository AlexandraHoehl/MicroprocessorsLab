#include <xc.inc>
	
psect	code, abs
main:
	org 0x0
	goto	setup
	
	org 0x100		    ; Main code starts here at address 0x100

	; ******* Programme FLASH read Setup Code ****  
setup:	
    	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	movlw	0xFF
	movwf	TRISD, A
	movlw	0x0
	movwf	TRISC, A

	goto	start
	; ******* My data and where to put it in RAM *
myTable:
	db	0x01, 0x01, 0x02, 0x03, 0x05, 0x08, 0x0D, 0x15, 0x22, 0x37, 0x59, 0x90
	db	0xE9
	myArray EQU 0x400	; Address in RAM for data
	listCounter EQU 0x10	; Address of list counter variable
	dCounter EQU 0x06	; Address of the portd delay duration counter
	align	2		; ensure alignment of subsequent instructions 
	; ******* Main programme *********************
start:
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A	; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A	; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A	; load low byte to TBLPTRL
	movlw	13		; 13 bytes to read
	movwf 	listCounter, A	; our counter register for running through the list
	
loop:
	movff	PORTD, dCounter, A  ; set memory value of dCounter to have value PORTD
	;decf	dCounter, f, A	; subtract 1 from the value stored in dCounter (due to nature of subloop)
	movlw	0x0
	movwf	PORTC
	call	delayTimer
	call	delayTimer
	call	delayTimer
	call	delayTimer
	tblrd*+			; move one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, PORTC	; move byte stored in TABLAT to PORTC
	movff	TABLAT, POSTINC0	; move read data from TABLAT to (FSR0), increment FSR0
	movlw	high(0xFFFF)	; load 16 bit number into
	movwf	0x20, A		; FR 0x10
	movlw	low(0xFFFF)
	movwf	0x21, A
	movlw	0x00
	cpfseq	dCounter
	call	subloop
	decfsz	listCounter, A	; count down to zero
	bra	loop		; keep going until finished
	goto	0

subloop:
	decfsz	dCounter, A
	call subsubloop
	return
subsubloop:
	call	delayTimer
	bra subloop

delayTimer:
	movlw	0x00		; W=0
dLoop:	decf	0x21, f, A
	subwfb	0x20, f, A
	bc dLoop
	return
	
	end	main




