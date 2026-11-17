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
:: eva source
echo Splitting audio services...
copy /y "%windir%\System32\svchost.exe" "%windir%\System32\audiosvchost.exe" > NUL 2>&1
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Audiosrv" /v "ImagePath" /t REG_EXPAND_SZ /d "%SystemRoot%\System32\audiosvchost.exe -k LocalServiceNetworkRestricted -p" /f > NUL 2>&1
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AudioEndpointBuilder" /v "ImagePath" /t REG_EXPAND_SZ /d "%SystemRoot%\System32\audiosvchost.exe -k LocalSystemNetworkRestricted -p" /f > NUL 2>&1
exit 
