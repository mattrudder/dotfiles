' Launch a command line with no window at all.
'
' pwsh.exe is console-subsystem, so Windows shows its console before
' -WindowStyle Hidden can apply and a black window flashes at every start.
' wscript.exe is GUI-subsystem and never gets one, and its children inherit
' that absence -- which is why the server stops flashing too.
'
' Args: the program to run, then its arguments. Anything containing a space is
' re-quoted, since Run() takes a single string.

Option Explicit

Dim shell, i, arg, commandLine
Set shell = CreateObject("WScript.Shell")

If WScript.Arguments.Count = 0 Then
  WScript.Quit 1
End If

commandLine = ""
For i = 0 To WScript.Arguments.Count - 1
  arg = WScript.Arguments(i)
  If InStr(arg, " ") > 0 And Left(arg, 1) <> """" Then
    arg = """" & arg & """"
  End If
  If i > 0 Then commandLine = commandLine & " "
  commandLine = commandLine & arg
Next

' 0 = hidden, False = do not wait; the supervisor runs forever.
shell.Run commandLine, 0, False
