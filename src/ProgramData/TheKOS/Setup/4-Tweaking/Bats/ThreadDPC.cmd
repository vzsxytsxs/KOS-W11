@echo off
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