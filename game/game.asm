;===================================================================================================
; Written By: Tomer Cnaan
; Description: game related functions
;===================================================================================================
LOCALS @@

STATE_WELCOME       = 1
STATE_LEVEL1        = 2
STATE_LEVEL2        = 3
STATE_LEVEL3        = 4
STATE_RESULTS       = 5
STATE_EXIT          = 10

DATASEG
    ImageBgLvl1         Bitmap       {ImagePath="screen\\lvl1.bmp"}
    ImageBgLvl2         Bitmap       {ImagePath="screen\\lvl2.bmp"}
    ImageBox            Bitmap       {ImagePath="assets\\box.bmp"}
    ImageFloor          Bitmap       {ImagePath="assets\\floor.bmp"}
    ImageChar           Bitmap       {ImagePath="assets\\char.bmp"}
    ImageTarget         Bitmap       {ImagePath="assets\\target.bmp"}
    ErrLoadImg          db           "Could not open file",0dh, 0ah,'$'
    ErrLoadLvl          db           "Could not load level file",0dh, 0ah,'$'

    _GameState          dw           STATE_WELCOME

CODESEG
    include "game/level.asm"
    include "game/welcome.asm"

;------------------------------------------------------------------------
; PlayGame: 
; 
; Input:
;     call PlayGame
; 
; Output: None
;------------------------------------------------------------------------
PROC PlayGame
    push bp
    mov bp,sp
    pusha
 
 @@state:
    mov bx,[_GameState]
    ; switch (state) {
        cmp bx,STATE_WELCOME
        jne @@lvl1

        call HandleWelcome

        jmp @@state
@@lvl1:
        cmp bx,STATE_LEVEL1
        jne @@lvl2

        call HandleLevel

        jmp @@state

@@lvl2:
        cmp bx,STATE_LEVEL2
        jne @@result

        call HandleLevel

        jmp @@state

@@result:
        cmp bx,STATE_RESULTS
        jne @@done

        ; call HandleResults

        jmp @@state
 @@done:
        cmp bx,STATE_EXIT
        je @@end

        ; ERROR - Invalid state        
        jmp @@end
    ;}
 
@@end:
    popa
    mov sp,bp
    pop bp
    ret 
ENDP PlayGame

;------------------------------------------------------------------------
; HandleWelcomeScreen: 
; 
; Input:
;     push  X1 
;     push  X2
;     call HandleWelcomeScreen
; 
; Output: 
;     AX - 
; 
; Affected Registers: 
; Limitations: 
;------------------------------------------------------------------------
PROC HandleWelcomeScreen
    push bp
    mov bp,sp
    ;sub sp,2            ;<- set value
    pusha
 
    ; now the stack is
    ; bp-2 => 
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => 
    ; bp+6 => 
    ; saved registers
 
    ;{
    varName_         equ        [word bp-2]
 
    parName2_        equ        [word bp+4]
    parName1_        equ        [word bp+6]
    ;}
    ; Switch to VGA 256 colors 320x200 pixels
    gr_set_video_mode_vga
    ; Use the palette of the first image for all other images
    set_draw_palette FALSE

    ; Load level one
    push offset fileLevel1
    call ReadLevelFile
    cmp ax, FALSE
    jne @@startVGA

    mov dx, offset ErrLoadLvl
    call printStr 
    jmp @@end

@@startVGA:
    ; Draw level one
    push offset ImageBgLvl1
    call DrawBoard

    jmp @@end

fileErr:
    ; Error message if file was not fount
    mov dx, offset ErrLoadImg
	mov ah,9
	int 21h	 
 
@@end:
    popa
    mov sp,bp
    pop bp
    ret ;4               ;<- set value
ENDP HandleWelcomeScreen