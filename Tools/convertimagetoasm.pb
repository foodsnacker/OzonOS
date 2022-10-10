; Copyright (c) 2022, Jörg Burbach, Ducks on the Water
; All rights reserved.

; This source code is licensed under the BSD-style license found in the LICENSE file in the root directory of this source tree. 

; convert a PNG to an .asm-usable file

file.s = OpenFileRequester("File","","*.*",0)

UsePNGImageDecoder()
LoadImage(0,file)

StartDrawing(ImageOutput(0))

CreateFile(1,file + ".asm")
  WriteStringN(1,GetFilePart(file) + ":",#PB_Ascii)
  For i.l=0 To ImageHeight(0) - 1
    a$ = Chr(9) + Chr(9) + Chr(9) + Chr(9) + "db "
    For j.l=0 To ImageWidth(0) - 1
      a$+"0x"+RSet(Hex(Point(j,i)&$FF),2,"0")+","
    Next
    a$ = Trim(a$, ",")
    Debug a$
    WriteStringN(1,a$,#PB_Ascii)
  Next
  CloseFile(1)
 StopDrawing()
; IDE Options = PureBasic 6.00 LTS (MacOS X - x64)
; CursorPosition = 5
; EnableXP
; EnableUnicode