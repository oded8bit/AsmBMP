;------------------------------------------------------------------
;
;------------------------------------------------------------------
PROC TestLines
    mov ax, 4

    push 2
    push 0
    push 0
    push 320
    push 200
    call FillScreen

    ; Draw the image
    mov si, offset Image
    DisplayBmp si,0, 0

    push 4
    push 149
    push 0
    push 150
    call DrawVerticalLine

    push 4
    push 0
    push 149
    push 150
    call DrawHorizonalLine

    push offset _Buffer
    push 0
    push 0
    push 150
    push 150
    call CopyScreenArea

    push 120
    push 0
    push 0
    push 320
    push 200
    call FillScreen

    push offset _Buffer
    push 30
    push 30
    push 150
    push 150
    call CopyBufferToScreen


    ret
ENDP TestLines
;------------------------------------------------------------------
;
;------------------------------------------------------------------
PROC TestDrawAndMove

    push 2
    push 0
    push 0
    push 320
    push 200
    call FillScreen

    mov bx,10        ; x
    mov cx,1

@@move:
    push offset _Buffer
    push 10
    push 10
    push 150
    push 150
    call CopyScreenArea

    push 1
    push 0
    push 0
    push 320
    push 200
    call FillScreen

    ; Draw the image
    mov si, offset Image
    DisplayBmp si,10, 10

    push offset _Buffer
    push 10
    push 11
    push 150
    push 150
    call CopyBufferToScreen

    ;add bx,50

    loop @@move

    ret
ENDP TestDrawAndMove
;------------------------------------------------------------------
; Loop that draws the image multiple times
;------------------------------------------------------------------	
PROC TestDrawMultiple
    ; Draw the bitmap 10 times shifted on the screen
    mov cx, 2
    mov bx, 0       ; x
    mov dx, 0       ; y
@@draw:    
    push cx
    ; Draw the image
    mov si, offset Image
    DisplayBmp si, bx, dx

    cmp ax, FALSE   ; Error openning file?
    je fileErr

    add bx,20       ; x+=20
    add dx,10       ; y+=10
    pop cx
    loop @@draw

    ret
ENDP TestDrawMultiple    
;------------------------------------------------------------------
; capture screen into buffer, erase it and draw buffer back to 
; screen in a different location
;------------------------------------------------------------------	
PROC TestSaveScreen	
    push offset _Buffer
    push 0
    push 0
    push 80
    push 80
    call CopyScreenArea


    ;push 0
    ;push 0
    ;push 320
    ;push 200
    ;call EraseScreenArea

	
    push offset _Buffer
    push 0
    push 70
    push 80
    push 80
    call CopyBufferToScreen

	ret
ENDP TestSaveScreen