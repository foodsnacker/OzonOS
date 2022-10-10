; Bootloader for Ozon.OS
use16						; we like to use 16 Bits Real Mode
org 0x7C00					; the boot block is read into memory at $7c00
%include "include/bpb.asm"	; Include Bios Paremeter Block for compatibility

white     equ 0x0f
lightgrey equ 0x07
darkgrey  equ 0x08

bootBlock:

; create stack
    xor ax, ax                  ; DS=SS=ES=0
    mov ds, ax
    mov ss, ax                  
    mov sp, 0x7c00				; Stack at 0x0000:0x7c00
    cld                         ; Set string instructions to use forward movement
	jmp 0x0000:bootStart		; ensure cs == 0x0000

bootStart:
	mov AX, 0x0013				; switch Mode to MCGA 320x200
	int 0x10
	
; Paint a frame
	mov AX, 0					; top
	mov BX, 0
	mov CH, lightgrey
	mov DX, 320
	call plotLineX
	
	mov CH, darkgrey			; bottom
	mov AX, 22
	call plotLineX
	
	mov CH, lightgrey			; left
	mov AX, 0
	mov DX, 22
	call plotLineY
	
	mov CH, darkgrey			; right
	mov BX, 319
	call plotLineY
	
; write WelcomeMessage
	mov DX, 0x0101					; Position: 1 / 1
	mov DI, WelcomeMsg
	call writeStringWithLength

	mov DX, 0x0401
	mov DI, LoadingMsg
	call writeStringWithLength
  
; load the Kernal from Disk
    mov  al, 0x01           	; load 1 sector
    mov  bx, 0x0100      		; destination (directly after IRQ table)
    mov  cx, 0x0002         	; cylinder 0, sector 2
    mov  dl, 0x80		    	; boot drive
    xor  dh, dh             	; head 0
    call readSectors
    jnc  .success           	; if carry flag is set, either the disk system wouldn't reset, or we exceeded our maximum attempts and the disk is probably shagged
;	mov CH, lightgrey
;	mov DX, 0x0401				; 10, 2
;	mov DI, readFailureMsg
;	call writeStringWithLength
    jmp halt                	; jump to a hang routine to prevent further execution
.success:
; !! warum jetzt schwarz?

  	mov DX, 0x0202
	mov DI, readSuccessMsg
	call writeStringWithLength

	xor  AH, AH                 ; wait for key press
	int  16h
	
    jmp 0x0000:0x0100			; jump into the Kernal

halt:
    cli
    hlt
    jmp halt

; Subroutines
writeStringWithLength:		; subroutine to get length of string, then write it
	call stringLength

	mov CX, AX				; stringLength gave back the length in AX
	mov BP, DI				; memory position of string is still in DI
	mov AX, 0x1301			; function 13h, attributes in AL:
				  			; 0 string is chars only, attribute in BL, cursor not moved
							; 1 string is chard only, attribute in BL, cursor moved
							; 2 string contains chars and attributes, cursor not moved
							; 3 string contains chars and attributes, cursor moved
	mov BH, 0x00			; video page 0
	mov BL, white			; lightgrey on black background
	int 0x10				; call video interrupt
retn

stringLength:				; subroutine to read length of string (max 255)
	push DI					; in DI is the position of the string
	push BX					; save used registers
	push CX

	mov   BX, DI
	xor   AL, AL                               
	mov   CX, 0xffff     
                                                     
	repne scasb              ; REPeat while Not Equal [di] != al

	sub   DI, BX             ; length = offset of (edi - ebx)
	mov   AX, DI             ; in AX is the resulting length

	pop CX
	pop BX
	pop DI					 ; get the position back, it is needed
retn

; plotLineX
;
; Plots a line in MCGA 320x200
;
; input:    CH      = color
;           AX      = X (0 .. 320)
;           BX		= Y (0 .. 200)
;           DX		= Length in Pixels

plotLineX:
	push ES
	push DX
	
	mov DX, 0xa000			; 0x0000:0xa000
	mov ES, DX
	mov SI, 0x0000
	mov DX, 320				; mul multiplies AX with DX
	mul DX					; AX: X (0 - 320)
	add SI, AX
	add SI, BX				; BX: Y (0 - 200)
	
	pop DX
	mov DI, DX				; loop with DX rounds
lineXLoop:
    mov [ES:SI], CH			; CH: Color (0 - 256)
	inc SI
	dec DI
	jnz lineXLoop
	pop ES
retn

; plotLineY
;
; Plots a line in MCGA 320x200
;
; input:    CH      = color
;           AX      = X (0 .. 320)
;           BX		= Y (0 .. 200)
;           DX		= Height in Pixels

plotLineY:
	push ES
	push DX
	
	mov DX, 0xa000			; 0x0000:0xa000
	mov ES, DX
	mov SI, 0x0000
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
retn

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
    
; Data section
WelcomeMsg 		db 'Welcome to Ozon.OS v 0.0.1', 0	; Strings end with a 0
LoadingMsg 		db 'Loading Kernel...', 0
readFailureMsg 	db 'Boot disk read failure!', 0
readSuccessMsg 	db 'Kernal successfully loaded...', 13 , 10, ' Press any key to run Ozon.OS!', 0
						
times 510-($-$$) db 0		; the boot block has to be exactly 512 bytes. the $-$$
							; calculates the size of the code itself.

dw 0xaa55					; this is the boot sector signature. Keep in mind, that
							; Intel-CPUs are little ending first, so the $aa is first
