; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.
;
; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree.

; Window Manager for Ozon.OS
; Amiga Workbench 1.3 style - cooperative multitasking

WIN_SIZE        equ 16
MAX_WINDOWS     equ 8
TITLEBAR_H      equ 12
GADGET_W        equ 12

WIN_ACTIVE      equ 0x01
WIN_VISIBLE     equ 0x02
WIN_FOCUS       equ 0x80

WIN_TITLE_FG    equ 0x0F
WIN_CONTENT_BG  equ 0x07
WIN_BORDER_COL  equ 0x08
WIN_ACTIVE_TIT  equ 0x01
WIN_INACTIVE_TIT equ 0x08
DESKTOP_BG      equ 0x16
SCREEN_TITLE_BG equ 0x01

;------------------------------------------------------
; Window table
;------------------------------------------------------
align 2
winTable:       times (MAX_WINDOWS * WIN_SIZE) db 0
winCount:       db 0
winDragIdx:     db 0xFF
winDragOffsX:   dw 0
winDragOffsY:   dw 0

;------------------------------------------------------
; wmInit
;------------------------------------------------------
wmInit:
    pusha
    cli                        ; Disable interrupts during screen init
    call plotMouseBack         ; Hide mouse cursor before redraw

    ; plotBoxXY: CX=Y, DX=X, SI=height, DI=width
    mov CX, 0              ; Y=0
    mov DX, 0              ; X=0
    mov SI, 200            ; height=200
    mov DI, 320            ; width=320
    mov AL, DESKTOP_BG
    call plotBoxXY

    mov CX, 0              ; Y=0
    mov DX, 0              ; X=0
    mov SI, 10             ; height=10
    mov DI, 320            ; width=320
    mov AL, SCREEN_TITLE_BG
    call plotBoxXY

    mov SI, strScreenTitle
    mov word [textPosX], 8
    mov word [textPosY], 1
    mov byte [textColor], WIN_TITLE_FG
    call drawTextXY

    mov byte [winCount], 0
    mov byte [winDragIdx], 0xFF
    call wmDrawDesktopIcons
    call saveMouseBackground   ; Save background at cursor position
    call plotMouse             ; Show cursor
    sti                        ; Re-enable interrupts
    popa
    ret

;------------------------------------------------------
; wmCreateWindow
; IN: AX=X, BX=Y, CX=W, DX=H, SI=title, DI=drawCB
;     [wmTempEvent] = eventCB
;------------------------------------------------------
wmTempEvent:    dw 0
wmNewX:     dw 0
wmNewY:     dw 0
wmNewW:     dw 0
wmNewH:     dw 0
wmNewTitle: dw 0
wmNewDraw:  dw 0

wmCreateWindow:
    pusha
    cmp byte [winCount], MAX_WINDOWS
    jge .fail

    mov [wmNewX], ax
    mov [wmNewY], bx
    mov [wmNewW], cx
    mov [wmNewH], dx
    mov [wmNewTitle], si
    mov [wmNewDraw], di

    xor bx, bx
    mov bl, [winCount]
    shl bx, 4

    mov ax, [wmNewX]
    mov [winTable + bx + 0], ax
    mov ax, [wmNewY]
    mov [winTable + bx + 2], ax
    mov ax, [wmNewW]
    mov [winTable + bx + 4], ax
    mov ax, [wmNewH]
    mov [winTable + bx + 6], ax
    mov byte [winTable + bx + 8], WIN_ACTIVE | WIN_VISIBLE | WIN_FOCUS
    mov byte [winTable + bx + 9], 0
    mov ax, [wmNewTitle]
    mov [winTable + bx + 10], ax
    mov ax, [wmNewDraw]
    mov [winTable + bx + 12], ax
    mov ax, [wmTempEvent]
    mov [winTable + bx + 14], ax

    call wmUnfocusAll
    or byte [winTable + bx + 8], WIN_FOCUS
    inc byte [winCount]
    call wmRedrawAll
    popa
    clc
    ret
.fail:
    popa
    stc
    ret

