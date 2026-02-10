; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree. 

HW_EQUIP_PS2     equ 4          ; PS2 mouse installed?
MOUSE_PKT_BYTES  equ 3          ; Number of bytes in mouse packet
MOUSE_RESOLUTION equ 3          ; Mouse resolution 8 counts/mm
MCGA_BUFFER_OFFSET equ 64000   ; Unused MCGA memory starts at byte 64000 (320x200=64000)
MOUSE_WIDTH      equ 8          ; Mouse cursor width in pixels
MOUSE_HEIGHT     equ 12         ; Mouse cursor height in pixels


; Function: mouseInitialize
;           Initialize the mouse if present
;
; Inputs:   None
; Returns:  CF = 1 if error, CF=0 success
; Clobbers: AX

mouseInitialize:   
    push ES
    push BX

	mov si,mouseDetect             ; offset address
    mov word [textPosX], 8
    mov word [textPosY], 56
    mov byte [textColor], white
	call drawTextXY
	
    int 0x11                    ; Get equipment list
    test ax, HW_EQUIP_PS2       ; Is a PS2 mouse installed?
    jz .no_mouse                ;     if not print error and end

    mov ax, 0xC205              ; Initialize mouse
    mov bh, MOUSE_PKT_BYTES     ; 3 byte packets
    int 0x15                    ; Call BIOS to initialize
    jc .no_mouse                ;    If not successful assume no mouse

    mov ax, 0xC203              ; Set resolution
    mov bh, MOUSE_RESOLUTION    ; 8 counts / mm
    int 0x15                    ; Call BIOS to set resolution
    jc .no_mouse                ;    If not successful assume no mouse

    push cs
    pop es                      ; ES = segment where code and mouse handler reside

    mov bx, mouseCallbackDummy
    mov ax, 0xC207              ; Install a default null handler (ES:BX)
    int 0x15                    ; Call BIOS to set callback
    jc .no_mouse                ;    If not successful assume no mouse

	call mouseEnable
	
    mov word [textPosY], 56
	call printOptionFound		; positions: textPosX und textPosY, Length = cl

    clc                         ; CF=0 is success
    jmp .finished
.no_mouse:
    stc                         ; CF=1 is error
 
    mov word [textPosY], 56
	call printOptionNotFound

.finished:
    pop bx
    pop es
ret

; Function: mouseEnable
;           Enable the mouse
;
; Inputs:   None
; Returns:  None
; Clobbers: AX

mouseEnable:
    push es
    push bx

    call mouseDisable          ; Disable mouse before enabling

    push cs
    pop es
    mov bx, mouseCallback
    mov ax, 0xC207              ; Set mouse callback function (ES:BX)
    int 0x15                    ; Call BIOS to set callback

    mov ax, 0xC200              ; Enable/Disable mouse
    mov bh, 1                   ; BH = Enable = 1
    int 0x15                    ; Call BIOS to disable mouse

    pop bx
    pop es
ret

; Function: mouseDisable
;           Disable the mouse
;
; Inputs:   None
; Returns:  None
; Clobbers: AX

mouseDisable:
    push es
    push bx

    mov ax, 0xC200              ; Enable/Disable mouse
    xor bx, bx                  ; BH = Disable = 0
    int 0x15                    ; Call BIOS to disable mouse

    mov es, bx
    mov ax, 0xC207              ; Clear callback function (ES:BX=0:0)
    int 0x15                    ; Call BIOS to set callback

    pop bx
    pop es
ret

; Function: mouseCallback (FAR)
;           called by the interrupt handler to process a mouse data packet
;           All registers that are modified must be saved and restored
;           Since we are polling manually this handler does nothing
;
; Inputs:   SP+4  = Unused (0)
;           SP+6  = MovementY
;           SP+8  = MovementX
;           SP+10 = Mouse Status
;
; Returns:  None
; Clobbers: None

ARG_OFFSETS      equ 6          ; Offset of args from BP

mouseCallback:
    push bp                     ; Function prologue
    mov bp, sp
    push ds                     ; Save registers we modify
    push ax
    push bx
    push cx
    push dx

    push cs
    pop ds                  ; DS = CS, CS = where our variables are stored

							; save previous position
	mov AX, [mouseX]        ; Update current virtual mouseX coord
	mov [lastMouseX], AX
    mov BX, [mouseY]        ; Update current virtual mouseY coord
	mov [lastMouseY], BX

	; get new position
    mov al,[bp+ARG_OFFSETS+6]
    mov bl, al                  ; BX = copy of status byte
    mov cl, 3                   ; Shift signY (bit 5) left 3 bits
    shl al, cl                  ; CF = signY
                                ; Sign bit of AL = SignX
    sbb dh, dh                  ; CH = SignY value set in all bits
    cbw                         ; AH = SignX value set in all bits
    mov dl, [bp+ARG_OFFSETS+2]  ; CX = movementY
    mov al, [bp+ARG_OFFSETS+4]  ; AX = movementX

    ; new mouse X_coord = X_Coord + movementX
    ; new mouse Y_coord = Y_Coord + (-movementY)
    neg dx
    mov cx, [mouseY]
    add dx, cx                  ; DX = new mouse Y_coord
    mov cx, [mouseX]
    add ax, cx                  ; AX = new mouse X_coord

	; check if MouseX > 311 (320 - 8 pixels cursor width)
	cmp ax, 311
	JLE MouseXOK311
	mov ax, 311
MouseXOK311:
	; check if MouseX < 0 => 0
	cmp ax, 0
	JGE MouseXOK0
	mov ax, 0
MouseXOK0:

	; check if MouseY > 187 (199 - 12 pixels cursor height)
	cmp DX, 187
	JLE MouseYOK187
	mov DX, 187
