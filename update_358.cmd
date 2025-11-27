@echo off
title Don't Close This Window / Updating....
taskkill /im explorer.exe /f >nul 2>&1

:: Change Ver 
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "currentver" /t REG_SZ /d "358" /f >nul 2>&1
label C: TheKOS-23H2-3.5.8
bcdedit /set {current} description "TheKOS-23H2-3.5.8"

:: updates
echo [K?] Editing Bcdedit 
bcdedit /set nocrashautoreboot off 
:: Enables automatic restart on crash.
bcdedit /set nx alwaysoff
:: Disables Data Execution Prevention || is a security feature, DEP is intended to prevent an application or service from executing code from a non-executable memory region
:: In short, DEP perform additional checks on memory to prevent malicious code or exploits from running on the system by shut down the process once detected
bcdedit /set disabledynamictick yes
bcdedit /deletevalue useplatformclock
:: forcing it to off makes mousegraphs unstable, 
:: even tho wintimertester shows the same QueryPerfFreq as deleted
bcdedit /set bootmenupolicy legacy
:: Defines the type of boot menu the system will use.
bcdedit /set hypervisorlaunchtype off
:: Enables loading of the hypervisor on a Hyper-V system, or forces it to be disabled.
bcdedit /deletevalue useplatformtick
:: Forces the clock to be backed by a platform source.
:: bcdedit /set loadoptions SYSTEMWATCHDOGPOLICY=DISABLED
:: disables the Windows startup watchdog that normally intervenes when repeated boot failures occur.
bcdedit /timeout 10
:: time to display boot options
:: set this to 0 if you have only 1 OS
bcdedit /set quietboot yes
:: Controls the display of a high-resolution bitmap in place of the Windows boot screen display and animation
bcdedit /set {globalsettings} custom:16000067 true > NUL 2>&1
:: Disable the Spinning Animation in the Boot Screen
bcdedit /set {globalsettings} custom:16000069 true > NUL 2>&1
:: Disable Boot Messages
bcdedit /set {globalsettings} custom:16000068 true > NUL 2>&1
:: Disable Automatic Repair, Better to Debug/Check Manually
bcdedit /set debug No
:: Disables kernel debugger
bcdedit /set ems No
bcdedit /set bootems No 
:: Emergency Management Services (EMS) provides an RS-232 accessible serial console interface to the bootloader menu on modern versions of Microsoft Windows
:: EMS allows users to control particular components of a server remotely, even when the server is not connected to the network or to other standard remote-administration tools
bcdedit /set bootux Disabled
:: Defines the boot graphics user experience that the user will see. Disabled means that no graphics will be seen during boot time (only a black screen)
bcdedit /set bootlog no
:: Disables the system initialization log. This log is stored in the Ntbtlog.txt file in the %WINDIR% directory. 
:: It includes a list of loaded and unloaded drivers in text format.
bcdedit /event off
:: Disables remote event logging for the current Windows operating system boot entry
cls


:: remove shortcut arrows 
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons]
"29"="%windir%\\System32\\shell32.dll,-50"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v "29" /t "REG_DWORD" /d "%windir%\\System32\\shell32.dll,-50"

:: download latest cleanup script
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\cleanup.cmd"
curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/src/ProgramData/TheKOS/bin/3/cleanup.cmd" -o "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\cleanup.cmd" --connect-timeout 300 2>nul

:: download the latest open-shell config
curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/src/ProgramData/TheKOS/bin/2/config.xml" -o "%temp%\config.xml"

:: import the latest open-shell config
"C:\Program Files\Open-Shell\StartMenu.exe" -xml "%temp%\config.xml"
timeout /t 2 > nul 
del "%temp%\config.xml" 

:: update network tweaking
del /s /f /q "%ProgramData%\TheKOS\Setup\4-Tweaking\Network" >NUL 2>&1
rd /s /q "%ProgramData%\TheKOS\Setup\4-Tweaking\Network" >NUL 2>&1
:: download the update
curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/updates\358\Network.zip" -o "%temp%\Network.zip"
powershell Expand-Archive -LiteralPath "%temp%\Network.zip" -DestinationPath "%ProgramData%\TheKOS\Setup\4-Tweaking"

start /b "" cmd /c del "%~f0"&exit /b