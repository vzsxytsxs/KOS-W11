@echo off
:: KOS ISO build menu (build.ps1). Asks for administrator (DISM requires it); the arguments go to build.ps1.
fltmc >nul 2>&1 && goto admin
set "KOS_SCRIPT=%~f0"
set "KOS_ARGS=%*"
powershell.exe -NoProfile -Command "$a = @{ Verb = 'RunAs'; FilePath = $env:KOS_SCRIPT }; if ($env:KOS_ARGS) { $a.ArgumentList = $env:KOS_ARGS }; Start-Process @a"
exit /b

:admin
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
