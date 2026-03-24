@echo off
title Windows Update - Enable / Disable - credits to imribiy
echo [1] Enable Windows Update
echo [2] Moderate (Manual Updates, No Drivers)
echo [3] Hard Disable Windows Update
echo [4] Enable UsoSVC (for MS-Store)
set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else if "%input%"=="3" (
    goto h
) else if "%input%"=="4" (
    goto usosvc
) else (
    exit
)

:e
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "2" /f >nul 2>&1
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Windows\UpdateOrchestrator\Start Oobe Expedite Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_LicenseAccepted" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_OobeAppReady" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScanAfterUpdate" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\UIEOrchestrator" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WindowsUpdate\Refresh Group Policy Cache" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start" >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 1 /f >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v PreventDeviceMetadataFromNetwork /f >nul 2>&1
echo please reboot your system.
timeout /t 3 /nobreak
exit

:d
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\bits" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dosvc" /v "Start" /t REG_DWORD /d "2" /f
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Windows\UpdateOrchestrator\Start Oobe Expedite Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_LicenseAccepted" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_OobeAppReady" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScanAfterUpdate" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\UIEOrchestrator" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WindowsUpdate\Refresh Group Policy Cache" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start" >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f >nul
echo please reboot your system.
timeout /t 3 /nobreak
exit

:h 
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\bits" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dosvc" /v "Start" /t REG_DWORD /d "4" /f
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Windows\UpdateOrchestrator\Start Oobe Expedite Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_LicenseAccepted" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_OobeAppReady" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScanAfterUpdate" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\UIEOrchestrator" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WindowsUpdate\Refresh Group Policy Cache" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WaaSMedic\PerformRemediation" >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v PreventDeviceMetadataFromNetwork /t REG_DWORD /d 1 /f >nul
echo please reboot your system.
timeout /t 3 /nobreak
exit

:usosvc
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dosvc" /v "Start" /t REG_DWORD /d "2" /f
echo please reboot your system.
timeout /t 3 /nobreak
exit
