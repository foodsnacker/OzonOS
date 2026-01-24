; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.
;
; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree.

; GUI Icons and Window Gadgets for OzonOS
; All icons stored in 2-bit format (4 grayscale colors) to save space
; 2-bit encoding: 00=transparent(0x00), 01=darkgrey(0x08), 10=lightgrey(0x07), 11=white(0x0F)

; MCGA Buffer Layout (starting after mouse background at 0xFA60 / 64096)
ICON_BASE           equ 64096

; Window Gadgets (12×12 pixels, 2-bit = 36 bytes each)
ICON_CLOSE_NORMAL   equ ICON_BASE + 0      ; 64096
ICON_CLOSE_PRESSED  equ ICON_BASE + 36     ; 64132
ICON_DEPTH_NORMAL   equ ICON_BASE + 72     ; 64168
ICON_DEPTH_PRESSED  equ ICON_BASE + 108    ; 64204
ICON_SIZE_NORMAL    equ ICON_BASE + 144    ; 64240
ICON_SIZE_PRESSED   equ ICON_BASE + 180    ; 64276

; Mouse Cursors (8×12 pixels, 2-bit = 24 bytes each)
ICON_MOUSE_ARROW    equ ICON_BASE + 216    ; 64312
ICON_MOUSE_BUSY     equ ICON_BASE + 240    ; 64336
ICON_MOUSE_HAND     equ ICON_BASE + 264    ; 64360
ICON_MOUSE_IBEAM    equ ICON_BASE + 288    ; 64384

; Scroll Arrows (10×10 pixels, 2-bit = 25 bytes each)
ICON_SCROLL_UP      equ ICON_BASE + 312    ; 64408
ICON_SCROLL_DOWN    equ ICON_BASE + 337    ; 64433
ICON_SCROLL_LEFT    equ ICON_BASE + 362    ; 64458
ICON_SCROLL_RIGHT   equ ICON_BASE + 387    ; 64483

; Busy Animation (8×12 pixels, 4 frames, 2-bit = 24 bytes each)
ICON_BUSY_ANIM0     equ ICON_BASE + 412    ; 64508
ICON_BUSY_ANIM1     equ ICON_BASE + 436    ; 64532
ICON_BUSY_ANIM2     equ ICON_BASE + 460    ; 64556
ICON_BUSY_ANIM3     equ ICON_BASE + 484    ; 64580

; Checkbox/Radio (8×8 pixels, 2-bit = 16 bytes each)
ICON_CHECKBOX_OFF   equ ICON_BASE + 508    ; 64604
ICON_CHECKBOX_ON    equ ICON_BASE + 524    ; 64620
ICON_RADIO_OFF      equ ICON_BASE + 540    ; 64636
ICON_RADIO_ON       equ ICON_BASE + 556    ; 64652

; Total space used: 572 bytes (ending at 64668)
; Space remaining in MCGA buffer: ~868 bytes

; Grayscale palette for 2-bit encoding
GREY_TRANSPARENT    equ 0x00
GREY_DARK           equ 0x08
GREY_LIGHT          equ 0x07
GREY_WHITE          equ 0x0F

;==============================================================================
; Function: loadGuiIcons
;           Load all GUI icons from CS to MCGA buffer
; Inputs:   None
; Returns:  None
; Clobbers: AX, BX, CX, DX, SI, DI, ES
;==============================================================================
loadGuiIcons:
    push DS

    ; Setup segments
    push CS
    pop DS                      ; DS = CS (source: icon data in code segment)
    mov AX, 0xA000
    mov ES, AX                  ; ES = MCGA video memory

    ; Copy all icon data to MCGA buffer
    mov SI, iconDataStart       ; Source: icon data
    mov DI, ICON_BASE           ; Destination: MCGA buffer
    mov CX, iconDataEnd - iconDataStart  ; Size in bytes
    rep movsb                   ; Fast copy

    pop DS
ret