MouseYOK187:
	; check if MouseY < 0 => 0
	cmp DX, 0
	JGE MouseYOK0
	mov DX, 0
MouseYOK0:

    ; Status
    mov [curStatus], bl         ; Update the current status with the new bits
    mov [mouseX], ax            ; Update current virtual mouseX coord
    mov [mouseY], dx            ; Update current virtual mouseY coord

	call plotMouseBack			; Restore old background
	call saveMouseBackground	; Save new background before drawing cursor
	call plotMouse				; Draw cursor at new position 

    pop dx                      ; Restore all modified registers
    pop cx
    pop bx
    pop ax
    pop ds
    pop bp                      ; Function epilogue

mouseCallbackDummy:
retf                     	   ; This routine was reached via FAR CALL. Need a FAR RET

; Function: saveMouseBackground
;           Save the screen background at current mouse position to MCGA buffer
; Inputs:   mouseX, mouseY = current mouse position
; Returns:  None
; Clobbers: None (all registers preserved)
saveMouseBackground:
	push ES
	push DS
	push SI
	push DI
	push AX
	push BX
	push CX
	push DX

	; Setup segments: DS = ES = 0xA000 (MCGA video memory)
	mov AX, 0xA000
	mov DS, AX
	mov ES, AX

	; DI = destination in buffer (MCGA_BUFFER_OFFSET)
	mov DI, MCGA_BUFFER_OFFSET

	; Calculate source position: SI = mouseY * 320 + mouseX
	mov AX, [CS:mouseY]
	mov DX, 320
	mul DX					; AX = mouseY * 320
	add AX, [CS:mouseX]
	mov SI, AX				; SI = source offset in video memory

	; Copy 8x12 pixels
	mov BX, MOUSE_HEIGHT	; Outer loop: 12 rows
.save_row:
	mov CX, MOUSE_WIDTH		; Inner loop: 8 pixels per row
	rep movsb				; Copy 8 bytes from DS:SI to ES:DI

	add SI, 320 - MOUSE_WIDTH  ; Move to next row (320 - 8)
	dec BX
	jnz .save_row

	pop DX
	pop CX
	pop BX
	pop AX
	pop DI
	pop SI
	pop DS
	pop ES
ret

; Function: plotMouseBack
;           Restore the saved background from MCGA buffer to previous mouse position
; Inputs:   lastMouseX, lastMouseY = previous mouse position
; Returns:  None
; Clobbers: None (all registers preserved)
plotMouseBack:
	push ES
	push DS
	push SI
	push DI
	push AX
	push BX
	push CX
	push DX

	; Setup segments
	mov AX, 0xA000
	mov DS, AX				; DS = source (MCGA buffer)
	mov ES, AX				; ES = destination (video memory)

	; SI = source in buffer
	mov SI, MCGA_BUFFER_OFFSET

	; Calculate destination position: DI = lastMouseY * 320 + lastMouseX
	mov AX, [CS:lastMouseY]
	mov DX, 320
	mul DX					; AX = lastMouseY * 320
	add AX, [CS:lastMouseX]
	mov DI, AX				; DI = destination offset

	; Copy 8x12 pixels back
	mov BX, MOUSE_HEIGHT	; Outer loop: 12 rows
.restore_row:
	mov CX, MOUSE_WIDTH		; Inner loop: 8 pixels per row
	rep movsb				; Copy 8 bytes from DS:SI to ES:DI

	add DI, 320 - MOUSE_WIDTH  ; Move to next row
	dec BX
	jnz .restore_row

	pop DX
	pop CX
	pop BX
	pop AX
	pop DI
	pop SI
	pop DS
	pop ES
ret

plotMouse:
    push ax
    push bx
    push dx

    cli
       
	; Paint Mouse...
	mov AX, 8			; the mouse is 8x16 pixels
	mov BX, 12
	mov CX, [mouseY]
	mov DX, [mouseX]
	mov SI, mouseArrow	; Source: Mouse-Pointer
	call plotImageXY
	
    sti
    
    pop dx
    pop bx
    pop ax
ret

align 2
mouseX:			dw 160            ; Current mouse X coordinate
mouseY:			dw 100            ; Current mouse Y coordinate
curStatus:  	db 0              ; Current mouse status
lastMouseX:		dw 160            ; Previous mouse X coordinate (initialized to same as mouseX)
lastMouseY:		dw 100            ; Previous mouse Y coordinate (initialized to same as mouseY)

mouseArrow:		db 0x0f,0x08,0x00,0x00,0x00,0x00,0x00,0x00
				db 0x0f,0x0f,0x08,0x00,0x00,0x00,0x00,0x00
				db 0x0f,0x01,0x0f,0x08,0x00,0x00,0x00,0x00
				db 0x0f,0x01,0x01,0x0f,0x08,0x00,0x00,0x00
				db 0x0f,0x01,0x01,0x01,0x0f,0x08,0x00,0x00
				db 0x0f,0x01,0x01,0x01,0x01,0x0f,0x08,0x00
				db 0x0f,0x01,0x01,0x01,0x01,0x01,0x0f,0x08
				db 0x0f,0x0f,0x0f,0x01,0x01,0x0f,0x0f,0x0f
				db 0x0f,0x00,0x0f,0x01,0x01,0x0f,0x00,0x0f
				db 0x00,0x00,0x00,0x01,0x01,0x0f,0x00,0x00
				db 0x00,0x00,0x00,0x0f,0x0f,0x0f,0x00,0x00
				db 0x00,0x00,0x00,0x0f,0x0f,0x0f,0x00,0x00
				
