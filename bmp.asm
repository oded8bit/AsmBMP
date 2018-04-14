;===================================================================================================
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Date: 13-04-2018
;
; Description: Draws a BMP on the screen
; You need to include "defs.asm" within your DATASEG and this file within you CODESEG
;===================================================================================================
LOCALS @@

; BMP related size constants
BMP_MAX_WIDTH 			 = 320
BMP_HEADER_SIZE			 = 54
BMP_HEADER_WIDTH_OFFSET  = 12h
BMP_HEADER_HEIGHT_OFFSET = 16h
; Struc ofsets
BMP_FILE_HANDLE_OFFSET 	= 0
BMP_HEADER_OFFSET 		= BMP_FILE_HANDLE_OFFSET + 2
BMP_PALETTE_OFFSET 		= BMP_HEADER_OFFSET + BMP_HEADER_SIZE
BMP_WIDTH_OFFSET 		= BMP_PALETTE_OFFSET + BMP_PALETTE_SIZE
BMP_HEIGHT_OFFSET 		= BMP_WIDTH_OFFSET + 2
BMP_IMAGE_PATH 			= BMP_HEIGHT_OFFSET + 2
BMP_LOADED_OFFSET		= BMP_IMAGE_PATH + BMP_PATH_LENGTH + 1
BMP_SKIP_SIZE			= BMP_HEADER_SIZE + BMP_PALETTE_SIZE

DATASEG
	; Used to read a single line from the file
    _bmpSingleLine 	db BMP_MAX_WIDTH dup (0)  
CODESEG

;------------------------------------------------------------------------
; Gets a pointer (address) to a specific field in the Bitmap struct
; Puts the address in specified register
;------------------------------------------------------------------------
MACRO get_struc_ptr reg, base, offst
	mov reg, base
	add reg, offst
ENDM
;------------------------------------------------------------------------
; Reads a BMP image from disk and displays it on the screen
; You can use the 'DisplayBmp' macro to make it easier to call this
; proc
;
; Input:
;     push  offset of BMP struct
;     push  xtopLeft
;     push  ytopLeft
;     call OpenShowBmp
; 
; Output: 	
;     AX - TRUE on success, FALSE on error
;------------------------------------------------------------------------
PROC OpenShowBmp 
    push bp
	mov bp,sp
	push bx cx dx si di
    
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => ytopLeft
	; bp+6 => xtopLeft
    ; bp+8 => offset of BMP struct
	; saved registers      

    ;{
        ytopLeft    equ     [WORD bp+4]
        xtopLeft    equ     [WORD bp+6]
        bmp         equ     [WORD bp+8]
        filePath    equ     [WORD bp+10]
    ;}
	
	push bmp
    call OpenBmpFile    
	cmp ax,FALSE    
	je @@ExitPROC

	get_struc_ptr di, bmp, BMP_LOADED_OFFSET
	cmp [WORD di], TRUE
	je @@alreadyLoaded

	; Read bitmap header
    push bmp
	call ReadBmpHeader

	; Read bitmap palette
    push bmp
	call ReadBmpPalette

	jmp @@handlePalete

@@alreadyLoaded:
	; If the structure was already loaded in the past, 
	; move file pointer over header and palette	(fseek)

	mov ah, 42h				; Move File Pointer Using Handle
	mov al, 1				; current location plus offset (SEEK_CUR)

	get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET
	mov bx, [si]

	mov cx, 0
	mov dx, BMP_SKIP_SIZE
	int 21h

@@handlePalete:	
	; Copy palette to screen
    push bmp
	call CopyBmpPalette	
	; Display the bitmap
    push bmp
	push xtopLeft
	push ytopLeft
	call ShowBMP 
	; Close file
    push bmp
	call CloseBmpFile
	mov ax, TRUE
@@ExitPROC:
	pop di si dx cx bx
    mov sp,bp
    pop bp
	ret 6
