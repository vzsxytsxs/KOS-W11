@echo off
setlocal
pushd "%~dp0" || exit /b 2

echo.
echo DirectX Redistributable 1-Click Installer by W1zzard @ TechPowerUp
echo https://www.techpowerup.com/download/directx-redistributable-runtime/
echo.
echo Installing runtime packages...

echo Installing DirectX Runtimes

start /wait "" "%~dp0dxsetup.exe" /silent
set "KOS_DIRECTX_RESULT=%errorlevel%"
popd
endlocal & exit /b %KOS_DIRECTX_RESULT%
