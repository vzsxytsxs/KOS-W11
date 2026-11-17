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
setlocal enabledelayedexpansion
set "work_path=%ProgramData%\TheKOS\bin"

echo This updater only updates system tweaks. If there are any changes directly to the ISO, they will not be applied by the updater.
pause

del "%work_path%\update.cmd"
cls

:: read current version
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\TheKOS" /v currentver') do set current_ver=%%B

:: check if a new version is available
curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/updates/latest_os.txt" -o "%work_path%\latest_update.txt" --connect-timeout 300 2>nul
if exist "%work_path%\latest_update.txt" (
    set /p latest_ver=<"%work_path%\latest_update.txt"
    del /f /q "%work_path%\latest_update.txt" >nul 2>&1
    set /a current_ver_num=!current_ver!
    set /a latest_ver_num=!latest_ver!
    goto :check_ver
) else (
    echo make sure that you are connected to internet 
    pause
    exit
)

:check_ver
if %current_ver_num% LSS %latest_ver_num% (
    echo New Update Found / Update: %latest_ver_num%
    timeout /t 4 >nul 
    goto :download_update
) else (
    echo No updates found, you are already on the latest version.
    pause
    exit
)

:download_update
echo Downloading New Update
curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/updates/update_%latest_ver%.cmd" -o "%work_path%\update.cmd" --connect-timeout 300 2>nul
if exist "%work_path%\update.cmd" (
    start %work_path%\update.cmd
    exit
) else (
    echo The update cannot be downloaded.
    pause
    exit
)
