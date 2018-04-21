;===================================================================================================
; Written By: Tomer Cnaan
; Description: A sample program showing how to use the Bitmap code
;===================================================================================================
LOCALS @@

.486
IDEAL
MODEL small
STACK 2000h

    include "lib.inc"    
DATASEG

CODESEG
    include 'game/game.asm'

start:
    mov ax, @data
    mov ds,ax

    call PlayGame
exit:
    ; Restore video mode
    gr_set_video_mode_txt

    ; exit program
    mov ah, 4ch
    mov al, 0
    int 21h
	
END start

CODSEG ENDS