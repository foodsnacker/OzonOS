; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree.


; Sound-Routines for Ozon.OS
PgPort     equ 83h
AddPort    equ 02h
LenPort    equ 03h
ModeReg    equ 49h
Channel    equ 01h
BasePort   equ 220h
Freq       equ 8000

Length1    dw  00h
MemLoc     dw  0000h
Page1      db  00h

align 2
sbInstalled: db 0

detectSoundBlaster:
	mov si,soundblasterDetect     ; offset address
    mov word [textPosX], 8
    mov word [textPosY], 76
    mov byte [textColor], white
	call drawTextXY

	call ResetDSP
	cmp AX, 0
	je sbFound
    mov word [textPosY], 76
	call printOptionNotFound	; AX != 0 means DSP reset failed = not found
	mov byte [sbInstalled], 0
	jmp sbDetectOk
sbFound:
    mov word [textPosY], 76
	call printOptionFound		; AX == 0 means DSP reset OK = found
	mov byte [sbInstalled], 1
sbDetectOk:
    clc
ret

MstrVol:
           push ax
           mov  dx,(BasePort+4)
           mov  al,22h
           out  dx,al
           pop  ax
           inc  dx
           out  dx,al
ret

ResetDSP:
           mov  dx,(BasePort+6)
           mov  al,01
           out  dx,al
           mov  cx,50
WaitIt1:   in   al,dx
           loop WaitIt1
           xor  al,al
           out  dx,al
           mov  cx,50
WaitIt2:   in   al,dx
           loop WaitIt2
           mov  ah,0FFh                 ; part of Return Code
           mov  dx,(BasePort+14)
           in   al,dx
           and  al,80h
           cmp  al,80h
           jne  short ResetErr
           mov  dx,(BasePort+10)
           in   al,dx
           cmp  al,0AAh
           jne  short ResetErr
ResetOK:   xor  ax,ax                   ; return ax = 0 if reset ok
ResetErr:
ret

WriteDSP:
           push ax
           mov  dx,(BasePort+12)
WaitIt:    in   al,dx
           and  al,80h
           jnz  short WaitIt
           pop  ax
           out  dx,al
ret

; ------------------------------------------------------------------
; playSBSample -- Play 8-bit PCM sample via Sound Blaster DMA
; IN: SI = pointer to raw PCM data (linear address low word)
;     CX = length of sample in bytes
; OUT: Nothing (registers preserved)

playSBSample:
    pusha

    ; Calculate linear address from CS:SI
    ; Linear = CS * 16 + SI
    mov ax, cs
    mov dx, 16
    mul dx                      ; DX:AX = CS * 16
    add ax, si                  ; AX = low word of linear address
    adc dx, 0                   ; DX = high word (page)

    mov [MemLoc], ax            ; Store DMA address (low 16 bits)
    mov [Page1], dl             ; Store DMA page (bits 16-19)

    dec cx                      ; DMA length is count-1
    mov [Length1], cx

    ; Program DMA Channel 1 for single-cycle playback
    mov al, 05h                 ; Mask DMA channel 1
    out 0Ah, al

    mov al, 0                   ; Clear flip-flop
    out 0Ch, al

    mov al, ModeReg             ; Mode: single, read, channel 1
    out 0Bh, al

    mov ax, [MemLoc]            ; DMA base address low byte
    out AddPort, al
    mov al, ah                  ; DMA base address high byte
    out AddPort, al

    mov ax, [Length1]           ; DMA transfer length low byte
    out LenPort, al
    mov al, ah                  ; DMA transfer length high byte
    out LenPort, al

    mov al, [Page1]            ; DMA page register
    out PgPort, al

    mov al, 01h                 ; Unmask DMA channel 1
    out 0Ah, al

    ; Set Sound Blaster sample rate
    mov al, 40h                 ; Set time constant command
    call WriteDSP
    mov al, 256 - (1000000 / Freq) ; Time constant for 8000 Hz = 131
    call WriteDSP

    ; Start single-cycle DMA playback
    mov al, 14h                 ; 8-bit single-cycle DMA output
    call WriteDSP
    mov ax, [Length1]           ; Send length low byte
    call WriteDSP
    mov al, ah                  ; Send length high byte
    call WriteDSP

    popa
ret

; ------------------------------------------------------------------
; os_speaker_tone -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note frequency; OUT: Nothing (registers preserved)

os_speaker_tone:
	pusha

	mov cx, ax			; Store note value for now

	mov al, 182
	out 43h, al
	mov ax, cx			; Set up frequency
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h			; Switch PC speaker on
	or al, 03h
	out 61h, al

	popa
	ret


; ------------------------------------------------------------------
; os_speaker_off -- Turn off PC speaker
; IN/OUT: Nothing (registers preserved)

os_speaker_off:
	pusha

	in al, 61h
	and al, 0FCh
	out 61h, al

	popa
	ret

; ------------------------------------------------------------------
; os_speaker_beep -- Short beep on PC speaker
; IN/OUT: Nothing (registers preserved)

os_speaker_beep:
    pusha

    mov ax, 2000                ; ~600 Hz beep
    call os_speaker_tone

    ; Delay loop (~100ms at typical CPU speeds)
    mov cx, 0FFFFh
.delay:
    nop
    nop
    loop .delay

    call os_speaker_off

    popa
    ret

; ------------------------------------------------------------------
; playSound -- Play sound: SB sample if available, PC Speaker beep as fallback
; IN: Nothing; OUT: Nothing (registers preserved)

playSound:
    pusha

    cmp byte [sbInstalled], 1
    jne .useSpeaker

    ; Play test.wav via Sound Blaster (skip 44-byte WAV header)
    mov si, testwav + 44        ; Skip WAV header (44 bytes)
    mov cx, testwavend - testwav - 44  ; Raw PCM length
    call playSBSample
    jmp .done

.useSpeaker:
    call os_speaker_beep

.done:
    popa
    ret
