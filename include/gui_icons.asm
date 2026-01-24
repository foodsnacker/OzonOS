; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.
;
; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree.

; GUI Icons and Window Gadgets for OzonOS
; All icons stored in 2-bit format (4 grayscale colors) to save space
; 2-bit encoding: 00=transparent(0x00), 01=darkgrey(0x08), 10=lightgrey(0x07), 11=white(0x0F)

; MCGA Buffer Layout (starting after mouse background at 0xFA60 / 64096)
ICON_BASE           equ 64096

; Color Palette (4 bytes - stores the 4 grayscale colors)
GUI_PALETTE         equ ICON_BASE + 0      ; 64096 (4 bytes)

; Window Gadgets (12×12 pixels, 2-bit = 36 bytes each)
ICON_CLOSE_NORMAL   equ ICON_BASE + 4      ; 64100
ICON_CLOSE_PRESSED  equ ICON_BASE + 40     ; 64140
ICON_DEPTH_NORMAL   equ ICON_BASE + 76     ; 64176
ICON_DEPTH_PRESSED  equ ICON_BASE + 112    ; 64212
ICON_SIZE_NORMAL    equ ICON_BASE + 148    ; 64248
ICON_SIZE_PRESSED   equ ICON_BASE + 184    ; 64284

; Mouse Cursors - Standard (8×12 pixels, 2-bit = 24 bytes each)
ICON_MOUSE_ARROW    equ ICON_BASE + 220    ; 64316
ICON_MOUSE_BUSY     equ ICON_BASE + 244    ; 64340
ICON_MOUSE_HAND     equ ICON_BASE + 268    ; 64364
ICON_MOUSE_IBEAM    equ ICON_BASE + 292    ; 64388

; Mouse Cursors - Resize (8×12 pixels, 2-bit = 24 bytes each)
ICON_MOUSE_RESIZE_H equ ICON_BASE + 316    ; 64412 (horizontal ↔)
ICON_MOUSE_RESIZE_V equ ICON_BASE + 340    ; 64436 (vertical ↕)
ICON_MOUSE_RESIZE_D1 equ ICON_BASE + 364   ; 64460 (diagonal ↖↘)
ICON_MOUSE_RESIZE_D2 equ ICON_BASE + 388   ; 64484 (diagonal ↗↙)

; Scroll Arrows (10×10 pixels, 2-bit = 25 bytes each)
ICON_SCROLL_UP      equ ICON_BASE + 412    ; 64508
ICON_SCROLL_DOWN    equ ICON_BASE + 437    ; 64533
ICON_SCROLL_LEFT    equ ICON_BASE + 462    ; 64558
ICON_SCROLL_RIGHT   equ ICON_BASE + 487    ; 64583

; Busy Animation (8×12 pixels, 4 frames, 2-bit = 24 bytes each)
ICON_BUSY_ANIM0     equ ICON_BASE + 512    ; 64608
ICON_BUSY_ANIM1     equ ICON_BASE + 536    ; 64632
ICON_BUSY_ANIM2     equ ICON_BASE + 560    ; 64656
ICON_BUSY_ANIM3     equ ICON_BASE + 584    ; 64680

; Checkbox/Radio (8×8 pixels, 2-bit = 16 bytes each)
ICON_CHECKBOX_OFF   equ ICON_BASE + 608    ; 64704
ICON_CHECKBOX_ON    equ ICON_BASE + 624    ; 64720
ICON_RADIO_OFF      equ ICON_BASE + 640    ; 64736
ICON_RADIO_ON       equ ICON_BASE + 656    ; 64752

; System Icons (16×16 pixels, 2-bit = 64 bytes each)
ICON_SYS_WARNING    equ ICON_BASE + 672    ; 64768
ICON_SYS_INFO       equ ICON_BASE + 736    ; 64832
ICON_SYS_ERROR      equ ICON_BASE + 800    ; 64896

; Menu Icons (8×8 pixels, 2-bit = 16 bytes each)
ICON_MENU_FILE      equ ICON_BASE + 864    ; 64960
ICON_MENU_EDIT      equ ICON_BASE + 880    ; 64976
ICON_MENU_VIEW      equ ICON_BASE + 896    ; 64992
ICON_MENU_TOOLS     equ ICON_BASE + 912    ; 65008
ICON_MENU_HELP      equ ICON_BASE + 928    ; 65024

