@echo off
title made by vzsxytsxs
echo [K?] Cleanup
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
    %windir%\SoftwareDistribution\Download\
    %windir%\Logs\
    %windir%\temp\
    %temp%\
) do (
    rd /s /q "%%a" 
)
del "%HOMEPATH%\AppData\Local\updater.log" >nul 2>&1
del "%HOMEPATH%\AppData\Local\UserProducts.xml" >nul 2>&1
exit 