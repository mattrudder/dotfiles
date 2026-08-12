@echo off
REM omnivoice CLI shim for cmd/pwsh. Stowed to ~/.local/bin by rstow.
REM Companion: `omnivoice` (no extension) beside this one, for bash.
pwsh -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.local\share\omnivoice\omnivoice-service.ps1" %*
exit /b %ERRORLEVEL%
