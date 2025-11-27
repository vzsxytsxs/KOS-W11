@echo off
title Don't Close This Window / Updating....
taskkill /im explorer.exe /f >nul 2>&1

:: Change Ver 
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "currentver" /t REG_SZ /d "358" /f >nul 2>&1
label C: TheKOS-23H2-3.5.8
bcdedit /set {current} description "TheKOS-23H2-3.5.8"


curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/updates/358/Network.zip" -o "%temp%\Network.zip"
curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/src/ProgramData/TheKOS/bin/2/config.xml" -o "%temp%\config.xml"
curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/src/ProgramData/TheKOS/bin/3/cleanup.cmd" -o "%temp%\cleanup.cmd" --connect-timeout 300 2>nul
curl -sL "https://github.com/vzsxytsxs/KOS-W11/raw/refs/heads/main/updates/358/update_358.reg" -o "%temp%\update_358.reg" --connect-timeout 300 2>nul

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

:: import reg 
regedit /s "%temp%\update_358.reg" && del "%temp%\update_358.reg"

:: replace old cleanup.cmd
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\cleanup.cmd"
copy "%temp%\cleanup.cmd" "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\cleanup.cmd" && del "%temp%\cleanup.cmd"

:: import the latest open-shell config
"C:\Program Files\Open-Shell\StartMenu.exe" -xml "%temp%\config.xml"
timeout /t 2 > nul 
del "%temp%\config.xml" 

:: delete old network tweaking
del /s /f /q "%ProgramData%\TheKOS\Setup\4-Tweaking\Network" >NUL 2>&1
rd /s /q "%ProgramData%\TheKOS\Setup\4-Tweaking\Network" >NUL 2>&1

:: unzip network.zip
powershell Expand-Archive -LiteralPath "%temp%\Network.zip" -DestinationPath 
"%ProgramData%\TheKOS\Setup\4-Tweaking"
del "%temp%\Network.zip" 

echo please restart your pc
timeout /t 5 > nul
start /b "" cmd /c del "%~f0"&exit /b