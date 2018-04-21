;===================================================================================================
; Written By: Tomer Cnaan
; Description: board related functions
;===================================================================================================
LOCALS @@

;------------------------------------------------------------------------
; DrawBoard: Draws the board
; 
; Input:
;     call DrawBoard
; 
; Output: None
;------------------------------------------------------------------------
PROC DrawBoard
    push bp
    mov bp,sp
    sub sp,4
    pusha
 
    ; now the stack is
    ; bp-4 => box col
    ; bp-2 => box row
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; saved registers
 
    ;{
    boxRow         equ        [word bp-2]
    boxCol         equ        [word bp-4]
    ;}

    mov boxRow,0
    mov boxCol,0
    mov cx, SCRN_ARRAY_SIZE
    xor ax,ax
    mov si, offset levelScreen
    xor bx,bx       ; x coordinate of box top corner
    xor dx,dx       ; y coordinate of box top corner
@@lp:
    mov al, [BYTE si]
    ;switch (levelScreen[i]) {
    
    ;case WALL:
    cmp al, WALL
    jne @@floor

    mov di, offset ImageWall
    Display_BMP di,bx,dx
    
    jmp @@cnt
@@floor:    
    cmp al, FLOOR
    jne @@char

    mov di, offset ImageFloor
    Display_BMP di,bx,dx
    
    jmp @@cnt
@@char:    
    cmp al, PLAYER
    jne @@box

    mov di, offset ImageChar
    ;Display_BMP di,bx,dx
    
    jmp @@cnt
@@box:    
    cmp al, BOX
    jne @@cnt

    mov di, offset ImageBox
    Display_BMP di,bx,dx  
    ;}
 @@cnt:
    inc si
    inc boxCol
    add bx, SCRN_BOX_WIDTH
    cmp bx, VGA_SCREEN_WIDTH
    jb @@next


    mov boxCol,0
    inc boxRow
    xor bx,bx
    add dx, SCRN_BOX_HEIGHT

    cmp boxRow, 2
    je @@end
@@next:    
    loop @@lp    
 
@@end:
    popa
    mov sp,bp
    pop bp
    ret
ENDP DrawBoard