;------------------------------------------------------
; wmCloseWindow - IN: AL = window index
;------------------------------------------------------
wmCloseWindow:
    pusha
    xor si, si
    mov si, ax
    and si, 0x00FF
    xor di, di
    mov dl, [winCount]
    xor dh, dh
    cmp si, dx
    jge .done

    mov di, si
.shiftLoop:
    inc di
    cmp di, MAX_WINDOWS
    jge .decCount
    xor bx, bx
    mov bl, [winCount]
    cmp di, bx
    jge .decCount

    push si
    push di
    mov bx, di
    shl bx, 4
    mov si, di
    dec si
    shl si, 4
    mov cx, WIN_SIZE
.copyByte:
    mov al, [winTable + bx]
    mov [winTable + si], al
    inc bx
    inc si
    loop .copyByte
    pop di
    pop si
    jmp .shiftLoop

.decCount:
    dec byte [winCount]
    cmp byte [winCount], 0
    je .noFocus
    xor bx, bx
    mov bl, [winCount]
    dec bx
    shl bx, 4
    call wmUnfocusAll
    or byte [winTable + bx + 8], WIN_FOCUS
.noFocus:
    call wmRedrawAll
.done:
    popa
    ret

;------------------------------------------------------
; wmUnfocusAll
;------------------------------------------------------
wmUnfocusAll:
    pusha
    xor cx, cx
    mov cl, [winCount]
    xor bx, bx
.loop:
    cmp cx, 0
    je .done
    and byte [winTable + bx + 8], 0x7F
    add bx, WIN_SIZE
    dec cx
    jmp .loop
.done:
    popa
    ret

;------------------------------------------------------
; wmWindowToFront - IN: AL = index
;------------------------------------------------------
wmWindowToFront:
    pusha
    xor si, si
    mov si, ax
    and si, 0x00FF

    cmp byte [winCount], 1
    jle .done

    xor cx, cx
    mov cl, [winCount]
    dec cx
    cmp si, cx
    je .justFocus

    ; Save window to temp
    mov bx, si
    shl bx, 4
    mov cx, WIN_SIZE
    xor di, di
.save:
    mov al, [winTable + bx]
    mov [wmTempWin + di], al
    inc bx
    inc di
    loop .save

    mov di, si
.shift:
    mov bx, di
    inc bx
    xor cx, cx
    mov cl, [winCount]
    cmp bx, cx
    jge .place

    push di
    mov bx, di
    inc bx
    shl bx, 4
    shl di, 4
    mov cx, WIN_SIZE
.scopy:
    mov al, [winTable + bx]
    mov [winTable + di], al
    inc bx
    inc di
    loop .scopy
    pop di
    inc di
    jmp .shift

.place:
    xor di, di
    mov dl, [winCount]
    xor dh, dh
    mov di, dx
    dec di
    shl di, 4
    xor si, si
    mov cx, WIN_SIZE
.restore:
    mov al, [wmTempWin + si]
    mov [winTable + di], al
    inc si
    inc di
    loop .restore

.justFocus:
    call wmUnfocusAll
    xor bx, bx
    mov bl, [winCount]
    dec bx
    shl bx, 4
    or byte [winTable + bx + 8], WIN_FOCUS
    call wmRedrawAll
.done:
    popa
    ret

wmTempWin: times WIN_SIZE db 0

;------------------------------------------------------
; wmWindowToBack
;------------------------------------------------------
wmWindowToBack:
    pusha
    cmp byte [winCount], 2
    jl .done

    ; Save top window
    xor bx, bx
    mov bl, [winCount]
    dec bx
    shl bx, 4
    xor di, di
    mov cx, WIN_SIZE
.save:
    mov al, [winTable + bx]
    mov [wmTempWin + di], al
    inc bx
    inc di
    loop .save

    ; Shift up from top down
    xor di, di
    mov dl, [winCount]
    xor dh, dh
    mov di, dx
    sub di, 2
.sloop:
    cmp di, 0
    jl .place
    push di
    mov bx, di
    shl bx, 4
    mov si, bx
    add si, WIN_SIZE
    mov cx, WIN_SIZE
