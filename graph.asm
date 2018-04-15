;===================================================================================================
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Date: 13-04-2018
;
; Description: 
;
;===================================================================================================
LOCALS @@

; Global definitions
TRUE 			 		 = 1
FALSE 			 		 = 0
NULL 			 		 = 0
; Video constants (VGA)
VIDEO_MEMORY_ADDRESS_VGA = 0A000h
VGA_SCREEN_WIDTH         = 320
VGA_SCREEN_HEIGHT        = 200
; Colors
VGA_COLOR_BLACK          = 0
; Global Bitmap constants
BMP_PALETTE_SIZE 	 	 = 400h
BMP_HEADER_SIZE 	 	 = 54
BMP_PATH_LENGTH   	 	 = 40

DATASEG
	; The Bitmap struct
	struc Bitmap
		FileHandle	dw ?
		Header 	    db BMP_HEADER_SIZE dup(0)
		Palette 	db BMP_PALETTE_SIZE dup (0)
		Width		dw 0
		Height		dw 0
		ImagePath   db BMP_PATH_LENGTH+1 dup(0)
		Loaded		dw 0
	ENDS Bitmap
	
CODESEG
;----------------------------------------------------------
; Sets the MS-DOS BIOS Video Mode
;----------------------------------------------------------
MACRO gr_set_video_mode mode
  mov al, mode
  mov ah, 0
  int 10h
ENDM
;----------------------------------------------------------
; Explicitly sets the MS-DOS BIOS Video Mode
; to 80x25 Monochrome text 
;----------------------------------------------------------
MACRO gr_set_video_mode_txt 
  gr_set_video_mode 03h
ENDM
;----------------------------------------------------------
; Explicitly sets the MS-DOS BIOS Video Mode
; to 320x200 256 color graphics
;----------------------------------------------------------
MACRO gr_set_video_mode_vga 
  gr_set_video_mode 13h
ENDM
;----------------------------------------------------------
; Sets a pixel using Video Memory 
; Cannot use registers ax, bx, di as arguments
;----------------------------------------------------------
MACRO gr_set_pixel x, y, color
  local _NotDbl, _out
  push ax bx dx di es

  push VIDEO_MEMORY_ADDRESS_VGA
  pop es

_NotDbl:    
  mov ax, y
  mov bx, VGA_SCREEN_WIDTH
  mul bx
  mov di, ax
  add di, x
  mov al, color
  mov [es:di], al

_out:  
  pop es di dx bx ax
ENDM
;----------------------------------------------------------
; Checks if the coords are within the VGA screen size
; Output:
;   if valid => ax = 1   else   ax = 0
;----------------------------------------------------------
MACRO is_valid_coord_vga x,y,w,h
  local end, valid, invalid

  mov ax, x
  cmp ax,0
  jl invalid

  add ax, w
  cmp ax,VGA_SCREEN_WIDTH
  ja invalid

  mov ax, y
  cmp ax,0
  jl invalid

  add ax, h
  cmp ax,VGA_SCREEN_HEIGHT
  ja invalid

valid:
  mov ax,0  
  jmp end
invalid:
  mov ax,1  
end:  
ENDM
;------------------------------------------------------------------------
; Copies an area on the screen into a buffer
; 
; Input:
;	  push offset buffer
;     push xTopLeft
;     push yTopLeft
;     push theWidth
;     push theHeight
;     call CopyScreenArea
; 
; Output: None
;------------------------------------------------------------------------
PROC CopyScreenArea
    push bp
	mov bp,sp
	sub sp,2
    pusha
    push es ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => theHeight
	; bp+6 => theWidth
    ; bp+8 => ytopLeft
    ; bp+10 => xtopLeft
    ; bp+12 => offset buffer
	; saved registers  

    ;{
        theHeight   equ         [word bp+4]
        theWidth    equ         [word bp+6]
        ytopLeft    equ         [word bp+8]
        xtopLeft    equ         [word bp+10]
        buffer      equ         [word bp+12]
		y           equ			[word bp-2]
    ;}    

    push ds
    pop es

    push VIDEO_MEMORY_ADDRESS_VGA
    pop ds
    
    mov cx, theHeight
    mov di, buffer
	
	mov ax, yTopLeft
	mov y,ax				; current y
