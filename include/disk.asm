; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree. 

; Disk-Functions for Ozon.OS

resetDisk:
  mov ah, 0x00  ; reset function
  mov dl, 0x00  ; drive
  int 0x13   ; disk int
  jc resetDisk
  
readDisk:
  mov bx, 0x8000  ; segment
  mov es, bx
  mov bx, 0x0000  ; offset

  mov ah, 0x02  ; read function
  mov al, 0x03  ; sectors
  mov ch, 0x00  ; cylinder
  mov cl, 0x02  ; sector
  mov dh, 0x00  ; head
  mov dl, 0x00  ; drive
int 0x13   ; disk int
  
  jc readDisk
  jmp [es:bx]   ; buffer
    