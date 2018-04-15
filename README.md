# AsmBMP
For more projects, [click here](http://odedc.net)

A 16-bits x86 DOS Assembly library for displaying bitmap files on VGA (320x200, 256 colors) displays.

**Note** The library was developed and tested using [TASM 4.1](https://sourceforge.net/projects/guitasm8086/files/) and [DosBox](https://www.dosbox.com/)

# How to use
See included [sample](sample.asm) program

Follow these steps:
1. You must use the .486 directive at the beginning of the program
```sh
.486
IDEAL
MODEL small
STACK 256
```
2. First, include the [graph](graph.asm) file before your DATASEG section
```sh
    include "graph.asm"                            ; Include Bitmap definitions
DATASEG
    ; Your variables
```

# Drawing a Bitmap

1. Create a bitmap struct in your DATASEG and initialize it with the file path (may include directories)
```sh
DATASEG
    ; This is the Bitmap that we are going to draw. Note how it is initialized
    ; with the file path (path should be up to BMP_PATH_LENGHTH bytes)
    Image          Bitmap    {ImagePath="img\\b1.bmp"}
```
2. Switch display to VGA mode (see gr_set_video_mode_vga macro in sample program)
3. To draw the bitmap use:
```sh
    ; Draw the image
    mov si, offset Image
    DisplayBmp si, 10,20
```
where Image is the bitmap struct and the values are x and y coordinates on the screen


# General graphics utilities

## Switch video mode

## Paint a Pixel

## Check if coordinates are in the screen

## Copy screen into buffer

## Copy buffer to screen

## Erase area on the screen


