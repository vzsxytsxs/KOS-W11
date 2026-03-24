@echo off
title Screen Capture Settings
:: Ensure admin privileges
fltmc >nul 2>&1 || (
    echo Administrator privileges are required.
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo Right-click on the script and select "Run as administrator".
        pause & exit 1
    )
    exit 0
)
echo [1] Enable Screen Capture
echo [2] Disable Screen Capture
set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else (
    exit
)

:e
:: sc config cbdhsvc start=auto > nul 2>&1
:: sc config WpnService start=auto > nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"    /v "DisabledHotkeys" /f
reg add    "HKCU\Control Panel\Keyboard"                                         /v "PrintScreenKeyForSnippingEnabled" /t REG_DWORD /d "1" /f
cls
echo Screen Capture enabled.
pause
exit /b 0

:d 
:: sc config cbdhsvc start=disabled > nul 2>&1
:: sc config WpnService start=disabled > nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisabledHotkeys" /t REG_SZ /d "S" /f 
reg add "HKCU\Control Panel\Keyboard"                                      /v "PrintScreenKeyForSnippingEnabled" /t REG_DWORD /d "0" /f
cls
echo Screen Capture disabled.
pause
exit /b 0