@echo off
title DEP Settings
:: Ensure admin privileges
fltmc >nul 2>&1 || (
    echo Administrator privileges are required.
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo Right-click on the script and select "Run as administrator".
        pause & exit 1
    )
    exit 0
)
setlocal EnableExtensions DisableDelayedExpansion
echo [1] Enable DEP
echo [2] Disable DEP
set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else (
    exit
)

:e
bcdedit /set {current} nx optin
echo "please reboot."
pause
endlocal
exit /b 0

:d 
bcdedit /set {current} nx alwaysoff
echo "please reboot."
pause
endlocal
exit /b 0
