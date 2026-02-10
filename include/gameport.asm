; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree. 

; Gameport-Routines for Ozon.OS

detectGameport:
	mov  al,01h                  ; value to write to
	mov  dx,0201h                ; port number 0201h
	out  dx,al                   ; 

	mov si,gamePortDetect        ; offset address
    mov word [textPosX], 8
    mov word [textPosY], 86
    mov byte [textColor], white
	call drawTextXY
	
    mov  cx,0F00h                ; number of loops
port_loop:
	in   al,dx                   ; read from port
	and  al,0Fh                  ; if joystick present, then AL should
	cmp  al,0Fh                  ; be 0Fh after ANDing with 0Fh.
	je   short done
	loop port_loop
           
	mov byte [gameportInstalled],0
    mov word [textPosY], 86
	call printOptionNotFound	; not found: loop exhausted without joystick response
ret
done:
	mov byte [gameportInstalled],1
    mov word [textPosY], 86
	call printOptionFound		; found: joystick responded with 0Fh

ret

align 2
gameportInstalled: db 0