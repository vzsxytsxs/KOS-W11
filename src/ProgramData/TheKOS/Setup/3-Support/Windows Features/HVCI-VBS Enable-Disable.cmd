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
:: VBS and memory integrity (HVCI), the same values as the toolbox's "Virtualization-based security" and "Memory integrity".
:: Usage: "HVCI-VBS Enable-Disable.cmd" 1, 2 or 3 (with no argument it shows the menu). Restart afterwards.
:: Credential Guard is turned on without the UEFI lock (LsaCfgFlags 2), so turning VBS off later works from Windows.
set "DG=HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard"
set "DGPOL=HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"
set "LSA=HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
set "input=%~1"
if defined input goto choose
cls
echo note: turning these off can improve performance at the cost of a layer of security
echo [1] Enable VBS and memory integrity (HVCI)
echo [2] Enable VBS only (memory integrity off)
echo [3] Disable VBS and memory integrity
set /p input=":"
:choose
if "%input%"=="1" goto enable
if "%input%"=="2" goto enable
if "%input%"=="3" goto disable
exit /b 2

:enable
reg add "%DGPOL%" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul
reg add "%DGPOL%" /v ConfigureSystemGuardLaunch /t REG_DWORD /d 1 /f >nul
for %%v in (RequirePlatformSecurityFeatures LsaCfgFlags ConfigureKernelShadowStacksLaunch HypervisorEnforcedCodeIntegrity) do reg delete "%DGPOL%" /v %%v /f >nul 2>&1
reg add "%DG%" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 1 /f >nul
reg add "%DG%\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f >nul
reg add "%LSA%" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul
bcdedit /set {current} vsmlaunchtype Auto >nul
bcdedit /set {current} hypervisorlaunchtype Auto >nul
if "%input%"=="2" goto hvcioff
reg add "%DG%\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul
reg add "%DG%\Scenarios\HypervisorEnforcedCodeIntegrity" /v HVCIMATRequired /t REG_DWORD /d 1 /f >nul
goto done

:disable
reg add "%DGPOL%" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul
for %%v in (RequirePlatformSecurityFeatures LsaCfgFlags ConfigureSystemGuardLaunch ConfigureKernelShadowStacksLaunch HypervisorEnforcedCodeIntegrity) do reg delete "%DGPOL%" /v %%v /f >nul 2>&1
reg add "%DG%" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul
reg add "%DG%" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f >nul
reg add "%DG%" /v Mandatory /t REG_DWORD /d 0 /f >nul
reg add "%DG%\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "%DG%\Scenarios\CredentialGuard" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "%LSA%" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul
bcdedit /set {current} vsmlaunchtype Off >nul

:hvcioff
reg add "%DG%\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "%DG%\Scenarios\HypervisorEnforcedCodeIntegrity" /v HVCIMATRequired /t REG_DWORD /d 0 /f >nul

:done
echo Done, restart your pc.
if "%~1"=="" pause
exit /b 0