; Window Decoration Patterns (8×8 pixels, 2-bit = 16 bytes each)
PATTERN_TITLEBAR    equ ICON_BASE + 944    ; 65040
PATTERN_BORDER_V    equ ICON_BASE + 960    ; 65056 (vertical border)
PATTERN_BORDER_H    equ ICON_BASE + 976    ; 65072 (horizontal border)

; Desktop Icons (16×16 pixels, 2-bit = 64 bytes each)
ICON_DISK           equ ICON_BASE + 992    ; 65088
ICON_FOLDER         equ ICON_BASE + 1056   ; 65152
ICON_DOCUMENT       equ ICON_BASE + 1120   ; 65216
ICON_TRASH          equ ICON_BASE + 1184   ; 65280

; Total space used: 1248 bytes (ending at 65344)
; Space remaining in MCGA buffer: ~192 bytes

; Grayscale palette for 2-bit encoding (these values are stored at GUI_PALETTE offset)
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

; Color Palette (4 bytes - grayscale colors for UI)
colorPalette:
    db GREY_TRANSPARENT         ; Color 0: Transparent (0x00)
    db GREY_DARK                ; Color 1: Dark grey (0x08)
    db GREY_LIGHT               ; Color 2: Light grey (0x07)
    db GREY_WHITE               ; Color 3: White (0x0F)

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

; Mouse Resize Horizontal (8×12, ↔)
mouseResizeH:
    db 0x00, 0x00               ; Row  0: ........
    db 0x00, 0x00               ; Row  1: ........
    db 0x00, 0xF0               ; Row  2: ....██..
    db 0xF0, 0xF0               ; Row  3: ██..██..
    db 0xFF, 0xFF               ; Row  4: ████████
    db 0xFF, 0xFF               ; Row  5: ████████
    db 0xFF, 0xFF               ; Row  6: ████████
    db 0xFF, 0xFF               ; Row  7: ████████
    db 0xF0, 0xF0               ; Row  8: ██..██..
    db 0x00, 0xF0               ; Row  9: ....██..
    db 0x00, 0x00               ; Row 10: ........
    db 0x00, 0x00               ; Row 11: ........

; Mouse Resize Vertical (8×12, ↕)
mouseResizeV:
    db 0x00, 0xF0               ; Row  0: ....██..
    db 0x0F, 0xF0               ; Row  1: ..████..
    db 0xFF, 0xFF               ; Row  2: ████████
    db 0x00, 0xF0               ; Row  3: ....██..
    db 0x00, 0xF0               ; Row  4: ....██..
    db 0x00, 0xF0               ; Row  5: ....██..
    db 0x00, 0xF0               ; Row  6: ....██..
    db 0x00, 0xF0               ; Row  7: ....██..
    db 0x00, 0xF0               ; Row  8: ....██..
    db 0xFF, 0xFF               ; Row  9: ████████
    db 0x0F, 0xF0               ; Row 10: ..████..
    db 0x00, 0xF0               ; Row 11: ....██..

; Mouse Resize Diagonal 1 (8×12, ↖↘)
mouseResizeD1:
    db 0xFF, 0xF0               ; Row  0: ██████..
    db 0xFF, 0x00               ; Row  1: ████....
    db 0xFA, 0xF0               ; Row  2: ██▓▓██..
    db 0xF0, 0xFF               ; Row  3: ██..████
    db 0x00, 0xAF               ; Row  4: ....▓▓██
    db 0x00, 0x00               ; Row  5: ........
    db 0x00, 0x00               ; Row  6: ........
    db 0xFA, 0x00               ; Row  7: ██▓▓....
    db 0xFF, 0x0F               ; Row  8: ████..██
    db 0x0F, 0xAF               ; Row  9: ..██▓▓██
    db 0x00, 0xFF               ; Row 10: ....████
    db 0x0F, 0xFF               ; Row 11: ..██████

; Mouse Resize Diagonal 2 (8×12, ↗↙)
mouseResizeD2:
    db 0x0F, 0xFF               ; Row  0: ..██████
    db 0x00, 0xFF               ; Row  1: ....████
    db 0x0F, 0xAF               ; Row  2: ..██▓▓██
    db 0xFF, 0x0F               ; Row  3: ████..██
    db 0xFA, 0x00               ; Row  4: ██▓▓....
    db 0x00, 0x00               ; Row  5: ........
    db 0x00, 0x00               ; Row  6: ........
    db 0x00, 0xAF               ; Row  7: ....▓▓██
    db 0xF0, 0xFF               ; Row  8: ██..████
    db 0xFA, 0xF0               ; Row  9: ██▓▓██..
    db 0xFF, 0x00               ; Row 10: ████....
    db 0xFF, 0xF0               ; Row 11: ██████..

