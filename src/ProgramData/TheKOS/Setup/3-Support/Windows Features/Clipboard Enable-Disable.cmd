@echo off
title Clipboard Enable / Disable
:: Ensure admin privileges
fltmc >nul 2>&1 || (
    echo Administrator privileges are required.
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo Right-click on the script and select "Run as administrator".
        pause & exit 1
    )
    exit 0
)
:: The same three options as the toolbox's "Clipboard history". Usage: "Clipboard Enable-Disable.cmd" 1, 2 or 3.
:: [3] also turns off the notification services and toasts, which the Notifications setting controls too.
set "input=%~1"
if defined input goto choose
echo [1] Enable Clipboard
echo [2] Disable Clipboard history (keep notifications)
echo [3] Disable Clipboard history and notifications
set /p input=":"
:choose
if "%input%"=="1" goto e
if "%input%"=="2" goto d
if "%input%"=="3" goto d
exit /b 2

:e
sc config cbdhsvc start= demand > nul 2>&1
sc config WpnService start= auto > nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WpnUserService" /v Start /t REG_DWORD /d 2 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableCdp" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /t REG_DWORD /d "1" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "1" /f > nul
echo Clipboard enabled. Restart your computer.
if "%~1"=="" pause
exit /b 0

:d
sc config cbdhsvc start= disabled > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableCdp" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /t REG_DWORD /d "0" /f > nul
if "%input%"=="3" (
    sc config WpnService start= disabled > nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WpnUserService" /v Start /t REG_DWORD /d 4 /f > nul 2>&1
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f > nul
)
echo Clipboard history disabled. Restart your computer.
if "%~1"=="" pause
exit /b 0
