; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree. 

; Kernal for Ozon.OS

use16
org 0x0500						; Memory layout is free from 0x0500

	xor ax, ax                  ; DS=SS=ES=0
    mov ds, ax
    mov ss, ax 
	mov sp, 0x0500				; stack pointer
	cld
	jmp 0x0000:kernalStart		; ensure cs == 0x0000

times 512 db 0 					; cleared space for stack (512 bytes)

kernalStart:       
; Initialize Peripherals
	call mouseInitialize		; switch on Mouse
    jc .err_loop                ; If CF set then error, inform user and end

	call keyboardInitialize		; switch on Keyboard
    jc .err_loop                ; If CF set then error, inform user and end

	call detectSoundBlaster		; detect Soundblaster-Card
	jc .err_loop

	call detectGameport			; detect Game Port
	jc .err_loop

	; Load GUI icons into MCGA buffer
	call loadGuiIcons

	; Test: Draw icons to screen
	call testDrawIcons

	mov SI,readyMSD             ; offset address
	mov word [textPosX], 8	    ; x horizontal coordinate
    mov word [textPosY], 182
    mov byte [textColor], white
	call drawTextXY

; finished initializing

	; Enter main loop - mouse and keyboard are handled via interrupts
	call .main_loop

.err_loop:
	; Display error message
	mov SI, errorMSD            ; offset address
	mov word [textPosX], 8	    ; x horizontal coordinate
    mov word [textPosY], 182
    mov byte [textColor], white
	call drawTextXY

	; Halt system
    hlt
    jmp .err_loop
    
; finished init
    
.main_loop:
    hlt                         ; Halt processor until next interrupt
    call plotMouse              ; Poll mouse and update display with coordintes & status
    jmp .main_loop              ; Endless main loop


%include "include/strings.asm"
%include "include/gfx.asm"
%include "include/gui_icons.asm"
%include "include/ps2mouse.asm"
%include "include/keyboard.asm"
%include "include/sound.asm"
%include "include/gameport.asm"

%include "include/mandelbrot.asm"

;testwav: INCBIN "incbin/test.wav"
;testwavend:

%include "include/english.asm"

times 8192-($-$$) db 0