;==============================================================================
; Function: draw2BitIcon
;           Draw a 2-bit compressed icon to screen
; Inputs:   CX = X position
;           DX = Y position
;           SI = Icon offset in MCGA buffer (e.g., ICON_CLOSE_NORMAL)
;           BX = Width in pixels
;           AX = Height in pixels
; Returns:  None
; Clobbers: All registers
;==============================================================================
draw2BitIcon:
    push BP
    mov BP, SP
    sub SP, 12
    ; [BP-2] = width, [BP-4] = height, [BP-6] = xpos, [BP-8] = ypos
    ; [BP-10] = src offset, [BP-12] = pixels_in_row

    mov [BP-2], BX              ; Save width
    mov [BP-4], AX              ; Save height
    mov [BP-6], CX              ; Save X pos
    mov [BP-8], DX              ; Save Y pos
    mov [BP-10], SI             ; Save source offset

    push DS
    push ES

    ; Setup segments
    mov AX, 0xA000
    mov DS, AX                  ; DS = MCGA (source for 2-bit data)
    mov ES, AX                  ; ES = MCGA (destination for screen)

    ; Calculate screen destination: DI = Y * 320 + X
    mov AX, [BP-8]              ; Y position
    mov DX, 320
    mul DX
    add AX, [BP-6]              ; Add X position
    mov DI, AX                  ; DI = screen offset

    mov SI, [BP-10]             ; SI = source offset in MCGA buffer

    ; Outer loop: rows
    mov DX, [BP-4]              ; DX = height (row counter)
.row_loop:
    push DI                     ; Save screen position
    mov word [BP-12], 0         ; Reset pixel counter in row

.pixel_loop:
    ; Check if we need to load a new byte (every 4 pixels)
    mov AX, [BP-12]
    test AX, 3                  ; Check if pixel_count % 4 == 0
    jnz .use_current_byte

    ; Load new byte containing 4 pixels
    lodsb                       ; AL = [DS:SI], SI++
    mov AH, AL                  ; Keep copy in AH

.use_current_byte:
    ; Extract 2 bits for current pixel
    ; Pixel position in byte: (pixel_count % 4)
    mov CX, [BP-12]
    and CX, 3                   ; CX = pixel_count % 4
    shl CX, 1                   ; Multiply by 2 (2 bits per pixel)

    ; Shift AH right by CX bits and mask
    mov AL, AH
    shr AL, CL
    and AL, 0x03                ; Mask to 2 bits

    ; Convert 2-bit value to 8-bit color
    ; 00 = transparent, 01 = dark grey, 10 = light grey, 11 = white
    cmp AL, 0
    je .skip_pixel              ; Transparent - don't draw
    cmp AL, 1
    je .color_dark
    cmp AL, 2
    je .color_light
    ; else (AL == 3) white
    mov AL, GREY_WHITE
    jmp .draw_pixel

.color_dark:
    mov AL, GREY_DARK
    jmp .draw_pixel

.color_light:
    mov AL, GREY_LIGHT

.draw_pixel:
    mov [ES:DI], AL             ; Write pixel to screen

.skip_pixel:
    inc DI                      ; Next screen position
    inc word [BP-12]            ; Increment pixel counter

    ; Check if row is complete
    mov AX, [BP-12]
    cmp AX, [BP-2]              ; Compare with width
    jl .pixel_loop              ; Continue if more pixels in row

    ; Row complete, move to next row
    pop DI                      ; Restore screen position
    add DI, 320                 ; Move to next row
    dec DX                      ; Decrement row counter
    jnz .row_loop               ; Next row if not done

    pop ES
    pop DS
    mov SP, BP
    pop BP
ret

;==============================================================================
; Icon Data in 2-bit format (4 pixels per byte)
; Bit encoding: [pixel3|pixel2|pixel1|pixel0] where each pixel is 2 bits
;==============================================================================
iconDataStart:

; Close Gadget Normal (12×12, filled square)
closeNormal:
    db 0xFF, 0xFF, 0xFF         ; Row  0: ████████████ (white border)
    db 0xAA, 0xAA, 0xAA         ; Row  1: ▓▓▓▓▓▓▓▓▓▓▓▓ (light fill)
    db 0xAA, 0xAA, 0xAA         ; Row  2: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xAA, 0xAA, 0xAA         ; Row  3: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xAA, 0xAA, 0xAA         ; Row  4: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xAA, 0xAA, 0xAA         ; Row  5: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xAA, 0xAA, 0xAA         ; Row  6: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xAA, 0xAA, 0xAA         ; Row  7: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xAA, 0xAA, 0xAA         ; Row  8: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xAA, 0xAA, 0xAA         ; Row  9: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xAA, 0xAA, 0xAA         ; Row 10: ▓▓▓▓▓▓▓▓▓▓▓▓
    db 0xFF, 0xFF, 0xFF         ; Row 11: ████████████ (white border)

; Close Gadget Pressed (12×12, inverted)
closePressed:
    db 0xFF, 0xFF, 0xFF         ; Row  0: ████████████
    db 0x55, 0x55, 0x55         ; Row  1: ░░░░░░░░░░░░ (dark fill)
    db 0x55, 0x55, 0x55         ; Row  2: ░░░░░░░░░░░░
    db 0x55, 0x55, 0x55         ; Row  3: ░░░░░░░░░░░░
    db 0x55, 0x55, 0x55         ; Row  4: ░░░░░░░░░░░░
    db 0x55, 0x55, 0x55         ; Row  5: ░░░░░░░░░░░░
    db 0x55, 0x55, 0x55         ; Row  6: ░░░░░░░░░░░░
    db 0x55, 0x55, 0x55         ; Row  7: ░░░░░░░░░░░░
    db 0x55, 0x55, 0x55         ; Row  8: ░░░░░░░░░░░░
    db 0x55, 0x55, 0x55         ; Row  9: ░░░░░░░░░░░░
    db 0x55, 0x55, 0x55         ; Row 10: ░░░░░░░░░░░░
    db 0xFF, 0xFF, 0xFF         ; Row 11: ████████████

; Depth Gadget Normal (12×12, two overlapping squares)
depthNormal:
    db 0xFF, 0xFF, 0xFF         ; Row  0: ████████████
    db 0xFA, 0xAA, 0xBF         ; Row  1: ██▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xBF         ; Row  2: ██▓▓▓▓▓▓▓▓██
    db 0xFA, 0xFF, 0xFF         ; Row  3: ██▓▓████████
    db 0xFA, 0xAA, 0xAF         ; Row  4: ██▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAF         ; Row  5: ██▓▓▓▓▓▓▓▓██
    db 0xFF, 0xAA, 0xAF         ; Row  6: ████▓▓▓▓▓▓██
    db 0xAA, 0xAA, 0xAF         ; Row  7: ▓▓▓▓▓▓▓▓▓▓██
    db 0xAA, 0xAA, 0xAF         ; Row  8: ▓▓▓▓▓▓▓▓▓▓██
    db 0xAA, 0xAA, 0xAF         ; Row  9: ▓▓▓▓▓▓▓▓▓▓██
    db 0xAA, 0xAA, 0xAF         ; Row 10: ▓▓▓▓▓▓▓▓▓▓██
    db 0xFF, 0xFF, 0xFF         ; Row 11: ████████████

; Depth Gadget Pressed (12×12, inverted)
depthPressed:
    db 0xFF, 0xFF, 0xFF         ; Row  0: ████████████
    db 0xF5, 0x55, 0x5F         ; Row  1: ██░░░░░░░░██
    db 0xF5, 0x55, 0x5F         ; Row  2: ██░░░░░░░░██
    db 0xF5, 0xFF, 0xFF         ; Row  3: ██░░████████
    db 0xF5, 0x55, 0x5F         ; Row  4: ██░░░░░░░░██
    db 0xF5, 0x55, 0x5F         ; Row  5: ██░░░░░░░░██
    db 0xFF, 0x55, 0x5F         ; Row  6: ████░░░░░░██
    db 0x55, 0x55, 0x5F         ; Row  7: ░░░░░░░░░░██
    db 0x55, 0x55, 0x5F         ; Row  8: ░░░░░░░░░░██
    db 0x55, 0x55, 0x5F         ; Row  9: ░░░░░░░░░░██
    db 0x55, 0x55, 0x5F         ; Row 10: ░░░░░░░░░░██
    db 0xFF, 0xFF, 0xFF         ; Row 11: ████████████