; System Icon - Warning (16×16, exclamation mark in triangle)
sysWarning:
    db 0x00, 0x00, 0xF0, 0x00               ; Row  0: ........██......
    db 0x00, 0x0F, 0xF0, 0x00               ; Row  1: ......████......
    db 0x00, 0x0F, 0xAF, 0x00               ; Row  2: ......██▓▓██....
    db 0x00, 0xFA, 0xAF, 0x00               ; Row  3: ....██▓▓▓▓██....
    db 0x00, 0xFA, 0xFA, 0x00               ; Row  4: ....██▓▓██▓▓....
    db 0x0F, 0xA0, 0xFA, 0x00               ; Row  5: ..██▓▓..██▓▓....
    db 0x0F, 0xA0, 0xAF, 0x00               ; Row  6: ..██▓▓..▓▓██....
    db 0xFA, 0x00, 0xAF, 0x00               ; Row  7: ██▓▓....▓▓██....
    db 0xFA, 0x00, 0xFA, 0x00               ; Row  8: ██▓▓....██▓▓....
    db 0xF0, 0x00, 0xFA, 0x00               ; Row  9: ██......██▓▓....
    db 0xF0, 0xF0, 0xAF, 0x00               ; Row 10: ██..██..▓▓██....
    db 0xFA, 0xFA, 0xAF, 0x00               ; Row 11: ██▓▓██▓▓▓▓██....
    db 0xFF, 0xFF, 0xFF, 0x00               ; Row 12: ████████████....
    db 0xFF, 0xFF, 0xFF, 0x00               ; Row 13: ████████████....
    db 0x00, 0x00, 0x00, 0x00               ; Row 14: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 15: ................

; System Icon - Info (16×16, 'i' in circle)
sysInfo:
    db 0x00, 0x0F, 0xF0, 0x00               ; Row  0: ......████......
    db 0x00, 0xFA, 0xAF, 0x00               ; Row  1: ....██▓▓▓▓██....
    db 0x0F, 0xA0, 0x0A, 0xF0               ; Row  2: ..██▓▓....▓▓██..
    db 0xF0, 0x0F, 0xF0, 0x0F               ; Row  3: ██....████....██
    db 0xF0, 0x0F, 0xF0, 0x0F               ; Row  4: ██....████....██
    db 0xF0, 0x00, 0xF0, 0x0F               ; Row  5: ██......██....██
    db 0xF0, 0x00, 0xF0, 0x0F               ; Row  6: ██......██....██
    db 0xF0, 0x00, 0xF0, 0x0F               ; Row  7: ██......██....██
    db 0xF0, 0x00, 0xF0, 0x0F               ; Row  8: ██......██....██
    db 0xF0, 0x00, 0xF0, 0x0F               ; Row  9: ██......██....██
    db 0xF0, 0x0F, 0xF0, 0x0F               ; Row 10: ██....████....██
    db 0x0F, 0xA0, 0x0A, 0xF0               ; Row 11: ..██▓▓....▓▓██..
    db 0x00, 0xFA, 0xAF, 0x00               ; Row 12: ....██▓▓▓▓██....
    db 0x00, 0x0F, 0xF0, 0x00               ; Row 13: ......████......
    db 0x00, 0x00, 0x00, 0x00               ; Row 14: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 15: ................

; System Icon - Error (16×16, X in circle)
sysError:
    db 0x00, 0x0F, 0xF0, 0x00               ; Row  0: ......████......
    db 0x00, 0xFA, 0xAF, 0x00               ; Row  1: ....██▓▓▓▓██....
    db 0x0F, 0xAF, 0xFA, 0xF0               ; Row  2: ..██▓▓████▓▓██..
    db 0xF0, 0xFA, 0xAF, 0x0F               ; Row  3: ██..██▓▓▓▓██..██
    db 0xF0, 0x0F, 0xF0, 0x0F               ; Row  4: ██....████....██
    db 0xF0, 0x00, 0x00, 0x0F               ; Row  5: ██..........██
    db 0xF0, 0x00, 0x00, 0x0F               ; Row  6: ██..........██
    db 0xF0, 0x00, 0x00, 0x0F               ; Row  7: ██..........██
    db 0xF0, 0x00, 0x00, 0x0F               ; Row  8: ██..........██
    db 0xF0, 0x0F, 0xF0, 0x0F               ; Row  9: ██....████....██
    db 0xF0, 0xFA, 0xAF, 0x0F               ; Row 10: ██..██▓▓▓▓██..██
    db 0x0F, 0xAF, 0xFA, 0xF0               ; Row 11: ..██▓▓████▓▓██..
    db 0x00, 0xFA, 0xAF, 0x00               ; Row 12: ....██▓▓▓▓██....
    db 0x00, 0x0F, 0xF0, 0x00               ; Row 13: ......████......
    db 0x00, 0x00, 0x00, 0x00               ; Row 14: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 15: ................

