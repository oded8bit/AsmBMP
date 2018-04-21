;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: Keyboard related utilities
;===================================================================================================
LOCALS @@

KEY_S = 1F73h
KEY_E = 1265h
KEY_R = 1372h

KEY_DOWN = 5000h
KEY_UP   = 4800h
KEY_RIGHT = 4D00h
KEY_LEFT = 4B00h

CODESEG
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
;------------------------------------------------------------------
; Read keyboard _Key if pressed - non blocking
;
; returns:
; ZF = 0 if a _Key pressed (even Ctrl-Break)
;	AX = 0 if no scan code is available
;	AH = scan code
;	AL = ASCII character or zero if special function _Key
;------------------------------------------------------------------
PROC GetKeyboardStatus
    mov ah, 01h
    int 16h  
    ret
ENDP GetKeyboardStatus
;------------------------------------------------------------------
; Consume the keyboard char
;------------------------------------------------------------------
PROC ConsumeKey
    mov ah,0
    int 16h
    ret
ENDP ConsumeKey
;------------------------------------------------------------------
; Get keyboard key if available
;------------------------------------------------------------------
PROC GetKeyboardKey
    mov ax,0
    call GetKeyboardStatus
    jnz @@exit
    call ConsumeKey
@@exit:    
    ret
ENDP GetKeyboardKey

