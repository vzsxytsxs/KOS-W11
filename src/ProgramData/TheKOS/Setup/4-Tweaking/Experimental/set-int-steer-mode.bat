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
::Check Administrator Privileges
dism >nul 2>&1 || (echo ^<Run Script In Administrator^> && pause>nul && cls&exit)
title set-int-steer-mode
set krnl_key=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel
mode 39,2
choice -c 12 -n -m "[1] Force | [2] Disabled | [3] Default"
if %errorlevel% equ 1 (
	:: KiInterruptSteeringFlags
	:: bit 0 = default, bit 1 = disabled, bit 2 = force enabled
	reg add "%krnl_key%" /v InterruptSteeringFlags /t reg_dword /d 2 /f >nul
	
	:: lock Interrupt Routing	
	powercfg -setacvalueindex scheme_current SUB_INTSTEER MODE 4 >nul
	powercfg -s scheme_current
)
if %errorlevel% equ 2 (
	reg add "%krnl_key%" /v InterruptSteeringFlags /t reg_dword /d 1 /f >nul
	
	:: Any processor
	powercfg -setacvalueindex scheme_current SUB_INTSTEER MODE 1 >nul
	powercfg -s scheme_current
)
if %errorlevel% equ 2 (
	reg delete "%krnl_key%" /v InterruptSteeringFlags /f >nul 2>&1
	
	:: Default
	powercfg -setacvalueindex scheme_current SUB_INTSTEER MODE 0 >nul
	powercfg -s scheme_current
)
exit