; Menu Icon - File (8×8, folder symbol)
menuFile:
    db 0xFF, 0xF0               ; Row 0: ██████..
    db 0xFA, 0xAF               ; Row 1: ██▓▓▓▓██
    db 0xFF, 0xFF               ; Row 2: ████████
    db 0xFA, 0xAA               ; Row 3: ██▓▓▓▓▓▓
    db 0xFA, 0xAA               ; Row 4: ██▓▓▓▓▓▓
    db 0xFA, 0xAA               ; Row 5: ██▓▓▓▓▓▓
    db 0xFA, 0xAA               ; Row 6: ██▓▓▓▓▓▓
    db 0xFF, 0xFF               ; Row 7: ████████

; Menu Icon - Edit (8×8, pencil)
menuEdit:
    db 0x00, 0x00               ; Row 0: ........
    db 0x00, 0x0F               ; Row 1: ......██
    db 0x00, 0xF0               ; Row 2: ....██..
    db 0x0F, 0xA0               ; Row 3: ..██▓▓..
    db 0xF0, 0xA0               ; Row 4: ██..▓▓..
    db 0xF0, 0x00               ; Row 5: ██......
    db 0xFF, 0x00               ; Row 6: ████....
    db 0x00, 0x00               ; Row 7: ........

; Menu Icon - View (8×8, eye)
menuView:
    db 0x0F, 0xF0               ; Row 0: ..████..
    db 0xFA, 0xAF               ; Row 1: ██▓▓▓▓██
    db 0xF0, 0x0F               ; Row 2: ██....██
    db 0xF0, 0xF0               ; Row 3: ██..██..
    db 0xF0, 0xF0               ; Row 4: ██..██..
    db 0xF0, 0x0F               ; Row 5: ██....██
    db 0xFA, 0xAF               ; Row 6: ██▓▓▓▓██
    db 0x0F, 0xF0               ; Row 7: ..████..

; Menu Icon - Tools (8×8, wrench)
menuTools:
    db 0x00, 0xFF               ; Row 0: ....████
    db 0x00, 0xAF               ; Row 1: ....▓▓██
    db 0xF0, 0xAF               ; Row 2: ██..▓▓██
    db 0xFA, 0x0F               ; Row 3: ██▓▓..██
    db 0x0F, 0xA0               ; Row 4: ..██▓▓..
    db 0x0F, 0x00               ; Row 5: ..██....
    db 0x0F, 0x00               ; Row 6: ..██....
    db 0x00, 0x00               ; Row 7: ........

; Menu Icon - Help (8×8, question mark)
menuHelp:
    db 0x0F, 0xF0               ; Row 0: ..████..
    db 0xFA, 0xAF               ; Row 1: ██▓▓▓▓██
    db 0x00, 0xAF               ; Row 2: ....▓▓██
    db 0x00, 0xF0               ; Row 3: ....██..
    db 0x00, 0xF0               ; Row 4: ....██..
    db 0x00, 0x00               ; Row 5: ........
    db 0x00, 0xF0               ; Row 6: ....██..
    db 0x00, 0x00               ; Row 7: ........

; Window Pattern - Titlebar (8×8, horizontal stripes)
patternTitlebar:
    db 0xAA, 0xAA               ; Row 0: ▓▓▓▓▓▓▓▓
    db 0xFF, 0xFF               ; Row 1: ████████
    db 0xAA, 0xAA               ; Row 2: ▓▓▓▓▓▓▓▓
    db 0xFF, 0xFF               ; Row 3: ████████
    db 0xAA, 0xAA               ; Row 4: ▓▓▓▓▓▓▓▓
    db 0xFF, 0xFF               ; Row 5: ████████
    db 0xAA, 0xAA               ; Row 6: ▓▓▓▓▓▓▓▓
    db 0xFF, 0xFF               ; Row 7: ████████

