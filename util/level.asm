;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: Handling level files
;===================================================================================================
LOCALS @@

SCRN_BOX_WIDTH      = 10
SCRN_BOX_HEIGHT     = 10
SCRN_NUM_BOXES_WIDTH  = 320/SCRN_BOX_WIDTH
SCRN_NUM_BOXES_HEIGHT = 200/SCRN_BOX_HEIGHT
SCRN_ARRAY_SIZE     = SCRN_BOX_WIDTH * SCRN_BOX_HEIGHT

LVL_FILE_NUM_LINES      = SCRN_NUM_BOXES_HEIGHT
LVL_FILE_LINE_LEN       = SCRN_NUM_BOXES_WIDTH + 2
LVL_FILE_SIZE           = LVL_FILE_LINE_LEN*LVL_FILE_NUM_LINES

PLAYER                  = 3     ; '@'
BOX                     = 2     ; '+'
WALL                    = 1     ; '*'
FLOOR                   = 0     ; ' '
INVALID                 = -1

DIR_UP                  = 1
DIR_DOWN                = 2
DIR_LEFT                = 3
DIR_RIGHT               = 4


DATASEG
    fileLevel1      db          "screen\\lvl1.dat",0

    levelLine       db          LVL_FILE_LINE_LEN dup(0)
    levelScreen     dw          SCRN_ARRAY_SIZE dup(0)

CODESEG
;------------------------------------------------------------------------
; ReadLevelFile: 
; 
; Input:
;     push  offset path 
;     call ReadLevelFile
; 
; Output: AX TRUE/FALSE
;------------------------------------------------------------------------
PROC ReadLevelFile
    push bp
    mov bp,sp
    push si di 
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => lvlFilePath
    ; saved registers
 
    ;{
    lvlFilePath        equ        [word bp+4]
    ;}


    mov si, offset fileLevel1
    m_fsize si ds

    cmp ax, LVL_FILE_SIZE
    jne @@badSize

    ; open file
    m_fopen si, ds

    mov cx, LVL_FILE_NUM_LINES
    mov di, 0           ; current line
@@rd:    
    ; read single line, including new line (0A,0D) chars at the end
    mov si, offset levelLine
    m_fread LVL_FILE_LINE_LEN, si, ds

    push di
    call ParseLevelData

    inc di
    loop @@rd

    m_fclose
    
    mov ax, TRUE
    jmp @@end
    
@@badSize:
    mov ax, FALSE    
 
@@end:
    pop di si
    mov sp,bp
    pop bp
    ret 2
ENDP ReadLevelFile

;------------------------------------------------------------------------
; ParseLevelData: parsing the data in levelLine into the array levelScreen
; 
; Input:
;     push  current_line
;     call ParseLevelData
; 
; Output: None
;------------------------------------------------------------------------
PROC ParseLevelData
    push bp
    mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => current line
    ; saved registers
 
    ;{
    curLine        equ        [word bp+4]
    ;}

    ; si = levelScreen + 2*(curLine * SCRN_BOX_WIDTH)
    ; points to the array address of the current row 
    mov si, offset levelScreen
    mov ax, curLine
    mov bx, SCRN_BOX_WIDTH
    mul bl
    shl ax,1
    add si, ax

    mov cx, SCRN_NUM_BOXES_WIDTH
    mov di, offset levelLine
@@parse:
    mov ax,[di]
    cmp al, '*'
    jne @@box

    ; Found an *
    mov [WORD si], WALL
    jmp @@cont

@@box:
    cmp al,'+'
    jne @@player

    mov [WORD si], BOX
    jmp @@cont

@@player:
    cmp al,'@'
    jne @@space

    mov [WORD si], PLAYER
    jmp @@cont

@@space:
    mov [WORD si], SPACE
@@cont:
    inc si
    inc di
    loop @@parse

@@end:
    popa
    mov sp,bp
    pop bp
    ret 2
