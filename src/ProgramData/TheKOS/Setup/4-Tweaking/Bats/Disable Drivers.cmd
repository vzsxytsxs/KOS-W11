@echo off
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