; Size Gadget Normal (12×12, resize corner)
sizeNormal:
    db 0x00, 0x00, 0x00         ; Row  0: ............
    db 0x00, 0x00, 0x00         ; Row  1: ............
    db 0x00, 0x00, 0x00         ; Row  2: ............
    db 0x00, 0x00, 0x00         ; Row  3: ............
    db 0x00, 0x00, 0x00         ; Row  4: ............
    db 0x00, 0x00, 0x00         ; Row  5: ............
    db 0x00, 0x00, 0xF0         ; Row  6: ..........██
    db 0x00, 0x00, 0xFF         ; Row  7: ........████
    db 0x00, 0x00, 0xFF         ; Row  8: ........████
    db 0x00, 0xF0, 0xFF         ; Row  9: ......██████
    db 0x00, 0xFF, 0xFF         ; Row 10: ....████████
    db 0xF0, 0xFF, 0xFF         ; Row 11: ..██████████

; Size Gadget Pressed (12×12, darker)
sizePressed:
    db 0x00, 0x00, 0x00         ; Row  0: ............
    db 0x00, 0x00, 0x00         ; Row  1: ............
    db 0x00, 0x00, 0x00         ; Row  2: ............
    db 0x00, 0x00, 0x00         ; Row  3: ............
    db 0x00, 0x00, 0x00         ; Row  4: ............
    db 0x00, 0x00, 0x00         ; Row  5: ............
    db 0x00, 0x00, 0xA0         ; Row  6: ..........▓▓
    db 0x00, 0x00, 0xAA         ; Row  7: ........▓▓▓▓
    db 0x00, 0x00, 0xAA         ; Row  8: ........▓▓▓▓
    db 0x00, 0xA0, 0xAA         ; Row  9: ......▓▓▓▓▓▓
    db 0x00, 0xAA, 0xAA         ; Row 10: ....▓▓▓▓▓▓▓▓
    db 0xA0, 0xAA, 0xAA         ; Row 11: ..▓▓▓▓▓▓▓▓▓▓

; Mouse Arrow (8×12, standard pointer) - 2-bit version
mouseArrow:
    db 0xF0, 0x00               ; Row  0: ██......
    db 0xFA, 0x00               ; Row  1: ██▓▓....
    db 0xFA, 0xA0               ; Row  2: ██▓▓▓▓..
    db 0xFA, 0xAA               ; Row  3: ██▓▓▓▓▓▓
    db 0xFA, 0xAA               ; Row  4: ██▓▓▓▓▓▓
    db 0xFA, 0xAA               ; Row  5: ██▓▓▓▓▓▓
    db 0xFA, 0xAA               ; Row  6: ██▓▓▓▓▓▓
    db 0xFF, 0xAA               ; Row  7: ████▓▓▓▓
    db 0xF0, 0xFA               ; Row  8: ██..██▓▓
    db 0x00, 0x5A               ; Row  9: ....░░▓▓
    db 0x00, 0x0F               ; Row 10: ......██
    db 0x00, 0x0F               ; Row 11: ......██

; Mouse Busy/Hourglass (8×12)
mouseBusy:
    db 0xFF, 0xFF               ; Row  0: ████████
    db 0xFF, 0xFF               ; Row  1: ████████
    db 0x0F, 0xF0               ; Row  2: ..████..
    db 0x00, 0xF0               ; Row  3: ....██..
    db 0x00, 0xA0               ; Row  4: ....▓▓..
    db 0x00, 0xA0               ; Row  5: ....▓▓..
    db 0x00, 0xA0               ; Row  6: ....▓▓..
    db 0x00, 0xF0               ; Row  7: ....██..
    db 0x0F, 0xF0               ; Row  8: ..████..
    db 0xAF, 0xFA               ; Row  9: ▓▓████▓▓
    db 0xFF, 0xFF               ; Row 10: ████████
    db 0xFF, 0xFF               ; Row 11: ████████

