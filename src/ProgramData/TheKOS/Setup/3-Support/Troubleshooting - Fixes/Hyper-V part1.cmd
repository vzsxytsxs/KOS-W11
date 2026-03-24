@echo off
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vdrvroot" /v "Start" /t REG_DWORD /d "3" /f
devmanview /enable "Microsoft Virtual Drive Enumerator"
devmanview /enable "Microsoft Hyper-V Virtualization Infrastructure Driver"
bcdedit /set hypervisorlaunchtype auto
cls
echo Read Hyper-V Part2
pause
exit
