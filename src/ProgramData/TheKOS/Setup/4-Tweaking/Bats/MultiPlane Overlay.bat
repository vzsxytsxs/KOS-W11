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
title MPO Enable/Disable - TEST
color a
mode con: cols=102 lines=25
:home
cls
echo.
echo ------------------------------
echo - PLEASE READ THIS CAREFULLY -
echo ------------------------------
timeout /t 2 /nobreak >nul
echo A feature that allows compositing of multiple framebuffers through hardware 
echo instead of using graphics shaders for compositing, which can generate power savings. 
echo Benefits include decreased GPU and CPU workload, plane-independent page flips, 
echo and improved game performance. However, MPO may cause flickering or choppiness 
echo problems in some cases and disabling it may break some Windows full-screen optimizations.
echo. 
echo On NVIDIA 461.09 or later drivers, where some applications may flicker when resizing the window.
echo The suggested workaround is to disable MPO and if you are in Hardware Composed: Independent Flip mode
echo and want to switch to Hardware: Legacy Flip presentation, disable MPO.
echo.
echo AT THE END OF THE SCRIPT YOUR PC WILL RESTART.
echo.
echo -----------------------------------
echo - 1. Enable Multi-Plane Overlay   -
echo - 2. Disable Multi-Plane Overlay  -
echo -----------------------------------
echo.
set /p mpo=:
if %mpo% EQU 1 goto 1
if %mpo% EQU 2 goto 2
goto home

:1
Reg.exe delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode /f
exit
:2
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /t REG_DWORD /d "5" /f
exit
