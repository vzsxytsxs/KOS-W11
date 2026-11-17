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
setlocal EnableExtensions
title PowerShell Logging Enable - Disable
:: Script Block Logging and Module Logging (policies in HKLM, 64 and 32-bit views). KOS default: on.
:: Events in: Event Viewer > Applications and Services Logs > Microsoft > Windows > PowerShell > Operational
::   4104 = text of each script block executed; 4103 = module command invocations.
:: Transcription is not part of this toggle: it would write every whole session to text files on disk.
:: Silent use: "PowerShell Logging Enable-Disable.cmd" 1 (enable) or 2 (disable). Exit 0 = ok, 1 = failure, 2 = invalid option.
set "SB=HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
set "SB32=HKLM\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
set "ML=HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
set "ML32=HKLM\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
set "fail=0"
call :state
echo.
echo [1] Enable PowerShell logging (KOS default)
echo [2] Disable PowerShell logging
set "input=%~1"
if not defined input set /p input=":"
if "%input%"=="1" goto e
if "%input%"=="2" goto d
exit /b 2

:e
for %%k in ("%SB%" "%SB32%") do (
    Reg.exe add %%k /v "EnableScriptBlockLogging" /t REG_DWORD /d "1" /f >nul || set "fail=1"
    Reg.exe delete %%k /v "EnableScriptBlockInvocationLogging" /f >nul 2>&1
)
for %%k in ("%ML%" "%ML32%") do (
    Reg.exe add %%k /v "EnableModuleLogging" /t REG_DWORD /d "1" /f >nul || set "fail=1"
    Reg.exe add "%%~k\ModuleNames" /v "*" /t REG_SZ /d "*" /f >nul || set "fail=1"
)
goto done

:d
for %%k in ("%SB%" "%SB32%") do Reg.exe add %%k /v "EnableScriptBlockLogging" /t REG_DWORD /d "0" /f >nul || set "fail=1"
for %%k in ("%ML%" "%ML32%") do Reg.exe add %%k /v "EnableModuleLogging" /t REG_DWORD /d "0" /f >nul || set "fail=1"
goto done

:done
call :state
if "%fail%"=="1" (
    echo Failed to write the policy. Run as administrator.
    if "%~1"=="" timeout /t 5 /nobreak
    exit /b 1
)
echo Done. New PowerShell windows use the new setting; no restart needed.
if "%~1"=="" timeout /t 3 /nobreak
exit /b 0

:state
:: Names that differ from SB/ML: cmd variables are case-insensitive.
set "sbState=off"
set "mlState=off"
reg query "%SB%" /v EnableScriptBlockLogging 2>nul | find "0x1" >nul && set "sbState=on"
reg query "%ML%" /v EnableModuleLogging 2>nul | find "0x1" >nul && set "mlState=on"
echo Current: script block logging %sbState%, module logging %mlState%
exit /b 0
