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
tittle Firewall Enabled - Disabled
echo [1] Enable Firewall
echo [2] Disable Firewall
set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else (
    exit
)

:e
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mpssvc" /v "Start" /t REG_DWORD /d "2" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "2" /f
echo Done, restart your computer.
timeout /t 3 /nobreak
exit

:d
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\mpssvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "4" /f
echo Done, restart your computer.
timeout /t 3 /nobreak
exit
