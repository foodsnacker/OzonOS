; Sound-Routines for Ozon.OS
PgPort     equ 83h
AddPort    equ 02h
LenPort    equ 03h
ModeReg    equ 49h
Channel    equ 01h
BasePort   equ 220h
Freq       equ 11000

Length1    dw  00h
MemLoc     dw  0000h
Page1      db  00h

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
	call printOptionFound		; positions: textPosX und textPosY, Length = cl
	jmp sbDetectOk
sbFound:
    mov word [textPosY], 76
	call optionNotFound
sbDetectOk:
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
           mov  dx,[BasePort+6]
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

; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2019 MikeOS Developers -- see doc/LICENSE.TXT
;
; PC SPEAKER SOUND ROUTINES
; ==================================================================

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

