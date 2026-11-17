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
title IOPageLockLimit
mode con: cols=83 lines=20
color a
:home
cls
echo.
echo This is experimental, it may cause unknown problems.
echo Performance may vary and it is recommended to test it, 
echo the default value used in previous SXKOS versions was the maximum value (opt 3).
echo ---------------------------------
echo Some of the problems that can occur are Stuttering, Micro-Stuttering, 
echo general ISO performance problems when running apps.
echo.
echo -------------------------------------------------
echo - 1) IOPageLockLimit default                    -
echo - 2) IOPageLockLimit according to your RAM      -
echo - 3) IOPageLockLimit max value                  -
echo - 4) IOPageLockLimit recommended buffer sizes   -
echo -------------------------------------------------
set /p io=:
if %io% EQU 1 goto R
if %io% EQU 2 goto GB
if %io% EQU 3 goto L
if %io% EQU 4 goto B
goto home

:R
Reg.exe delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IOPageLockLimit" /f
echo Done, restart your computer.
timeout /t 3 /nobreak
exit

:GB
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%i

IF %mem% LSS 32000000 (
set /a ram=%mem% * 128
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IOPageLockLimit" /t REG_DWORD /d "%mem%" /f
) ELSE (echo Excessive RAM, you cannot use this option.
timeout /t 3 /nobreak
goto home)
echo Done, restart your computer.
timeout /t 3 /nobreak
exit

:L
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IOPageLockLimit" /t REG_DWORD /d "4294967295" /f
echo Done, restart your computer.
timeout /t 3 /nobreak
exit

:B
cls
echo.
echo -----------------------------------
echo - 1) IOPageLockLimit in 1MB	  -
echo - 2) IOPageLockLimit in 2MB       - 
echo - 3) IOPageLockLimit in 4MB       - 
echo - 4) IOPageLockLimit in 8MB       -
echo -----------------------------------
set /p io2=:
if %io2%% EQU 1 goto 1
if %io2%% EQU 2 goto 2
if %io2%% EQU 3 goto 4
if %io2%% EQU 4 goto 8
goto B

:1
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IOPageLockLimit" /t REG_DWORD /d "1048576" /f
echo Done, restart your computer.
timeout /t 3 /nobreak

:2
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IOPageLockLimit" /t REG_DWORD /d "2097152" /f
echo Done, restart your computer.
timeout /t 3 /nobreak
exit

:4
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IOPageLockLimit" /t REG_DWORD /d "4194304" /f
echo Done, restart your computer.
timeout /t 3 /nobreak
exit

:8
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IOPageLockLimit" /t REG_DWORD /d "8388608" /f
echo Done, restart your computer.
timeout /t 3 /nobreak
exit
