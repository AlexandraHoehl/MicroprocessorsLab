#include <xc.inc>

extrn	LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Write_Distance, LCD_Max_Message, LCD_Mode_Error ; external LCD subroutines
extrn	ADC_Setup, ADC_Read, ADC_Convert		   ; external ADC subroutines
extrn	ULTRA_Setup, ULTRA_Pulse, ULTRA_Measure, ULTRA_Dist_Convert, ULTRA_delay_ms, High_ISR, ULTRA_Hex_Time_to_Dist, ULTRA_Motion_Detect
extrn	DIST1, DIST2, DIST3, DIST4, DIST5, DIST6, DIST7, deltat_H, deltat_L
extrn	LED_Setup, LED_Logic
extrn	t2H, t2L, TEMP
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup
	
int_hi:
    org 0x0008		    ; if high priority interrupt is triggered
    goto    High_ISR

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory   - is this necessary ? remove ?
	bsf	EEPGD 	; access Flash program memory
	clrf	LATD
	; call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	call	ULTRA_Setup
	
	; check for mode
	clrf	PORTJ
	clrf	LATJ
	movlw	0x0F
	movwf	TRISJ ; set output from port J 0-3 and input from port J 4-7
	nop
	nop
	nop
	nop
	
	movf	PORTJ, W
	iorlw	11110000B	; mask off top bits being used as outputs
	xorlw   11110001B	; compare to 0001B for cont dist mode
	btfsc   STATUS, 2, A    ; skip next instruction if comparison yielded false
	goto	Distance_cont_mode_start
	
	movf	PORTJ, W
	iorlw	11110000B	
	xorlw   11110010B	; compare to 0010B for single shot dist mode
	btfsc   STATUS, 2, A    ; skip next instruction if comparison yielded false
	goto	Distance_sish_mode_start
	
	movf	PORTJ, W
	iorlw	11110000B	    
	xorlw   11110100B	    ; compare to 0100B for proximity mode
	btfsc   STATUS, 2, A    ; skip next instruction if comparison yielded false
	goto	Proximity_mode_start
	
	movf	PORTJ, W
	iorlw	11110000B
	xorlw   11111000B	    ; compare to 1000B for motion mode
	btfsc   STATUS, 2, A    ; skip next instruction if comparison yielded false
	goto	Motion_mode_start
	
	goto	Mode_not_found	    ; check if an invalid mode was selected
	
Mode_not_found:
    call LCD_Mode_Error		    ; display error message
    goto    $
	
Proximity_mode_start:
    call    ADC_Setup	; setup ADC
   Proximity_mode_loop:
    call    ULTRA_Pulse
    call    ULTRA_Measure
    ; prepare distance scale
    call    ADC_Read
    movff   ADRESH, deltat_H
    movff   ADRESL, deltat_L
    ; clear carry bit and shift twice
    bcf    STATUS, 0
    rlcf    deltat_L
    rlcf    deltat_H
    ; execute distance check and LED logic
    call    LED_Setup	; keep in loop to allow for distance scale changes on the go
    call    LED_Logic
    goto    Proximity_mode_loop

Motion_mode_start:
    ;take initial reference reading
    call    ULTRA_Pulse
    call    ULTRA_Measure
    movff    t2H, TEMP, A
    motion_loop:
    call    ULTRA_Motion_Detect
    goto    motion_loop
    
Distance_cont_mode_start:	
	call	ULTRA_Pulse
	call	ULTRA_Measure
	call	ULTRA_Hex_Time_to_Dist
	call	ULTRA_Dist_Convert; use measured distance and convert to cm
	; output cm value to LCD
	call	LCD_Clear ; clear LCD to prepare for new value to be output
	; check for timer overflow
	btfsc	PIR1, 0
	call	LCD_Max_Message
	btfss	PIR1, 0
	call	LCD_Write_Distance
	
	;movlw	0xFF
	;call	ULTRA_delay_ms ; use if you wanna slow the display down
	   
	goto Distance_cont_mode_start
	
Distance_sish_mode_start: ; single shot mode
	call	ULTRA_Pulse
	call	ULTRA_Measure
	call	ULTRA_Hex_Time_to_Dist
	call	ULTRA_Dist_Convert; use measured distance and convert to cm
	; output cm value to LCD
	call	LCD_Clear ; clear LCD to prepare for new value to be output
	; check for timer overflow
	btfsc	PIR1, 0
	call	LCD_Max_Message
	btfss	PIR1, 0
	call	LCD_Write_Distance
	
    sish_wait_loop:	; poll button on RD1 and skip out back to measurement start if button pressed
	btfss	PORTD, 1
	goto	sish_wait_loop
	goto	Distance_sish_mode_start

	end	rst