.scpy:
    mov al, [winTable + bx]
    mov [winTable + si], al
    inc bx
    inc si
    loop .scpy
    pop di
    dec di
    jmp .sloop

.place:
    xor si, si
    xor di, di
    mov cx, WIN_SIZE
.rest:
    mov al, [wmTempWin + si]
    mov [winTable + di], al
    inc si
    inc di
    loop .rest

    call wmUnfocusAll
    xor bx, bx
    mov bl, [winCount]
    dec bx
    shl bx, 4
    or byte [winTable + bx + 8], WIN_FOCUS
    call wmRedrawAll
.done:
    popa
    ret

;------------------------------------------------------
; wmRedrawAll
;------------------------------------------------------
wmRedrawAll:
    pusha
    cli                        ; Disable interrupts during redraw
    call plotMouseBack         ; Hide mouse cursor before redraw

    ; plotBoxXY: CX=Y, DX=X, SI=height, DI=width
    mov CX, 10             ; Y=10 (below title bar)
    mov DX, 0              ; X=0
    mov SI, 190            ; height=190
    mov DI, 320            ; width=320
    mov AL, DESKTOP_BG
    call plotBoxXY

    mov CX, 0              ; Y=0
    mov DX, 0              ; X=0
    mov SI, 10             ; height=10
    mov DI, 320            ; width=320
    mov AL, SCREEN_TITLE_BG
    call plotBoxXY

    mov SI, strScreenTitle
    mov word [textPosX], 8
    mov word [textPosY], 1
    mov byte [textColor], WIN_TITLE_FG
    call drawTextXY

    call wmDrawDesktopIcons

    xor cx, cx
    mov cl, [winCount]
    cmp cx, 0
    je .noneOpen
    xor bx, bx
.drawLoop:
    test byte [winTable + bx + 8], WIN_VISIBLE
    jz .skip
    push cx
    push bx
    mov [wmTmpIdx], bx          ; save for wmDrawWindow
    call wmDrawWindow
    pop bx
    pop cx
.skip:
    add bx, WIN_SIZE
    loop .drawLoop

.noneOpen:
    call saveMouseBackground   ; Save background at cursor position
    call plotMouse             ; Show cursor
    sti                        ; Re-enable interrupts
    popa
    ret

;------------------------------------------------------
; wmDrawWindow - IN: BX = offset, wmTmpIdx set
;------------------------------------------------------
wmDrawWindow:
    pusha

    mov ax, [winTable + bx + 0]
    mov [wmTmpX], ax
    mov ax, [winTable + bx + 2]
    mov [wmTmpY], ax
    mov ax, [winTable + bx + 4]
    mov [wmTmpW], ax
    mov ax, [winTable + bx + 6]
    mov [wmTmpH], ax

    ; Content area background
    ; plotBoxXY: CX=Y, DX=X, SI=height, DI=width
    mov CX, [wmTmpY]
    add CX, TITLEBAR_H
    mov DX, [wmTmpX]
    mov SI, [wmTmpH]
    sub SI, TITLEBAR_H
    cmp SI, 1
    jl .skipContent
    mov DI, [wmTmpW]
    mov AL, WIN_CONTENT_BG
    call plotBoxXY
.skipContent:

    ; Title bar
    ; plotBoxXY: CX=Y, DX=X, SI=height, DI=width
    mov CX, [wmTmpY]
    mov DX, [wmTmpX]
    mov SI, TITLEBAR_H
    mov DI, [wmTmpW]
    mov bx, [wmTmpIdx]
    test byte [winTable + bx + 8], WIN_FOCUS
    jz .inactT
    mov AL, WIN_ACTIVE_TIT
    jmp .drawT
.inactT:
    mov AL, WIN_INACTIVE_TIT
