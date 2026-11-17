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
:: The whole Hyper-V stack (virtual machines, WSL 2, Docker, Android emulators), the same as the toolbox's "Hyper-V".
:: Usage: "HyperV Enable-Disable.cmd" on or off (with no argument it shows the menu). Restart afterwards.
:: Off also disables the Hyper-V guest drivers (keyboard, video, PCI): don't turn it off inside a Hyper-V virtual machine.
:: The KOS first boot disables gencounter, storflt, hvservice, HvHost and the infrastructure device; on brings them back.
set "input=%~1"
if defined input goto choose
echo [1] Enable Hyper-V
echo [2] Disable Hyper-V
set /p input=":"
:choose
if "%input%"=="1" set "input=on"
if "%input%"=="2" set "input=off"
if /i "%input%"=="on" goto on
if /i "%input%"=="off" goto off
exit /b 2

:on
for %%v in ("vid 1" "bttflt 0" "vpci 0" "gencounter 3" "hyperkbd 3" "hypervideo 3" "spaceparser 3" "storflt 3" "vmgid 3" "hvservice 3" "HvHost 3" "vdrvroot 3") do (
    for /f "tokens=1,2" %%a in (%%v) do call :svc %%a %%b
)
pnputil.exe /enable-device "ROOT\VID\0000" >nul 2>&1
pnputil.exe /enable-device "ROOT\VID\0001" >nul 2>&1
devmanview /enable "Microsoft Hyper-V Virtualization Infrastructure Driver" >nul 2>&1
devmanview /enable "Microsoft Virtual Drive Enumerator" >nul 2>&1
bcdedit /set {current} hypervisorlaunchtype Auto >nul
:: Features that don't exist on this edition (Hyper-V on Home) just fail.
for %%F in (Microsoft-Hyper-V-All Microsoft-Hyper-V Microsoft-Hyper-V-Tools-All Microsoft-Hyper-V-Management-PowerShell Microsoft-Hyper-V-Hypervisor Microsoft-Hyper-V-Services Microsoft-Hyper-V-Management-Clients HypervisorPlatform VirtualMachinePlatform) do (
    dism.exe /online /enable-feature /featurename:%%F /all /quiet /norestart >nul 2>&1
)
goto done

:off
for %%F in (Microsoft-Hyper-V-All HypervisorPlatform VirtualMachinePlatform) do (
    dism.exe /online /disable-feature /featurename:%%F /quiet /norestart >nul 2>&1
)
pnputil.exe /disable-device "ROOT\VID\0000" >nul 2>&1
pnputil.exe /disable-device "ROOT\VID\0001" >nul 2>&1
for %%S in (vid bttflt vpci gencounter hyperkbd hypervideo spaceparser storflt vmgid hvservice HvHost) do call :svc %%S 4

:done
echo Done, restart your computer.
if "%~1"=="" pause
exit /b 0

:: Start type of a Hyper-V driver or service, only where it exists; some are protected, hence PowerRun.
:svc
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1 || exit /b 0
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f >nul 2>&1
exit /b 0
