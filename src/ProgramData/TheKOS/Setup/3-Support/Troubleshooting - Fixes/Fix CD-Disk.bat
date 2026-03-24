@echo off
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\cdrom" /v "Start" /t REG_DWORD /d "1" /f
echo done, restart your pc.
timeout /t 5 /nobreak 
exit
