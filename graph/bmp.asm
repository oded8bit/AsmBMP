;===================================================================================================
; Written By: Tomer Cnaan
;
; Description: Draws a BMP on the screen
; You need to include "defs.asm" within your DATASEG and this file within you CODESEG
;
; Modified version of http://t67.tik-tak.co.il/uploadfiles/tzvia_b/users/357724/Pic48X78.txt
;===================================================================================================
LOCALS @@

; BMP related size constants
BMP_MAX_WIDTH 			 = 320
BMP_HEADER_SIZE			 = 54
BMP_HEADER_WIDTH_OFFSET  = 12h
BMP_HEADER_HEIGHT_OFFSET = 16h
; Struc ofsets
BMP_FILE_HANDLE_OFFSET 	 = 0
BMP_HEADER_OFFSET 		 = BMP_FILE_HANDLE_OFFSET + 2
BMP_PALETTE_OFFSET 		 = BMP_HEADER_OFFSET + BMP_HEADER_SIZE
BMP_WIDTH_OFFSET 		 = BMP_PALETTE_OFFSET + BMP_PALETTE_SIZE
BMP_HEIGHT_OFFSET 		 = BMP_WIDTH_OFFSET + 2
BMP_IMAGE_PATH 			 = BMP_HEIGHT_OFFSET + 2
BMP_LOADED_OFFSET		 = BMP_IMAGE_PATH + BMP_PATH_LENGTH + 1
; for seek
BMP_SKIP_SIZE			 = BMP_HEADER_SIZE + BMP_PALETTE_SIZE

DATASEG
	; Used to read a single line from the file
    _bmpSingleLine 			db BMP_MAX_WIDTH dup (0)  
	; Draw palette only ones
	_palSet					db FALSE	
	_shouldDrawPalette		db TRUE
CODESEG
;------------------------------------------------------------------------
; A C# like macro to display a Bitmap file on the screen
; 
; Input:
;	  bmp_offset - offset of the Bitmap struct
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
; Output: 	
;     AX - TRUE on success, FALSE on error
;------------------------------------------------------------------------
MACRO set_draw_palette state
	mov [_shouldDrawPalette], state
ENDM
;------------------------------------------------------------------------
; A C# like macro to display a Bitmap file on the screen
; 
; Input:
;	  bmp_offset - offset of the Bitmap struct
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
; Output: 	
;     AX - TRUE on success, FALSE on error
;------------------------------------------------------------------------
MACRO Display_BMP bmp_offset, xtopLeft, yTopLeft
	push bmp_offset
	push xTopLeft
	push ytopLeft
	call BmpDisplay
ENDM
;------------------------------------------------------------------------
; A C# like macro to get the Bitmap height
; 
; Input:
;	  bmp_offset - offset of the Bitmap struct
; Output: 	
;     AX - Bitmap height
;------------------------------------------------------------------------
MACRO Get_Bmp_Height bmp_offset
	push bmp
	call GetBmpHeight
ENDM
;------------------------------------------------------------------------
; A C# like macro to get the Bitmap width
; 
; Input:
;	  bmp_offset - offset of the Bitmap struct
; Output: 	
;     AX - Bitmap width
;------------------------------------------------------------------------
MACRO Get_Bmp_Width bmp_offset
	push bmp
	call GetBmpWidth
ENDM
;=+=+=+=+=+=+=+=+=+=+=+=+=+= IMPLEMENTATION +=+=+=+=+=+=+=+=+=+=+=+=+=+=+

;------------------------------------------------------------------------
; Gets a pointer (address) to a specific field in the Bitmap struct
; Puts the address in specified register
; Input:
; 	reg - a register that will hold the pointer
; 	base - offset of the Bitmap struct
; 	offst - offset of the variable within the struct
;------------------------------------------------------------------------
MACRO bmp_get_struc_ptr reg, base, offst
	mov reg, base
	add reg, offst
