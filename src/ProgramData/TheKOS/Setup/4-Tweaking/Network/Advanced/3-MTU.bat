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
netsh interface ipv4 set subinterface "1" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "10" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "12" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "16" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "33" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "1" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "10" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "12" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "16" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "33" mtu=1500 store=persistent
netsh interface ipv4 show interfaces
netsh interface ipv6 show interfaces

pause
