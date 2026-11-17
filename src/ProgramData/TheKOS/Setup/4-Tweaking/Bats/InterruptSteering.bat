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
title Interrupt Steering Enable/Disable
:home
cls
echo.
echo ------------------------------
echo - PLEASE READ THIS CAREFULLY -
echo ------------------------------
timeout /t 2 /nobreak >nul
echo "Interrupt Steering" is a technique that efficiently distributes IRQs among CPU cores.
echo It can enhance performance and responsiveness in multi-core systems. You need to TEST it.
echo.
echo AT THE END OF THE SCRIPT YOUR PC WILL RESTART.
echo.
echo --------------------------------
echo - 1. Disable InterruptSteering -
echo - 2. Enable InterruptSteering  -
echo --------------------------------
set /p menu2=:
if %menu2% EQU 1 goto d
if %menu2% EQU 2 goto e
goto home

:d
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "InterruptSteeringDisabled" /t REG_DWORD /d "1" /f
shutdown -r -f -t 5 -c "Please wait until your PC restarts..."
timeout /t 2 /nobreak >NUL 2>&1
exit

:e
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "InterruptSteeringDisabled" /t REG_DWORD /d "0" /f
shutdown -r -f -t 5 -c "Please wait until your PC restarts..."
timeout /t 2 /nobreak >NUL 2>&1
exit
