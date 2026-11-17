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
title Printer Enable - Disable
:: Services, virtual printers, tasks and optional features for printing and scanning.
:: The toolbox's "Printing" passes 1 or 2 on standard input.
echo [1] Enable Printer
echo [2] Disable Printer
set /p input=":"
if "%input%"=="1" (
    set "start=3"
    set "spooler=2"
    set "dev=/enable"
    set "task=/enable"
    set "feature=/enable-feature"
) else if "%input%"=="2" (
    set "start=4"
    set "spooler=4"
    set "dev=/disable"
    set "task=/disable"
    set "feature=/disable-feature"
) else (
    exit
)

if "%input%"=="2" sc stop Spooler >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Spooler" /v "Start" /t REG_DWORD /d "%spooler%" /f
for %%S in (PrintWorkFlowUserSvc StiSvc PrintNotify usbprint PrintScanBrokerService PrintDeviceConfigurationService) do (
    reg query "HKLM\SYSTEM\CurrentControlSet\Services\%%S" >nul 2>&1 && PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%S" /v "Start" /t REG_DWORD /d "%start%" /f
)
devmanview %dev% "Fax" > NUL 2>&1
devmanview %dev% "Microsoft Print to PDF" > NUL 2>&1
devmanview %dev% "Microsoft XPS Document Writer" > NUL 2>&1
devmanview %dev% "Root Print Queue" > NUL 2>&1
powerrun "schtasks.exe" /change %task% /TN "\Microsoft\Windows\Printing\PrintJobCleanupTask" >nul 2>&1
powerrun "schtasks.exe" /change %task% /TN "\Microsoft\Windows\Printing\PrinterCleanupTask" >nul 2>&1
powerrun "schtasks.exe" /change %task% /TN "\Microsoft\Windows\Printing\EduPrintProv" >nul 2>&1
for %%F in (Printing-Foundation-Features Printing-Foundation-InternetPrinting-Client Printing-Foundation-LPDPrintService Printing-Foundation-LPRPortMonitor Printing-PrintToPDFServices-Features Printing-XPSServices-Features) do (
    dism /online %feature% /featurename:%%F /quiet /norestart
)
if "%input%"=="1" sc start Spooler >nul 2>&1
echo Done, restart your computer.
timeout /t 3 /nobreak
exit
