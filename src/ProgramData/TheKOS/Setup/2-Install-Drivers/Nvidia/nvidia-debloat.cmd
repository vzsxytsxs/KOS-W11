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
:: Driver Debloat from nvidia_tool.cmd (option 5 > 2), without prompts, for the KOS Toolbox (GPU > Tweaks tab).
:: Usage: nvidia-debloat.cmd keepapp   (has GeForce Experience/NVIDIA app)
::        nvidia-debloat.cmd removeapp (does not: also removes the GeForce/NVIDIA app components)
:: Each removed file/folder gets owner and permission only for itself; the original gave the user full control over
:: whole folders (DriverStore, nv*.* in System32). The original's System32\lxss (WSL) folder was left out: it is not NVIDIA's.
setlocal
if /i not "%~1"=="keepapp" if /i not "%~1"=="removeapp" (
    echo Usage: %~nx0 keepapp^|removeapp
    exit /b 2
)
set "REPO=%SystemRoot%\System32\DriverStore\FileRepository"

if /i "%~1"=="removeapp" (
    echo [+] Removing GeForce components
    call :rd "%ProgramFiles%\NVIDIA Corporation"
    for /d %%D in ("%REPO%\nv_*") do (
        call :del "%%D\nvFBC*.dll"
        call :del "%%D\nvIFR*.dll"
        call :del "%%D\Display.NvContainer\plugins\Session\_NvGSTPlugin.dll"
    )
    call :del "%SystemRoot%\System32\NvFBC64.dll"
    call :del "%SystemRoot%\System32\NvIFR64.dll"
    call :del "%SystemRoot%\SysWOW64\NvFBC.dll"
    call :del "%SystemRoot%\SysWOW64\NvIFR.dll"
)

echo [+] Removing telemetry and unused driver components
call :rd "%SystemRoot%\System32\drivers\NVIDIA Corporation"
for /r "%REPO%" %%F in (NvTelemetry64.dll) do if exist "%%F" call :del "%%F"
reg add "HKCU\SOFTWARE\NVIDIA Corporation\NVControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d "0" /f >nul 2>&1
reg delete "HKLM\System\ControlSet001\Services\nvlddmkm\NvCamera" /f >nul 2>&1
for /d %%D in ("%REPO%\nv_*") do (
    call :rd "%%D\NVWMI"
    call :rd "%%D\NvCamera"
    for %%P in (nvptxJitCompiler32.dll nvptxJitCompiler64.dll nvsmartmax*.* nvinfo.pb nvIccAdvancedColorIdentity.icm nvEncMFT*.dll nvDevMFT*.dll) do call :del "%%D\%%P"
    call :del "%%D\Display.NvContainer\nvtopps.db3"
    call :del "%%D\Display.NvContainer\plugins\LocalSystem\_DisplayDriverRAS.dll"
    call :del "%%D\Display.NvContainer\plugins\LocalSystem\_nvtopps.dll"
    call :del "%%D\Display.NvContainer\plugins\Session\nvprofileupdaterplugin.dll"
)
for %%P in (nvinfo.pb MCU.exe nvcudadebugger.dll nvdebugdump.exe) do call :del "%SystemRoot%\System32\%%P"
sc config NVDisplay.ContainerLocalSystem start= auto >nul 2>&1
sc start NVDisplay.ContainerLocalSystem >nul 2>&1
echo [=] All done.
exit /b 0

:del
:: File (wildcard only in the name): owner and Administrators permission only on it, then delete. In use = stays.
if not exist "%~1" exit /b 0
echo     %~1
takeown /f "%~1" >nul 2>&1
icacls "%~1" /grant *S-1-5-32-544:F >nul 2>&1
del /f /q "%~1" >nul 2>&1
exit /b 0

:rd
if not exist "%~1\" exit /b 0
echo     %~1
takeown /f "%~1" /r /d Y >nul 2>&1
icacls "%~1" /grant *S-1-5-32-544:F /t >nul 2>&1
rmdir /s /q "%~1" >nul 2>&1
exit /b 0
