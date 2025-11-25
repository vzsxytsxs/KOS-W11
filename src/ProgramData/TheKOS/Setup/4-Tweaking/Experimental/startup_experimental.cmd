@echo off

:: services
sc stop UserManager
sc stop ProfSvc
sc stop sppsvc

:: winlogon normal priority (already set in registry)
wmic process where name="winlogon.exe" call setpriority 32

:: affinity
:: https://bitsum.com/tools/cpu-affinity-calculator/
set affinity=
if defined affinity (
    if not %affinity% GTR 0 goto done
    PowerShell -NoLogo -NoProfile -NonInteractive -Command "get-process dwm,audiodg,lsass,svchost | ForEach-Object {$.ProcessorAffinity=%affinity%}"
) 

:done
exit


