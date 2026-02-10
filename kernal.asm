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
	call switchMode13h			; switch to MCGA 320x200

	; Draw init screen background
	mov CX, 0
	mov DX, 0
	mov SI, 320
	mov DI, 200
	mov AL, 0x16				; medium grey
	call plotBoxXY

	call mouseInitialize		; switch on Mouse
    jc .err_loop                ; If CF set then error, inform user and end

	call keyboardInitialize		; switch on Keyboard
    jc .err_loop                ; If CF set then error, inform user and end

	call detectSoundBlaster		; detect Soundblaster-Card
	jc .err_loop

	call detectGameport			; detect Game Port
	jc .err_loop

	mov SI,readyMSD             ; offset address
	mov word [textPosX], 8	    ; x horizontal coordinate
    mov word [textPosY], 182
    mov byte [textColor], white
	call drawTextXY

	; Brief pause to show init screen
	mov cx, 0x0008
	mov dx, 0x0000
	mov ah, 0x86
	int 0x15

	; Play startup beep
	call os_speaker_beep

	; Initialize window manager and draw desktop
	call wmInit

; finished initializing

	; Enter main loop
	jmp .main_loop

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

; Main loop: cooperative multitasking event loop
.main_loop:
    hlt                         ; Halt processor until next interrupt

    ; --- Handle keyboard ---
    cmp byte [scancode], 0
    je .no_key

    ; ESC key (scancode 0x01) - close topmost window
    cmp byte [scancode], 0x01
    jne .not_esc
    mov byte [scancode], 0
    cmp byte [winCount], 0
    je .no_key
    mov al, [winCount]
    dec al
    call wmCloseWindow
    jmp .no_key
.not_esc:

    ; S key (scancode 0x1F) - play sound
    cmp byte [scancode], 0x1F
    jne .not_s_key
    mov byte [scancode], 0
    call playSound
    jmp .no_key
.not_s_key:

    mov byte [scancode], 0     ; consume unhandled key
.no_key:

    ; --- Handle mouse button ---
    ; Check for mouse button press (bit 0 of curStatus)
    test byte [curStatus], 0x01
    jz .mouse_released

    ; Button is pressed
    cmp byte [mouseWasPressed], 1
    je .mouse_held              ; already tracking

    ; New click!
    mov byte [mouseWasPressed], 1
    mov ax, [mouseX]
    mov bx, [mouseY]
    call wmHandleClick
    jmp .mouse_done

.mouse_held:
    ; Mouse held down - handle drag
    call wmHandleDrag
    jmp .mouse_done

.mouse_released:
    cmp byte [mouseWasPressed], 0
    je .mouse_done
    mov byte [mouseWasPressed], 0
    call wmHandleRelease

.mouse_done:

    ; --- Cooperative multitasking: tick animations ---
    ; Bouncing ball tick (only updates data, redraw happens via window system)
    inc word [tickCounter]
    test word [tickCounter], 0x07   ; every 8th tick
    jnz .no_tick
    call demoBounceTick
    ; Only redraw if a bounce window is open (check winCount > 0)
    ; Light redraw: just redraw all windows
    cmp byte [winCount], 0
    je .no_tick
    call wmRedrawAll
.no_tick:

    jmp .main_loop              ; Endless main loop

align 2
mouseWasPressed: db 0
tickCounter:     dw 0

%include "include/strings.asm"
%include "include/gfx.asm"
%include "include/gui_icons.asm"
%include "include/ps2mouse.asm"
%include "include/keyboard.asm"
%include "include/sound.asm"
%include "include/gameport.asm"
%include "include/window.asm"

testwav: INCBIN "incbin/test.wav"
testwavend:

%include "include/english.asm"

times 32768-($-$$) db 0
