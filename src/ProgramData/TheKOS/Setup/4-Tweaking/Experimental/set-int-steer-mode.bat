@echo off
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
