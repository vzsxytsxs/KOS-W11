@echo off
devmanview /enable "Microsoft Hyper-V Virtualization Infrastructure Driver"
bcdedit /set hypervisorlaunchtype auto
cls
echo read Hyper-V part2
pause
exit
