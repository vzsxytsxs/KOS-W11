@echo off
setlocal EnableExtensions EnableDelayedExpansion
title KOS Security Profile - Basic / Advanced
:: KOS security profile (README, "Security profiles" section). RunOnce calls this script on the first boot
:: with the user's choice; afterwards it is used to switch profiles. Everything takes effect after a restart.
::   Basic   = Windows protections: UAC, DEP, CFG, Spectre/Meltdown and per-process mitigations, VBS as Windows
::             leaves it, hypervisor available, driver DMA remapping and firewall rules.
::   Advanced = those protections turned off (KOS behavior up to 4.0.0).
:: Usage: "Security Profile Basic-Advanced.cmd" basic^|advanced (or 1^|2; with no argument it shows the menu)
::        RunOnce passes "--first-boot" as the second argument.
:: Exit: 0 = applied, 1 = some step failed or not administrator, 2 = invalid option.

fltmc >nul 2>&1 && goto admin
set "KOS_SCRIPT=%~f0"
set "KOS_SCRIPT_ARGS=%*"
powershell.exe -NoProfile -Command "try { $a=@{}; if ($env:KOS_SCRIPT_ARGS) { $a.ArgumentList=$env:KOS_SCRIPT_ARGS }; $p=Start-Process -FilePath $env:KOS_SCRIPT -Verb RunAs -Wait -PassThru @a; exit $p.ExitCode } catch { exit 1 }"
exit /b %errorlevel%

:admin
set "POL=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
set "MM=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
set "DG=HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard"
set "DGPOL=HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"
set "LSA=HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
set "previous="
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\TheKOS" /v Profile 2^>nul ^| findstr /i "REG_SZ"') do set "previous=%%B"
call :state

set "input=%~1"
if defined input goto choose
echo.
echo  [1] Basic   - keeps UAC, DEP, CFG, Spectre/Meltdown and process mitigations, VBS as Windows
echo                sets it, the hypervisor, DMA remapping and the firewall rules.
echo  [2] Advanced - turns all of those off for the lowest overhead. Some anti-cheats
echo                such as FACEIT and Vanguard may refuse to run.
echo  Restart the computer after switching.
set /p "input=: "
:choose
if "!input!"=="1" set "input=basic"
if "!input!"=="2" set "input=advanced"
if /i "!input!"=="extreme" set "input=advanced"
if /i "!input!"=="basic" goto basic
if /i "!input!"=="advanced" goto advanced
exit /b 2

