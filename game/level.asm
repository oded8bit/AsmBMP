;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: Handling level files
;===================================================================================================
LOCALS @@

SCRN_BOX_WIDTH          = 16
SCRN_BOX_HEIGHT         = 16
SCRN_DRAW_AREA_WIDTH    = 320
SCRN_DRAW_AREA_HEIGHT   = 176
SCRN_NUM_BOXES_WIDTH    = SCRN_DRAW_AREA_WIDTH/SCRN_BOX_WIDTH
SCRN_NUM_BOXES_HEIGHT   = SCRN_DRAW_AREA_HEIGHT/SCRN_BOX_HEIGHT
SCRN_ARRAY_SIZE         = SCRN_NUM_BOXES_WIDTH * SCRN_NUM_BOXES_HEIGHT

LVL_FILE_NUM_LINES      = SCRN_NUM_BOXES_HEIGHT                 ; numberof lines in a lvl file
LVL_FILE_LINE_LEN       = SCRN_NUM_BOXES_WIDTH + 2              ; number of chars in a lvl line
LVL_FILE_SIZE           = LVL_FILE_LINE_LEN*LVL_FILE_NUM_LINES

TARGET                  = 4     ; '#'
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
    levelScreen     db          SCRN_ARRAY_SIZE dup(0)

    ErrLoadLevel    db          "Error loading level file","$"
    currentRow      db          0
    currentCol      db          0

CODESEG
;------------------------------------------------------------------------
; ReadLevelFile: 
; 
; Input:
;     push offset path 
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

    ; si = levelScreen + (curLine * SCRN_BOX_WIDTH)
    ; points to the array address of the current row 
    mov si, offset levelScreen
    mov ax, curLine
    mov bx, SCRN_NUM_BOXES_WIDTH
    mul bl
    add si, ax


    xor bx,bx                   ; col index
    xor ax,ax
    mov cx, SCRN_NUM_BOXES_WIDTH
    mov di, offset levelLine
@@parse:
    mov al,[BYTE di]
    cmp al, '*'
    jne @@box

    ; Found an *
    mov [BYTE si], WALL
    jmp @@cont

@@box:
    cmp al,'+'
    jne @@target

    mov [BYTE si], BOX
    jmp @@cont

@@target:
    cmp al,'#'
    jne @@player

    mov [BYTE si], TARGET
    jmp @@cont

@@player:
    cmp al,'@'
    jne @@space

    mov [BYTE si], PLAYER
    mov dx, curLine
    mov currentRow, dx          ; row
    mov currentCol, bx          ; col
    jmp @@cont

@@space:
    mov [BYTE si], FLOOR
@@cont:
    inc si
    inc di
    inc bx
    loop @@parse

@@end:
    popa
    mov sp,bp
    pop bp
    ret 2