ENDP OpenShowBmp	
;------------------------------------------------------------------------
; Reads a BMP image from disk and displays it on the screen
; 
; Input:
;	  push offset bmp struct
;     call OpenShowBmp
; 
; Output: 
;     AX - TRUE on success, FALSE on error
;------------------------------------------------------------------------
PROC OpenBmpFile			
    push bp
	mov bp,sp
	push dx si

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
    ; bp+4 => offset of BMP struct
	; saved registers      

    ;{
        bmp         equ     [bp+4]
    ;}

	; Open file
	get_struc_ptr si, bmp, BMP_IMAGE_PATH
    mov dx, si
	mov ah, 3Dh
	xor al, al
	int 21h
	jc @@ErrorAtOpen    

	; Save file handle
	get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET
	mov [si],ax

    mov ax,TRUE
	jmp @@ExitPROC	
@@ErrorAtOpen:
	mov ax,FALSE
@@ExitPROC:	
	pop si dx
    mov sp,bp
    pop bp
	ret 2
ENDP OpenBmpFile
;------------------------------------------------------------------------
; Close a file
; 
; Input:
;     push  offset of BMP structure
;     call CloseBmpFile
; 
; Output: None
;------------------------------------------------------------------------
PROC CloseBmpFile 
    push bp
	mov bp,sp
	push ax bx

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
    ; bp+4 => offset of BMP struct
	; saved registers      

    ;{
        bmp    equ     [bp+4]
    ;}

	mov ah,3Eh
	get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET
	mov bx,[si]
	int 21h

	pop bx ax
    mov sp,bp
    pop bp
	ret 2
ENDP CloseBmpFile
;------------------------------------------------------------------------
; Read 54 bytes of BMP header
; 
; Input:
;     push  offset of BMP structure
;     call ReadBmpHeader
; 
; Output: None
;------------------------------------------------------------------------
PROC ReadBmpHeader	
    push bp
	mov bp,sp
	pusha

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
    ; bp+4 => offset of BMP struct
	; saved registers      

    ;{
         bmp    equ     [bp+4]
    ;}
	
	mov ah,3fh
	get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET	
	mov bx, [si]
	mov cx,BMP_HEADER_SIZE
	get_struc_ptr si, bmp, BMP_HEADER_OFFSET	
	mov dx,si
	int 21h
	
	; Store bitmap width and height in struct
	; for use when drawing the bitmap
	mov si,dx
	mov ax, [word si+BMP_HEADER_WIDTH_OFFSET]	; width
	get_struc_ptr di, bmp, BMP_WIDTH_OFFSET
	mov [di],ax
	mov ax, [word si+BMP_HEADER_HEIGHT_OFFSET]	; height
	get_struc_ptr di, bmp, BMP_HEIGHT_OFFSET
	mov [di],ax
	; Mark it loaded
	get_struc_ptr di, bmp, BMP_LOADED_OFFSET
	mov [WORD di], TRUE

	popa
    mov sp,bp
    pop bp
	ret 2
ENDP ReadBmpHeader
;------------------------------------------------------------------------
; Read BMP file color palette, 256 colors * 4 bytes (400h)
; 4 bytes for each color BGR + null)	
; 
; Input:
;     push  offset of BMP structure
;     call ReadBmpPalette
; 
; Output: None
;------------------------------------------------------------------------
PROC ReadBmpPalette 					
    push bp
	mov bp,sp
	push cx dx si
	
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
    ; bp+4 => offset of BMP struct
	; saved registers      

    ;{
         bmp    equ     [bp+4]
    ;}

	get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET	
	mov bx, [si]
	mov ah,3fh
	mov cx,BMP_PALETTE_SIZE
	get_struc_ptr dx, bmp, BMP_PALETTE_OFFSET
	int 21h
	
	pop si dx cx
	
    mov sp,bp
    pop bp
	ret 2
