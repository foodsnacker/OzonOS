; Bootloader for Ozon.OS
use16						; we like to use 16 Bits Real Mode
org 0x7C00					; the boot block is read into memory at $7c00
%include "include/bpb.asm"	; Include Bios Paremeter Block for compatibility

white     equ 0x0f
lightgrey equ 0x07
darkgrey  equ 0x08
midgrey   equ 0x16

bootBlock:

; create stack
    xor ax, ax                  ; DS=SS=ES=0
    mov ds, ax
    mov ss, ax                  
    mov sp, 0x7c00				; Stack at 0x0000:0x7c00
    cld                         ; Set string instructions to use forward movement
	jmp 0x0000:bootStart		; ensure cs == 0x0000

bootStart:
	mov	[bootDevice],DL			; BIOS supplies Drive in DL

	mov AX, 0x0013				; switch Mode to MCGA 320x200
	int 0x10
		
	; Paint a frame
	xor CX, CX					; draw block
	xor DX, DX
	mov SI, 1
	mov DI, 320
	mov AL, lightgrey
	call plotBoxXY

	mov SI, 23
	mov DI, 1
;	mov AL, lightgrey
	call plotBoxXY

	mov CX, 22
	mov DX, 1
	mov SI, 1
	mov DI, 319
	mov AL, darkgrey
	call plotBoxXY

	mov CX, 1
	mov DX, 319
	mov SI, 22
	mov DI, 1
;	mov AL, darkgrey
	call plotBoxXY
				
	mov CX, 1				; center block
	mov DX, 1
	mov SI, 21
	mov DI, 318
	mov AL, midgrey
	call plotBoxXY

; write WelcomeMessage
	mov si,WelcomeMsg             ; offset address
    mov BX, 8		              ; x horizontal coordinate
    mov word [textPosY], 8
    mov byte [textColor], white
    mov cl, LoadingMsg - WelcomeMsg
	call drawTextXY
	
	mov si,LoadingMsg             ; offset address
    mov BX, 8		              ; x horizontal coordinate
    mov word [textPosY], 32		  ; color was set before...
    mov cl, readFailureMsg - LoadingMsg
	call drawTextXY

; load the Kernal from Disk
    mov AL, 0x08           	; load 4 sectors
    mov BX, 0x0500      	; destination (directly after IRQ table)
    mov CX, 0x0002         	; cylinder 0, sector 2
    xor dh, dh
    mov DL, [bootDevice]
    call readSectors
    jnc  .success           ; if carry flag is set, either the disk system wouldn't reset, or we exceeded our maximum attempts and the disk is probably shagged
	
	mov si,readFailureMsg             ; offset address
    mov BX, 248		              ; x horizontal coordinate
    mov byte [textColor], white
    mov cl, 9
	call drawTextXY
    jmp halt                ; jump to a hang routine to prevent further execution
.success:
    mov BX, 248			              ; x horizontal coordinate
	mov si, readSuccessMsg             ; offset address
    mov cl, 9
	call drawTextXY

    jmp 0x0000:0x0500			; jump into the Kernal

halt:
    cli
    hlt
    jmp halt

drawTextXY:
find:
        lodsb                            
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

; readSectors
;
; Reads sectors from disk into memory using BIOS services
;
; input:    dl      = drive
;           ch      = cylinder[7:0]
;           cl[7:6] = cylinder[9:8]
;           dh      = head
;           cl[5:0] = sector (1-63)
;           es:bx  -> destination
;           al      = number of sectors
;
; output:   cf (0 = success, 1 = failure)

readSectors:
    pusha
    mov si, 0x02    ; maximum attempts - 1
.top:
    mov ah, 0x02    ; read sectors into memory (int 0x13, ah = 0x02)
    int 0x13
    jnc .end        ; exit if read succeeded
    dec si          ; decrement remaining attempts
    jc  .end        ; exit if maximum attempts exceeded
    xor ah, ah      ; reset disk system (int 0x13, ah = 0x00)
    int 0x13
    jnc .top        ; retry if reset succeeded, otherwise exit
.end:
    popa
retn

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
			pusha
			mov byte [ES:BX], al
			popa
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

; Data section
WelcomeMsg 		db 'Welcome to Ozon.OS v 0.0.1', 0
LoadingMsg		db 'Loading Kernel...', 0; Strings end with a 0
readFailureMsg 	db 'Failure!', 0
readSuccessMsg 	db 'Success!', 0
endMessage		db 0
textPosY 		dw 0
textColor 	 	db 0
bootDevice   	db 0x00
				
times 510-($-$$) db 0		; the boot block has to be exactly 512 bytes. the $-$$
							; calculates the size of the code itself.

dw 0xaa55					; this is the boot sector signature. Keep in mind, that
							; Intel-CPUs are little ending first, so the $aa is first
