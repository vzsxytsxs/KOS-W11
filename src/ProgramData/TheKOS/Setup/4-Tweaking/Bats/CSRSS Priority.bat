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
title CSRSS Priority Changer
mode con: cols=50 lines=10
color a
:home
cls
echo --------------------------------------
echo - 1) RealTime               -
echo - 2) High			         -
echo - 3) Above Normal		     -
echo - 4) Normal		         -
echo - 5) Below Normal		     -
echo --------------------------------------
echo.
set /p csrss=Select an option: 
if %csrss% EQU 1 goto R
if %csrss% EQU 2 goto H
if %csrss% EQU 3 goto A
if %csrss% EQU 4 goto N
if %csrss% EQU 5 goto B
goto home

:R
cls
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "4" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit

:H
cls
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit

:A
cls
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "6" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit

:N
cls
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "2" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit

:B
cls
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "5" /f
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit
