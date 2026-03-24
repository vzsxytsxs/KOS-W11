@echo off
title Fix Reliability Analysis (perfmon /rel)

fltmc >nul 2>&1 || (
    echo Administrator privileges are required.
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo Right-click on the script and select "Run as administrator".
        pause & exit 1
    )
    exit 0
)

cls
echo [1] Enable Reliability Analysis (perfmon /rel)
echo [2] Disable Reliability Analysis (perfmon /rel)
set /p input=":"

if "%input%"=="1" (
    goto :enable
) else if "%input%"=="2" (
    goto :disable
) else (
    exit
)


:enable
cls
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Reliability Analysis\WMI" /v "WMIEnable" /t REG_DWORD /d "1" /f 
echo Done, restart your pc.
pause
exit

:disable
cls
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Reliability Analysis\WMI" /v "WMIEnable" /t REG_DWORD /d "0" /f 
echo Done, restart your pc.
pause
exit