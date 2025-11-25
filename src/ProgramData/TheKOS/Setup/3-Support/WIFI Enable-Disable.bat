@echo off
title Wifi Enabled - Disabled
echo [1] Enable Wifi
echo [2] Disable Wifi
set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else (
    exit
)


:e
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\netprofm" /v "Start" /t REG_DWORD /d "3" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NlaSvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "Start" /t REG_DWORD /d "3" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "1" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\eventlog" /v "Start" /t REG_DWORD /d "2" /f
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WCM\WiFiTask" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WlanSvc\CDSSync" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WlanSvc\MoProfileManagement" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WwanSvc\NotificationTask" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WwanSvc\OobeDiscovery" >nul 2>&1
echo Done, restart your computer.
timeout /t 3 /nobreak
exit

:d
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "4" /f
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WCM\WiFiTask" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WlanSvc\CDSSync" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WlanSvc\MoProfileManagement" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WwanSvc\NotificationTask" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WwanSvc\OobeDiscovery" >nul 2>&1
echo Done, restart your computer.
timeout /t 3 /nobreak
exit