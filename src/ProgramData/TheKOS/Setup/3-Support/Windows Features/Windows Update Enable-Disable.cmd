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
title Windows Update - Enable / Disable - credits to imribiy
echo [1] Enable Windows Update
echo [2] Moderate (Manual Updates, No Drivers)
echo [3] Hard Disable Windows Update
echo [4] Enable Microsoft Store downloads (Windows Update remains disabled)
echo [5] Pause updates until 2038 (Windows Update stays on; resume with [1])
set "input=%~1"
if defined input set "noninteractive=1"
if not defined input set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="5" (
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
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "2" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\bits" /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dosvc" /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
call :checkStart WaaSMedicSvc 3 || goto enablefail
call :checkStart UsoSvc 2 || goto enablefail
call :checkStart wuauserv 3 || goto enablefail
call :checkStart bits 3 || goto enablefail
call :checkStart dosvc 3 || goto enablefail
call :svc uhssvc 2
call :clearPause
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Start Oobe Expedite Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_LicenseAccepted" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_OobeAppReady" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScanAfterUpdate" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\UIEOrchestrator" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WindowsUpdate\Refresh Group Policy Cache" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WaaSMedic\PerformRemediation" >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 1 /f >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v PreventDeviceMetadataFromNetwork /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /f >nul 2>&1
for %%v in (IsContinuousInnovationOptedIn AllowMUUpdateService IsExpedited) do reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v %%v /f >nul 2>&1
if "%input%"=="5" goto pauseValues
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "forceDisableWup" /t REG_SZ /d "0" /f >nul 2>&1
echo please reboot your system.
timeout /t 3 /nobreak
exit

:d
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\bits" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dosvc" /v "Start" /t REG_DWORD /d "2" /f
for %%S in (wuauserv bits UsoSvc WaaSMedicSvc dosvc) do (
    call :checkStart %%S 2
    if errorlevel 1 goto enablefail
)
call :svc uhssvc 2
call :clearPause
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\WaaSMedic\PerformRemediation" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\UpdateOrchestrator\Start Oobe Expedite Work" >nul 2>&1
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
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "forceDisableWup" /t REG_SZ /d "0" /f >nul 2>&1
echo please reboot your system.
timeout /t 3 /nobreak
exit

:h 
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "forceDisableWup" /t REG_SZ /d "1" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\bits" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dosvc" /v "Start" /t REG_DWORD /d "4" /f
call :svc uhssvc 4
call :clearPause
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Start Oobe Expedite Work" >nul 2>&1
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
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v UseWUServer /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 99 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f >nul
for %%v in (IsContinuousInnovationOptedIn AllowMUUpdateService IsExpedited) do reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v %%v /t REG_DWORD /d 0 /f >nul
echo please reboot your system.
timeout /t 3 /nobreak
exit

:usosvc
sc stop wuauserv >nul 2>&1
sc stop WaaSMedicSvc >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\bits" /v "Start" /t REG_DWORD /d "2" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dosvc" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "2" /f
call :checkStart wuauserv 4 || goto enablefail
call :checkStart WaaSMedicSvc 4 || goto enablefail
call :checkStart bits 2 || goto enablefail
call :checkStart dosvc 2 || goto enablefail
call :checkStart UsoSvc 2 || goto enablefail
call :svc uhssvc 4
call :clearPause
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "forceDisableWup" /t REG_SZ /d "store" /f >nul 2>&1
echo please reboot your system.
timeout /t 3 /nobreak
exit

:: [5]: the [1] steps, then Windows Update's own pause, set to end in 2038, and the policies that stop automatic installs.
:pauseValues
set "UX=HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
set "AU=HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
for %%v in ("NoAutoUpdate 1" "AUOptions 1" "NoAUShutdownOption 1" "AlwaysAutoRebootAtScheduledTime 0" "AutoInstallMinorUpdates 0" "UseWUServer 0") do (
    for /f "tokens=1,2" %%a in (%%v) do reg add "%AU%" /v %%a /t REG_DWORD /d %%b /f >nul
)
for %%v in (PauseFeatureUpdatesStartTime PauseQualityUpdatesStartTime PauseUpdatesStartTime PausedQualityDate PausedFeatureDate) do reg add "%UX%" /v %%v /t REG_SZ /d "2025-01-01T00:00:00Z" /f >nul
for %%v in (PauseFeatureUpdatesEndTime PauseQualityUpdatesEndTime PauseUpdatesExpiryTime) do reg add "%UX%" /v %%v /t REG_SZ /d "2038-01-19T03:14:07Z" /f >nul
reg add "%UX%" /v FlightSettingsMaxPauseDays /t REG_DWORD /d 5269 /f >nul
reg add "%UX%" /v PausedFeatureStatus /t REG_DWORD /d 1 /f >nul
reg add "%UX%" /v PausedQualityStatus /t REG_DWORD /d 1 /f >nul
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "forceDisableWup" /t REG_SZ /d "paused" /f >nul 2>&1
echo Updates paused until 2038. please reboot your system.
timeout /t 3 /nobreak
exit

:: Removes the pause that [5] (or Settings) set, so the other modes start from a clean state.
:clearPause
for %%v in (PauseFeatureUpdatesStartTime PauseFeatureUpdatesEndTime PauseQualityUpdatesStartTime PauseQualityUpdatesEndTime PauseUpdatesStartTime PauseUpdatesExpiryTime PausedQualityDate PausedFeatureDate FlightSettingsMaxPauseDays PausedFeatureStatus PausedQualityStatus) do (
    reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v %%v /f >nul 2>&1
)
exit /b 0

:: Start type of a service that not every build has (uhssvc is installed by an update).
:svc
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1 || exit /b 0
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f >nul 2>&1
exit /b 0

:checkStart
for /l %%R in (1,1,10) do (
    for /f "tokens=3" %%V in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start 2^>nul') do if /i "%%V"=="0x%~2" exit /b 0
    timeout /t 1 /nobreak >nul
)
exit /b 1

:enablefail
echo Failed to set all required Windows Update services. forceDisableWup was not changed.
if not defined noninteractive pause
exit /b 1
