@echo off
setlocal EnableExtensions DisableDelayedExpansion
DeviceCleanupCmd.exe * -s -m:7d
for %%a in (
    WindowsUpdate.log
    setuperr.log
    setupact.log
    lsasetup.log
    DtcInstall.log
    DirectX.log
    Logs\DirectX.log
) do (
    del "%windir%\%%a" >nul 2>&1
)
for %%a in (
    %windir%\Logs\
    %windir%\temp\
    %temp%\
) do (
    rd /s /q "%%a"
)

set "wupState="
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\TheKOS" /v forceDisableWup 2^>nul') do if /i "%%A"=="REG_SZ" set "wupState=%%B"
if "%wupState%"=="1" if defined windir if exist "%windir%\SoftwareDistribution\Download" (
    rd /s /q "%windir%\SoftwareDistribution\Download" >nul 2>&1
)

set "gdidState="
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\TheKOS" /v GDIDTRACKING 2^>nul') do if /i "%%A"=="REG_SZ" set "gdidState=%%B"
if "%gdidState%"=="1" if defined LOCALAPPDATA if exist "%LOCALAPPDATA%\ConnectedDevicesPlatform" (
    rd /s /q "%LOCALAPPDATA%\ConnectedDevicesPlatform" >nul 2>&1
)

del "%HOMEPATH%\AppData\Local\updater.log" >nul 2>&1
del "%HOMEPATH%\AppData\Local\UserProducts.xml" >nul 2>&1
exit