.drawT:
    call plotBoxXY

    ; Borders - plotBoxXY: CX=Y, DX=X, SI=height, DI=width
    ; Top border (horizontal line)
    mov CX, [wmTmpY]
    mov DX, [wmTmpX]
    mov SI, 1
    mov DI, [wmTmpW]
    mov AL, WIN_BORDER_COL
    call plotBoxXY

    ; Bottom border (horizontal line)
    mov CX, [wmTmpY]
    add CX, [wmTmpH]
    dec CX
    mov DX, [wmTmpX]
    mov SI, 1
    mov DI, [wmTmpW]
    mov AL, WIN_BORDER_COL
    call plotBoxXY

    ; Left border (vertical line)
    mov CX, [wmTmpY]
    mov DX, [wmTmpX]
    mov SI, [wmTmpH]
    mov DI, 1
    mov AL, WIN_BORDER_COL
    call plotBoxXY

    ; Right border (vertical line)
    mov CX, [wmTmpY]
    mov DX, [wmTmpX]
    add DX, [wmTmpW]
    dec DX
    mov SI, [wmTmpH]
    mov DI, 1
    mov AL, WIN_BORDER_COL
    call plotBoxXY

    ; Close gadget (top-left)
    mov CX, [wmTmpY]
    mov DX, [wmTmpX]
    mov AX, 12
    mov BX, 12
    mov SI, closeNormal
    call plotImageXY

    ; Depth gadget (near top-right)
    mov CX, [wmTmpY]
    mov DX, [wmTmpX]
    add DX, [wmTmpW]
    sub DX, 24
    mov AX, 12
    mov BX, 12
    mov SI, depthNormal
    call plotImageXY

    ; Size gadget (top-right)
    mov CX, [wmTmpY]
    mov DX, [wmTmpX]
    add DX, [wmTmpW]
    sub DX, 12
    mov AX, 12
    mov BX, 12
    mov SI, sizeNormal
    call plotImageXY

    ; Title text
    mov AX, [wmTmpX]
    add AX, 14
    mov [textPosX], AX
    mov AX, [wmTmpY]
    add AX, 2
    mov [textPosY], AX
    mov byte [textColor], WIN_TITLE_FG
    mov bx, [wmTmpIdx]
    mov SI, [winTable + bx + 10]
    call drawTextXY

    ; Content draw callback
    mov bx, [wmTmpIdx]
    mov ax, [winTable + bx + 12]
    cmp ax, 0
    je .noCB

    mov ax, [wmTmpX]
    inc ax
    mov [wmContentX], ax
    mov ax, [wmTmpY]
    add ax, TITLEBAR_H
    mov [wmContentY], ax
    mov ax, [wmTmpW]
    sub ax, 2
    mov [wmContentW], ax
    mov ax, [wmTmpH]
    sub ax, TITLEBAR_H + 1
    mov [wmContentH], ax

    mov bx, [wmTmpIdx]
    call [winTable + bx + 12]
.noCB:
    popa
    ret

wmTmpX:   dw 0
wmTmpY:   dw 0
wmTmpW:   dw 0
wmTmpH:   dw 0
wmTmpIdx: dw 0
wmContentX: dw 0
wmContentY: dw 0
wmContentW: dw 0
wmContentH: dw 0

;------------------------------------------------------
; wmHitTest
; IN: AX=mouseX, BX=mouseY
; OUT: AL=index (0xFF=none), AH=area (0=content,1=title,2=close,3=depth,4=size)
;------------------------------------------------------
wmHitTest:
    push cx
    push dx
    push si
    push di

    mov [wmHitMX], ax
    mov [wmHitMY], bx

    xor cx, cx
    mov cl, [winCount]
    cmp cx, 0
    je .miss

    mov di, cx
    dec di

.testLoop:
    mov si, di
    shl si, 4

    mov ax, [wmHitMX]
    mov dx, [winTable + si + 0]
    cmp ax, dx
    jl .notThis
    add dx, [winTable + si + 4]
    cmp ax, dx
    jge .notThis

    mov ax, [wmHitMY]
    mov dx, [winTable + si + 2]
    cmp ax, dx
    jl .notThis
    add dx, [winTable + si + 6]
    cmp ax, dx
    jge .notThis

    ; Hit! Check title bar
    mov dx, [winTable + si + 2]
    add dx, TITLEBAR_H
    mov ax, [wmHitMY]
    cmp ax, dx
    jge .hitContent

    ; Gadgets
    mov dx, [winTable + si + 0]
    add dx, 12
    mov ax, [wmHitMX]
    cmp ax, dx
    jl .hitClose

    mov dx, [winTable + si + 0]
    add dx, [winTable + si + 4]
    sub dx, 24
    cmp ax, dx
    jl .hitTitlebar
    add dx, 12
    cmp ax, dx
    jl .hitDepth
    jmp .hitSize

