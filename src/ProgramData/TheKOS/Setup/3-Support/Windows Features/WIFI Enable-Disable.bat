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
setlocal EnableExtensions
title Wifi Enabled - Disabled
echo [1] Enable Wifi
echo [2] Disable Wifi
set "input=%~1"
if not defined input set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else (
    exit /b 2
)


:e
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\netprofm" /v "Start" /t REG_DWORD /d "3" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NlaSvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "1" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\eventlog" /v "Start" /t REG_DWORD /d "2" /f
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WCM\WiFiTask" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WlanSvc\CDSSync" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WlanSvc\MoProfileManagement" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WwanSvc\NotificationTask" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WwanSvc\OobeDiscovery" >nul 2>&1
echo Done, restart your computer.
if "%~1"=="" timeout /t 3 /nobreak
exit /b 0

:d
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "4" /f
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WCM\WiFiTask" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WlanSvc\CDSSync" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WlanSvc\MoProfileManagement" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WwanSvc\NotificationTask" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WwanSvc\OobeDiscovery" >nul 2>&1
echo Done, restart your computer.
if "%~1"=="" timeout /t 3 /nobreak
exit /b 0
