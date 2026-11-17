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
title Enable/Disable TextInputHost
echo [1] Enable TextInputHost
echo [2] Disable TextInputHost
set /p input=":"
if "%input%"=="1" (
    goto e
) else if "%input%"=="2" (
    goto d
) else (
    exit
)

:e
PowerRun.exe /SW:0 Reg.exe del "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\TextInputHost.exe" /f
PowerRun.exe /SW:0 Reg.exe del "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\WindowsInternal.ComposableShell.Experiences.TextInput.InputApp.exe" /f
exit

:d
PowerRun.exe /SW:0 Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\TextInputHost.exe" /v Debugger /d "%SystemRoot%\system32\systray.exe" /f
PowerRun.exe /SW:0 taskkill.exe /im "TextInputHost.exe" /t /f
PowerRun.exe /SW:0 Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\WindowsInternal.ComposableShell.Experiences.TextInput.InputApp.exe" /v Debugger /d "%SystemRoot%\system32\systray.exe" /f
PowerRun.exe /SW:0 taskkill.exe /im "WindowsInternal.ComposableShell.Experiences.TextInput.InputApp.exe" /t /f 
PowerRun.exe /SW:0 Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\WindowsInternal.ComposableShell.Experiences.TextInput.InputApp.exe" /v Debugger /f
exit
