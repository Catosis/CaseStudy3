LIST P=16F747
title "Solenoid Control"

#include <P16F747.INC> ; include file for the device

__CONFIG _CONFIG1, _FOSC_HS & _CP_OFF & _DEBUG_OFF & _VBOR_2_0 & _BOREN_0 & _MCLR_ON & _PWRTE_ON & _WDT_OFF
__CONFIG _CONFIG2, _BORSEN_0 & _IESO_OFF & _FCMEN_OFF

;Variable Declarations
	
	mode equ 20h
	modeComf equ 21h
	
	org 00h
	goto initPort

	org 04h
	goto isrService

	org 10h

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Port Initialization

    initPort
	clrf PORTE	; Clear Port E input latches (Modes)
	clrf PORTC	; Clear Port C input latches (red = 1, green = 0)
	clrf PORTB	; LED lights
	clrf PORTD	; Clear Port D Solenoid output latches + sensor output
	bsf STATUS,RP0 ; Set bit in STATUS register for bank 1
	movlw B'11111111' ; move hex value FF into W register (maybe no need)
	movwf TRISE ; Configure Port E as all inputs
	movwf TRISC ; Configure port C as all inputs
	movlw B'00111111' ; move hex value FF into W register (maybe no need)
	movwf TRISD ; Configure D for input and output
	clrf  TRISB ; Config B as all outputs
	
	bcf STATUS,RP0 ; Clear bit in STATUS register for bank 0
	
    waitPress ;sees if green button is pressed, goto Green Press
	btfsc PORTC,0 ; see if green button pressed
	goto GreenPress ; green button is pressed - goto routine
	goto waitPress ; keep checking
    
    GreenPress ;read in switch, go to correct mode
	movf PORTE,W ;(hopefully) moves values in port E to register W
	movwf modeComf
	comf modeComf, mode
	

    Mode1RedPress ;activate solenoid on red press
	btfss PORTC,1 ; see if red button pressed
	goto Mode1RedPress
	; actual response for solenoid
    