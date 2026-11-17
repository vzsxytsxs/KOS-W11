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
setlocal EnableExtensions DisableDelayedExpansion
cls
call :showGdidStatus
echo.
echo [1] Enable MS-Store
echo [2] Disable MS-Store
set /p input=":"
if "%input%"=="1" (
    goto enable
) else if "%input%"=="2" (
    goto disable
) else (
    exit
)

:: The Store's own install services. Disable leaves AppXSvc, ClipSVC and LicenseManager alone: every Store and MSIX app
:: (Calculator, Photos, Notepad, Terminal) and the KOS Toolbox's Store downloader need them. Windows Hello (NgcSvc,
:: NgcCtnrSvc), IP Helper and Windows Update's download services (dosvc, bits) aren't part of the Store and stay as they are.
:disable
for %%s in (InstallService PushToInstall) do (
  PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\%%s" /v "Start" /t REG_DWORD /d "4" /f
)

echo restart your pc
pause
exit /b

:enable
for %%s in (InstallService PushToInstall AppXSvc ClipSVC LicenseManager) do (
  PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\%%s" /v "Start" /t REG_DWORD /d "3" /f
)

echo The Store app downloads through Windows Update's services: to download from it, run
echo Windows Update Enable-Disable.cmd and choose [4] Enable Microsoft Store downloads.
echo restart your pc
pause
exit /b

:showGdidStatus
set "gdidState="
set "hostsBlock="
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\TheKOS" /v GDIDTRACKING 2^>nul') do if /i "%%A"=="REG_SZ" set "gdidState=%%B"
set "hostsDir=%SystemRoot%\System32\drivers\etc"
if exist "%hostsDir%\hosts_1" if not exist "%hostsDir%\hosts_gdid" set "hostsBlock=1"
if exist "%hostsDir%\hosts_gdid" if not exist "%hostsDir%\hosts_1" set "hostsBlock=0"
if not exist "%hostsDir%\hosts" set "hostsBlock="
if exist "%hostsDir%\hosts_1.tmp" set "hostsBlock="
if exist "%hostsDir%\hosts_gdid.tmp" set "hostsBlock="
if "%gdidState%:%hostsBlock%"=="1:1" (
  echo [GDID] Domain blocking: ENABLED. Store sign-in or downloads may fail.
  echo        To disable the block, run GDID-Tracking.cmd option 2 and restart.
) else if "%gdidState%:%hostsBlock%"=="0:0" (
  echo [GDID] Domain blocking: DISABLED. GDID is not blocking Store domains.
  echo        To enable the block later, run GDID-Tracking.cmd option 1 and restart.
) else (
  echo [GDID] Inconsistent or unknown state ^(registry=%gdidState%, hosts=%hostsBlock%^).
  echo        Check GDID-Tracking.cmd and the hosts files before using the Store.
)
exit /b 0
