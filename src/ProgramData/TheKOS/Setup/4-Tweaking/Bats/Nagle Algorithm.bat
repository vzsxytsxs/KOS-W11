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
color a
title Nagle Algorithm
:home
cls
echo.
echo ------------------------------
echo - PLEASE READ THIS CAREFULLY -
echo ------------------------------
timeout /t 2 /nobreak >nul
echo Enabling or disabling the Nagle Algorithm can improve or hurt your connection. SHOULD BE TESTED
echo Enabling it, data is buffered until it's larger than the MSS size (value close to MTU), 
echo this can lead to higher latencies.
echo Disabling it no data is buffered but under load it can become congested and consequently lose internet connection.
echo.
echo.
echo ----------------------------------------
echo - 1. Enable Nagle Algorithm            -
echo - 2. Disable Nagle Algorithm           -
echo ----------------------------------------
set /p menu=Enter an option:
if %menu% EQU 1 goto e
if %menu% EQU 2 goto d
goto home

:: Every TCP/IP interface, read from the registry (wmic, used before, is gone from current Windows). The toolbox's
:: "Nagle's algorithm" writes the same values.
:e
for /f "delims=" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul') do if /i not "%%i"=="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" (
    reg delete "%%i" /v "TcpAckFrequency" /f >nul 2>&1
    reg delete "%%i" /v "TcpDelAckTicks" /f >nul 2>&1
    reg delete "%%i" /v "TCPNoDelay" /f >nul 2>&1
)
timeout /t 2 /nobreak >NUL 2>&1
exit

:d
for /f "delims=" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul') do if /i not "%%i"=="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" (
    reg add "%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f >nul
    reg add "%%i" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f >nul
    reg add "%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f >nul
)
timeout /t 2 /nobreak >NUL 2>&1
exit
