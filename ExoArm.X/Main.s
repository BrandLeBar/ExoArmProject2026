;Brandon Barrera
;Idaho State University
;Exo arm - Solenoid controller
;12/20/2025

; PIC16F1788 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTOSC         ; Oscillator Selection (INTOSC oscillator: I/O function on CLKIN pin)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable (WDT disabled)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable (PWRT disabled)
  CONFIG  MCLRE = ON            ; MCLR Pin Function Select (MCLR/VPP pin function is MCLR)
  CONFIG  CP = OFF              ; Flash Program Memory Code Protection (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Memory Code Protection (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown-out Reset Enable (Brown-out Reset disabled)
  CONFIG  CLKOUTEN = ON         ; Clock Out Enable (CLKOUT function is enabled on the CLKOUT pin)
  CONFIG  IESO = OFF            ; Internal/External Switchover (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enable (Fail-Safe Clock Monitor is disabled)

; CONFIG2
  CONFIG  WRT = OFF             ; Flash Memory Self-Write Protection (Write protection off)
  CONFIG  VCAPEN = OFF          ; Voltage Regulator Capacitor Enable bit (Vcap functionality is disabled on RA6.)
  CONFIG  PLLEN = OFF           ; PLL Enable (4x PLL disabled)
  CONFIG  STVREN = OFF          ; Stack Overflow/Underflow Reset Enable (Stack Overflow or Underflow will not cause a Reset)
  CONFIG  BORV = HI             ; Brown-out Reset Voltage Selection (Brown-out Reset Voltage (Vbor), high trip point selected.)
  CONFIG  LPBOR = OFF           ; Low Power Brown-Out Reset Enable Bit (Low power brown-out is disabled)
  CONFIG  DEBUG = OFF           ; In-Circuit Debugger Mode (In-Circuit Debugger disabled, ICSPCLK and ICSPDAT are general purpose I/O pins)
  CONFIG  LVP = OFF             ; Low-Voltage Programming Enable (High-voltage on MCLR/VPP must be used for programming)

// config statements should precede project file includes.
#include <xc.inc>
#include <pic16f1788.inc>
  
BANKSAVE EQU 0x020
WSAVE EQU 0x021
ADCHIGH EQU 0x022
ADCLOW EQU 0x023
PREVIOUSPOSITION EQU 0x024
CURRENTPOSITION EQU 0x025

;Reset Vector
PSECT resetVect,class=CODE,delta=2  ;-Wl,-presetVect=00h
  GOTO Setup

;Interrupt Vector
PSECT isrVect,class=CODE,delta=2     ;-Wl,-pisrVect=04h
  GOTO InterruptHandler
  
;Start of program 
PSECT code,class=CODE,delta=2	;-Wl,-pcode=08h
 
Setup:
    MOVLB 0x07		;Bank 7
    CLRF INLVLA		;Configures voltage level to trigger IOC, Port A
    CLRF INLVLB		;Configures voltage level to trigger IOC, Port B
    CLRF INLVLC		;Configures voltage level to trigger IOC, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x06		;Bank 6
    CLRF SLRCONA	;Configures Slew Rate Limit, Port A
    CLRF SLRCONB	;Configures Slew Rate Limit, Port B
    CLRF SLRCONC	;Configures Slew Rate Limit, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x05		;Bank 5
    CLRF ODCONA		;Configures Sink/Source Current, Port A
    CLRF ODCONB		;Configures Sink/Source Current, Port B
    CLRF ODCONC		;Configures Sink/Source Current, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x04		;Bank 4
    CLRF WPUA		;Configures Internal Pull-ups, Port A
    CLRF WPUB		;Configures Internal Pull-ups, Port B
    CLRF WPUC		;Configures Internal Pull-ups, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x03		;Bank 3
    MOVLW 0x01		;Enable RA0 as analog input
    MOVWF ANSELA	;Configures Analog Inputs, Port A
    CLRF ANSELB		;Configures Analog Inputs, Port B
    CLRF ANSELC		;Configures Analog Inputs, Port C
    
    ;----------------------------------------------------------
    MOVLB 0x02		;Bank 2
    CLRF FVRCON		;Configures Fixed reference voltage
    
    ;----------------------------------------------------------
    MOVLB 0x01		;Bank 1
    MOVLW 0x0F		;Set RA0, RA1, RA2, and RA3 as inputs
    MOVWF TRISA		;Configures I/0, Port A
    CLRF TRISB		;Configures I/0, Port B
    CLRF TRISC		;Configures I/0, Port C
    MOVLW 0x80
    MOVWF OPTION_REG	;Settings for TMR0, INT edge, and Pullup control, All Ports
    MOVLW 0X68		;Configures Oscillator, Internal, 4MHz
    MOVWF OSCCON
    BTFSC OSCSTAT, 5	;Is Osc ready?
    GOTO $-1		;No, Wait
    MOVLW 0x01		;Enables AN0 and ADC with 12 bits
    MOVWF ADCON0	;Configures ADC GO/DONE, Enable, AN0-13, 10 or 12 Bit
    MOVLW 0x40		;Enables Vref+ as Vdd and Vref- as Vss with fosc/4
    MOVWF ADCON1	;Configures ADC reference voltage, sampling rate, and sign formating
    MOVLW 0x0F		;Enables Ground as reference
    MOVWF ADCON2	;Configures negative voltage reference and auto conversion method
    MOVLW 0x40		;Enable ADC interrupts
    MOVWF PIE1		;Configures peripheral interrupts 
    
    ;----------------------------------------------------------
    MOVLB 0x00		;Bank 0
    CLRF PORTA		;Clears port to ensure known state, Port A
    CLRF PORTB		;Clears port to ensure known state, Port B
    CLRF PORTC		;Clears port to ensure known state, Port C
    BCF PIR1, 6		;Clears flag to ensure known state, ADCIF
    MOVLW 0xC0		;Enables global and peripheral interrupts
    MOVWF INTCON	;Configures Allowed interrupts, Globals & Preriphrials
    
    ;----------------------------------------------------------
    GOTO Main		;End of Setup
    
Main:
    MOVLB 0x00		;Bank 0
    MOVF ADCHIGH, 0	;Load data
    MOVWF PORTB		;Display data
    MOVLB 0x01		;Bank 1
    BSF ADCON0, 1	;Start ADC
    GOTO Main		;Do it again
    
InterruptHandler:
    ;<editor-fold defaultstate="collapsed" desc="Save Bank & W">
    MOVWF WSAVE		
    MOVF BSR, 0		;Save Bank & W
    MOVWF BANKSAVE;</editor-fold>
    MOVLB 0x00		;Bank 0
    BTFSC PIR1, 6	;Did ADC cause the interrupt?
    GOTO ADCHandler	
    ;<editor-fold defaultstate="collapsed" desc="Restore: Restore Bank & W">
Restore:
    MOVLB 0x00		;Bank 0
    MOVF BANKSAVE, 0	
    MOVWF BSR		;Restore Bank & W
    MOVF WSAVE, 0	
    RETFIE;</editor-fold>
   
;<editor-fold defaultstate="collapsed" desc="ADCHandler: Waits to collect sample and saves values">
ADCHandler:
    BCF PIR1, 6		;Clear ADC flag
    MOVLB 0x01		;Bank 1
    BTFSC ADCON0, 1	;Is ADC done sampling?
    GOTO $-1		;No keep waiting
    MOVF ADRESH, 0	;Yes
    MOVLB 0x00		;Bank 0
    MOVWF ADCHIGH	;Save high
    MOVLB 0x01		;Bank 1
    MOVF ADRESL, 0	
    MOVLB 0x00		;Bank 0
    MOVWF ADCLOW	;Save low
    GOTO Restore	;Restore W and Bank
    ;</editor-fold>

END