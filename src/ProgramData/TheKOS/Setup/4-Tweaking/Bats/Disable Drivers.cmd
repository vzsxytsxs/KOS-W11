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
SETLOCAL ENABLEDELAYEDEXPANSION
:: from Kizimo

:welcome
set /P "START=Continue? (y/n): "
 
if '%START%' equ 'y' goto work
if '%START%' equ 'n' goto exit
goto welcome

:work
:: variables for file paths
SET "DRIVERS_DIR=%SystemRoot%\System32\drivers"
SET "ACPI_DRIVER1=Acpidev.sys"
SET "ACPI_DRIVER2=Acpipagr.sys"
SET "ACPI_DRIVER3=Acpitime.sys"
SET "ACPI_DRIVER4=Acpipmi.sys"
SET "MSPQM_DRIVER=mspqm.sys"
SET "MSPCLOCK_DRIVER=mspclock.sys"

:: take ownership and rename specified drivers
FOR %%d IN (%ACPI_DRIVER1%, %ACPI_DRIVER2%, %ACPI_DRIVER3%, %ACPI_DRIVER4%, %WOF_DRIVER%, %MSPQM_DRIVER%, %MSPCLOCK_DRIVER%) DO (
    ECHO Taking ownership of %%d
    takeown /f "%DRIVERS_DIR%\%%d"
    icacls "%DRIVERS_DIR%\%%d" /grant "%username%":F

    ECHO Renaming %%d to %%~ndBACKUP%%~xd
    REN "%DRIVERS_DIR%\%%d" "%%~ndBACKUP%%~xd"
)

ECHO selected drivers have been renamed. please reboot your system to apply changes.
PAUSE
exit

:exit
exit
