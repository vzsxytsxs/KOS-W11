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
title Drivers IntelPPM - AmdPPM
mode con: cols=75 lines=15
color a
:home
cls

set "PPM="
for /f "delims=" %%a in ('wmic cpu get name') do (
    echo %%a | findstr /i "AMD" >nul && set "PPM=AmdPPM"
    echo %%a | findstr /i "Intel" >nul && set "PPM=IntelPPM"
)

:drv
echo ----------------------------------------------------------------------
echo This is experimental, as you may get or have performance problems,   -
echo BSODs, possible causes are: Stuttering or Micro-Stuttering.          -
echo This can have great variability in any system.                       -
echo ----------------------------------------------------------------------
echo.
echo --------------------------------
echo - 1) %PPM% Enabled (Default)  -
echo - 2) %PPM% Disabled           -
echo --------------------------------
set /p option=:
if %option%==1 (
    cls
    reg add "HKLM\System\CurrentControlSet\Services\%PPM%" /v "Start" /t REG_DWORD /d "3" /f
) else if %option%==2 (
    cls
    reg add "HKLM\System\CurrentControlSet\Services\%PPM%" /v "Start" /t REG_DWORD /d "4" /f
    exit
) else (
    cls
    goto :drv
)
echo Done, restart your computer and test it.
timeout /t 3 /nobreak
exit
