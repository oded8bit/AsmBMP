;===================================================================================================
; Written By: Tomer Cnaan
; Description: A sample program showing how to use the Bitmap code
;===================================================================================================
LOCALS @@

.486
IDEAL
MODEL small
STACK 2048

    include "lib.inc"    
DATASEG
    ; This is the Bitmap that we are going to draw. Note how it is initialized
    ; with the file path (path should be up to BMP_PATH_LENGHTH bytes)
    Image          Bitmap       {ImagePath="assets\\b2.bmp"}
    ErrMsg         db           "Could not open file",0dh, 0ah,'$'
    _Buffer        db          150*150 dup(0)

CODESEG

start:
    mov ax, @data
    mov ds,ax

    push offset fileLevel1
    call ReadLevelFile
    cmp ax, FALSE
    je exit

    push DIR_LEFT
    push 1
    push 2
    call GetBoxValueInDirection

    call PrintDecimal

    jmp exit
    ; Switch to VGA 256 colors 320x200 pixels
    gr_set_video_mode_vga

    ; Draw the image
    mov si, offset Image
    Display_BMP si,0, 0
    cmp ax, FALSE
    je fileErr

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

CODSEG ENDS