; Window Pattern - Border Vertical (8×8)
patternBorderV:
    db 0xF0, 0x00               ; Row 0: ██......
    db 0xF0, 0x00               ; Row 1: ██......
    db 0xF0, 0x00               ; Row 2: ██......
    db 0xF0, 0x00               ; Row 3: ██......
    db 0xF0, 0x00               ; Row 4: ██......
    db 0xF0, 0x00               ; Row 5: ██......
    db 0xF0, 0x00               ; Row 6: ██......
    db 0xF0, 0x00               ; Row 7: ██......

; Window Pattern - Border Horizontal (8×8)
patternBorderH:
    db 0xFF, 0xFF               ; Row 0: ████████
    db 0xFF, 0xFF               ; Row 1: ████████
    db 0x00, 0x00               ; Row 2: ........
    db 0x00, 0x00               ; Row 3: ........
    db 0x00, 0x00               ; Row 4: ........
    db 0x00, 0x00               ; Row 5: ........
    db 0x00, 0x00               ; Row 6: ........
    db 0x00, 0x00               ; Row 7: ........

; Desktop Icon - Disk (16×16, floppy disk)
iconDisk:
    db 0xFF, 0xFF, 0xFF, 0xFF               ; Row  0: ████████████████
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  1: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  2: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  3: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFF, 0xFF, 0xFF, 0xFF               ; Row  4: ████████████████
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  5: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  6: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  7: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  8: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  9: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row 10: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row 11: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFF, 0xFF, 0xFF, 0xFF               ; Row 12: ████████████████
    db 0xF0, 0x00, 0x00, 0x0F               ; Row 13: ██..........██
    db 0xFF, 0xFF, 0xFF, 0xFF               ; Row 14: ████████████████
    db 0x00, 0x00, 0x00, 0x00               ; Row 15: ................

; Desktop Icon - Folder (16×16)
iconFolder:
    db 0x00, 0x00, 0x00, 0x00               ; Row  0: ................
    db 0x00, 0xFF, 0xF0, 0x00               ; Row  1: ....██████......
    db 0x00, 0xFA, 0xAF, 0x00               ; Row  2: ....██▓▓▓▓██....
    db 0xFF, 0xFF, 0xFF, 0xFF               ; Row  3: ████████████████
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  4: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  5: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  6: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  7: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  8: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row  9: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row 10: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFA, 0xAA, 0xAA, 0xAF               ; Row 11: ██▓▓▓▓▓▓▓▓▓▓▓▓██
    db 0xFF, 0xFF, 0xFF, 0xFF               ; Row 12: ████████████████
    db 0x00, 0x00, 0x00, 0x00               ; Row 13: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 14: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 15: ................

; Desktop Icon - Document (16×16, sheet of paper)
iconDocument:
    db 0x00, 0xFF, 0xFF, 0x00               ; Row  0: ....████████....
    db 0x00, 0xFA, 0xAF, 0x00               ; Row  1: ....██▓▓▓▓██....
    db 0x00, 0xFA, 0xFF, 0xF0               ; Row  2: ....██▓▓██████..
    db 0x00, 0xFA, 0xAA, 0xAF               ; Row  3: ....██▓▓▓▓▓▓██
    db 0x00, 0xFA, 0xAA, 0xAF               ; Row  4: ....██▓▓▓▓▓▓██
    db 0x00, 0xFF, 0xFF, 0xAF               ; Row  5: ....████████▓▓██
    db 0x00, 0xFA, 0xAA, 0xAF               ; Row  6: ....██▓▓▓▓▓▓██
    db 0x00, 0xFA, 0xAA, 0xAF               ; Row  7: ....██▓▓▓▓▓▓██
    db 0x00, 0xFF, 0xFF, 0xAF               ; Row  8: ....████████▓▓██
    db 0x00, 0xFA, 0xAA, 0xAF               ; Row  9: ....██▓▓▓▓▓▓██
    db 0x00, 0xFA, 0xAA, 0xAF               ; Row 10: ....██▓▓▓▓▓▓██
    db 0x00, 0xFA, 0xAA, 0xAF               ; Row 11: ....██▓▓▓▓▓▓██
    db 0x00, 0xFF, 0xFF, 0xFF               ; Row 12: ....████████████
    db 0x00, 0x00, 0x00, 0x00               ; Row 13: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 14: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 15: ................

