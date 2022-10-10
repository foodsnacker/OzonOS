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

; holt den letzten Scancode und schreibt ein c auf den Schirm
keyboardHandler:
	pusha
	cli
	
    in AL,0x60               ; Read the scan code
	mov [scancode],AL        ; Save it

    mov AL, 0x61
    out 0x20, AL
    
    popa
retf

align 2
scancode: db 0
