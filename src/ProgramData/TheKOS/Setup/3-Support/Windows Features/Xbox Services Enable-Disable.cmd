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
cls

echo [1] Enable Xbox Services
echo [2] Disable Xbox Services
set /p input=":"
if "%input%"=="1" (
    goto enable
) else if "%input%"=="2" (
    goto disable
) else (
    exit
)

:enable
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\XboxNetApiSvc" /v "Start" /t REG_DWORD /d "3" /f 
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\XblGameSave" /v "Start" /t REG_DWORD /d "3" /f 
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\XblAuthManage" /v "Start" /t REG_DWORD /d "3" /f 
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\xbgm" /v "Start" /t REG_DWORD /d "3" /f
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\XboxGipSvc" /v "Start" /t REG_DWORD /d "3" /f 
echo restart your pc
pause
exit /b

:disable
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\XboxNetApiSvc" /v "Start" /t REG_DWORD /d "4" /f 
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\XblGameSave" /v "Start" /t REG_DWORD /d "4" /f 
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\XblAuthManage" /v "Start" /t REG_DWORD /d "4" /f 
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\xbgm" /v "Start" /t REG_DWORD /d "4" /f
Reg.exe add "HKLM\SYSTEM\ControlSet\Services\XboxGipSvc" /v "Start" /t REG_DWORD /d "4" /f 
echo restart your pc
pause
exit /b
