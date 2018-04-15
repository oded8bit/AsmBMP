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
STACK 256

    include "bmpdef.asm"                            ; Include Bitmap definitions
DATASEG
    ; This is the Bitmap that we are going to draw. Note how it is initialized
    ; with the file path (opath should be up to BMP_PATH_LENGHTH bytes)
    Image          Bitmap       {ImagePath="b1.bmp"}
    ErrMsg         db           "Could not open file",0dh, 0ah,'$'
CODESEG
    include "bmp.asm"                               ; Include Bitmap code

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

;----------------------------------------------------------
; Sets the MS-DOS BIOS Video Mode
;----------------------------------------------------------
MACRO gr_set_video_mode mode
  mov al, mode
  mov ah, 0
  int 10h
ENDM
;----------------------------------------------------------
; Explicitly sets the MS-DOS BIOS Video Mode
; to 80x25 Monochrome text 
;----------------------------------------------------------
MACRO gr_set_video_mode_txt 
  gr_set_video_mode 03h
ENDM
;----------------------------------------------------------
; Explicitly sets the MS-DOS BIOS Video Mode
; to 320x200 256 color graphics
;----------------------------------------------------------
MACRO gr_set_video_mode_vga 
  gr_set_video_mode 13h
ENDM

start:
    mov ax, @data
    mov ds,ax

    ; Switch to VGA 256 colors 320x200 pixels
    gr_set_video_mode_vga

    ; Draw the bitmap 10 times shifted on the screen
    mov cx, 10
    mov bx, 0       ; x
    mov dx, 0       ; y
@@draw:    
    push cx
    ; Draw the image
    mov si, offset Image
    DisplayBmp si, bx, dx

    cmp ax, FALSE   ; Error openning file?
    je fileErr

    add bx,20       ; x+=20
    add dx,10       ; y+=10
    pop cx
    loop @@draw

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