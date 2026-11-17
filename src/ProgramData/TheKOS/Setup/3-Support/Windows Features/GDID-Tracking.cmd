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
title GDID Tracking - Enable or Disable

set "HOSTS_DIR=%SystemRoot%\System32\drivers\etc"
set "ERRORS=0"

where.exe PowerRun.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerRun.exe was not found.
    echo Run this script from the normal TheKOS environment.
    goto :failure
)

if "%~1"=="1" goto :disable
if "%~1"=="2" goto :enable
if not "%~1"=="" (
    echo [ERROR] Invalid argument "%~1". Use 1 to disable or 2 to enable.
    goto :failure
)

echo [1] Disable GDID Tracking ^(default^)
echo [2] Enable GDID Tracking
choice /c 12 /n /m "Select an option [1-2]: "

if errorlevel 2 goto :enable
if errorlevel 1 goto :disable
goto :cancelled

:enable
echo.
echo Enabling GDID Tracking...
call :SetServiceStart "CDPSvc" 2
call :SetServiceStart "CDPUserSvc" 2
call :SetServiceStart "wlidsvc" 3
call :EnableHosts
goto :finish_enable

:disable
echo.
echo Disabling GDID Tracking...
call :SetServiceStart "CDPSvc" 4
call :SetServiceStart "CDPUserSvc" 4
call :SetServiceStart "wlidsvc" 4
call :DisableHosts
goto :finish_disable

:finish_enable
if not "%ERRORS%"=="0" goto :partial_failure
call :SetTrackingState 0
if not "%ERRORS%"=="0" goto :partial_failure
echo.
echo GDID Tracking was enabled successfully.
goto :restart_notice

:finish_disable
if not "%ERRORS%"=="0" goto :partial_failure
call :SetTrackingState 1
if not "%ERRORS%"=="0" goto :partial_failure
echo.
echo GDID Tracking was disabled successfully.
goto :restart_notice

:SetServiceStart
PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Could not update the %~1 service.
    set /a ERRORS+=1
)
exit /b 0

:SetTrackingState
PowerRun.exe /SW:0 Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "GDIDTRACKING" /t REG_SZ /d "%~1" /f >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Could not update the GDIDTRACKING state.
    set /a ERRORS+=1
)
exit /b 0

:EnableHosts
if not exist "%HOSTS_DIR%\hosts" goto :missing_active_hosts
if exist "%HOSTS_DIR%\hosts_gdid.tmp" goto :temporary_hosts_file
if exist "%HOSTS_DIR%\hosts_1.tmp" goto :temporary_hosts_file
if exist "%HOSTS_DIR%\hosts_gdid" if not exist "%HOSTS_DIR%\hosts_1" (
    echo The GDID hosts configuration is already enabled.
    exit /b 0
)
if exist "%HOSTS_DIR%\hosts_gdid" if exist "%HOSTS_DIR%\hosts_1" goto :ambiguous_hosts
if not exist "%HOSTS_DIR%\hosts_1" goto :missing_hosts_backup

move /y "%HOSTS_DIR%\hosts" "%HOSTS_DIR%\hosts_gdid.tmp" >nul 2>&1
if errorlevel 1 goto :hosts_move_failed
move /y "%HOSTS_DIR%\hosts_1" "%HOSTS_DIR%\hosts" >nul 2>&1
if errorlevel 1 (
    move /y "%HOSTS_DIR%\hosts_gdid.tmp" "%HOSTS_DIR%\hosts" >nul 2>&1
    goto :hosts_move_failed
)
move /y "%HOSTS_DIR%\hosts_gdid.tmp" "%HOSTS_DIR%\hosts_gdid" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] The hosts file was changed, but its GDID backup could not be named.
    set /a ERRORS+=1
)
exit /b 0

:DisableHosts
if not exist "%HOSTS_DIR%\hosts" goto :missing_active_hosts
if exist "%HOSTS_DIR%\hosts_gdid.tmp" goto :temporary_hosts_file
if exist "%HOSTS_DIR%\hosts_1.tmp" goto :temporary_hosts_file
if exist "%HOSTS_DIR%\hosts_1" if not exist "%HOSTS_DIR%\hosts_gdid" (
    echo The GDID hosts configuration is already disabled.
    exit /b 0
)
if exist "%HOSTS_DIR%\hosts_1" if exist "%HOSTS_DIR%\hosts_gdid" goto :ambiguous_hosts
if not exist "%HOSTS_DIR%\hosts_gdid" goto :missing_hosts_backup

move /y "%HOSTS_DIR%\hosts" "%HOSTS_DIR%\hosts_1.tmp" >nul 2>&1
if errorlevel 1 goto :hosts_move_failed
move /y "%HOSTS_DIR%\hosts_gdid" "%HOSTS_DIR%\hosts" >nul 2>&1
if errorlevel 1 (
    move /y "%HOSTS_DIR%\hosts_1.tmp" "%HOSTS_DIR%\hosts" >nul 2>&1
    goto :hosts_move_failed
)
move /y "%HOSTS_DIR%\hosts_1.tmp" "%HOSTS_DIR%\hosts_1" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] The hosts file was changed, but its normal backup could not be named.
    set /a ERRORS+=1
)
exit /b 0

:ambiguous_hosts
echo [ERROR] Both hosts_1 and hosts_gdid exist. The hosts state is ambiguous.
set /a ERRORS+=1
exit /b 0

:missing_hosts_backup
echo [ERROR] The required alternate hosts file was not found in "%HOSTS_DIR%".
set /a ERRORS+=1
exit /b 0

:missing_active_hosts
echo [ERROR] The active hosts file was not found in "%HOSTS_DIR%".
set /a ERRORS+=1
exit /b 0

:temporary_hosts_file
echo [ERROR] A temporary hosts file from an earlier operation still exists.
echo Resolve the .tmp file in "%HOSTS_DIR%" before trying again.
set /a ERRORS+=1
exit /b 0

:hosts_move_failed
echo [ERROR] Could not switch the hosts file. Check administrator permissions.
set /a ERRORS+=1
exit /b 0

:partial_failure
echo.
echo [ERROR] The operation was not completed. One or more changes may have been applied.
goto :failure

:restart_notice
echo Restart your computer to apply all changes.
timeout /t 3 /nobreak >nul
endlocal & exit /b 0

:cancelled
echo.
echo Operation cancelled.
endlocal & exit /b 1

:failure
echo.
if not "%~1"=="" (
    endlocal
    exit /b 1
)
pause
endlocal & exit /b 1
