file.s = OpenFileRequester("Datei","","*.*",0)

If ReadFile(0,file)
CreateFile(1,file + ".asm")
  Lines.l=(Lof(0)-1)/16
  WriteStringN(1,GetFilePart(file) + ":",#PB_Ascii)
  For i.l=0 To Lines
    a$ = Chr(9) + Chr(9) + Chr(9) + Chr(9) + "db "
    If i=Lines
      Bytes.l=(Lof(0)-Lines*16)-1
    Else
      Bytes=15
    EndIf
    For j.l=1 To Bytes
      a$+"0x"+RSet(Hex(ReadByte(0)&$FF),2,"0")+","
    Next
    a$+"0x"+RSet(Hex(ReadByte(0)&$FF),2,"0")
    WriteStringN(1,a$,#PB_Ascii)
  Next
  CloseFile(0)
  CloseFile(1);
EndIf
; IDE Options = PureBasic 5.46 LTS (MacOS X - x64)
; CursorPosition = 14
; EnableUnicode
; EnableXP