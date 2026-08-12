@echo off
REM vox CLI shim for cmd/pwsh. Stowed to ~/.local/bin by rstow.
REM Companion: `vox` (no extension) beside this one, for bash.
if "%VOX_HOME%"=="" set "VOX_HOME=D:\jade-nova\vox"
"%VOX_HOME%\.venv\Scripts\vox.exe" %*
exit /b %ERRORLEVEL%