; Mouse Hand (8×12, pointing finger)
mouseHand:
    db 0x00, 0x00               ; Row  0: ........
    db 0x00, 0xF0               ; Row  1: ....██..
    db 0x00, 0xFA               ; Row  2: ....██▓▓
    db 0x00, 0xFA               ; Row  3: ....██▓▓
    db 0x00, 0xFA               ; Row  4: ....██▓▓
    db 0xF0, 0xFA               ; Row  5: ██..██▓▓
    db 0xFA, 0xFA               ; Row  6: ██▓▓██▓▓
    db 0xFA, 0xFA               ; Row  7: ██▓▓██▓▓
    db 0xFA, 0xFA               ; Row  8: ██▓▓██▓▓
    db 0x0F, 0xFA               ; Row  9: ..████▓▓
    db 0x00, 0xFF               ; Row 10: ....████
    db 0x00, 0x00               ; Row 11: ........

; Mouse I-Beam (8×12, text cursor)
mouseIBeam:
    db 0x0F, 0xF0               ; Row  0: ..████..
    db 0x00, 0xF0               ; Row  1: ....██..
    db 0x00, 0xF0               ; Row  2: ....██..
    db 0x00, 0xF0               ; Row  3: ....██..
    db 0x00, 0xF0               ; Row  4: ....██..
    db 0x00, 0xF0               ; Row  5: ....██..
    db 0x00, 0xF0               ; Row  6: ....██..
    db 0x00, 0xF0               ; Row  7: ....██..
    db 0x00, 0xF0               ; Row  8: ....██..
    db 0x00, 0xF0               ; Row  9: ....██..
    db 0x00, 0xF0               ; Row 10: ....██..
    db 0x0F, 0xF0               ; Row 11: ..████..

; Scroll Up Arrow (10×10)
scrollUp:
    db 0x00, 0xF0, 0x00         ; Row 0: ....██....
    db 0x00, 0xFF, 0x00         ; Row 1: ....████..
    db 0x0F, 0xFF, 0x00         ; Row 2: ..██████..
    db 0x0F, 0xAF, 0x00         ; Row 3: ..██▓▓██..
    db 0xFA, 0xAF, 0xA0         ; Row 4: ██▓▓▓▓██▓▓
    db 0x00, 0xAA, 0x00         ; Row 5: ....▓▓▓▓..
    db 0x00, 0xAA, 0x00         ; Row 6: ....▓▓▓▓..
    db 0x00, 0xAA, 0x00         ; Row 7: ....▓▓▓▓..
    db 0x00, 0xAA, 0x00         ; Row 8: ....▓▓▓▓..
    db 0x00, 0x00, 0x00         ; Row 9: ..........

; Scroll Down Arrow (10×10)
scrollDown:
    db 0x00, 0x00, 0x00         ; Row 0: ..........
    db 0x00, 0xAA, 0x00         ; Row 1: ....▓▓▓▓..
    db 0x00, 0xAA, 0x00         ; Row 2: ....▓▓▓▓..
    db 0x00, 0xAA, 0x00         ; Row 3: ....▓▓▓▓..
    db 0x00, 0xAA, 0x00         ; Row 4: ....▓▓▓▓..
    db 0xFA, 0xAF, 0xA0         ; Row 5: ██▓▓▓▓██▓▓
    db 0x0F, 0xAF, 0x00         ; Row 6: ..██▓▓██..
    db 0x0F, 0xFF, 0x00         ; Row 7: ..██████..
    db 0x00, 0xFF, 0x00         ; Row 8: ....████..
    db 0x00, 0xF0, 0x00         ; Row 9: ....██....

