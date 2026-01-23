; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree. 

; Graphic-Routines for Ozon.OS
white     equ 0x0f
lightgrey equ 0x07
darkgrey  equ 0x08
midgrey   equ 0x16

textPosX    dw 0
textPosY 	dw 0
textColor   db 0

printChar:					; subroutine to print character on screen
							; Assume an ASCII value in register AL
	mov AH, 0x0E			; BIOS should print one char on screen
	mov BH, 0x00			; Page no, should be zero
	mov BL, 0x07			; Text attribute 0x07 is lightgrey font on black background
	int 0x10				; call video interrupt
ret							; Return to calling procedure

writeString:				; subroutine to write a text on screen
							; Assume dh, dl = position on screen
							; ES:BP pointer to string
							; CX: length of string
	mov AH, 0x13			; function 13h
	mov AL, 0x01			; attributes:
				  			; 0 string is chars only, attribute in BL, cursor not moved
							; 1 string is chard only, attribute in BL, cursor moved
							; 2 string contains chars and attributes, cursor not moved
							; 3 string contains chars and attributes, cursor moved
	mov BH, 0x00			; video page 0
	mov BL, 0x0f			; lightgrey on black background
	int 0x10				; call video interrupt
ret

writeStringWithLength:		; subroutine to get length of string, then write it
	call stringLength

	mov CX, AX				; stringLength gave back the length in AX
	mov BP, SI				; memory position of string is still in SI
	call writeString
ret

switchMode13h:				; subroutine to switch to MCGA 320x200
	mov AX, 0x0013
	int 0x10
ret

switchMode80x25:			; subroutine, will set 
	mov AX, 0x0003			; switch Mode to 80x25 in 16 colors
	int 0x10				; and int 0x10 will clear the screen
ret

plotPixel:
	push ES					; we may need the current memory position...
	  
	mov DX, 0xa000			; 0x0000:0xa000
	mov ES, DX
	xor SI, SI
	mov DX, 320				; mul multiplies AX with DX
	mul DX					; AX: X (0 - 320)
	add SI, AX
	add SI, BX				; BX: Y (0 - 200)
    mov [ES:SI], CH			; CH: Color (0 - 256)

    pop ES
ret

plotLineX:
	push ES
	push DX
	
	mov DX, 0xa000			; 0x0000:0xa000
	mov ES, DX
	xor SI,SI
	mov DX, 320				; mul multiplies AX with DX
	mul DX					; AX: Y (0 - 320)
	add SI, AX
	add SI, BX				; BX: X (0 - 200)
	
	pop DX
	mov DI, DX				; loop with DX rounds
lineXLoop:
    mov [ES:SI], CH			; CH: Color (0 - 256)
	inc SI
	dec DI
	jnz lineXLoop
	pop ES
ret

plotLineY:
	push ES
	push DX
	
	mov DX, 0xa000			; 0x0000:0xa000
	mov ES, DX
	xor SI, SI
	mov DX, 320				; mul multiplies AX with DX
	mul DX					; AX: Y (0 - 320)
	add SI, AX
	add SI, BX				; BX: X (0 - 200)
	
	pop DX
	mov DI, DX				; loop with DX rounds
lineYLoop:
    mov [ES:SI], CH			; CH: Color (0 - 256)
	add SI, 320
	dec DI
	jnz lineYLoop
	pop ES
ret

;------------------------------------------------------
;cx = xpos , dx = ypos, si = x-length, di = y-length, al = color
plotBoxXY:
	push ES
	push AX
	push DX
	
	mov BX, 0xa000
	mov ES, BX
	xor BX, BX
	add BX, DX
	mov AX, CX
	mov DX, 320				; mul multiplies AX with DX
	mul DX	
	add BX, AX

	pop DX
	pop AX
	
	push si               ;save x-length
	.for_x:
		push di           ;save y-length
		.for_y:
			;pusha
			mov byte [ES:BX], al
			;popa
		inc BX
		sub di, 1         ;decrease di by one and set flags
		jnz .for_y        ;repeat for y-length times
		pop di            ;restore di to y-length
		add BX, 320		  ; next line is 320 pixel forward, then some backward
		sub BX, DI
	sub si, 1             ;decrease si by one and set flags
	jnz .for_x            ;repeat for x-length times
	pop si                ;restore si to x-length  -> starting state restored
	pop ES
