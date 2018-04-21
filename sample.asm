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
    ; This is the Bitmap that we are going to draw. Note how it is initialized
    ; with the file path (path should be up to BMP_PATH_LENGHTH bytes)
;    _ScreenCapture      db           VGA_SCREEN_WIDTH*(VGA_SCREEN_HEIGHT-1) dup(0)
    ImageWall           Bitmap       {ImagePath="assets\\wall.bmp"}
    ImageBox            Bitmap       {ImagePath="assets\\box.bmp"}
    ImageFloor          Bitmap       {ImagePath="assets\\floor.bmp"}
    ImageChar           Bitmap       {ImagePath="assets\\char.bmp"}
    ImageTarget         Bitmap       {ImagePath="assets\\target.bmp"}
    ErrLoadImg          db           "Could not open file",0dh, 0ah,'$'
    ErrLoadLvl          db           "Could not load level file",0dh, 0ah,'$'

CODESEG
include 'board.asm'

start:
    mov ax, @data
    mov ds,ax

jmp @@startVGA

    push offset fileLevel1
    call ReadLevelFile
    cmp ax, FALSE
    jne @@startVGA

    mov dx, offset ErrLoadLvl
    call printStr 

    jmp exit

@@startVGA:
    ; Switch to VGA 256 colors 320x200 pixels
    gr_set_video_mode_vga

;   call DrawBoard

    ; Draw the image
    mov si, offset ImageWall
    Display_BMP si,0, 0
    mov si, offset ImageFloor
    Display_BMP si,30, 0
    mov si, offset ImageTarget
    Display_BMP si,60, 0
    mov si, offset ImageChar
    Display_BMP si,90, 0
    mov si, offset ImageBox
    Display_BMP si,120, 0
    cmp ax, FALSE
    je fileErr

    jmp exit

fileErr:
    ; Error message if file was not fount
    mov dx, offset ErrLoadImg
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