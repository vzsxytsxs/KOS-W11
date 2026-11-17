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
title Increase User VA
color a
:home
cls
echo.
echo ------------------
echo - 1. Increase VA -
echo - 2. Default VA  -
echo ------------------
echo.
set /p menu=:
if %menu% EQU 1 goto e
if %menu% EQU 2 goto d
goto home

:e
bcdedit /set IncreaseUserVA 3072
exit

:d
bcdedit /deletevalue IncreaseUserVA
exit




