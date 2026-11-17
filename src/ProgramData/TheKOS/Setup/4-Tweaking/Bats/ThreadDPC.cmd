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
title Thread DPC Enable/Disable
:home
cls
echo.
echo ------------------------------
echo - PLEASE READ THIS CAREFULLY -
echo ------------------------------
timeout /t 2 /nobreak >nul
echo "Thread DPC" enables preemption by an ordinary DPC, but not by other threads.
echo This can help with System stability at the cost of more interruptions and context switches.
echo If you disable it, it may improve system performance and responsiveness, or it could lead to freezes/crashes, 
echo especially on faulty hardware. 
echo You need to TEST it.
echo.
echo AT THE END OF THE SCRIPT YOUR PC WILL RESTART.
echo.
echo -----------------------------------
echo - 1. Disable ThreadDPC            -
echo - 2. Enable ThreadDPC             -
echo -----------------------------------
set /p menu2=:
if %menu2% EQU 1 goto d
if %menu2% EQU 2 goto e
goto home

:d
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v ThreadDpcEnable /t REG_DWORD /f /d 0
shutdown -r -f -t 5 -c "Please wait until your PC restarts..."
timeout /t 2 /nobreak >NUL 2>&1
exit

:e
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v ThreadDpcEnable /t REG_DWORD /f /d 1
shutdown -r -f -t 5 -c "Please wait until your PC restarts..."
timeout /t 2 /nobreak >NUL 2>&1
exit
