@echo off
Title First Boot
setlocal EnableDelayedExpansion
:: vantageos

echo [K?] Do not close this window.
echo [K?] Waiting 10 seconds for system stability...
timeout /t 15 /nobreak >nul 2>&1 
cls

echo [K?] TheKOS Reg
regedit /s "%programdata%\TheKOS\bin\2\TheKOS_reg.reg"
PowerRun.exe "regedit.exe" /s "%programdata%\TheKOS\bin\2\TheKOS_reg.reg" >nul 2>&1
cls

echo [K?] RunOnce entry added for VantageOS.bat 
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v runonce /t REG_SZ /d "C:\Windows\RunOnce.cmd" /f >nul 2>&1

endlocal
shutdown /r /t 5 >nul 2>&1
start /b "" cmd /c del "%~f0"&exit /b


