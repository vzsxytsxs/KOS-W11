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
title Configure Power Savings / credits to imribiy

if /i "%~1"=="desktop" goto desktop
if /i "%~1"=="laptop" goto laptop
if not "%~1"=="" (
    echo [ERROR] Use desktop or laptop.
    exit /b 2
)

:menu
cls
echo [1] Disable Power Savings (Desktop)
echo [2] Enable Power Savings (Laptop)
echo [3] Exit
echo.
set "choice="
set /p "choice=Select an option (1-3): "
if "%choice%"=="1" goto desktop
if "%choice%"=="2" goto laptop
if "%choice%"=="3" exit /b 0
goto menu

:desktop
set "failed=0"
echo Configuring desktop power defaults...
for %%a in (
    EnhancedPowerManagementEnabled
    AllowIdleIrpInD3
    EnableSelectiveSuspend
    DeviceSelectiveSuspended
    SelectiveSuspendEnabled
    SelectiveSuspendOn
    WaitWakeEnabled
    D3ColdSupported
    WdfDirectedPowerTransitionEnable
    EnableIdlePowerManagement
    IdleInWorkingState
    WakeEnabled
) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%a" ^| findstr "HKEY"') do Reg.exe add "%%b" /v "%%a" /t REG_DWORD /d 0 /f >nul 2>&1

if exist "%windir%\co.pow" (
    powercfg /list | findstr /i "b0a71852-3be4-43b1-9aff-70d3c8430794" >nul
    if errorlevel 1 powercfg /import "%windir%\co.pow" b0a71852-3be4-43b1-9aff-70d3c8430794 || set "failed=1"
    powercfg /setactive b0a71852-3be4-43b1-9aff-70d3c8430794 || set "failed=1"
) else (
    echo [ERROR] Missing %windir%\co.pow
    set "failed=1"
)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 || set "failed=1"
:: PCIe link state power management, disk idle timeout and AHCI link power management (HIPM/DIPM) off.
powercfg /SETACVALUEINDEX SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 || set "failed=1"
powercfg /SETACVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\0b2d69d7-a2a1-449c-9680-f91c70521c60" /v Attributes /t REG_DWORD /d 2 /f >nul || set "failed=1"
powercfg /SETACVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 0b2d69d7-a2a1-449c-9680-f91c70521c60 0 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 0b2d69d7-a2a1-449c-9680-f91c70521c60 0 || set "failed=1"
:: NVMe drives stay out of their idle power states (no wake-up delay on the next read): idle timeouts 0 = never.
powercfg /SETACVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0 || set "failed=1"
powercfg /SETACVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d3d55efd-c1ff-424e-9dc3-441be7833010 0 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d3d55efd-c1ff-424e-9dc3-441be7833010 0 || set "failed=1"
powercfg /SETACTIVE SCHEME_CURRENT || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v DisableLPM /t REG_DWORD /d 1 /f >nul || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v Ceip /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v DisableSelectiveSuspendUI /t REG_DWORD /d 1 /f >nul || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\usbccgp\Parameters" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v D3ColdSupport /t REG_DWORD /d 0 /f >nul || set "failed=1"
powercfg /h off || set "failed=1"
:: "Allow the computer to turn off this device" off for every device that has it (MSPower_DeviceEnable), and sound devices
:: stay powered when silent (no delay or pop on the first sound; the driver's values are kept as Kos* for Laptop).
powershell.exe -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; Get-CimInstance -Namespace root\wmi MSPower_DeviceEnable | Where-Object Enable | ForEach-Object { $_.Enable = $false; Set-CimInstance -InputObject $_ }; Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}' | ForEach-Object { $k = Join-Path $_.PSPath 'PowerSettings'; if (Test-Path $k) { $p = Get-ItemProperty $k; foreach ($n in 'ConservationIdleTime','PerformanceIdleTime','IdlePowerState') { if ($null -ne $p.$n) { if ($null -eq $p.('Kos' + $n)) { New-ItemProperty $k ('Kos' + $n) -Value $p.$n -PropertyType Binary -Force | Out-Null }; Set-ItemProperty $k $n ([byte[]](0,0,0,0)) -Type Binary } } } }" < nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 0 /f >nul || set "failed=1"
wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /e:false >nul 2>&1
wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /e:false >nul 2>&1
wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /e:false >nul 2>&1
echo [KOS] Desktop power defaults applied. USB selective suspend, NVMe idle and device power-off disabled.
if /i "%~1"=="desktop" exit /b %failed%
pause
goto menu

:laptop
set "failed=0"
echo Configuring laptop power defaults...
for %%a in (
    EnhancedPowerManagementEnabled
    AllowIdleIrpInD3
    EnableSelectiveSuspend
    DeviceSelectiveSuspended
    SelectiveSuspendEnabled
    SelectiveSuspendOn
    WaitWakeEnabled
    D3ColdSupported
    WdfDirectedPowerTransitionEnable
    EnableIdlePowerManagement
    IdleInWorkingState
    WakeEnabled
) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%a" ^| findstr "HKEY"') do Reg.exe add "%%b" /v "%%a" /t REG_DWORD /d 1 /f >nul 2>&1

reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v DisableLPM /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v D3ColdSupported /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v Ceip /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v DisableSelectiveSuspendUI /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\usbccgp\Parameters" /v D3ColdSupported /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v D3ColdSupported /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v D3ColdSupport /f >nul 2>&1
powercfg /h on || set "failed=1"
:: Windows can turn devices off again to save power, and sound devices get their driver's idle values back.
powershell.exe -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; Get-CimInstance -Namespace root\wmi MSPower_DeviceEnable | Where-Object { -not $_.Enable } | ForEach-Object { $_.Enable = $true; Set-CimInstance -InputObject $_ }; Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}' | ForEach-Object { $k = Join-Path $_.PSPath 'PowerSettings'; if (Test-Path $k) { $p = Get-ItemProperty $k; foreach ($n in 'ConservationIdleTime','PerformanceIdleTime','IdlePowerState') { if ($null -ne $p.('Kos' + $n)) { Set-ItemProperty $k $n ([byte[]]$p.('Kos' + $n)) -Type Binary; Remove-ItemProperty $k ('Kos' + $n) } } } }" < nul
:: A reduced hiberfil.sys only serves fast startup; Hibernate needs the full one.
powercfg /h /type full || set "failed=1"
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e || set "failed=1"
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 || set "failed=1"
:: PCIe link state power management (moderate / maximum), disk idle after 20 / 10 minutes, AHCI link power management (DIPM / HIPM+DIPM).
powercfg /SETACVALUEINDEX SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 2 || set "failed=1"
powercfg /SETACVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 1200 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 600 || set "failed=1"
powercfg /SETACVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 0b2d69d7-a2a1-449c-9680-f91c70521c60 2 || set "failed=1"
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 0b2d69d7-a2a1-449c-9680-f91c70521c60 3 || set "failed=1"
powercfg /SETACTIVE SCHEME_CURRENT || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 1 /f >nul || set "failed=1"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v ShowHibernateOption /t REG_DWORD /d 1 /f >nul || set "failed=1"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v ShowLockOption /t REG_DWORD /d 1 /f >nul || set "failed=1"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v ShowSleepOption /t REG_DWORD /d 1 /f >nul || set "failed=1"
wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /e:true >nul 2>&1
wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /e:true >nul 2>&1
wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /e:true >nul 2>&1
echo [KOS] Laptop power defaults applied. USB selective suspend enabled.
if /i "%~1"=="laptop" exit /b %failed%
pause
goto menu
