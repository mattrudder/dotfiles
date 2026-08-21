' Launch a command line with no window at all.
'
' pwsh.exe is console-subsystem, so Windows shows its console before
' -WindowStyle Hidden can apply and a black window flashes at every start.
' wscript.exe is GUI-subsystem and never gets one, and its children inherit
' that absence -- which is why the server stops flashing too.
'
' Args: the program to run, then its arguments. Anything containing a space is
' re-quoted, since Run() takes a single string.
'
' Every launch appends to %LOCALAPPDATA%\omnivoice\launcher.log. Nothing
' downstream has a console, so without this line a shortcut that fired and died
' is indistinguishable from one that never fired -- which is exactly the
' question a missing tray icon asks, and it cost a session of forensics to not
' be able to answer it. Read alongside tray.log:
'
'   line here + line there  -> it started; tray.log says how it ended
'   line here, none there   -> pwsh never got going (path, policy, AV)
'   neither line            -> Explorer or Task Scheduler never ran us

Option Explicit

Dim shell, fso, i, arg, commandLine
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

LogLine "launching: " & commandLine

' 0 = hidden, False = do not wait; the supervisor runs forever.
shell.Run commandLine, 0, False

Sub LogLine(text)
  ' Logging must never be the reason a launch fails, so every error here is
  ' swallowed. Error handling in VBScript is per-procedure, so this does not
  ' leak into the Run() above.
  On Error Resume Next
  Dim dir, f
  Set fso = CreateObject("Scripting.FileSystemObject")
  dir = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\omnivoice"
  If Not fso.FolderExists(dir) Then fso.CreateFolder dir
  ' 8 = append, True = create if missing.
  Set f = fso.OpenTextFile(dir & "\launcher.log", 8, True)
  f.WriteLine Stamp() & " " & text
  f.Close
End Sub

' Match the ISO-ish stamps the PowerShell logs use (Get-Date -Format s), so the
' three files can be read together. VBScript's Now is locale-formatted.
Function Stamp()
  Dim n
  n = Now
  Stamp = Year(n) & "-" & Pad(Month(n)) & "-" & Pad(Day(n)) & "T" & _
          Pad(Hour(n)) & ":" & Pad(Minute(n)) & ":" & Pad(Second(n))
End Function

Function Pad(v)
  Pad = Right("0" & v, 2)
End Function
