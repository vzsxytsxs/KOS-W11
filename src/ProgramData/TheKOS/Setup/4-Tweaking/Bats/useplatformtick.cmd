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
title useplatformtick
:home
cls
echo.
echo ------------------------------
echo - PLEASE READ THIS CAREFULLY -
echo ------------------------------
timeout /t 2 /nobreak >nul
echo IN NO CASE SHOULD YOU MODIFY THIS IF YOU DISABLE HPET IN BIOS, 
echo this results in PMT being used as timer and you will get DESYNC.
echo.
echo Enabling useplatformtick you will be using RTC instead of TSC; this results in higher accuracy/stability 
echo but will not be as fast as TSC.
echo Disabling useplatformtick will use TSC clock + TSC Tick, it's important not to have DESYNC when doing this (HPET On - BIOS).
echo.
echo.
echo --------------------------------------
echo - 1. Enable useplatformtick (RTC)    -
echo - 2. Disable useplatformtick (TSC)   -
echo --------------------------------------
set /p menu=Enter an option:
if %menu% EQU 1 goto e
if %menu% EQU 2 goto d
goto home

:e
bcdedit /set useplatformtick Yes
timeout /t 2 /nobreak >NUL 2>&1
exit

:d
bcdedit /set useplatformtick No
timeout /t 2 /nobreak >NUL 2>&1
exit
