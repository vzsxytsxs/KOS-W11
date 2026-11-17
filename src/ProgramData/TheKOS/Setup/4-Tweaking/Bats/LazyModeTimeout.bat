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
title LazyModeTimeout
mode con: cols=80 lines=20
color a
:home
cls
echo -----------------------------------
echo - 1) LazyModeTimeout reverse.     -
echo - 2) LazyModeTimeout at 10000.    -
echo - 3) LazyModeTimeout at 25000.    -
echo - 4) LazyModeTimeout at 150000.   -	 
echo -----------------------------------
echo.
echo --------------------------------------------
echo - IT IS RECOMMENDED TO READ THIS CAREFULLY -
echo --------------------------------------------
echo.
echo This value will modify the MMCSS cycle suspension 
echo between idle time periods.   
echo.
echo May increase FPS, reduce latencies, or the opposite. It has to be tested.
echo On the other hand, it can cause "Stuttering or Micro-Stuttering".
echo.
set /p lmt=Select an option: 
if %lmt% EQU 1 goto 0
if %lmt% EQU 2 goto 10
if %lmt% EQU 3 goto 25
if %lmt% EQU 4 goto 150
goto home

:0
cls
Reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit

:10
cls
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t REG_DWORD /d "10000" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit

:25
cls
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t REG_DWORD /d "25000" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit

:150
cls
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t REG_DWORD /d "150000" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit
