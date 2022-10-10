; Kernal for Ozon.OS

use16
org 0x0500						; Memory layout is free from 0x0500

	xor ax, ax                  ; DS=SS=ES=0
    mov ds, ax
    mov ss, ax 
	mov sp, 0x0500				; stack pointer
	cld
	jmp 0x0000:kernalStart		; ensure cs == 0x0000

times 100 db 0 					; cleared space for stack

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
	
	mov SI,readyMSD             ; offset address
	mov word [textPosX], 8	    ; x horizontal coordinate
    mov word [textPosY], 182
    mov byte [textColor], white
	call drawTextXY

; finished initializing
	
	; !!! hier noch auf Maus und Tastendruck warten
;	call switchMode13h

	call .main_loop

.err_loop:
    hlt
    jmp .err_loop
    
; finished init
    
.main_loop:
    hlt                         ; Halt processor until next interrupt
    call plotMouse              ; Poll mouse and update display with coordintes & status
    jmp .main_loop              ; Endless main loop


%include "include/strings.asm"
%include "include/gfx.asm"
%include "include/ps2mouse.asm"
%include "include/keyboard.asm"
%include "include/sound.asm"
%include "include/gameport.asm"

%include "include/mandelbrot.asm"

;testwav: INCBIN "incbin/test.wav"
;testwavend:

%include "include/english.asm"

times 8192-($-$$) db 0