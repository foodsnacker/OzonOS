; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree. 

; String-functions for Ozon.OS

stringLength:				; subroutine to read length of string (max 255)
  push DI					; in SI is the position of the string
  push BX					; save used registers
  push CX

  mov BX, DI            	; 
  xor AL, AL                               
  mov CX, 0xffff     
                                                     
  repne scasb               ; REPeat while Not Equal [di] != al

  sub DI, BX                ; length = offset of (edi - ebx)
  sub DI, 1
  mov AX, DI            	; in AX is the resulting length
  
  pop CX
  pop BX
  POP DI					; get the position back, it is needed
ret    