ENDM
;------------------------------------------------------------------------
; Move file pointer over the header and palette (fseek)
;------------------------------------------------------------------------
MACRO bmp_fseek
	mov ah, 42h				; Move File Pointer Using Handle
	mov al, 1				; current location plus offset (SEEK_CUR)

	bmp_get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET
	mov bx, [si]			; Handle

	mov cx, 0				; High order offset
	mov dx, BMP_SKIP_SIZE	; Low order offset
	int 21h
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
;     call BmpDisplay
; 
; Output: 	
;     AX - TRUE on success, FALSE on error
;------------------------------------------------------------------------
PROC BmpDisplay 
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
	
	; Open the file
	push bmp
    call BmpOpenFile
	cmp ax,FALSE    
	je @@ExitPROC				; Abort on error

	; Check if it has been loaded alrady
	bmp_get_struc_ptr di, bmp, BMP_LOADED_OFFSET
	cmp [WORD di], TRUE
	je @@alreadyLoaded			; Avoid reading header and palette again

	; Read bitmap header
    push bmp
	call BmpReadHeader

	; Read bitmap palette	
    push bmp
	call BmpReadPalette

	jmp @@handlePalete

@@alreadyLoaded:
	; If the struct has already been loaded in the past, 
	; move file pointer over header and palette	(fseek)
	bmp_fseek

@@handlePalete:	
	; Copy palette to screen

	; if (_shouldDrawPalette) then draw palette
	cmp [_shouldDrawPalette], TRUE
	je @@doPal

	; else, check if it has already been drawn
	cmp [_palSet], TRUE
	je @@nopal
	mov [_palSet],TRUE
@@doPal:	
    push bmp
	call BmpCopyPalette	
@@nopal:	
	; Display the bitmap
    push bmp
	push xtopLeft
	push ytopLeft
	call BmpShowScreen 
	; Close file
    push bmp
	call BmpCloseFile
	mov ax, TRUE
@@ExitPROC:
	pop di si dx cx bx
    mov sp,bp
    pop bp
	ret 6
ENDP BmpDisplay	
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
PROC BmpOpenFile			
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
	bmp_get_struc_ptr si, bmp, BMP_IMAGE_PATH
    mov dx, si				; Path
	mov ah, 3Dh		
	xor al, al
	int 21h
	jc @@ErrorAtOpen    

	; Save file handle (ax)
	bmp_get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET
	mov [si],ax

    mov ax,TRUE				; Success
	jmp @@ExitPROC	
@@ErrorAtOpen:
	mov ax,FALSE			; Error
@@ExitPROC:	
	pop si dx
    mov sp,bp
    pop bp
	ret 2
ENDP BmpOpenFile
;------------------------------------------------------------------------
; Close a file
; 
; Input:
;     push  offset of BMP structure
;     call BmpCloseFile
; 
; Output: None
;------------------------------------------------------------------------
PROC BmpCloseFile 
    push bp
	mov bp,sp
	push ax bx si

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
    ; bp+4 => offset of BMP struct
	; saved registers      

    ;{
        bmp    equ     [bp+4]
    ;}

	mov ah,3Eh
	bmp_get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET
	mov bx,[si]				; Handle
	int 21h

	pop si bx ax
    mov sp,bp
    pop bp
	ret 2
ENDP BmpCloseFile
;------------------------------------------------------------------------
; Read 54 bytes of BMP header
; 
; Input:
;     push  offset of BMP structure
;     call BmpReadHeader
; 
; Output: None
;------------------------------------------------------------------------
PROC BmpReadHeader	
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
	bmp_get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET	
	mov bx, [si]
	mov cx,BMP_HEADER_SIZE
	bmp_get_struc_ptr si, bmp, BMP_HEADER_OFFSET	
	mov dx,si
	int 21h
	
	; Store bitmap width and height in struct
	; for use when drawing the bitmap
	mov si,dx
	mov ax, [word si+BMP_HEADER_WIDTH_OFFSET]	; width
	bmp_get_struc_ptr di, bmp, BMP_WIDTH_OFFSET
	mov [di],ax
	mov ax, [word si+BMP_HEADER_HEIGHT_OFFSET]	; height
	bmp_get_struc_ptr di, bmp, BMP_HEIGHT_OFFSET
	mov [di],ax
	; Mark it loaded
	bmp_get_struc_ptr di, bmp, BMP_LOADED_OFFSET	; Loaded
	mov [WORD di], TRUE

	popa
    mov sp,bp
    pop bp
	ret 2
