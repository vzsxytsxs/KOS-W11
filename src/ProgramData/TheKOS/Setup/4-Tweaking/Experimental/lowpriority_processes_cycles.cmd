@echo off
:: Low Priority for processes that use Cycles
:: eva source
echo Setting process priority and disabling security mitigations
for %%i in (
    dwm.exe
    lsass.exe
    svchost.exe
    WmiPrvSE.exe
) do (
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "1" /f > NUL 2>&1
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i\PerfOptions" /v "IoPriority" /t REG_DWORD /d "0" /f > NUL 2>&1
)
echo @echo off >> "lowpriority.cmd"
echo wmic process where name="dwm.exe" call setpriority 64 >> "lowpriority.cmd"
echo wmic process where name="lsass.exe" call setpriority 64 >> "lowpriority.cmd"
echo wmic process where name="svchost.exe" call setpriority 64 >> "lowpriority.cmd"
echo wmic process where name="WmiPrvSE.exe" call setpriority 64 >> "lowpriority.cmd"
echo exit >> "lowpriority.cmd"
move "lowpriority.cmd" "%programdata%\TheKOS\bin\3"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "LowPriority" /t REG_SZ /d "%programdata%\TheKOS\bin\3\lowpriority.cmd" /f > NUL 2>&1
exit

