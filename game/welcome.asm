;===================================================================================================
; Written By: Tomer Cnaan
; Description: Welcome screen
;===================================================================================================
LOCALS @@

DATASEG

    welcomeStr      db          "-------------------------------------------------------------------------------",10,13
                    db          "-                                M Y    G A M E                               -",10,13
                    db          "-                                                                             -",10,13
                    db          "-                                                                             -",10,13
                    db          "-                                                                             -",10,13
                    db          "-                                                                             -",10,13
                    db          "-                                                                             -",10,13
                    db          "-                                                                             -",10,13
                    db          "-                                                                             -",10,13
                    db          "-------------------------------------------------------------------------------",10,13,10,13
                    db          "                  S = Start Game                E = Exit                       ",'$'
CODESEG
;------------------------------------------------------------------------
; HandleWelcome: 
; 
; Input:
;     call HandleWelcome
; 
; Output: None
;------------------------------------------------------------------------
PROC HandleWelcome
    push bp
    mov bp,sp
    ;sub sp,2            ;<- set value
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; saved registers
 
    ;{
    ;}

    gr_set_video_mode_txt

    push offset welcomeStr
    call PrintStr
    
@@key:    
    call WaitForKeypress

    ; Possible keys S and E
    cmp ax, KEY_S
    jne @@keyE

    mov [_GameState], STATE_LEVEL1
    jmp @@end
    
@@keyE:
    cmp ax, KEY_E
    jne @@key

    ; Exit game
    mov [_GameState], STATE_EXIT
    jmp @@end
    
@@end:
    popa
    mov sp,bp
    pop bp
    ret 
ENDP HandleWelcome