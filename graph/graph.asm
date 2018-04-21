;===================================================================================================
; Written By: Tomer Cnaan
;
; Description: Graphic related utilities
;===================================================================================================
LOCALS @@

; Video constants (VGA)
VIDEO_MEMORY_ADDRESS_VGA = 0A000h
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
;------------------------------------------------------------------------
; A C# like macro to copy a screen area into a buffer
; Assumes the coordinates are within the screen limits
;
; Input:
;	  buffer - offset of the buffer
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
;     theWidth - the area width 
;     theHeight - the area height
; Output: None
;------------------------------------------------------------------------
MACRO Copy_Screen_Area buffer, xTopLeft, yTopLeft, theWidth, theHeight
    push buffer
    push xTopLeft
    push yTopLeft
    push theWidth
    push theHeight
    call CopyScreenArea 
ENDM
;------------------------------------------------------------------------
; A C# like macro to copy buffer into the screen memory
; Assumes the coordinates are within the screen limits
;
; Input:
;	  buffer - offset of the buffer
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
;     theWidth - the area width 
;     theHeight - the area height
; Output: None
;------------------------------------------------------------------------
MACRO Copy_Buffer_To_Screen buffer, xTopLeft, yTopLeft, theWidth, theHeight
    push buffer
    push xTopLeft
    push yTopLeft
    push theWidth
    push theHeight
    call CopyBufferToScreen 
ENDM
;------------------------------------------------------------------------
; A C# like macro to draw color black (0) on the screen
; - ssumes the coordinates are within the screen limits
; - if the default palette was changed, use Fill_Screen instead
;
; Input:
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
;     theWidth - the area width 
;     theHeight - the area height
; Output: None
;------------------------------------------------------------------------
MACRO Erase_Screen_Area xTopLeft, yTopLeft, theWidth, theHeight
    push xTopLeft
    push yTopLeft
    push theWidth
    push theHeight
    call EraseScreenArea 
ENDM
;------------------------------------------------------------------------
; A C# like macro to fill the screen with a color
; - ssumes the coordinates are within the screen limits
;
; Input:
;     color - the color
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
;     theWidth - the area width 
;     theHeight - the area height
; Output: None
;------------------------------------------------------------------------
MACRO Fill_Screen color, xTopLeft, yTopLeft, theWidth, theHeight
    push color
    push xTopLeft
    push yTopLeft
    push theWidth
    push theHeight
    call FillScreen 
ENDM
;------------------------------------------------------------------------
; A C# like macro to draw a horizontal line
; - ssumes the coordinates are within the screen limits
;
; Input:
;     color - the color
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
;     theWidth - the area width 
;     theHeight - the area height
; Output: None
;------------------------------------------------------------------------
MACRO Draw_Horiz_Line color, xTopLeft, yTopLeft, theLength
    push color
    push xTopLeft
    push yTopLeft
    push theLength
    call DrawHorizonalLine
ENDM
;------------------------------------------------------------------------
; A C# like macro to draw a vertical line
; - ssumes the coordinates are within the screen limits
;
; Input:
;     color - the color
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
;     theWidth - the area width 
;     theHeight - the area height
; Output: None
;------------------------------------------------------------------------
MACRO Draw_Vert_Line color, xTopLeft, yTopLeft, theLength
    push color
    push xTopLeft
    push yTopLeft
    push theLength
    call DrawVerticalLine
ENDM
;=+=+=+=+=+=+=+=+=+=+=+=+=+= IMPLEMENTATION +=+=+=+=+=+=+=+=+=+=+=+=+=+=+

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
; Sets reg to the video address for coordinates x,y
;----------------------------------------------------------
MACRO get_video_address reg, x, y
  mov ax, y
  mov bx, VGA_SCREEN_WIDTH
  mul bx
  mov reg, ax
  add reg, x    
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
; Draws black on the screen
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
    
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => theHeight
	; bp+6 => theWidth
    ; bp+8 => ytopLeft
    ; bp+10 => xtopLeft
    ; bp+12 => color
	; saved registers  

    ;{
        theHeight   equ         [word bp+4]
        theWidth    equ         [word bp+6]
        ytopLeft    equ         [word bp+8]
        xtopLeft    equ         [word bp+10]
        color       equ         [word bp+12]
    ;}    

    push VGA_COLOR_BLACK
    push yTopLeft
    push theWidth
    push theHeight
    call FillScreen

    mov sp,bp
    pop bp
	ret 10
ENDP EraseScreenArea
;------------------------------------------------------------------------
; Draws a color on the screen
; 
; Input:
;     push color
;     push xTopLeft
;     push yTopLeft
;     push theWidth
;     push theHeight
;     call FillScreen
; 
; Output: None
;------------------------------------------------------------------------
PROC FillScreen
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
    ; bp+12 => color
	; saved registers  

    ;{
        theHeight   equ         [word bp+4]
        theWidth    equ         [word bp+6]
        ytopLeft    equ         [word bp+8]
        xtopLeft    equ         [word bp+10]
        color       equ         [word bp+12]
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
    mov ax, color
    mov cx, theWidth
    rep stosb           ; Store AL at address ES:DI

	inc y				; y++
    pop cx
    loop @@copy

    pop ds es
    popa
    mov sp,bp
    pop bp
	ret 10
ENDP FillScreen
;------------------------------------------------------------------------
; Draws a color on the screen
; 
; Input:
;     push color
;     push xTopLeft
;     push yTopLeft
;     push theLength
;     call DrawHorizonalLine
; 
; Output: None
;------------------------------------------------------------------------
PROC DrawHorizonalLine
    push bp
	mov bp,sp
    pusha
    push es 

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => theLength
    ; bp+6 => ytopLeft
    ; bp+8 => xtopLeft
    ; bp+10 => color
	; saved registers  

    ;{
        theLength   equ         [word bp+4]
        ytopLeft    equ         [word bp+6]
        xtopLeft    equ         [word bp+8]
        color       equ         [word bp+10]
    ;}    

    get_video_address di, xTopLeft, yTopLeft

    push VIDEO_MEMORY_ADDRESS_VGA
    pop es

    mov ax, color
    
    cld
    mov cx, theLength
    rep stosb           ; Store AL at address ES:DI

    pop es
    popa
    mov sp,bp
    pop bp
	ret 8
ENDP DrawHorizonalLine
;------------------------------------------------------------------------
; Draws a color on the screen
; 
; Input:
;     push color
;     push xTopLeft
;     push yTopLeft
;     push theLength
;     call DrawVerticalLine
; 
; Output: None
;------------------------------------------------------------------------
PROC DrawVerticalLine
    push bp
	mov bp,sp
    sub sp,2
    pusha
    push es 

    ; now the stack is
    ; bp-2 => y
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => theLength
    ; bp+6 => ytopLeft
    ; bp+8 => xtopLeft
    ; bp+10 => color
	; saved registers  

    ;{
        theLength   equ         [word bp+4]
        ytopLeft    equ         [word bp+6]
        xtopLeft    equ         [word bp+8]
        color       equ         [byte bp+10]
        y           equ         [word bp-2]
    ;}    

    push VIDEO_MEMORY_ADDRESS_VGA
    pop es
    
    mov cx, theLength
    mov si, xTopLeft
    mov ax, ytopLeft
    mov y, ax
@@vert:
    gr_set_pixel si, y, color
    inc y

    loop @@Vert    


    pop es
    popa
    mov sp,bp
    pop bp
	ret 8
ENDP DrawVerticalLine


; Inlcludes
include "graph/bmp.asm"