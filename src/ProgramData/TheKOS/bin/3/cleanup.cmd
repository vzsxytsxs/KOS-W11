@echo off
title TheKOS Cleanup
if exist "%systemdrive%\windows\system32\smartscreen.exe" (
    cd C:\Windows\System32
    takeown /f "smartscreen.exe"
    icacls "C:\Windows\System32\smartscreen.exe" /grant Administrators:F
    taskkill /f /im smartscreen.exe /t
    ren smartscreen.exe smartscreen.old
)
DeviceCleanupCmd.exe * -s -m:7d
del "%HOMEPATH%\AppData\Local\updater.log" >nul 2>&1
del "%HOMEPATH%\AppData\Local\UserProducts.xml" >nul 2>&1
del "%SYSTEMROOT%\Logs\DirectX.log" >nul 2>&1
del "%SYSTEMROOT%\DirectX.log" >nul 2>&1
del "%SYSTEMROOT%\DtcInstall.log" >nul 2>&1
del "%SYSTEMROOT%\lsasetup.log" >nul 2>&1
del "%SYSTEMROOT%\setupact.log" >nul 2>&1
del "%SYSTEMROOT%\setuperr.log" >nul 2>&1
del "%SYSTEMROOT%\WindowsUpdate.log" >nul 2>&1
del /q /f /s %TEMP%\ >nul 2>&1
del /q /f /s %SYSTEMROOT%\Logs\* >nul 2>&1
rd /s /q %SYSTEMROOT%\Logs\* >NUL 2>&1
md %systemroot%\Logs >NUL 2>&1
del /q /f /s %SYSTEMROOT%\Temp\* >nul 2>&1
del /q /f /s %SYSTEMROOT%\SoftwareDistribution\* >nul 2>&1
del /s /f /q %windir%\temp\*.* >NUL 2>&1
rd /s /q %windir%\temp >NUL 2>&1
md %windir%\temp >NUL 2>&1
del /s /f /q %temp%\*.* >NUL 2>&1
rd /s /q %temp% >NUL 2>&1
md %temp% >NUL 2>&1
del /s /f /q %windir%\Installer\*.* >NUL 2>&1
rd /s /q %windir%\Installer >NUL 2>&1
md %windir%\Installer >NUL 2>&1
del /s /f /q %windir%\*.log >NUL 2>&1
for %%F in ("C:\Windows\SoftwareDistribution\Download\*") do (
    del "%%F" /q /f >NUL 2>&1
    rd "%%F" /s /q >NUL 2>&1
) >NUL 2>&1
for %%A in ("%localappdata%\Microsoft\Windows\INetCache\IE\*") do (
    del "%%A" /q /f >NUL 2>&1
    rd "%%A" /s /q >NUL 2>&1
) >NUL 2>&1
exit 