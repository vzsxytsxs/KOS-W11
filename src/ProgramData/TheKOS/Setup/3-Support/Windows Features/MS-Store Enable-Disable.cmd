@echo off
cls
echo [1] Enable MS-Store
echo [2] Disable MS-Store
set /p input=":"
if "%input%"=="1" (
    goto enable
) else if "%input%"=="2" (
    goto disable
) else (
    exit
)

:disable
for %%s in (
  iphlpsvc
  ClipSVC
  AppXSvc
  LicenseManager
  NgcSvc
  NgcCtnrSvc
  wlidsvc
  TokenBroker
  WalletService
  DoSvc
) do (
  Reg.exe add "HKLM\SYSTEM\ControlSet\Services%%s" /v "Start" /t REG_DWORD /d "4" /f
)

echo restart your pc
pause
exit /b

:enable
for %%s in (
  iphlpsvc
  ClipSVC
  AppXSvc
  LicenseManager
  NgcSvc
  NgcCtnrSvc
  wlidsvc
  TokenBroker
  WalletService
  DoSvc
) do (
  Reg.exe add "HKLM\SYSTEM\ControlSet\Services%%s" /v "Start" /t REG_DWORD /d "3" /f
)

echo restart your pc
pause
exit /b