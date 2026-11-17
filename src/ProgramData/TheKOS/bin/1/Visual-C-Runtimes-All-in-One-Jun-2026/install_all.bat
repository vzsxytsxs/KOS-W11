@echo off
setlocal
pushd "%~dp0" || exit /b 2
set "KOS_INSTALL_RESULT=0"

echo.
echo Microsoft Visual C++ All-In-One Runtimes by W1zzard @ TechPowerUp
echo https://www.techpowerup.com/download/visual-c-redistributable-runtime-package-all-in-one/
echo.
echo Installing runtime packages...

set IS_X64=0
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set IS_X64=1
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set IS_X64=1
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set IS_X64=1

if "%IS_X64%" == "1" goto X64

echo 2005...
call :Install vcredist2005_x86.exe /q

echo 2008...
call :Install vcredist2008_x86.exe /qb

echo 2010...
call :Install vcredist2010_x86.exe /passive /norestart

echo 2012...
call :Install vcredist2012_x86.exe /passive /norestart

echo 2013...
call :Install vcredist2013_x86.exe /passive /norestart

echo v14 (2015-2026) ...
call :Install vcredist_v14.x86.exe /passive /norestart

goto END

:X64

echo 2005...
call :Install vcredist2005_x86.exe /q
call :Install vcredist2005_x64.exe /q

echo 2008...
call :Install vcredist2008_x86.exe /qb
call :Install vcredist2008_x64.exe /qb

echo 2010...
call :Install vcredist2010_x86.exe /passive /norestart
call :Install vcredist2010_x64.exe /passive /norestart

echo 2012...
call :Install vcredist2012_x86.exe /passive /norestart
call :Install vcredist2012_x64.exe /passive /norestart

echo 2013...
call :Install vcredist2013_x86.exe /passive /norestart
call :Install vcredist2013_x64.exe /passive /norestart

echo v14 (2015-2026) ...
call :Install vcredist_v14.x86.exe /passive /norestart
call :Install vcredist_v14.x64.exe /passive /norestart

goto END

:END

echo.
echo Installation finished with code %KOS_INSTALL_RESULT%

set "KOS_FINAL_RESULT=%KOS_INSTALL_RESULT%"
popd
endlocal & exit /b %KOS_FINAL_RESULT%

:Install
start /wait "" "%~dp0%~1" %2 %3
set "KOS_LAST_INSTALL=%errorlevel%"
if "%KOS_LAST_INSTALL%"=="0" exit /b 0
if "%KOS_LAST_INSTALL%"=="3010" (
    if "%KOS_INSTALL_RESULT%"=="0" set "KOS_INSTALL_RESULT=3010"
    exit /b 0
)
echo %~1 returned %KOS_LAST_INSTALL%
if "%KOS_INSTALL_RESULT%"=="0" set "KOS_INSTALL_RESULT=%KOS_LAST_INSTALL%"
if "%KOS_INSTALL_RESULT%"=="3010" set "KOS_INSTALL_RESULT=%KOS_LAST_INSTALL%"
exit /b 0
