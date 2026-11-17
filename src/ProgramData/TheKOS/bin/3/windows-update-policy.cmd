@echo off
setlocal
set "wupCheck="
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\TheKOS" /v forceDisableWup 2^>nul') do if /i "%%A"=="REG_SZ" set "wupCheck=%%B"

if "%wupCheck%"=="1" goto hard
if /i "%wupCheck%"=="store" goto store
:: "0" (on or manual) and "paused" need nothing here: the pause is Windows Update's own and lasts until 2038.
exit /b 0

:hard
sc stop wuauserv >NUL 2>&1
sc stop UsoSvc >NUL 2>&1
sc stop WaaSMedicSvc >NUL 2>&1
sc stop bits >NUL 2>&1
sc stop dosvc >NUL 2>&1
for %%S in (wuauserv bits dosvc UsoSvc WaaSMedicSvc) do PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 4 /f >NUL 2>&1
:: Update Health Service: only on builds that have it (an update installs it).
reg query "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" >NUL 2>&1 && PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" /v Start /t REG_DWORD /d 4 /f >NUL 2>&1
exit /b 0

:store
sc stop wuauserv >NUL 2>&1
sc stop WaaSMedicSvc >NUL 2>&1
for %%S in (wuauserv WaaSMedicSvc) do PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 4 /f >NUL 2>&1
for %%S in (bits UsoSvc dosvc) do PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 2 /f >NUL 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >NUL 2>&1
exit /b 0