; Scroll Left Arrow (10×10)
scrollLeft:
    db 0x00, 0x00, 0x00         ; Row 0: ..........
    db 0x00, 0xF0, 0x00         ; Row 1: ....██....
    db 0x00, 0xFF, 0x00         ; Row 2: ....████..
    db 0x0F, 0xFA, 0x00         ; Row 3: ..████▓▓..
    db 0xFA, 0xAA, 0x00         ; Row 4: ██▓▓▓▓▓▓..
    db 0xFA, 0xAA, 0x00         ; Row 5: ██▓▓▓▓▓▓..
    db 0x0F, 0xFA, 0x00         ; Row 6: ..████▓▓..
    db 0x00, 0xFF, 0x00         ; Row 7: ....████..
    db 0x00, 0xF0, 0x00         ; Row 8: ....██....
    db 0x00, 0x00, 0x00         ; Row 9: ..........

; Scroll Right Arrow (10×10)
scrollRight:
    db 0x00, 0x00, 0x00         ; Row 0: ..........
    db 0x00, 0xF0, 0x00         ; Row 1: ....██....
    db 0x00, 0xFF, 0x00         ; Row 2: ....████..
    db 0x00, 0xAF, 0xF0         ; Row 3: ....▓▓████
    db 0x00, 0xAA, 0xFA         ; Row 4: ....▓▓▓▓██
    db 0x00, 0xAA, 0xFA         ; Row 5: ....▓▓▓▓██
    db 0x00, 0xAF, 0xF0         ; Row 6: ....▓▓████
    db 0x00, 0xFF, 0x00         ; Row 7: ....████..
    db 0x00, 0xF0, 0x00         ; Row 8: ....██....
    db 0x00, 0x00, 0x00         ; Row 9: ..........

; Busy Animation Frame 0 (8×12, spinning)
busyAnim0:
    db 0x00, 0xFF, 0x00         ; Row  0: ....████
    db 0x0F, 0xAA, 0x00         ; Row  1: ..██▓▓▓▓
    db 0xF0, 0xAA, 0x00         ; Row  2: ██..▓▓▓▓
    db 0xF0, 0xAA, 0x00         ; Row  3: ██..▓▓▓▓
    db 0xF0, 0xAA, 0x00         ; Row  4: ██..▓▓▓▓
    db 0xF0, 0xAA, 0x00         ; Row  5: ██..▓▓▓▓
    db 0xF0, 0xAA, 0x00         ; Row  6: ██..▓▓▓▓
    db 0xF0, 0xAA, 0x00         ; Row  7: ██..▓▓▓▓
    db 0xF0, 0xAA, 0x00         ; Row  8: ██..▓▓▓▓
    db 0xF0, 0xAA, 0x00         ; Row  9: ██..▓▓▓▓
    db 0x0F, 0xAA, 0x00         ; Row 10: ..██▓▓▓▓
    db 0x00, 0xFF, 0x00         ; Row 11: ....████

; Busy Animation Frame 1 (8×12)
busyAnim1:
    db 0xFF, 0xF0, 0x00         ; Row  0: ██████..
    db 0xAA, 0xF0, 0x00         ; Row  1: ▓▓▓▓██..
    db 0xAA, 0xF0, 0x00         ; Row  2: ▓▓▓▓██..
    db 0xAA, 0xF0, 0x00         ; Row  3: ▓▓▓▓██..
    db 0xAA, 0xF0, 0x00         ; Row  4: ▓▓▓▓██..
    db 0xAA, 0xF0, 0x00         ; Row  5: ▓▓▓▓██..
    db 0xAA, 0xF0, 0x00         ; Row  6: ▓▓▓▓██..
    db 0xAA, 0xF0, 0x00         ; Row  7: ▓▓▓▓██..
    db 0xAA, 0xF0, 0x00         ; Row  8: ▓▓▓▓██..
    db 0xAA, 0xF0, 0x00         ; Row  9: ▓▓▓▓██..
    db 0xAA, 0x0F, 0x00         ; Row 10: ▓▓▓▓..██
    db 0xFF, 0x00, 0x00         ; Row 11: ████....

