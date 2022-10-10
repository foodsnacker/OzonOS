file.s = OpenFileRequester("Datei","","*.*",0)

UsePNGImageDecoder()
UsePNGImageEncoder()
LoadImage(0,file)
;SaveImage(0,"test.png",#PB_ImagePlugin_PNG,#PB_Image_FloydSteinberg,8)
;End

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
; IDE Options = PureBasic 5.62 (MacOS X - x64)
; CursorPosition = 10
; EnableXP
; EnableUnicode