;===================================================================================================
; Written By: Tomer Cnaan 
;
; Print related functions
;===================================================================================================
LOCALS @@

CODESEG
;----------------------------------------------------------
; Prints a char to the screen
; Input: DL
;----------------------------------------------------------
PROC PrintChar
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
ENDP PrintChar
;----------------------------------------------------------
; Prints a char to the screen + New line
; Input: DL
;----------------------------------------------------------
MACRO PrintCharNewLine
    call PrintChar
    call PrintNewLine
ENDM
;----------------------------------------------------------
; Prints a new line char to the screen
;----------------------------------------------------------
PROC PrintNewLine
    push dx
    mov dx, 0Ah
    call PrintChar
    pop dx
    ret
ENDP PrintNewLine
;----------------------------------------------------------
; Prints a space char to the screen
;----------------------------------------------------------
PROC PrintSpace
    push dx
    xor dx, dx
    mov dl, ' '
    call PrintChar
    pop dx
    ret
ENDP PrintSpace
;----------------------------------------------------------
; Prints a string to the screen
; Input: DS:DX pointer to string ending in "$"
; push offset
; call PrintSre
;----------------------------------------------------------
PROC PrintStr 
    push bp
    mov bp,sp

    mov dx, [word bp+4]
    push ax
    mov ah, 09h
    int 21h

    pop ax
    mov sp,bp
    pop bp
    ret 2
ENDP PrintStr
;----------------------------------------------------------
; Prints a NULL terminated string to the screen
; Input: DS:DX pointer to string ending in NULL
; push offset
; call PrintCStr
;----------------------------------------------------------
PROC PrintCStr
    push bp
    mov bp,sp
    push si bx ax

    push [word bp+4]
    call Strlen
    mov bx, ax                  ; store length
    mov si, dx
    add si, bx
    mov [BYTE si], '$'
    mov ah, 09h
    int 21h

    mov [BYTE si], Null

    pop ax bx si
    mov sp,bp
    pop bp
    ret 2
ENDP PrintCStr
;----------------------------------------------------------
; Prints a string to the screen + New line
; Input: DS:DX pointer to string ending in "$"
;----------------------------------------------------------
MACRO PrintStrNewLine
    call PrintStr
    call PrintNewLine
ENDM
;------------------------------------------------------------------------
; strlen: Calculates length of string ending with NULL
; 
; Input:
;     push  offset of string 
;     call strlen
; 
; Output: 
;     AX - string length 
; 
; Limitations: 
;   1. Assumes string are on DS
;   2. Assumes NULL terminating strings
;------------------------------------------------------------------------
PROC Strlen
    push bp
	mov bp,sp
    push bx
    push cx

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param2 (offset)
	; saved registers

  xor cx,cx                        ; Counter
  mov bx, [WORD PTR bp+04h]        ; String
  @@StrLengthInnerLoop:            ; Inner loop
    mov ax,[WORD PTR bx]           ; Read 16 bits from the string
    test al,al                     ; See if AL is zero
    je  @@StrLengthEP              ; Jump to the EP if yes
    inc cx                         ; Increment the count register
    test ah,ah                     ; See if AH is zero
    je @@StrLengthEP               ; Jump to the EP if yes
    add bx,02h                     ; Navigate to the next two bytes of the string
    inc cx                         ; Increment the count register once again
    jmp @@StrLengthInnerLoop       ; Repeat
  @@StrLengthEP:                   
    mov ax,cx                      ; Move the length of the string to AX
    
    pop cx
    pop bx
    mov sp,bp
    pop bp
    ret 2
ENDP Strlen
;----------------------------------------------------------
; Prints a character on VGA display
; DL: char
; BL, color
;----------------------------------------------------------
PROC PrintCharVGA
    push ax
    push bx
    mov ah, 0Eh
    mov al, dl
    mov bh, 0
    ;mov bl, [gr_pen_color]
    int 10h
    pop bx
    pop ax
    ret
ENDP PrintCharVGA
;----------------------------------------------------------
; Prints a string to the VGA screen
;
; push color
; push offset string
; push x
; push y
; call PrintStrVGA
;----------------------------------------------------------
PROC PrintStrVGA
    push bp
	mov bp,sp
    push ax
    push bx
    push cx

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => y
	; bp+6 => x
	; bp+8 => offset
    ; bp+10 => color
	; saved registers

    push [word bp+8]
    call Strlen
    mov cx, ax              ; length

    mov al, 1               ; move cursor
    mov ah, 13h
    mov bh, 0               ; page
    mov bl, [BYTE bp+10]    ; attrib
    mov dh, [BYTE bp+4]     ; y
    mov dl, [BYTE bp+6]     ; x
    push bp
    push es

    push ds
    pop es
    mov bp, [word bp+8]     ; string es:bp
    int 10h                 ; write string

    pop es
    pop bp

@@loopend:
    pop cx
    pop bx
    pop ax
    mov sp,bp
    pop bp
    ret 6
ENDP PrintStrVGA
;----------------------------------------------------------
; Set cursor position
;
; push x
; push y
; call SetCursorPosition
;----------------------------------------------------------
PROC SetCursorPosition
    push bp
	mov bp,sp
    pusha

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => y
    ; bp+6 => x
	; saved registers

    mov ah, 02
    mov bh, 0
    mov dh, [byte bp+4]
    mov dl, [byte bp+6]
    int 10h

    popa
    mov sp,bp
    pop bp
    ret 4
ENDP SetCursorPosition
;================================================
; Description - Write on screen the value of ax (decimal)
;               the practice :  
;				Divide AX by 10 and put the Mod on stack 
;               Repeat Until AX smaller than 10 then print AX (MSB) 
;           	then pop from the stack all what we kept there and show it. 
; INPUT: AX
; OUTPUT: Screen 
; Register Usage: AX  
;================================================
proc PrintDecimal
       push ax
	   push bx
	   push cx
	   push dx
	   
	   ; check if negative
	   test ax,08000h
	   jz PositiveAx
			
	   ;  put '-' on the screen
	   push ax
	   mov dl,'-'
	   mov ah,2
	   int 21h
	   pop ax

	   neg ax ; make it positive
PositiveAx:
       mov cx,0   ; will count how many time we did push 
       mov bx,10  ; the divider
   
put_mode_to_stack:
       xor dx,dx
       div bx
       add dl,30h
	   ; dl is the current LSB digit 
	   ; we cant push only dl so we push all dx
       push dx    
       inc cx
       cmp ax,9   ; check if it is the last time to div
       jg put_mode_to_stack

	   cmp ax,0
	   jz pop_next  ; jump if ax was totally 0
       add al,30h  
	   mov dl, al    
  	   mov ah, 2h
	   int 21h        ; show first digit MSB
	       
pop_next: 
       pop ax    ; remove all rest LIFO (reverse) (MSB to LSB)
	   mov dl, al
       mov ah, 2h
	   int 21h        ; show all rest digits
       loop pop_next
		
	   pop dx
	   pop cx
	   pop bx
	   pop ax
	   
	   ret
endp PrintDecimal
