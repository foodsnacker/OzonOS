; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree. 

; Keyboard-Handler for Ozon.OS

keyboardInitialize:
	mov si,keysDetect             ; offset address
    mov word [textPosX], 8
    mov word [textPosY], 66
    mov byte [textColor], white
	call drawTextXY
	
	push ds
	push word 0
	pop ds
	cli
	mov [4 * 9], word keyboardHandler
	mov [4 * 9 + 2], cs
	sti
	pop ds

    mov word [textPosY], 66
	call printOptionFound
	
    clc                         ; CF=0 is success
ret

; get last Scancode and show a 'c' on screen
keyboardHandler:
	pusha

    in AL,0x60               ; Read the scan code
	mov [scancode],AL        ; Save it

    mov AL, 0x20             ; Non-specific EOI
    out 0x20, AL

    popa
iret

align 2
scancode: db 0