ENDP BmpReadHeader
;------------------------------------------------------------------------
; Read BMP file color palette, 256 colors * 4 bytes (400h)
; 4 bytes for each color BGR + null)	
; 
; Input:
;     push  offset of BMP structure
;     call BmpReadPalette
; 
; Output: None
;------------------------------------------------------------------------
PROC BmpReadPalette 					
    push bp
	mov bp,sp
	push bx cx dx si
	
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
    ; bp+4 => offset of BMP struct
	; saved registers      

    ;{
         bmp    equ     [bp+4]
    ;}

	bmp_get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET	
	mov bx, [si]
	mov ah,3fh
	mov cx,BMP_PALETTE_SIZE
	bmp_get_struc_ptr dx, bmp, BMP_PALETTE_OFFSET
	int 21h
	
	pop si dx cx bx	
    mov sp,bp
    pop bp
	ret 2
ENDP BmpReadPalette
;------------------------------------------------------------------------
; Will move out to screen memory the colors
; video ports are 3C8h for number of first color
; and 3C9h for all rest
; 
; Input:
;     push  offset of BMP structure
;     call BmpCopyPalette
; 
; Output: None
;------------------------------------------------------------------------
PROC BmpCopyPalette		
    push bp
	mov bp,sp								
	push ax bx cx dx si
	
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
    ; bp+4 => offset of BMP struct
	; saved registers      

    ;{
         bmp    equ     [bp+4]
    ;}

	bmp_get_struc_ptr si, bmp, BMP_PALETTE_OFFSET
	mov cx,256
	mov dx,3C8h
	mov al,0  ; black first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
@@CopyNextColor:
	mov al,[si+2] 		; Red				
	shr al,2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution).				
	out dx,al 						
	mov al,[si+1] 		; Green				
	shr al,2            
	out dx,al 							
	mov al,[si] 		; Blue				
	shr al,2            
	out dx,al 							
	add si,4 			; Point to next color.  (4 bytes for each color BGR + null)				
								
	loop @@CopyNextColor
	
	pop si dx cx bx ax
    mov sp,bp
    pop bp
	ret 2
ENDP BmpCopyPalette
;------------------------------------------------------------------------
; BMP graphics are saved upside-down.
; Read the graphic line by line (BmpRowSize lines in VGA format),
; displaying the lines from bottom to top.
; 
; Input:
;     push  offset of BMP structure
;     push  xtopLeft
;     push  ytopLeft
;     call BmpShowScreen
; 
; Output: None
;------------------------------------------------------------------------
PROC BmpShowScreen 
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
    
	mov ax, VIDEO_MEMORY_ADDRESS_VGA			; Address of video memory
	mov es, ax
	
	; File handle
	bmp_get_struc_ptr si, bmp, BMP_FILE_HANDLE_OFFSET	
	mov bx, [si]

	; Height
	bmp_get_struc_ptr si, bmp, BMP_HEIGHT_OFFSET
	mov cx,[si]
	
	; Width
	bmp_get_struc_ptr si, bmp, BMP_WIDTH_OFFSET
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
	
	; Read a single line
	mov ah,3fh
	mov cx,imgWidth
	add cx,padding  				; extra  bytes to each row must be divided by 4
	mov dx,offset _bmpSingleLine
	int 21h

	; Copy line into video memory
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
ENDP BmpShowScreen 
;------------------------------------------------------------------------
; Returns the width of the bitmap as indicated in the struct
; 
; Input:
;     push  offset of BMP structure
;     call GetBmpWidth
; 
; Output: AX = width
;------------------------------------------------------------------------
PROC GetBmpWidth
    push bp
	mov bp,sp		
	push si
	
	bmp_get_struc_ptr si, bmp, BMP_WIDTH_OFFSET
	mov ax, [si]

	pop si
    mov sp,bp
    pop bp
	ret 2
ENDP GetBmpWidth
;------------------------------------------------------------------------
; Returns the height of the bitmap as indicated in the struct
; 
; Input:
;     push  offset of BMP structure
;     call GetBmpHeight
; 
; Output: AX = height
;------------------------------------------------------------------------
PROC GetBmpHeight
    push bp
	mov bp,sp		
	push si

	bmp_get_struc_ptr si, bmp, BMP_HEIGHT_OFFSET
	mov ax, [si]

	pop si
    mov sp,bp
    pop bp
	ret 2
ENDP GetBmpHeight
