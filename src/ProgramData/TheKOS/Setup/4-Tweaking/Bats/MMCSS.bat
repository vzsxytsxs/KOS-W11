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

cls
echo ------------------------------
echo - PLEASE READ THIS CAREFULLY -
echo ------------------------------
timeout /t 2 /nobreak >nul
echo This script disables the "Multimedia Class Scheduler" driver.
echo It can increase FPS, reduce latencies or the opposite. It has to be tested.
echo YOU CAN DISABLE THIS IF YOU HAVE STUTTERING OR DIVERSE PROBLEMS IN YOUR GAMES.
echo.
echo AT THE END OF THE SCRIPT YOUR PC WILL RESTART.
echo.
echo -----------------------------
echo - 1. Enable MMCSS           -
echo - 2. Disable MMCSS          -
echo -----------------------------
set /p menu2=:
if %menu2% EQU 1 goto e
if %menu2% EQU 2 goto d
goto english

:e
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MMCSS" /v "Start" /t REG_DWORD /d "2" /f
shutdown -r -f -t 5 -c "Please wait until your PC restarts..."
timeout /t 2 /nobreak >NUL 2>&1
exit

:d
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MMCSS" /v "Start" /t REG_DWORD /d "4" /f
shutdown -r -f -t 5 -c "Please wait until your PC restarts..."
timeout /t 2 /nobreak >NUL 2>&1
exit