.hitClose:
    mov ax, di
    mov ah, 2
    jmp .htDone
.hitDepth:
    mov ax, di
    mov ah, 3
    jmp .htDone
.hitSize:
    mov ax, di
    mov ah, 4
    jmp .htDone
.hitTitlebar:
    mov ax, di
    mov ah, 1
    jmp .htDone
.hitContent:
    mov ax, di
    mov ah, 0
    jmp .htDone

.notThis:
    dec di
    jns .testLoop

.miss:
    mov al, 0xFF
    mov ah, 0xFF

.htDone:
    pop di
    pop si
    pop dx
    pop cx
    ret

wmHitMX: dw 0
wmHitMY: dw 0

;------------------------------------------------------
; wmHandleClick - IN: AX=mouseX, BX=mouseY
;------------------------------------------------------
wmHandleClick:
    pusha
    call wmHitTest

    cmp al, 0xFF
    je .clickDesktop

    mov [wmClickIdx], al
    mov [wmClickArea], ah

    call wmWindowToFront
    ; After toFront, window is at winCount-1
    xor bx, bx
    mov bl, [winCount]
    dec bx

    cmp byte [wmClickArea], 2
    je .doClose
    cmp byte [wmClickArea], 3
    je .doDepth
    cmp byte [wmClickArea], 1
    je .startDrag
    cmp byte [wmClickArea], 4
    je .doNothing

    ; Content click
    push bx
    shl bx, 4
    mov si, [winTable + bx + 14]
    pop bx
    cmp si, 0
    je .done
    call si
    jmp .done

.doClose:
    mov al, bl
    call wmCloseWindow
    jmp .done

.doDepth:
    call wmWindowToBack
    jmp .done

.startDrag:
    mov [winDragIdx], bl
    push bx
    shl bx, 4
    mov ax, [mouseX]
    sub ax, [winTable + bx + 0]
    mov [winDragOffsX], ax
    mov ax, [mouseY]
    sub ax, [winTable + bx + 2]
    mov [winDragOffsY], ax
    pop bx
    jmp .done

.doNothing:
.clickDesktop:
    call wmDesktopIconHitTest
.done:
    popa
    ret

wmClickIdx:  db 0
wmClickArea: db 0

;------------------------------------------------------
; wmHandleDrag
;------------------------------------------------------
wmHandleDrag:
    pusha
    cmp byte [winDragIdx], 0xFF
    je .done

    xor bx, bx
    mov bl, [winDragIdx]
    shl bx, 4

    mov ax, [mouseX]
    sub ax, [winDragOffsX]
    cmp ax, 0
    jge .xL
    xor ax, ax
.xL:
    cmp ax, 308
    jle .xH
    mov ax, 308
.xH:
    mov [winTable + bx + 0], ax

    mov ax, [mouseY]
    sub ax, [winDragOffsY]
    cmp ax, 10
    jge .yL
    mov ax, 10
.yL:
    cmp ax, 188
    jle .yH
    mov ax, 188
.yH:
    mov [winTable + bx + 2], ax
    call wmRedrawAll
.done:
    popa
    ret

;------------------------------------------------------
; wmHandleRelease
;------------------------------------------------------
wmHandleRelease:
    mov byte [winDragIdx], 0xFF
    ret

;------------------------------------------------------
; Desktop Icons
;------------------------------------------------------
NUM_DESK_ICONS  equ 4
DESK_ICON_SIZE  equ 10

deskIcons:
    dw 264, 20, iconFolder, strDemos, deskLaunchDemos
    dw 264, 56, iconDisk, strSystem, deskLaunchSystem
    dw 264, 92, iconDocument, strSound, deskLaunchSound
    dw 264, 164, iconTrash, strTrash, 0

wmDrawDesktopIcons:
    pusha
    xor bp, bp
    mov di, deskIcons
.drawIcon:
    cmp bp, NUM_DESK_ICONS
    jge .done
    push di
    mov DX, [di + 0]
    mov CX, [di + 2]
    mov SI, [di + 4]
    mov AX, 16
    mov BX, 16
    call plotImageXY
    pop di
    push di
    mov AX, [di + 0]
    mov [textPosX], AX
    mov AX, [di + 2]
    add AX, 17
    mov [textPosY], AX
    mov byte [textColor], 0x0F
    mov SI, [di + 6]
    call drawTextXY
    pop di
    add di, DESK_ICON_SIZE
    inc bp
    jmp .drawIcon
.done:
    popa
    ret

;------------------------------------------------------
; wmDesktopIconHitTest
;------------------------------------------------------
wmDesktopIconHitTest:
    pusha
    mov ax, [mouseX]
    mov bx, [mouseY]
    xor bp, bp
    mov di, deskIcons
.check:
    cmp bp, NUM_DESK_ICONS
    jge .noHit
    mov cx, [di + 0]
    cmp ax, cx
    jl .next
    add cx, 48
    cmp ax, cx
    jge .next
    mov cx, [di + 2]
    cmp bx, cx
    jl .next
    add cx, 24
    cmp bx, cx
    jge .next
    mov si, [di + 8]
    cmp si, 0
    je .next
    call si
    jmp .noHit
.next:
    add di, DESK_ICON_SIZE
    inc bp
    jmp .check
.noHit:
    popa
    ret

;------------------------------------------------------
; Launch callbacks
;------------------------------------------------------
deskLaunchDemos:
    pusha
    mov word [wmTempEvent], demoListEvent
    mov AX, 20
    mov BX, 20
    mov CX, 200
    mov DX, 110
    mov SI, strDemos
    mov DI, demoListDraw
    call wmCreateWindow
    popa
    ret

deskLaunchSystem:
    pusha
    mov word [wmTempEvent], 0
    mov AX, 50
    mov BX, 30
    mov CX, 190
    mov DX, 100
    mov SI, strSystem
    mov DI, sysInfoDraw
    call wmCreateWindow
    popa
    ret

deskLaunchSound:
    pusha
    call playSound
    popa
    ret

;------------------------------------------------------
; Demo List content
;------------------------------------------------------
demoListDraw:
    pusha
    mov ax, [wmContentX]
    add ax, 4
    mov bx, [wmContentY]
    add bx, 4

    ; Mandelbrot entry
    push ax
    push bx
    mov DX, ax
    mov CX, bx
    mov SI, iconDocument
    mov AX, 16
    mov BX, 16
    call plotImageXY
    pop bx
    pop ax
    push ax
    add ax, 18
    mov [textPosX], ax
    mov [textPosY], bx
    add word [textPosY], 4
    mov byte [textColor], 0x00
    mov SI, strMandelbrot
    call drawTextXY
    pop ax

    ; Colors entry
    add bx, 20
    push ax
    push bx
    mov DX, ax
    mov CX, bx
    mov SI, iconDocument
    mov AX, 16
    mov BX, 16
    call plotImageXY
    pop bx
    pop ax
    push ax
    add ax, 18
    mov [textPosX], ax
    mov [textPosY], bx
    add word [textPosY], 4
    mov byte [textColor], 0x00
    mov SI, strColors
    call drawTextXY
    pop ax

    ; Sound Test entry
    add bx, 20
    push ax
    push bx
    mov DX, ax
    mov CX, bx
    mov SI, iconDocument
    mov AX, 16
    mov BX, 16
    call plotImageXY
    pop bx
    pop ax
    push ax
    add ax, 18
    mov [textPosX], ax
    mov [textPosY], bx
    add word [textPosY], 4
    mov byte [textColor], 0x00
    mov SI, strSoundTest
    call drawTextXY
    pop ax

    ; Bouncing Ball entry
    add bx, 20
    push ax
    push bx
    mov DX, ax
    mov CX, bx
    mov SI, iconDocument
    mov AX, 16
    mov BX, 16
    call plotImageXY
    pop bx
    pop ax
    add ax, 18
    mov [textPosX], ax
    mov [textPosY], bx
    add word [textPosY], 4
    mov byte [textColor], 0x00
    mov SI, strBounce
    call drawTextXY
    popa
    ret

