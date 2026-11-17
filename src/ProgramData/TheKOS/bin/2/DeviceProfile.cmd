@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "chassisTypes="
if /i "%~1"=="--test-chassis" (
    set "chassisTypes=%~2"
) else (
    for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "(Get-CimInstance Win32_SystemEnclosure).ChassisTypes -join ','" 2^>nul') do set "chassisTypes=%%A"
)

if defined chassisTypes (
    for %%C in (%chassisTypes:,= %) do (
        for %%L in (8 9 10 11 14 30 31 32) do if "%%C"=="%%L" set "hasLaptop=1"
        for %%D in (3 4 5 6 7 13 15 16 17 23 24) do if "%%C"=="%%D" set "hasDesktop=1"
    )
)
set "deviceType=UNKNOWN"
if defined hasDesktop set "deviceType=DESKTOP"
if defined hasLaptop set "deviceType=LAPTOP"
if "%deviceType%"=="UNKNOWN" (
    echo [KOS] Unknown chassis. Applying desktop defaults.
    set "deviceType=DESKTOP"
)

echo [KOS] Chassis types: %chassisTypes%. Device profile: %deviceType%.
if /i "%~1"=="--detect-only" goto return
if /i "%~1"=="--test-chassis" goto return
if not "%~1"=="" (
    echo [KOS] Invalid argument: %~1
    exit /b 2
)
set "wifiScript=%ProgramData%\TheKOS\Setup\3-Support\Windows Features\WIFI Enable-Disable.bat"
set "bluetoothScript=%ProgramData%\TheKOS\Setup\3-Support\Windows Features\Bluetooth Enable-Disable.bat"
set "powerScript=%ProgramData%\TheKOS\Setup\4-Tweaking\Bats\Configure Powersavings.bat"
if not exist "%wifiScript%" goto missingScript
if not exist "%bluetoothScript%" goto missingScript
if not exist "%powerScript%" goto missingScript

set "failed=0"
if "%deviceType%"=="LAPTOP" (
    call "%wifiScript%" 1 || set "failed=1"
    call "%bluetoothScript%" 1 || set "failed=1"
    call :checkStart WlanSvc 2 || set "failed=1"
    call :checkStart vwififlt 1 || set "failed=1"
    call :checkStart bthserv 3 || set "failed=1"
    call :checkStart BTHPORT 3 || set "failed=1"
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\serenum" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\sermouse" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\serial" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\dispbrokerdesktopsvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\wmiacpi" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
    call "%powerScript%" laptop || set "failed=1"
) else (
    call "%wifiScript%" 2 || set "failed=1"
    call "%bluetoothScript%" 2 || set "failed=1"
    call :checkStart WlanSvc 4 || set "failed=1"
    call :checkStart vwififlt 4 || set "failed=1"
    call :checkStart bthserv 4 || set "failed=1"
    call :checkStart BTHPORT 4 || set "failed=1"
    for %%S in (sensorservice sensordataservice sensrsvc DisplayEnhancementService wmiacpi) do reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
    call "%powerScript%" desktop || set "failed=1"
)
echo [KOS] Device profile complete. Result=%failed%.
endlocal & set "KOS_DEVICE_TYPE=%deviceType%" & exit /b %failed%

:missingScript
echo [KOS] A device-profile support script is missing.
endlocal & set "KOS_DEVICE_TYPE=%deviceType%" & exit /b 1

:return
endlocal & set "KOS_DEVICE_TYPE=%deviceType%" & exit /b 0

:checkStart
for /l %%R in (1,1,5) do (
    for /f "tokens=3" %%V in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start 2^>nul') do if /i "%%V"=="0x%~2" exit /b 0
    timeout /t 1 /nobreak >nul
)
echo [KOS] Failed to set %~1 Start=%~2.
exit /b 1
