;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: Timer related utilities
;===================================================================================================
LOCALS @@

CODESEG
;------------------------------------------------------------------------
; Creates a short delay 
;
; Uses system ticks (about 18/sec) so a delay of '1' is about 1/18 
; of a sec
;
; Delay (word msec)
;------------------------------------------------------------------------
PROC Delay
    push bp
	mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => # msecs
    ; saved registers
 
    xor ax,ax
    int 1Ah
    mov bx, dx            ; low order word of tick count
    mov cx, [word bp+4]   ; delay time

@@jmp_delay:
    push cx
    int 1Ah
    sub dx, bx
    ;there are about 18 ticks in a second, 10 ticks are about enough
    pop cx
    cmp dx, cx                                                      
    jl @@jmp_delay        

@@end:
    popa
    mov sp,bp
    pop bp
    ret 2 
ENDP Delay
;------------------------------------------------------------------------
; PROC Description:
; Delay execution for given number of microseconds
;
; Notes:
;   1. 1,000,000 microseconds = 1 second. For 2 seconds, 
;      set CX=001eH and DX=8480H.   (1E 8480 = 2,000,000)
;   2. 1 msec = 1000*1 = CX=0  DX=03eBh
;   3. CX must be at least 1000 (03e8H)
;
; Input:
;     high order - of number of microseconds
;     low order - of number of microseconds
; 
; Output:
;     None
; 
; DelayMS(high, low)
;------------------------------------------------------------------------
PROC DelayMS
    push bp
	mov bp,sp

    push ax dx cx
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => low word (DX)
    ; bp+6 => high word (CX)
    ; saved registers
 
    mov cx, [word bp+6]
    mov dx, [word bp+4]
    mov ah, 86h 
    int 15h

@@end:
    pop cx dx ax
    mov sp,bp
    pop bp
    ret 4
ENDP DelayMS