;------------------------------------------------------
; demoListEvent
;------------------------------------------------------
demoListEvent:
    pusha
    mov ax, [mouseY]
    sub ax, [wmContentY]
    sub ax, 4
    cmp ax, 0
    jl .done
    cmp ax, 20
    jl .lMandel
    cmp ax, 40
    jl .lColors
    cmp ax, 60
    jl .lSound
    cmp ax, 80
    jl .lBounce
    jmp .done

.lMandel:
    mov word [wmTempEvent], 0
    mov AX, 10
    mov BX, 15
    mov CX, 200
    mov DX, 160
    mov SI, strMandelbrot
    mov DI, demoMandelbrotDraw
    call wmCreateWindow
    jmp .done
.lColors:
    mov word [wmTempEvent], 0
    mov AX, 40
    mov BX, 25
    mov CX, 146
    mov DX, 150
    mov SI, strColors
    mov DI, demoColorsDraw
    call wmCreateWindow
    jmp .done
.lSound:
    call playSound
    jmp .done
.lBounce:
    mov word [wmTempEvent], 0
    mov AX, 60
    mov BX, 20
    mov CX, 160
    mov DX, 130
    mov SI, strBounce
    mov DI, demoBounceDraw
    call wmCreateWindow
    jmp .done
.done:
    popa
    ret

;------------------------------------------------------
; System Info
;------------------------------------------------------
sysInfoDraw:
    pusha
    mov ax, [wmContentX]
    add ax, 4
    mov bx, [wmContentY]
    add bx, 6
    mov [textPosX], ax
    mov [textPosY], bx
    mov byte [textColor], 0x00
    mov SI, strCPU
    call drawTextXY
    add bx, 12
    mov [textPosX], ax
    mov [textPosY], bx
    mov SI, strVideo
    call drawTextXY
    add bx, 12
    mov [textPosX], ax
    mov [textPosY], bx
    cmp byte [sbInstalled], 1
    je .sby
    mov SI, strSBNo
    jmp .sbd
.sby:
    mov SI, strSBYes
.sbd:
    call drawTextXY
    add bx, 12
    mov [textPosX], ax
    mov [textPosY], bx
    mov SI, strMouseOK
    call drawTextXY
    popa
    ret

;------------------------------------------------------
; Demo: Mandelbrot
;------------------------------------------------------
demoMandelbrotDraw:
    pusha
    mov word [mbRow], 0
.mb_yloop:
    mov ax, [mbRow]
    cmp ax, [wmContentH]
    jge .mb_done
    mov word [mbCol], 0
.mb_xloop:
    mov ax, [mbCol]
    cmp ax, [wmContentW]
    jge .mb_nextrow

    ; cr = (col*2 - w) * 64 / w
    mov ax, [mbCol]
    shl ax, 1
    sub ax, [wmContentW]
    shl ax, 6
    mov cx, [wmContentW]
    cwd
    idiv cx
    mov [mbCR], ax

    ; ci = (row*2 - h) * 64 / h
    mov ax, [mbRow]
    shl ax, 1
    sub ax, [wmContentH]
    shl ax, 6
    mov cx, [wmContentH]
    cwd
    idiv cx
    mov [mbCI], ax

    xor si, si
    xor di, di
    xor bx, bx

.mb_iter:
    cmp bx, 32
    jge .mb_plot

    mov ax, si
    imul si
    mov cx, ax
    sar cx, 6

    mov ax, di
    imul di
    mov bp, ax
    sar bp, 6

    mov ax, cx
    add ax, bp
    cmp ax, 256
    jg .mb_plot

    mov ax, si
    imul di
    sar ax, 5
    add ax, [mbCI]
    mov di, ax

    mov ax, cx
    sub ax, bp
    add ax, [mbCR]
    mov si, ax

    inc bx
    jmp .mb_iter