ret

;------------------------------------------------------
;cx = xpos , dx = ypos, si = x-length, di = y-length, ax = source
plotImageXY:
	push ES
	push AX
	push BX
		
	mov BX, 0xa000			; Target: MCGA-Ram
	mov ES, BX
	xor DI, DI
	add DI, DX
	mov AX, CX
	mov DX, 320				; mul multiplies AX with DX
	mul DX	
	add DI, AX
	
	
	
	pop BX
	pop AX
	
	; if di + xy > 200 dann di = 200
	; if si + cx > 320 dann si = 320
	
	push BX               ;save x-length
	.for_x:
		push AX           ;save y-length
		.for_y:
			mov CL, byte [CS:SI]
			cmp CL, 0
			je .notDraw
			mov byte [ES:DI], CL
			.notDraw:
		inc DI			  ; next target position
		inc SI			  ; next source position
		sub AX, 1         ; decrease di by one and set flags
		jnz .for_y        ; repeat for y-length times
		pop AX            ; restore di to y-length
		add DI, 320		  ; next line is 320 pixel forward, then some backward
		sub DI, AX
	sub BX, 1             ;decrease si by one and set flags
	jnz .for_x            ;repeat for x-length times
	pop CX                ;restore si to x-length  -> starting state restored

	pop ES
ret

; Draw a Text directly to graphics memory
;		mov si,text             ; offset address
;       mov BX, 4               ; x horizontal coordinate
;       mov word [textPosY], 50
;       mov byte [textColor], darkgrey
;       mov cl, keysDetect - mouseDetect             ; outer loop (4 characters)
;		call drawTextXY
		
drawTextXY:
        mov BX, [textPosX]		; x horizontal coordinate
find:
        lodsb
        cmp al, 0				; Is the letter a zero, meaning 0, end
        je finished
        cbw                     ; byte to word
        shl ax,3                ; ax*8
        lgs di,[fs:43h*4]       ; font table location        
        add di,ax               ; find current letter 
        mov DX, [textPosY] 		; y vertical coordinate
        mov ch,8                ; inner loop (8 bytes)
get:                                 
        mov ah,[gs:di]          ; get character byte
        call draw                       
        add dx,1                    
        inc di                  ; next byte              
        dec ch                         
        jnz get                         
        add bx,8
        loop find               ; find next character
                   
draw:
        pusha                   ; save registers
        mov al,8                ; for each bit in byte
bit:
        shl ah,1                ; shift to the left
        jnc nxt                 ; draw tile if carry flag
        mov cl,1                ; tile height (pixels)
tout:        
        mov ch,1                ; tile width
tin:
        call pixel

        inc bx                            
        dec ch
        jnz tin
        sub bx,1
        inc dx
        loop tout
        sub dx,1       
nxt:
        add bx,1                       
        dec al                    
        jnz bit
        popa                               ; restore registers                   
finished:
ret     
                
pixel:
		pusha
		push ES
		push AX
		mov AX, 0xa000
		mov ES, AX
		mov SI, BX
		mov AX, DX
		mov DX, 320
		mul DX
		add SI, AX
		mov DL, [textColor]
		mov [ES:SI], DL
		pop AX
		pop ES
		popa
ret   

printOptionFound:			; needs textPosY
	mov SI,optionFound
    mov word [textPosX], 264
    mov byte [textColor], white
    call drawTextXY
ret

printOptionNotFound:		; needs textPosY
	mov si,optionNotFound
    mov word [textPosX], 232
    mov byte [textColor], white
    call drawTextXY
ret
    