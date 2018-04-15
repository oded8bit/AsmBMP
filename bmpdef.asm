;===================================================================================================
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Date: 13-04-2018
;
; Description: A sample program showing how to use the Bitmap code
;===================================================================================================
; Global Bitmap constants
BMP_PALETTE_SIZE 	 = 400h
BMP_HEADER_SIZE 	 = 54
BMP_PATH_LENGTH   	 = 40
; Global definitions
TRUE 			 = 1
FALSE 			 = 0
NULL 			 = 0

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