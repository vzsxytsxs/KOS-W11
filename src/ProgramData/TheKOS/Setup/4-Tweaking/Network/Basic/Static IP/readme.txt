Be careful when using the Automatically Set Static IP.cmd script, as it disables some services that are necessary for certain applications. 
If this happens, try using these commands:

Reg.exe add "HKLM\System\CurrentControlSet\services\Netman" /v "Start" /t REG_DWORD /d "2" /f >nul 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\services\NlaSvc" /v "Start" /t REG_DWORD /d "2" /f >nul 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\services\Dhcp" /v "Start" /t REG_DWORD /d "2" /f >nul 2>&1