:: ======================================================================== Basic
:basic
set "failed=0"
echo Applying the Basic profile...
:: UAC at the Windows default values. The NTLite preset leaves UAC off so boot.bat and RunOnce run
:: as administrator without a prompt; this step turns it back on and takes effect from the next boot.
for %%v in ("EnableLUA 1" "ConsentPromptBehaviorAdmin 5" "ConsentPromptBehaviorUser 3" "PromptOnSecureDesktop 1" "EnableInstallerDetection 1" "EnableVirtualization 1" "FilterAdministratorToken 0") do (
    for /f "tokens=1,2" %%a in (%%v) do reg add "%POL%" /v %%a /t REG_DWORD /d %%b /f >nul || set "failed=1"
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\luafv" /v Start /t REG_DWORD /d 2 /f >nul || set "failed=1"
:: DEP and hypervisor at the default.
bcdedit /set {current} nx OptIn >nul || set "failed=1"
bcdedit /set {current} hypervisorlaunchtype Auto >nul || set "failed=1"
call "%~dp0CFG Enable-Disable.cmd" on || set "failed=1"
:: Spectre/Meltdown: the documented "mitigations on" values (override 0, mask 3).
reg delete "%MM%" /v FeatureSettings /f >nul 2>&1
reg add "%MM%" /v FeatureSettingsOverride /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "%MM%" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul || set "failed=1"
call :feature process on || set "failed=1"
:: VBS and memory integrity: removes only what Advanced writes (0 values); what Windows turned on at OOBE stays.
call :deleteIfZero "%DGPOL%" EnableVirtualizationBasedSecurity
call :deleteIfZero "%DG%" EnableVirtualizationBasedSecurity
call :deleteIfZero "%DG%" RequirePlatformSecurityFeatures
call :deleteIfZero "%DG%\Scenarios\HypervisorEnforcedCodeIntegrity" Enabled
call :deleteIfZero "%DG%\Scenarios\HypervisorEnforcedCodeIntegrity" HVCIMATRequired
call :deleteIfZero "%LSA%" LsaCfgFlags
call :deleteIfZero "%DG%" Mandatory
call :deleteIfZero "%DG%\Scenarios\SystemGuard" Enabled
call :deleteIfZero "%DG%\Scenarios\CredentialGuard" Enabled
bcdedit /enum {current} | findstr /r /c:"^vsmlaunchtype  *Off" >nul && bcdedit /deletevalue {current} vsmlaunchtype >nul
:: DMA remapping: restores the values Advanced saved before zeroing them.
call :feature dma on || set "failed=1"
:: Firewall: Advanced (and KOS up to 4.0.0) deletes all the rules. On leaving it, the netsh reset brings back the
:: default rules (with the KOS telemetry blocks, which the .reg also writes to Defaults). On the first boot the rules
:: are intact and nothing is done.
if /i not "%~2"=="--first-boot" if /i not "!previous!"=="basic" (
    call :feature firewall on || set "failed=1"
)
reg add "HKLM\SOFTWARE\TheKOS" /v Profile /t REG_SZ /d basic /f >nul || set "failed=1"
goto done

:: ======================================================================== Advanced
:advanced
set "failed=0"
echo Applying the Advanced profile...
:: UAC off, as the NTLite preset leaves it, and without UAC file virtualization (luafv).
for %%v in ("EnableLUA 0" "ConsentPromptBehaviorAdmin 0" "ConsentPromptBehaviorUser 0" "PromptOnSecureDesktop 0" "EnableInstallerDetection 0" "EnableVirtualization 0" "FilterAdministratorToken 0") do (
    for /f "tokens=1,2" %%a in (%%v) do reg add "%POL%" /v %%a /t REG_DWORD /d %%b /f >nul || set "failed=1"
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\luafv" /v Start /t REG_DWORD /d 4 /f >nul || set "failed=1"
bcdedit /set {current} nx AlwaysOff >nul || set "failed=1"
bcdedit /set {current} hypervisorlaunchtype Off >nul || set "failed=1"
call "%~dp0CFG Enable-Disable.cmd" off || set "failed=1"
:: Spectre v2 and Meltdown off (Intel only, as KOS has always done).
reg query "HKLM\HARDWARE\DESCRIPTION\System\CentralProcessor\0" /v VendorIdentifier 2>nul | find /i "GenuineIntel" >nul && (
    reg add "%MM%" /v FeatureSettings /t REG_DWORD /d 1 /f >nul || set "failed=1"
    reg add "%MM%" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul || set "failed=1"
    reg add "%MM%" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul || set "failed=1"
)
:: Mitigations off in the processes below (each "2" digit = always off).
call :feature process off || set "failed=1"
:: VBS, memory integrity and Credential Guard off.
reg delete "%DGPOL%" /v RequirePlatformSecurityFeatures /f >nul 2>&1
reg add "%DGPOL%" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul || set "failed=1"
for %%v in (ConfigureSystemGuardLaunch ConfigureKernelShadowStacksLaunch HypervisorEnforcedCodeIntegrity LsaCfgFlags) do reg delete "%DGPOL%" /v %%v /f >nul 2>&1
reg add "%DG%" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "%DG%" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "%DG%\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "%DG%\Scenarios\HypervisorEnforcedCodeIntegrity" /v HVCIMATRequired /t REG_DWORD /d 0 /f >nul || set "failed=1"
reg add "%LSA%" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul || set "failed=1"
bcdedit /set {current} vsmlaunchtype Off >nul || set "failed=1"
:: DMA remapping off in the drivers that declare the value; the original is saved for Basic to restore.
call :feature dma off || set "failed=1"
:: Firewall rules deleted (the firewall stays on, with no rules).
call :feature firewall off || set "failed=1"
reg add "HKLM\SOFTWARE\TheKOS" /v Profile /t REG_SZ /d advanced /f >nul || set "failed=1"
goto done

:done
:: Under RunOnce it does not ask to restart: RunOnce restarts by itself at the end, and restarting earlier interrupts the post-install.
if "!failed!"=="1" (
    echo Some steps failed. Check that the script runs as administrator.
) else if /i "%~2"=="--first-boot" (
    echo Done.
) else (
    echo Done. Restart the computer to apply the profile.
)
if "%~1"=="" pause
exit /b !failed!

:: ======================================================================== helpers
:state
set "uac=?"
set "dep=?"
for /f "tokens=3" %%a in ('reg query "%POL%" /v EnableLUA 2^>nul ^| findstr /i "REG_DWORD"') do if "%%a"=="0x1" (set "uac=on") else set "uac=off"
for /f "tokens=2" %%a in ('bcdedit /enum {current} ^| findstr /r /c:"^nx "') do set "dep=%%a"
if defined previous (
    echo Current profile: !previous!   UAC: !uac!   DEP: !dep!
) else (
    echo Current profile: not recorded, KOS 4.0.0 or older behaves as Advanced   UAC: !uac!   DEP: !dep!
)
exit /b 0

:deleteIfZero
reg query "%~1" /v %~2 2>nul | findstr /r /c:"REG_DWORD *0x0$" >nul || exit /b 0
reg delete "%~1" /v %~2 /f >nul 2>&1 || set "failed=1"
exit /b 0

:feature
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Security Feature Toggle.ps1" %~1 %~2
exit /b %errorlevel%