; Busy Animation Frame 2 (8×12)
busyAnim2:
    db 0x00, 0xFF, 0x00         ; Row  0: ....████
    db 0x00, 0xAA, 0xF0         ; Row  1: ....▓▓▓▓██
    db 0x00, 0xAA, 0x0F         ; Row  2: ....▓▓▓▓..██
    db 0x00, 0xAA, 0x0F         ; Row  3: ....▓▓▓▓..██
    db 0x00, 0xAA, 0x0F         ; Row  4: ....▓▓▓▓..██
    db 0x00, 0xAA, 0x0F         ; Row  5: ....▓▓▓▓..██
    db 0x00, 0xAA, 0x0F         ; Row  6: ....▓▓▓▓..██
    db 0x00, 0xAA, 0x0F         ; Row  7: ....▓▓▓▓..██
    db 0x00, 0xAA, 0x0F         ; Row  8: ....▓▓▓▓..██
    db 0x00, 0xAA, 0x0F         ; Row  9: ....▓▓▓▓..██
    db 0x00, 0xAA, 0xF0         ; Row 10: ....▓▓▓▓██
    db 0x00, 0xFF, 0x00         ; Row 11: ....████

; Busy Animation Frame 3 (8×12)
busyAnim3:
    db 0x00, 0x0F, 0xFF         ; Row  0: ......████
    db 0x00, 0x0F, 0xAA         ; Row  1: ......██▓▓▓▓
    db 0xF0, 0x0F, 0xAA         ; Row  2: ██....██▓▓▓▓
    db 0xF0, 0x0F, 0xAA         ; Row  3: ██....██▓▓▓▓
    db 0xF0, 0x0F, 0xAA         ; Row  4: ██....██▓▓▓▓
    db 0xF0, 0x0F, 0xAA         ; Row  5: ██....██▓▓▓▓
    db 0xF0, 0x0F, 0xAA         ; Row  6: ██....██▓▓▓▓
    db 0xF0, 0x0F, 0xAA         ; Row  7: ██....██▓▓▓▓
    db 0xF0, 0x0F, 0xAA         ; Row  8: ██....██▓▓▓▓
    db 0xF0, 0x0F, 0xAA         ; Row  9: ██....██▓▓▓▓
    db 0x00, 0x0F, 0xAA         ; Row 10: ......██▓▓▓▓
    db 0x00, 0x0F, 0xFF         ; Row 11: ......████

; Checkbox Unchecked (8×8)
checkboxOff:
    db 0xFF, 0xFF               ; Row 0: ████████
    db 0xF0, 0x0F               ; Row 1: ██....██
    db 0xF0, 0x0F               ; Row 2: ██....██
    db 0xF0, 0x0F               ; Row 3: ██....██
    db 0xF0, 0x0F               ; Row 4: ██....██
    db 0xF0, 0x0F               ; Row 5: ██....██
    db 0xF0, 0x0F               ; Row 6: ██....██
    db 0xFF, 0xFF               ; Row 7: ████████

; Checkbox Checked (8×8)
checkboxOn:
    db 0xFF, 0xFF               ; Row 0: ████████
    db 0xF0, 0xFF               ; Row 1: ██..████
    db 0xF0, 0xAF               ; Row 2: ██..▓▓██
    db 0xFA, 0xAF               ; Row 3: ██▓▓▓▓██
    db 0xFA, 0x0F               ; Row 4: ██▓▓..██
    db 0xFF, 0x0F               ; Row 5: ████..██
    db 0xF0, 0x0F               ; Row 6: ██....██
    db 0xFF, 0xFF               ; Row 7: ████████

; Radio Button Off (8×8, circle)
radioOff:
    db 0x00, 0xFF, 0x00         ; Row 0: ....████
    db 0x0F, 0x00, 0xF0         ; Row 1: ..██..██
    db 0xF0, 0x00, 0x0F         ; Row 2: ██....██
    db 0xF0, 0x00, 0x0F         ; Row 3: ██....██
    db 0xF0, 0x00, 0x0F         ; Row 4: ██....██
    db 0xF0, 0x00, 0x0F         ; Row 5: ██....██
    db 0x0F, 0x00, 0xF0         ; Row 6: ..██..██
    db 0x00, 0xFF, 0x00         ; Row 7: ....████