.mb_plot:
    mov al, bl
    cmp al, 32
    jl .mb_notMax
    xor al, al
    jmp .mb_drawPx
.mb_notMax:
    add al, 0x10
.mb_drawPx:
    push ES
    push ax
    mov ax, 0xA000
    mov ES, ax
    mov ax, [wmContentY]
    add ax, [mbRow]
    mov bx, 320
    mul bx
    add ax, [wmContentX]
    add ax, [mbCol]
    mov bx, ax
    pop ax
    mov [ES:bx], al
    pop ES

    inc word [mbCol]
    jmp .mb_xloop
.mb_nextrow:
    inc word [mbRow]
    jmp .mb_yloop
.mb_done:
    popa
    ret

mbRow:  dw 0
mbCol:  dw 0
mbCR:   dw 0
mbCI:   dw 0

;------------------------------------------------------
; Demo: Color Palette
;------------------------------------------------------
demoColorsDraw:
    pusha
    xor bp, bp
    xor cx, cx
.color_row:
    cmp cx, 16
    jge .color_done
    xor dx, dx
.color_col:
    cmp dx, 16
    jge .color_nextrow
    push cx
    push dx
    mov ax, dx
    shl ax, 3
    add ax, [wmContentX]
    add ax, 4
    mov si, ax
    mov ax, cx
    shl ax, 3
    add ax, [wmContentY]
    add ax, 4
    mov CX, ax             ; CX=Y (row position)
    mov DX, si             ; DX=X (col position)
    mov SI, 7              ; height
    mov DI, 7              ; width
    mov ax, bp
    call plotBoxXY
    pop dx
    pop cx
    inc bp
    inc dx
    jmp .color_col
.color_nextrow:
    inc cx
    jmp .color_row
.color_done:
    popa
    ret

;------------------------------------------------------
; Demo: Bouncing Ball
;------------------------------------------------------
ballX:      dw 20
ballY:      dw 20
ballDX:     dw 2
ballDY:     dw 1
BALL_SIZE   equ 6

demoBounceDraw:
    pusha
    ; plotBoxXY: CX=Y, DX=X, SI=height, DI=width
    mov CX, [wmContentY]
    add CX, [ballY]
    mov DX, [wmContentX]
    add DX, [ballX]
    mov SI, BALL_SIZE
    mov DI, BALL_SIZE
    mov AL, 0x0C
    call plotBoxXY
    popa
    ret

demoBounceTick:
    pusha
    mov ax, [ballX]
    add ax, [ballDX]
    mov [ballX], ax
    mov ax, [ballY]
    add ax, [ballDY]
    mov [ballY], ax
    cmp word [ballX], 2
    jg .xL
    neg word [ballDX]
    mov word [ballX], 2
.xL:
    mov ax, [ballX]
    add ax, BALL_SIZE
    cmp ax, 140
    jl .xH
    neg word [ballDX]
.xH:
    cmp word [ballY], 2
    jg .yL
    neg word [ballDY]
    mov word [ballY], 2
.yL:
    mov ax, [ballY]
    add ax, BALL_SIZE
    cmp ax, 100
    jl .yH
    neg word [ballDY]
.yH:
    popa
    ret

;------------------------------------------------------
; Strings
;------------------------------------------------------
strScreenTitle: db 'Ozon.OS 1.0', 0
strDemos:       db 'Demos', 0
strSystem:      db 'System', 0
strSound:       db 'Sound', 0
strTrash:       db 'Trash', 0
strMandelbrot:  db 'Mandelbrot', 0
strColors:      db 'Colors', 0
strSoundTest:   db 'Sound Test', 0
strBounce:      db 'Bouncing Ball', 0
strCPU:         db 'CPU: 8086/8088', 0
strVideo:       db 'MCGA 320x200x256', 0
strSBYes:       db 'Sound Blaster', 0
strSBNo:        db 'PC Speaker only', 0
strMouseOK:     db 'PS/2 Mouse OK', 0
