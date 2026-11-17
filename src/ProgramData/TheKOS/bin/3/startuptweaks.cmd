@echo off
call "%programdata%\TheKOS\bin\3\edge-webview.cmd"

:: from blitzos
:: SET MANUAL SERVICES
sc config W32Time start= demand >nul 2>&1
sc start W32Time >nul 2>&1

:: SYNC TIME
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org" >nul 2>nul
w32tm /config /update >nul 2>nul
w32tm /resync >nul 2>nul
timeout /t 3 /nobreak >nul

:: STOP SERVICES
sc stop msiserver >nul 2>&1
sc stop W32Time >nul 2>&1
timeout /t 30 /nobreak >nul

:: LOWER PRIORITY OF SYSTEM PROCESSES
wmic process where name="gamingservices.exe" call setpriority "below normal" >nul 2>&1
wmic process where name="ctfmon.exe" call setpriority "below normal" >nul 2>&1
:: runtimebroker.exe and WmiPrvSE.exe are no longer killed at startup (roadmap: game mode candidates).

:: Apply the selected Windows Update policy without changing the user's mode.
call "%programdata%\TheKOS\bin\3\windows-update-policy.cmd"

:: rwe: USB interrupt moderation off through RW. The script checks itself whether Windows would block the RW driver
:: (vulnerable driver blocklist, VBS or memory integrity) or the toolbox turned the tweak off, and doesn't start RW then.
powershell.exe -NoProfile -WindowStyle Hidden -File "%programdata%\TheKOS\bin\3\XHCI-IMOD-Interval.ps1" >nul 2>&1

exit