ENDP ReadBmpPalette
;------------------------------------------------------------------------
; Will move out to screen memory the colors
; video ports are 3C8h for number of first color
; and 3C9h for all rest
; 
; Input:
;     push  offset of BMP structure
;     call CopyBmpPalette
; 
; Output: None
;------------------------------------------------------------------------
PROC CopyBmpPalette		
    push bp
	mov bp,sp								
	push cx dx
	
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
    ; bp+4 => offset of BMP struct
	; saved registers      

    ;{
         bmp    equ     [bp+4]
    ;}

	get_struc_ptr si, bmp, BMP_PALETTE_OFFSET
	mov cx,256
	mov dx,3C8h
	mov al,0  ; black first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
@@CopyNextColor:
	mov al,[si+2] 		; Red				
	shr al,2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution).				
	out dx,al 						
	mov al,[si+1] 		; Green.				
	shr al,2            
	out dx,al 							
	mov al,[si] 		; Blue.				
	shr al,2            
	out dx,al 							
	add si,4 			; Point to next color.  (4 bytes for each color BGR + null)				
								
	loop @@CopyNextColor
	
	pop dx cx
    mov sp,bp
    pop bp
	ret 2
ENDP CopyBmpPalette
;------------------------------------------------------------------------
; BMP graphics are saved upside-down.
; Read the graphic line by line (BmpRowSize lines in VGA format),
; displaying the lines from bottom to top.
; 
; Input:
;     push  offset of BMP structure
;     push  xtopLeft
;     push  ytopLeft
;     call ShowBMP
; 
; Output: None
;------------------------------------------------------------------------
PROC ShowBMP 
    push bp
	mov bp,sp		
	sub sp, 4			; local vars					
	pusha
	
    ; now the stack is
	; bp-4 => imgWidth
	; bp-2 => padding
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => yTopLeft
	; bp+6 => xTopLeft
    ; bp+8 => offset of BMP struct
	; saved registers      

    ;{
        ytopLeft    equ     [WORD bp+4]
        xtopLeft    equ     [WORD bp+6]		 
        bmp    		equ     [WORD bp+8]

		padding 	equ		[WORD bp-2]
		imgWidth   	equ		[WORD bp-4]
    ;}
    
	mov ax, 0A000h
	mov es, ax
	
	; File handle
	get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET	
	mov bx, [si]

	; Height
	get_struc_ptr si, bmp, BMP_HEIGHT_OFFSET
	mov cx,[si]
	
	; Width
	get_struc_ptr si, bmp, BMP_WIDTH_OFFSET
	mov ax,[si] 
	mov imgWidth, ax

	; row size must dived by 4 so if it less we must calculate the extra padding bytes
	xor dx,dx
	mov si,4
	div si
	mov padding,dx
	
	mov dx,xtopLeft
	
@@NextLine:
	push cx
	push dx
	
	mov di,cx  						; Current Row at the small bmp (each time -1)
	add di,ytopLeft 				; add the Y on entire screen
	 
	; next 5 lines  di will be  = cx*320 + dx , point to the correct screen line
	mov cx,di
	shl cx,6
	shl di,8
	add di,cx
	add di,dx
	
	; small Read one line
	mov ah,3fh
	mov cx,imgWidth
	add cx,padding  				; extra  bytes to each row must be divided by 4
	mov dx,offset _bmpSingleLine
	int 21h

	; Copy one line into video memory
	cld 							; Clear direction flag, for movsb
	mov ax,imgWidth
	mov si,offset _bmpSingleLine
	rep movsb 						; Copy line to the screen
	
	pop dx
	pop cx
	 
	loop @@NextLine
	
	popa
    mov sp,bp
    pop bp
	ret 6
ENDP ShowBMP 
;------------------------------------------------------------------------
; A C# like macro to display a Bitmap file on the screen
; Output: 	
;     AX - TRUE on success, FALSE on error
;------------------------------------------------------------------------
MACRO DisplayBmp bmp_offset, xtopLeft, yTopLeft
	push bmp_offset
	push xTopLeft
	push ytopLeft
	call OpenShowBmp
ENDM