ENDP ParseLevelData
;------------------------------------------------------------------------
; SetBoxValue: 
; 
; Input:
;     push  row
;     push  col
;     push  value
;     call SetBoxValue
; 
; Output: None
;------------------------------------------------------------------------
PROC SetBoxValue
    push bp
    mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => value
    ; bp+6 => col
    ; bp+8 => row
    ; saved registers
 
    ;{
    value        equ        [word bp+4]
    column       equ        [word bp+6]
    row          equ        [word bp+8]
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
    add si, ax
    add si, column

    mov ax, value
    mov [BYTE si], al

    jmp @@end
@@err:
    ; do nothing
@@end:
    popa
    mov sp,bp
    pop bp
    ret 6
ENDP SetBoxValue
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
    add si, ax
    add si, column

    ; get value
    xor ax,ax
    mov al, [BYTE si]
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
; MovePlayer: 
; 
; Input:
;     push  target row
;     push  target col
;     call MovePlayer
; 
; Output: None
;------------------------------------------------------------------------
PROC MovePlayer
    push bp
    mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => col
    ; bp+6 => row
    ; saved registers
 
    ;{
    row           equ        [word bp+4]
    column        equ        [word bp+6]
    ;}
 
    push row
    push col
    push PLAYER
    call SetBoxValue

    push currentRow
    push currentCol
    push FLOOR
    call SetBoxValue

    mov bx, row
    mov currentRow, bx
    mov bx, column
    mov currentCol, bx

@@end:
    popa
    mov sp,bp
    pop bp
    ret 4
ENDP MovePlayer
;------------------------------------------------------------------------
; Gets the value in the box in the specified direction relative to 
; current player coordinates
; 
; Input:
;     push direction    
;     push  x - current coord
;     push  y - current coord
;     call GetBoxValueInDirection_Coord
; 
; Output: None
;------------------------------------------------------------------------
PROC GetBoxValueInDirection_Coord
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
    call GetBoxValueInDirection

@@end:
    pop dx si bx
    mov sp,bp
    pop bp
    ret 6
ENDP GetBoxValueInDirection_Coord
;------------------------------------------------------------------------
; Gets the value in the box in the specified direction relative to 
; current row,col
; 
; Input:
;     push  distance - 1 or 2
;     push  direction
;     push  current row
;     push  current col
;     call GetBoxValueInDirection
; 
; Output: 
;     AX - TRUE or FALSE
; 
; Affected Registers: 
; Limitations: 
;------------------------------------------------------------------------
PROC GetBoxValueInDirection
    push bp
    mov bp,sp
    push bx
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => current col
    ; bp+6 => current row
    ; bp+8 => direction
    ; bp+10 => distance
    ; saved registers
 
    ;{
    col             equ        [word bp+4]
    row             equ        [word bp+6]
    direction       equ        [word bp+8]
    distance        equ        [word bp+10]
    ;}

    mov bx, distance
    
    ; switch (direction) {
    mov ax, direction
        ; case DIR_DOWN:
        cmp ax, DIR_DOWN
        jne @@dup
                 
        add row, bx
        jmp @@check
@@dup:
        ; case DIR_UP
        cmp ax, DIR_UP
        jne @@dleft
 
        sub row, bx
        jmp @@check

@@dleft:
        ; case DIR_LEFT
        cmp ax, DIR_LEFT
        jne @@dright
 
        sub col, bx
        jmp @@check

@@dright:
        ; case DIR_RIGHT
        cmp ax, DIR_RIGHT
        jne @@default
 
        add col, bx
        jmp @@check

@@check:
    ; check row value valid
    cmp row, 0
    jb @@default
    cmp row, SCRN_NUM_BOXES_HEIGHT
    ja @@default

    ; check col value valid
    cmp col, 0
    jb @@default
    cmp col, SCRN_NUM_BOXES_WIDTH
    ja @@default

    push row
    push col
    call GetBoxValue    ; will set AX

    jmp @@end

@@default:
    ; default {
    mov ax, INVALID
    ;}
@@end:
    pop bx
    mov sp,bp
    pop bp
    ret 6
ENDP GetBoxValueInDirection
;------------------------------------------------------------------------
; DrawBoard: Draws the board
; 
; Input:
;     push bgImage offset    
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
    ; bp+4 => background image offset
    ; saved registers
 
    ;{
    bgImage        equ        [word bp+4]    
    boxRow         equ        [word bp-2]
    boxCol         equ        [word bp-4]
    ;}

    mov si, bgImage
    Display_BMP si,0, 0

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

    ; Ignore walls - drawn in the background

    jmp @@cnt
@@floor:    
    cmp al, FLOOR
    jne @@char

    ; Ignore floors - drawn in the background
    
    jmp @@cnt
@@char:    
    cmp al, PLAYER
    jne @@target

    mov di, offset ImageChar
    Display_BMP di,bx,dx
    
    jmp @@cnt
@@target:    
    cmp al, TARGET
    jne @@box

    mov di, offset ImageTarget
    Display_BMP di,bx,dx
    
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

@@next:    
    loop @@lp    
 
@@end:
    popa
    mov sp,bp
    pop bp
    ret 4
ENDP DrawBoard
;------------------------------------------------------------------------
; HandleLevel: 
; 
; Input:
;     call HandleLevel
; 
; Output: None
;------------------------------------------------------------------------
PROC HandleLevel
    push bp
    mov bp,sp
    sub sp,4
    pusha
 
    ; now the stack is
    ; bp-4 => offset lvl bmp
    ; bp-2 => offset lvl file    
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => 
    ; bp+6 => 
    ; saved registers
 
    ;{
    lvlBmp           equ        [word bp-4]
    lvlFile          equ        [word bp-2]
 
    parName2_        equ        [word bp+4]
    parName1_        equ        [word bp+6]
    ;}
 
    cmp [_GameState], STATE_LEVEL1
    jne @@lvl2

    ; This is level 1
    mov si, offset fileLevel1
    mov lvlFile, si
    mov si, offset ImageBgLvl1
    mov lvlBmp, si

    jmp @@lvl
@@lvl2:
    ; This is level 2
    mov si, offset fileLevel2
    mov lvlFile, si
    mov si, offset ImageBgLvl2
    mov lvlBmp, si

@@lvl:
    ; Load level file
    push lvlFile
    call ReadLevelFile
    cmp ax, FALSE
    jne @@fileError

    ; VGA mode
    gr_set_video_mode_vga

    ;------------------The main loop------------------
@@handle:
    ; Draw background
    push lvlBmp
    call DrawBoard

    call WaitForKeypress
    ; handle the key press
    push ax
    call HandleLevelKey

    ; Exit if needed
    cmp [_GameState], STATE_EXIT
    je @@end

    jmp @@handle                    ; Draw screen and get next key press
    ;--------------------------------------------------

@@fileError:
    push offset ErrLoadLevel
    call printStr 
    jmp @@end

@@end:
    popa
    mov sp,bp
    pop bp
    ret 
ENDP HandleLevel
;------------------------------------------------------------------------
; HandleLevelKey: 
; 
; Input:
;     push key
;     call LevelKeyDown
; 
; Output: None
;------------------------------------------------------------------------
PROC HandleLevelKey
    push bp
    mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => key pressed
    ; saved registers
 
    ;{
    key              equ        [word bp+4]
    ;}

    mov ax, key
    ; Key down
    cmp ax, KEY_DOWN
    jne @@up

    jmp @@end
@@up:
    cmp ax, KEY_DOWN
    jne @@left

    push 1
    push DIR_DOWN
    push currentRow
    push currentCol
    call GetBoxValueInDirection
    ; check box value
    cmp ax, FLOOR
    jne @@found_box
    ; floow
    mov bx, currentRow
    inc bx
    mov dx, currentCol

    jmp @@move
@@found_box:


@@move:
    push bx
    push dx
    call MovePlayer


    jmp @@end
@@left:
    cmp ax, KEY_DOWN
    jne @@right

    jmp @@end
@@right:
    cmp ax, KEY_E
    jne @@up

    jmp @@end
@@done:
    ; exit to welcome page
    mov [_GameState], STATE_WELCOME
    jmp @@end    

@@end:
    popa
    mov sp,bp
    pop bp
    ret 2
ENDP HandleLevelKey