; Desktop Icon - Trash (16×16, waste basket)
iconTrash:
    db 0x00, 0x00, 0x00, 0x00               ; Row  0: ................
    db 0x00, 0xFF, 0xFF, 0x00               ; Row  1: ....████████....
    db 0x00, 0xFA, 0xAF, 0x00               ; Row  2: ....██▓▓▓▓██....
    db 0xFF, 0xFF, 0xFF, 0xFF               ; Row  3: ████████████████
    db 0x0F, 0xAA, 0xAA, 0xF0               ; Row  4: ..██▓▓▓▓▓▓▓▓██..
    db 0x0F, 0xAA, 0xAA, 0xF0               ; Row  5: ..██▓▓▓▓▓▓▓▓██..
    db 0x0F, 0xAA, 0xAA, 0xF0               ; Row  6: ..██▓▓▓▓▓▓▓▓██..
    db 0x0F, 0xAA, 0xAA, 0xF0               ; Row  7: ..██▓▓▓▓▓▓▓▓██..
    db 0x0F, 0xAA, 0xAA, 0xF0               ; Row  8: ..██▓▓▓▓▓▓▓▓██..
    db 0x0F, 0xAA, 0xAA, 0xF0               ; Row  9: ..██▓▓▓▓▓▓▓▓██..
    db 0x00, 0xFA, 0xAF, 0x00               ; Row 10: ....██▓▓▓▓██....
    db 0x00, 0xFA, 0xAF, 0x00               ; Row 11: ....██▓▓▓▓██....
    db 0x00, 0x0F, 0xF0, 0x00               ; Row 12: ......████......
    db 0x00, 0x00, 0x00, 0x00               ; Row 13: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 14: ................
    db 0x00, 0x00, 0x00, 0x00               ; Row 15: ................

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

    ; Draw resize cursors at (170, 10)
    mov CX, 170
    mov DX, 10
    mov SI, ICON_MOUSE_RESIZE_H
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    mov CX, 185
    mov DX, 10
    mov SI, ICON_MOUSE_RESIZE_V
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    mov CX, 200
    mov DX, 10
    mov SI, ICON_MOUSE_RESIZE_D1
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    mov CX, 215
    mov DX, 10
    mov SI, ICON_MOUSE_RESIZE_D2
    mov BX, 8
    mov AX, 12
    call draw2BitIcon

    ; Draw system icons at (10, 85)
    mov CX, 10
    mov DX, 85
    mov SI, ICON_SYS_WARNING
    mov BX, 16
    mov AX, 16
    call draw2BitIcon

    mov CX, 30
    mov DX, 85
    mov SI, ICON_SYS_INFO
    mov BX, 16
    mov AX, 16
    call draw2BitIcon

    mov CX, 50
    mov DX, 85
    mov SI, ICON_SYS_ERROR
    mov BX, 16
    mov AX, 16
    call draw2BitIcon

    ; Draw menu icons at (75, 50)
    mov CX, 75
    mov DX, 50
    mov SI, ICON_MENU_FILE
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    mov CX, 90
    mov DX, 50
    mov SI, ICON_MENU_EDIT
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    mov CX, 105
    mov DX, 50
    mov SI, ICON_MENU_VIEW
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    mov CX, 120
    mov DX, 50
    mov SI, ICON_MENU_TOOLS
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    mov CX, 135
    mov DX, 50
    mov SI, ICON_MENU_HELP
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    ; Draw window patterns at (155, 50)
    mov CX, 155
    mov DX, 50
    mov SI, PATTERN_TITLEBAR
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    mov CX, 170
    mov DX, 50
    mov SI, PATTERN_BORDER_V
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    mov CX, 185
    mov DX, 50
    mov SI, PATTERN_BORDER_H
    mov BX, 8
    mov AX, 8
    call draw2BitIcon

    ; Draw desktop icons at (75, 85)
    mov CX, 75
    mov DX, 85
    mov SI, ICON_DISK
    mov BX, 16
    mov AX, 16
    call draw2BitIcon

    mov CX, 95
    mov DX, 85
    mov SI, ICON_FOLDER
    mov BX, 16
    mov AX, 16
    call draw2BitIcon

    mov CX, 115
    mov DX, 85
    mov SI, ICON_DOCUMENT
    mov BX, 16
    mov AX, 16
    call draw2BitIcon

    mov CX, 135
    mov DX, 85
    mov SI, ICON_TRASH
    mov BX, 16
    mov AX, 16
    call draw2BitIcon

ret