@@copy:    
    push cx di

    ; calculate address of first pixel on screen (for this line)
    ; and store it into ds:si
    mov ax, y
    mov bx, VGA_SCREEN_WIDTH
    mul bx
    mov si, ax
    add si, xtopLeft

    cld
    mov cx, theWidth
    rep movsb           ; Move byte at address DS:SI to address ES:DI

	inc y				; y++
    pop di cx
    add di, theWidth
    loop @@copy

    pop ds es
    popa
    mov sp,bp
    pop bp
	ret 10
ENDP CopyScreenArea
;------------------------------------------------------------------------
; Copies an area on the screen into a buffer
; 
; Input:
;	  push offset buffer
;     push xTopLeft
;     push yTopLeft
;     push theWidth
;     push theHeight
;     call CopyBufferToScreen
; 
; Output: None
;------------------------------------------------------------------------
PROC CopyBufferToScreen
    push bp
	mov bp,sp
	sub sp,2
    pusha
    push es ds
    ; now the stack is
	; bp-2 => current y
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => theHeight
	; bp+6 => theWidth
    ; bp+8 => ytopLeft
    ; bp+10 => xtopLeft
    ; bp+12 => offset buffer
	; saved registers  

    ;{
        theHeight   equ         [word bp+4]
        theWidth    equ         [word bp+6]
        ytopLeft    equ         [word bp+8]
        xtopLeft    equ         [word bp+10]
        buffer      equ         [word bp+12]
		y           equ			[word bp-2]
    ;}    

    push VIDEO_MEMORY_ADDRESS_VGA
    pop es
    
    mov cx, theHeight
    mov si, buffer
	mov ax, yTopLeft
	mov y,ax				; current y
@@copy:    
    push cx si

    ; calculate address of first pixel on screen (for this line)
    ; and store it into es:di
    mov ax, y
    mov bx, VGA_SCREEN_WIDTH
    mul bx
    mov di, ax
    add di, xtopLeft

    cld
    mov cx, theWidth
    rep movsb           ; Move byte at address DS:SI to address ES:DI

	inc y				; y++
    pop si cx
    add si, theWidth
    loop @@copy

    pop ds es
    popa
    mov sp,bp
    pop bp
	ret 10
ENDP CopyBufferToScreen
;------------------------------------------------------------------------
; Copies an area on the screen into a buffer
; 
; Input:
;     push xTopLeft
;     push yTopLeft
;     push theWidth
;     push theHeight
;     call EraseScreenArea
; 
; Output: None
;------------------------------------------------------------------------
PROC EraseScreenArea
    push bp
	mov bp,sp
	sub sp,2
    pusha
    push es ds
    ; now the stack is
	; bp-2 => current y
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => theHeight
	; bp+6 => theWidth
    ; bp+8 => ytopLeft
    ; bp+10 => xtopLeft
	; saved registers  

    ;{
        theHeight   equ         [word bp+4]
        theWidth    equ         [word bp+6]
        ytopLeft    equ         [word bp+8]
        xtopLeft    equ         [word bp+10]
		y           equ			[word bp-2]
    ;}    

    push VIDEO_MEMORY_ADDRESS_VGA
    pop es
    
    mov cx, theHeight
	mov ax, ytopLeft			
	mov y, ax					; current y
@@copy:    
    push cx

    ; calculate address of first pixel on screen (for this line)
    ; and store it into es:di
    mov ax, y
    mov bx, VGA_SCREEN_WIDTH
    mul bx
    mov di, ax
    add di, xtopLeft

    cld
    mov ax, VGA_COLOR_BLACK
    mov cx, theWidth
    rep stosb           ; Store AL at address ES:DI

	inc y				; y++
    pop cx
    loop @@copy

    pop ds es
    popa
    mov sp,bp
    pop bp
	ret 8
ENDP EraseScreenArea

include "bmp.asm"  