LIST P=16F747
title "Solenoid Control"

#include <P16F747.INC> ; include file for the device

__CONFIG _CONFIG1, _FOSC_HS & _CP_OFF & _DEBUG_OFF & _VBOR_2_0 & _BOREN_0 & _MCLR_ON & _PWRTE_ON & _WDT_OFF
__CONFIG _CONFIG2, _BORSEN_0 & _IESO_OFF & _FCMEN_OFF

;Variable Declarations
	
	mode equ 20h
	modeInput equ 21h
	porteComf equ 22h
	
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
	movwf porteComf
	comf porteComf, 1 ; Complement the input from Port E
	movlw B'00000111'
 	andwf porteComf, 0 ; Clear the higher bits of input
	movwf modeInput ; Move the input of octal switch into the modeInput register
	
	btfsc modeInput,2
	goto Bit2Set
	goto Bit2Clear
	
    Bit2Set ; if the input bit 2 is set
	btfsc modeInput,1
	goto SetError
	btfsc modeInput,0
	goto SetError
	goto SetMode4

    Bit2Clear ; if the input bit 2 is clear
	btfsc modeInput,1 
	goto Mode2or3
	goto Mode1orE

    Mode2or3 ; Test if the mode is 2 or 3
	btfsc modeInput,0
	goto SetMode3
	goto SetMode2

    Mode1orE ; Test if the mode is 1 or Error
	btfsc modeInput,0
	goto SetMode1
	goto SetError
	
    SetError ; Set the mode to be error
	movlw B'00000001'
	movwf mode

    SetMode4 ; Set the mode to be 4
	movlw B'00010000'
	movwf mode
	call WaitRedPress

    SetMode3 ; Set the mode to be 3
	movlw B'00001000'
	movwf mode
	call WaitRedPress
	
    SetMode2 ; Set the mode to be 2
	movlw B'00000100'
	movwf mode
	call WaitRedPress

    SetMode1 ; Set the mode to be 1
	movlw B'00000010'
	movwf mode
	call WaitRedPress
	
    WaitRedPress ;activate solenoid on red press
	btfss PORTC,1 ; see if red button pressed
	goto WaitRedPress
	; actual response for solenoid

	isrService
	goto isrService
    
	end