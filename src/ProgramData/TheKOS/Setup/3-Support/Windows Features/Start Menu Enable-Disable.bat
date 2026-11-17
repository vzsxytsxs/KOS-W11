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
title Enable/Disable StartMenuExperienceHost.exe
:: 1 = Windows Start menu on, Open-Shell off; 2 = Windows Start menu off, Open-Shell on. Without an argument it asks.
set "SMEH=%SystemRoot%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy"
set "OPENSHELL=%ProgramFiles%\Open-Shell\StartMenu.exe"
set "OSKEY=HKCU\Software\OpenShell\StartMenu\Settings"
echo [1] Enable Start Menu
echo [2] Disable Start Menu
set "input=%~1"
if not defined input set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else (
    exit /b 2
)

:e
if "%~1"=="" cls
cd /d %SystemRoot%
PowerRun.exe /SW:0 powershell.exe Rename-Item -Path "%SMEH%\StartMenuExperienceHost.old" -NewName "StartMenuExperienceHost.exe"
:: PowerRun returns before the rename is done: Open-Shell is only turned off once the Windows Start menu is back.
for /l %%i in (1,1,20) do (
    if exist "%SMEH%\StartMenuExperienceHost.exe" goto e_openshell
    ping -n 2 127.0.0.1 >nul
)
echo The Windows Start menu could not be restored, so Open-Shell was left on.
if "%~1"=="" pause
exit /b 1

:e_openshell
if not exist "%OPENSHELL%" goto e_done
:: Open-Shell stays installed: AutoStart 0 is its "Start automatically for this user" option.
reg add "%OSKEY%" /v AutoStart /t REG_DWORD /d 0 /f >nul
"%OPENSHELL%" -exit
for /l %%i in (1,1,5) do (
    call :running || goto e_done
    ping -n 2 127.0.0.1 >nul
)
echo Open-Shell is still running (it was busy) and closes when you sign out. It won't start again.
:e_done
echo done
if "%~1"=="" pause
exit /b 0

:d
if "%~1"=="" cls
cd /d %SystemRoot%
if not exist "%OPENSHELL%" (
    echo Open-Shell is not installed.
    goto d_off
)
reg delete "%OSKEY%" /v AutoStart /f >nul 2>&1
:: Started through Explorer, so it doesn't inherit this script's elevation.
call :running || explorer.exe "%OPENSHELL%"
:d_off
PowerRun.exe /SW:0 taskkill.exe /im "StartMenuExperienceHost.exe" /t /f
PowerRun.exe /SW:0 powershell.exe Rename-Item -Path "%SMEH%\StartMenuExperienceHost.exe" -NewName "StartMenuExperienceHost.old"
:: PowerRun returns before the rename is done: wait for it before reporting.
for /l %%i in (1,1,20) do (
    if exist "%SMEH%\StartMenuExperienceHost.old" if not exist "%SMEH%\StartMenuExperienceHost.exe" goto d_done
    ping -n 2 127.0.0.1 >nul
)
echo The Windows Start menu could not be turned off.
if "%~1"=="" pause
exit /b 1

:d_done
echo done
if "%~1"=="" pause
exit /b 0

:running
tasklist /fi "imagename eq StartMenu.exe" /fi "username eq %USERDOMAIN%\%USERNAME%" 2>nul | find /i "StartMenu.exe" >nul
exit /b %errorlevel%