ENDP ParseLevelData
;------------------------------------------------------------------------
; GetBoxValue: 
; 
; Input:
;     push  row
;     push  col
;     call GetBoxValue
; 
; Output: 
;     AX - WALL or FLOOR or INVALID
;------------------------------------------------------------------------
PROC GetBoxValue
    push bp
    mov bp,sp
    push dx bx si
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => col
    ; bp+6 => row
    ; saved registers
 
    ;{
    column        equ        [word bp+4]
    row           equ        [word bp+6]
    ;}
 
    ; check valid input
    mov ax, row
    cmp ax, SCRN_NUM_BOXES_HEIGHT
    jae @@err

    mov ax, column
    cmp ax, SCRN_NUM_BOXES_WIDTH
    jae @@err

    ; si = levelScreen + (row * SCRN_BOX_WIDTH) + column
    ; points to the array address of the current (row,col)
    mov si, offset levelScreen
    mov ax, row
    mov bx, SCRN_BOX_WIDTH
    mul bl
    shl ax,1    
    add si, ax
    add si, column

    ; get value
    mov ax, [si]
    jmp @@end
@@err:
    mov ax, INVALID
@@end:
    pop si bx dx
    mov sp,bp
    pop bp
    ret 4
ENDP GetBoxValue
;------------------------------------------------------------------------
; CanMoveTo: 
; 
; Input:
;     push direction    
;     push  x - current coord
;     push  y - current coord
;     call CanMoveTo
; 
; Output: None
;------------------------------------------------------------------------
PROC CanMoveTo
    push bp
    mov bp,sp
    sub sp,4
    push bx si dx
 
    ; now the stack is
    ; bp-4 => row
    ; bp-2 => col
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => y
    ; bp+6 => x
    ; bp+6 => direction
    ; saved registers
 
    ;{
    row             equ        [word bp-4]
    col             equ        [word bp-2]

    theY            equ        [word bp+4]
    theX            equ        [word bp+6]
    direction       equ        [word bp+8]
    ;}

    mov si, offset wallAroundMe

    mov ax, theX
    mov bx, SCRN_NUM_BOXES_WIDTH
    div bx

    mov col, ax                   ; column

    mov ax, theY
    mov bx, SCRN_NUM_BOXES_HEIGHT
    div bx
    mov row, ax                   ; row

    push direction
    push row
    push col
    call CanMoveToBox

@@end:
    pop dx si bx
    mov sp,bp
    pop bp
    ret 6
ENDP CanMoveTo
;------------------------------------------------------------------------
; CanMoveToBox: 
; 
; Input:
;     push  direction
;     push  current row
;     push  current col
;     call CanMoveToBox
; 
; Output: 
;     AX - TRUE or FALSE
; 
; Affected Registers: 
; Limitations: 
;------------------------------------------------------------------------
PROC CanMoveToBox
    push bp
    mov bp,sp
    push bx
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => current col
    ; bp+6 => current row
    ; bp+8 => direction
    ; saved registers
 
    ;{
    col             equ        [word bp+4]
    row             equ        [word bp+6]
    direction       equ        [word bp+8]
    ;}

    ; switch (direction) {
    mov ax, direction
        ; case DIR_DOWN:
        cmp ax, DIR_DOWN
        jne @@dup
 
        inc row
        jmp @@check
@@dup:
        ; case DIR_UP
        cmp ax, DIR_UP
        jne @@dleft
 
        dec row
        jmp @@check

@@dleft:
        ; case DIR_LEFT
        cmp ax, DIR_LEFT
        jne @@dright
 
        dec col
        jmp @@check

@@dright:
        ; case DIR_RIGHT
        cmp ax, DIR_RIGHT
        jne @@default
 
        dec col
        jmp @@check

@@check:
    ; check that row,col are valid
    mov ax, row
    cmp ax, SCRN_NUM_BOXES_HEIGHT
    jae @@default

    mov ax, column
    cmp ax, SCRN_NUM_BOXES_WIDTH
    jae @@default

    push row
    push col
    call GetBoxValue    ; will set AX

    mov ax, FALSE       

    cmp ax, FLOOR
    jne @@end

    mov ax, TRUE

    jmp @@end
@@default:
    ; default {
        mov ax, FALSE
    ;}
@@end:
    pop bx
    mov sp,bp
    pop bp
    ret 6
ENDP CanMoveToBox