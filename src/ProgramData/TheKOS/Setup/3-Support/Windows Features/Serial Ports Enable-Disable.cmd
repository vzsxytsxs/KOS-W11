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
:: COM and LPT ports, the same as the toolbox's "Serial and parallel ports". Usage: "Serial Ports Enable-Disable.cmd" on or off.
:: Some laptop touchpads and USB serial adapters (Arduino, modems) need them; on laptops the KOS first boot keeps them on.
set "input=%~1"
if defined input goto choose
echo [1] Enable serial and parallel ports
echo [2] Disable serial and parallel ports
set /p input=":"
:choose
if "%input%"=="1" set "input=on"
if "%input%"=="2" set "input=off"
if /i "%input%"=="on" goto on
if /i "%input%"=="off" goto off
exit /b 2

:on
for %%S in (Serenum Serial sermouse usbser Parport) do call :svc %%S 3
powershell.exe -NoProfile -Command "Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
goto done

:off
powershell.exe -NoProfile -Command "Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
for %%S in (Serenum Serial sermouse usbser Parport) do call :svc %%S 4

:done
echo Done, restart your computer.
if "%~1"=="" pause
exit /b 0

:svc
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1 || exit /b 0
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f >nul 2>&1
exit /b 0