; Radio Button On (8×8, circle with dot)
radioOn:
    db 0x00, 0xFF, 0x00         ; Row 0: ....████
    db 0x0F, 0x00, 0xF0         ; Row 1: ..██..██
    db 0xF0, 0xFF, 0x0F         ; Row 2: ██..████..██
    db 0xF0, 0xFF, 0x0F         ; Row 3: ██..████..██
    db 0xF0, 0xFF, 0x0F         ; Row 4: ██..████..██
    db 0xF0, 0xFF, 0x0F         ; Row 5: ██..████..██
    db 0x0F, 0x00, 0xF0         ; Row 6: ..██..██
    db 0x00, 0xFF, 0x00         ; Row 7: ....████

iconDataEnd:

;==============================================================================
; Function: testDrawIcons
;           Test function to draw some icons on screen
; Inputs:   None
; Returns:  None
; Clobbers: All registers
;==============================================================================
testDrawIcons:
    ; Draw Close button normal at (10, 10)
    mov CX, 10
    mov DX, 10
    mov SI, ICON_CLOSE_NORMAL
    mov BX, 12                  ; Width
    mov AX, 12                  ; Height
    call draw2BitIcon

    ; Draw Close button pressed at (30, 10)
    mov CX, 30
    mov DX, 10
    mov SI, ICON_CLOSE_PRESSED
    mov BX, 12
    mov AX, 12
    call draw2BitIcon

    ; Draw Depth button normal at (50, 10)
    mov CX, 50
    mov DX, 10
    mov SI, ICON_DEPTH_NORMAL
    mov BX, 12
    mov AX, 12
    call draw2BitIcon

    ; Draw Size button normal at (70, 10)
    mov CX, 70
    mov DX, 10
    mov SI, ICON_SIZE_NORMAL
    mov BX, 12
    mov AX, 12
    call draw2BitIcon

    ; Draw mouse arrow at (100, 10)
    mov CX, 100
    mov DX, 10
    mov SI, ICON_MOUSE_ARROW
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    ; Draw mouse busy at (115, 10)
    mov CX, 115
    mov DX, 10
    mov SI, ICON_MOUSE_BUSY
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    ; Draw mouse hand at (130, 10)
    mov CX, 130
    mov DX, 10
    mov SI, ICON_MOUSE_HAND
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    ; Draw mouse I-beam at (145, 10)
    mov CX, 145
    mov DX, 10
    mov SI, ICON_MOUSE_IBEAM
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    ; Draw scroll arrows at (10, 30)
    mov CX, 10
    mov DX, 30
    mov SI, ICON_SCROLL_UP
    mov BX, 10
    mov AX, 10
    call draw2BitIcon

    mov CX, 25
    mov DX, 30
    mov SI, ICON_SCROLL_DOWN
    mov BX, 10
    mov AX, 10
    call draw2BitIcon

    mov CX, 40
    mov DX, 30
    mov SI, ICON_SCROLL_LEFT
    mov BX, 10
    mov AX, 10
    call draw2BitIcon

    mov CX, 55
    mov DX, 30
    mov SI, ICON_SCROLL_RIGHT
    mov BX, 10
    mov AX, 10
    call draw2BitIcon

    ; Draw checkboxes at (10, 50)
    mov CX, 10
    mov DX, 50
    mov SI, ICON_CHECKBOX_OFF
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    mov CX, 25
    mov DX, 50
    mov SI, ICON_CHECKBOX_ON
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    ; Draw radio buttons at (40, 50)
    mov CX, 40
    mov DX, 50
    mov SI, ICON_RADIO_OFF
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    mov CX, 55
    mov DX, 50
    mov SI, ICON_RADIO_ON
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    ; Draw busy animation frames at (10, 65)
    mov CX, 10
    mov DX, 65
    mov SI, ICON_BUSY_ANIM0
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    mov CX, 25
    mov DX, 65
    mov SI, ICON_BUSY_ANIM1
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    mov CX, 40
    mov DX, 65
    mov SI, ICON_BUSY_ANIM2
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    mov CX, 55
    mov DX, 65
    mov SI, ICON_BUSY_ANIM3
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

ret
