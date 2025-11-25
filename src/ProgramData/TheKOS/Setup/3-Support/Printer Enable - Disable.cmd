@echo off
title Printer Enable - Disable
echo [1] Enable Printer
echo [2] Disable Disable
set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else (
    exit
)

:e
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Spooler" /v "Start" /t REG_DWORD /d "2" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PrintWorkFlowUserSvc" /v "Start" /t REG_DWORD /d "3" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\StiSvc" /v "Start" /t REG_DWORD /d "3" /f
devmanview /enable "Fax" > NUL 2>&1
devmanview /enable "Microsoft Print to PDF" > NUL 2>&1
devmanview /enable "Microsoft XPS Document Writer" > NUL 2>&1
devmanview /enable "Root Print Queue" > NUL 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\Printing\PrintJobCleanupTask" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\Printing\PrinterCleanupTask" >nul 2>&1
powerrun "schtasks.exe" /change /enable /TN "\Microsoft\Windows\Printing\EduPrintProv" >nul 2>&1
dism /online /enable-feature /featurename:Printing-Foundation-Features
dism /online /enable-feature /featurename:Internet-Printing-Client
dism /online /enable-feature /featurename:Printing-LPDPrintService
dism /online /enable-feature /featurename:Printing-LPRPortMonitor
echo Done, restart your computer.
timeout /t 3 /nobreak
exit

:d
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Spooler" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PrintWorkFlowUserSvc" /v "Start" /t REG_DWORD /d "4" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\StiSvc" /v "Start" /t REG_DWORD /d "4" /f
devmanview /disable "Fax" > NUL 2>&1
devmanview /disable "Microsoft Print to PDF" > NUL 2>&1
devmanview /disable "Microsoft XPS Document Writer" > NUL 2>&1
devmanview /disable "Root Print Queue" > NUL 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Printing\PrintJobCleanupTask" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Printing\PrinterCleanupTask" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Printing\EduPrintProv" >nul 2>&1
dism /online /disable-feature /featurename:Printing-Foundation-Features
dism /online /disable-feature /featurename:Internet-Printing-Client
dism /online /disable-feature /featurename:Printing-LPDPrintService
dism /online /disable-feature /featurename:Printing-LPRPortMonitor
echo Done, restart your computer.
timeout /t 3 /nobreak
exit