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
:: Windows Search, the same three options as the toolbox's "Windows Search". Usage: "Windows Search Enable-Disable.cmd" on, noindex or off.
:: on: the indexer (WSearch, delayed start) and the search app. noindex: indexer off, the search app stays.
:: off: also blocks the search app: SearchHost.exe renamed to .old (as the KOS first boot does) and redirected to systray.exe, which does nothing.
set "IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
set "APP=%SystemRoot%\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy"
set "input=%~1"
if defined input goto choose
echo [1] Enable Windows Search
echo [2] Disable indexing only
echo [3] Disable Windows Search
set /p input=":"
:choose
if "%input%"=="1" set "input=on"
if "%input%"=="2" set "input=noindex"
if "%input%"=="3" set "input=off"
if /i "%input%"=="on" goto on
if /i "%input%"=="noindex" goto noindex
if /i "%input%"=="off" goto off
exit /b 2

:on
PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v DelayedAutoStart /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Search" /v SetupCompletedSuccessfully /t REG_DWORD /d 1 /f >nul 2>&1
call :app on
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode 2>nul | findstr /r /c:"0x0$" >nul && reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f >nul
sc start WSearch >nul 2>&1
goto done

:noindex
sc stop WSearch >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
call :app on
goto done

:off
sc stop WSearch >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f >nul
call :app off
goto done

:done
echo Done, restart your computer.
if "%~1"=="" pause
exit /b 0

:: The search app: an IFEO redirect for the three names Windows has used, and SearchHost.exe renamed like the KOS first boot.
:: If an update brought SearchHost.exe back next to the .old copy, the copy goes.
:app
for %%E in (SearchApp.exe SearchUI.exe SearchHost.exe) do (
    if /i "%~1"=="off" (
        reg add "%IFEO%\%%E" /v Debugger /t REG_SZ /d "%%SystemRoot%%\System32\systray.exe" /f >nul
    ) else (
        reg delete "%IFEO%\%%E" /v Debugger /f >nul 2>&1
    )
)
set "exe=%APP%\SearchHost.exe"
set "old=%APP%\SearchHost.old"
if exist "%old%" if exist "%exe%" call :own "%old%" && del /f /q "%old%" >nul 2>&1
if /i "%~1"=="off" (
    taskkill /f /im SearchHost.exe >nul 2>&1
    if exist "%exe%" call :own "%exe%" && ren "%exe%" SearchHost.old
) else (
    if exist "%old%" call :own "%old%" && ren "%old%" SearchHost.exe
)
exit /b 0

:own
takeown /f "%~1" /a >nul 2>&1
icacls "%~1" /grant *S-1-5-32-544:F >nul 2>&1
exit /b 0
