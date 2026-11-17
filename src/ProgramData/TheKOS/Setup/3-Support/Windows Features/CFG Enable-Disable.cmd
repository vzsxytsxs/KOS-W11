@echo off
setlocal EnableExtensions
if "%~1"=="" goto state
if /i not "%~1"=="on" if /i not "%~1"=="off" exit /b 2
fltmc >nul 2>&1 && goto admin
set "KOS_SCRIPT=%~f0"
set "KOS_SCRIPT_ARGS=%~1"
powershell.exe -NoProfile -Command "try { $p=Start-Process -Verb RunAs -Wait -PassThru -FilePath $env:KOS_SCRIPT -ArgumentList $env:KOS_SCRIPT_ARGS; exit $p.ExitCode } catch { exit 1 }"
exit /b %errorlevel%

:admin
:: On clears the CFG override (bits 40-41 of MitigationOptions, so byte 5) back to the Windows default.
:: Set-ProcessMitigation -System -Remove -Disable CFG fails with C000000D on current builds and changes nothing.
if /i "%~1"=="on" (
    powershell.exe -NoProfile -Command "try { $k='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; $m=(Get-ItemProperty -LiteralPath $k -ErrorAction Stop).MitigationOptions; if ($m -is [byte[]] -and $m.Length -gt 5) { $m[5]=$m[5] -band 0xFC; Set-ItemProperty -LiteralPath $k -Name MitigationOptions -Value $m -Type Binary -ErrorAction Stop }; if ((Get-ProcessMitigation -System).CFG.Enable.ToString() -eq 'OFF') { exit 1 } } catch { exit 1 }"
) else (
    powershell.exe -NoProfile -Command "try { Set-ProcessMitigation -System -Disable CFG -ErrorAction Stop; if ((Get-ProcessMitigation -System).CFG.Enable.ToString() -ne 'OFF') { exit 1 } } catch { exit 1 }"
)
exit /b %errorlevel%

:state
powershell.exe -NoProfile -Command "(Get-ProcessMitigation -System).CFG.Enable"
exit /b %errorlevel%
