;===================================================================================================
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Date: 13-04-2018
;
; Description: A sample program showing how to use the Bitmap code
;===================================================================================================
LOCALS @@

.486
IDEAL
MODEL small
STACK 2048

    include "graph.asm"
DATASEG
    ; This is the Bitmap that we are going to draw. Note how it is initialized
    ; with the file path (path should be up to BMP_PATH_LENGHTH bytes)
    Image          Bitmap       {ImagePath="b2.bmp"}
    ErrMsg         db           "Could not open file",0dh, 0ah,'$'
    _Buffer        db          150*150 dup(0)

CODESEG
include 'test.asm'
;------------------------------------------------------------------
; Checks for a keypress; Sets ZF if no keypress is available
; Otherwise returns it's scan code into AH and it's ASCII into al
; Removes the charecter from the Type Ahead Buffer 
; return: AX  = _Key
;------------------------------------------------------------------
PROC WaitForKeypress
    push bp
	mov bp,sp

@@check_keypress:
    mov ah, 1     ; Checks if there is a character in the type ahead buffer
    int 16h       ; MS-DOS BIOS Keyboard Services Interrupt
    jz @@check_keypress_empty
    mov ah, 0
    int 16h
    jmp @@exit
@@check_keypress_empty:
    cmp ax, ax    ; Explicitly sets the ZF
    jz   @@check_keypress

@@exit:
    mov sp,bp
    pop bp
    ret
ENDP WaitForKeypress



start:
    mov ax, @data
    mov ds,ax

    ; Switch to VGA 256 colors 320x200 pixels
    gr_set_video_mode_vga

    call TestLines
    ;call TestDrawAndMove
    ;call TestDrawMultiple
	;call TestSaveScreen
    ;call TestLines

    jmp exit

fileErr:
    ; Error message if file was not fount
    mov dx, offset ErrMsg
	mov ah,9
	int 21h	 

exit:
    ; Wait for keystroke
    call WaitForKeypress
    ; Restore video mode
    gr_set_video_mode_txt

    ; exit program
    mov ah, 4ch
    mov al, 0
    int 21h
	
END start

CODSEG ends