@echo off
setlocal EnableExtensions
:: cmd skips the current folder when looking for programs: a powershell.exe or reg.bat dropped next to this script is not run.
set "NoDefaultCurrentDirectoryInExePath=1"
fltmc >nul 2>&1 && goto KOS_ADMIN
set "KOS_SCRIPT=%~f0"
set "KOS_SCRIPT_ARGS=%*"
powershell.exe -NoProfile -Command "try { $a=@{}; if ($env:KOS_SCRIPT_ARGS) { $a.ArgumentList=$env:KOS_SCRIPT_ARGS }; $p=Start-Process -FilePath $env:KOS_SCRIPT -Verb RunAs -Wait -PassThru @a; exit $p.ExitCode } catch { exit 1 }"
exit /b %errorlevel%
:KOS_ADMIN
color a
title Power Throttling Enable/Disable
:home
cls
echo.
echo ------------------------------
echo - PLEASE READ THIS CAREFULLY -
echo ------------------------------
timeout /t 2 /nobreak >nul
echo "PowerThrottling" allows you to enable or disable this function. If you enable it, you could achieve better
echo temperatures/energy consumption at the cost of worse performance.
echo If you disable it, you might have better performance at the cost of higher temperatures/energy consumption.
echo.
echo Some forums report that disabling this option can lead to stuttering in some games, even if the temperatures are good. 
echo You need to TEST it.
echo.
echo AT THE END OF THE SCRIPT YOUR PC WILL RESTART.
echo.
echo --------------------------------------------------
echo - 1. Disable Power Throttling (Default TheKOS)    -
echo - 2. Enable Power Throttling (Default Windows)   -
echo --------------------------------------------------
set /p menu2=:
if %menu2% EQU 1 goto d
if %menu2% EQU 2 goto e
goto home

:e
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /f /d 0
shutdown -r -f -t 5 -c "Please wait until your PC restarts..."
timeout /t 2 /nobreak >NUL 2>&1
exit

:d
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /f /d 1
shutdown -r -f -t 5 -c "Please wait until your PC restarts..."
timeout /t 2 /nobreak >NUL 2>&1
exit
