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

:: Menu for user selection
echo Select an option for Kernel Worker Threads:
echo 1. Default (0) - Windows manages thread count automatically
echo 2. Per Core (1) - Adds one thread per logical processor
echo 3. Maximum (2) - Adds two threads per logical processor
set /p choice=Enter your choice (1-3): 

:: Determine the corresponding values
if "%choice%"=="1" (
    set value=0
) else if "%choice%"=="2" (
    set value=1
) else if "%choice%"=="3" (
    set value=2
) else (
    echo Invalid choice. Exiting.
    exit /b
)

:: Apply registry modifications
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v AdditionalCriticalWorkerThreads /t REG_DWORD /d %value% /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v AdditionalDelayedWorkerThreads /t REG_DWORD /d %value% /f

echo Kernel Worker Threads setting applied successfully.
pause
