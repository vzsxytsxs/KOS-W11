@echo off
title "TheKOS 25H2 Post-Script"
SETLOCAL EnableDelayedExpansion
setx POWERSHELL_TELEMETRY_OPTOUT 1 >NUL 2>&1
setx DOTNET_CLI_TELEMETRY_OPTOUT 1 >NUL 2>&1

taskkill /im explorer.exe /f >nul 2>&1
Reg.exe add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t "REG_DWORD" /d "100" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /t REG_SZ /d "." /f >nul 2>&1
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "currentver" /t REG_SZ /d "400" /f >nul 2>&1
label C: TheKOS-25H2-4.0.0
bcdedit /set {current} description "TheKOS-25H2-4.0.0"
cls

:: cleanup script
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TheKOS Cleanup" /t REG_SZ /d "wscript.exe C:\ProgramData\TheKOS\bin\3\cleanup.vbs" /f 
cls

:: installers
echo [K?] Visual C++
start /b /wait "" "%programdata%\TheKOS\bin\1\Visual-C-Runtimes-All-in-One-Dec-2025\install_all.bat" >nul 2>&1
cls

echo [K?] DirectX
start /min /wait "" "%programdata%\TheKOS\bin\1\DirectX\install.bat" >NUL 2>&1
timeout /t 5 /nobreak >NUL 2>&1
cls

echo [K?] 7z
start /b /wait "" "%programdata%\TheKOS\bin\1\7z2600-x64.msi" /passive >nul 2>&1
cls

echo [K?] VLC 
%programdata%\TheKOS\bin\1\vlc-3.0.21-win64.exe /L=1033 /S
cls

echo [K?] Lightshot 
call "%programdata%\TheKOS\bin\1\lightshot.exe" /VERYSILENT /NORESTART
cls

:: Open-Shell
echo [K?] Open-Shell
start %programdata%\TheKOS\bin\1\openshell.exe /qn ADDLOCAL=StartMenu
timeout /t 2 /nobreak >NUL 2>&1
"%programfiles%\Open-Shell\StartMenu.exe" -xml "%programdata%\TheKOS\bin\2\config.xml"
PowerRun.exe /SW:0 taskkill.exe /im "StartMenuExperienceHost.exe" /t /f
PowerRun.exe /SW:0 powershell.exe Rename-Item -Path "%windir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" -NewName "StartMenuExperienceHost.old"

:: TheKOS Reg 
cls
echo [K?] 7z Config
start /b /wait "" "%programdata%\TheKOS\bin\2\7zip-pexp.bat" >NUL 2>&1
regedit /s "%programdata%\TheKOS\bin\2\TheKOS_reg.reg"
regedit /s "%programdata%\TheKOS\bin\2\legalnotice.reg"

echo [K?] Disabling Process Mitigations 
PowerShell Set-ProcessMitigation -System -Disable CFG
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set "mitigation_mask=%%a"
)
for /L %%a in (0,1,9) do (
    set "mitigation_mask=!mitigation_mask:%%a=2!"
    reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "%mitigation_mask%" /f > nul 2>&1
    reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "%mitigation_mask%" /f > nul 2>&1
)
for %%d in (
    fontdrvhost.exe
    dwm.exe
    lsass.exe
    svchost.exe
    WmiPrvSE.exe
    winlogon.exe
    csrss.exe
    audiodg.exe
    ntoskrnl.exe
    services.exe
) do (
    Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%d" /v "MitigationOptions" /t REG_BINARY /d "%mitigation_mask%" /f > NUL 2>&1
    Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%d" /v "MitigationAuditOptions" /t REG_BINARY /d "%mitigation_mask%" /f > NUL 2>&1
)
cls

echo [K?] Reserved Storage
DISM /Online /Set-ReservedStorageState /State:Disabled >nul 2>&1

echo [K?] Write Cache Buffer
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\SCSI"^| findstr "HKEY"') do (
	for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do reg.exe add "%%a\Device Parameters\Disk" /v "CacheIsPowerProtected" /t REG_DWORD /d "1" /f > NUL 2>&1
)
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\SCSI"^| findstr "HKEY"') do (
	for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do reg.exe add "%%a\Device Parameters\Disk" /v "UserWriteCacheSetting" /t REG_DWORD /d "1" /f > NUL 2>&1
)
cls

echo [K?] Execution Policy To Unrestricted
powershell set-executionpolicy unrestricted -force >nul 2>&1
cls

echo [K?] Bcdedit
bcdedit /set nx alwaysoff
:: Disables Data Execution Prevention || is a security feature, DEP is intended to prevent an application or service from executing code from a non-executable memory region
:: In short, DEP perform additional checks on memory to prevent malicious code or exploits from running on the system by shut down the process once detected
bcdedit /set hypervisorlaunchtype off
:: Enables loading of the hypervisor on a Hyper-V system, or forces it to be disabled.
bcdedit /set nocrashautoreboot off 
:: Enables automatic restart on crash.
bcdedit /set disabledynamictick yes
bcdedit /deletevalue useplatformclock
:: forcing it to off makes mousegraphs unstable, 
:: even tho wintimertester shows the same QueryPerfFreq as deleted
bcdedit /set bootmenupolicy legacy
:: Defines the type of boot menu the system will use.
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

echo [K?] Device Manager Devices
devmanview /disable "Microsoft Virtual Drive Enumerator"
devmanview /disable "Generic Bluetooth Adapter"
devmanview /disable "Microsoft Hyper-V Virtualization Infrastructure Driver"
devmanview /disable "AMD PSP"
devmanview /disable "Intel SMBus"
devmanview /disable "Intel Management Engine"
devmanview /disable "Communications Port (COM1)"
devmanview /disable "Direct memory access Controller"
devmanview /disable "High Precision Event Timer"
devmanview /disable "Microsoft GS Wavetable Synth"
devmanview /disable "Remote Desktop Device Redirector Bus"
devmanview /disable "NDIS Virtual Network Adapter Enumerator"
devmanview /disable "UMBus Root Bus Enumerator"
devmanview /disable "Programmable interrupt controller"
devmanview /disable "Legacy device"
devmanview /disable "Numeric data processor"
devmanview /disable "System Speaker"
devmanview /disable "PCI Encryption/Decryption Controller"
devmanview /disable "PCI Memory Controller"
devmanview /disable "PCI standard RAM Controller"
devmanview /disable "System Timer"
devmanview /disable "Fax"
devmanview /disable "Microsoft Print to PDF"
devmanview /disable "Microsoft XPS Document Writer"
devmanview /disable "Root Print Queue"

:: Backup Default Services
echo [K?] Backup Services
set BACKUP="%ProgramData%\TheKOS\Setup\3-Support\Services\Windows.Default.Services.reg"
echo Windows Registry Editor Version 5.00 >>%BACKUP%

for /f "delims=" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services"') do (
    for /f "tokens=3" %%b in ('reg query "%%~a" /v "Start" 2^>nul') do (
        for /l %%c in (0,1,4) do (
            if "%%b"=="0x%%c" (
                echo. >>%BACKUP%
                echo [%%~a] >>%BACKUP%
                echo "Start"=dword:0000000%%c >>%BACKUP%
            ) 
        ) 
    ) 
) >nul 2>&1

echo [K?] Applying TheKOS Services
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}" /v "UpperFilters" /t REG_MULTI_SZ /d "" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{6bdd1fc6-810f-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_MULTI_SZ /d "" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{ca3e7ab9-b4c3-4ae6-8251-579ef933890f}" /v "UpperFilters" /t REG_MULTI_SZ /d "" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e967-e325-11ce-bfc1-08002be10318}" /v "LowerFilters" /t REG_MULTI_SZ /d "" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_MULTI_SZ /d "" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_MULTI_SZ /d "" /f
PowerRun.exe /SW:0 reg.exe delete  "HKLM\SYSTEM\ControlSet001\Control\Class\{36FC9E60-C465-11CF-8056-444553540000}"               /v "LowerFilters" /f
PowerRun.exe /SW:0 reg.exe delete  "HKLM\SYSTEM\ControlSet001\Control\Class\{36FC9E60-C465-11CF-8056-444553540000}"               /v "UpperFilters" /f 
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dhcp"                                        /v "DependOnService" /t REG_MULTI_SZ /d "NSI\0Afd" /f
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache"                                    /v "DependOnService" /t REG_MULTI_SZ /d "nsi" /f
Reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"                                            /v "InactivityShutdownDelay" /t REG_DWORD /d "4294967295" /f
for %%z in (
      DsmSvc
      autotimesvc
      W32Time
      DsSvc
      icssvc
      IKEEXT
      PcaSvc
      ShellHWDetection
      tzautoupdate
      OneSyncSvc
      Beep
      cdfs
      cdrom
      acpiex
      acpipagr
      acpipmi
      acpitime
      cnghwassist
      GpuEnergyDrv
      Telemetry
      VerifierExt
      MsLldp
      lltdio
      NdisVirtualBus
      NDU
      luafv
      BcastDVRUserService
      rdyboost
      rdpbus
      umbus
      vdrvroot
      CompositeBus
      rspndr
      NdisCap
      NetBIOS
      NetBT
      spaceport
      VaultSvc
      EventSystem
      bam
      bowser
      WarpJITSvc
      Wecsvc
      dmwappushservice
      GraphicsPerfSvc
      WMPNetworkSvc
      TermService
      UmRdpService
      PimIndexMaintenanceSvc
      UserDataSvc
      3ware
      arcsas
      buttonconverter
      circlass
      Dfsc
      ErrDev
      mrxsmb
      mrxsmb20
      PEAUTH
      QWAVEdrv
      srv
      SiSRaid2
      SiSRaid4
      Tcpip6
      tcpipreg
      vsmraid
      VSTXRAID
      wcnfs
      WindowsTrustedRTProxy
      SstpSvc
      SSDPSRV
      SmsRouter
      CldFlt
      iphlpsvc
      IpxlatCfgSvc
      NetTcpPortSharing
      KtmRm
      LanmanWorkstation
      LanmanServer
      lmhosts
      MSDTC
      QWAVE
      RmSvc
      RFCOMM
      BthEnum
      bthleenum
      BTHMODEM
      BthA2dp
      microsoft_bluetooth_avrcptransport
      BthHFEnum
      BTAGService
      bthserv
      BluetoothUserService
      BthAvctpSvc
      TsUsbFlt
      tsusbhub
      storflt
      RDPDR
      bttflt
      HidBth
      BthMini
      BTHPORT
      BTHUSB     
      hvservice
      HvHost     
      defragsvc
      dispbrokerdesktopsvc
      dam
      FontCache
      FontCache3.0.0.0
      lfsvc
      printworkflowusersvc
      PhoneSvc
      SharedAccess
      SysMain
      spooler
      Themes
      TapiSrv
      UnistoreSvc
      udfs
      WSearch
      WPDBusEnum
      CLFS
      lltdsvc
      gencounter
      scardsvr
      scdeviceenum
      scpolicysvc
      wscsvc
      webthreatdefsvc
      DPS
      DusmSvc
      wisvc
      MDCoreSvc
      WdNisSvc
      WdNisDrv
      Sense
      SecurityHealthService
      WdFilter
      WinDefend
      Trkwks
      :: WUP
      wuauserv
      bits
      :: dosvc / break ms-store 
      UsoSvc
      WaaSMedicSvc
) do (
    PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%z" /v "Start" /t REG_DWORD /d "4" /f
)
cls

:: Windows Update
echo [K?] Windows Update - VantageOS/RaxOS
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Windows\UpdateOrchestrator\Start Oobe Expedite Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_LicenseAccepted" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_OobeAppReady" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScanAfterUpdate" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\UIEOrchestrator" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WindowsUpdate\Refresh Group Policy Cache" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WaaSMedic\PerformRemediation" >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v PreventDeviceMetadataFromNetwork /t REG_DWORD /d 1 /f >nul

echo [K?] Windows Defender - Ancel
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"                                     /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"                                     /v "DisableRoutinelyTakingAction" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"                                     /v "ServiceKeepAlive" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"                /v "DisableBehaviorMonitoring" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"                /v "DisableIOAVProtection" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"                /v "DisableOnAccessProtection" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"                /v "DisableRealtimeMonitoring" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications"       /v "DisableNotifications" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting"                           /v "DisableEnhancedNotifications" /t REG_DWORD /d "1" /f > nul
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"             /v "NoToastApplicationNotification" /t REG_DWORD /d "1" /f > nul
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"             /v "NoToastApplicationNotificationOnLockScreen" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration"                    /v "Notification_Suppress" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT"                                                  /v "DontReportInfectionInformation" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"                                       /v "EnableSmartScreen" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter"                         /v "DontReportInfectionInformation" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen"                         /v "ConfigureAppInstallControlEnabled" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting"                           /v "DisableGenericReports" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"                              /v "LocalSettingOverrideSpynetReporting" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"                              /v "SpynetReporting" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"                              /v "SubmitSamplesConsent" /t REG_DWORD /d "2" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Threats"                             /v "Threats_ThreatSeverityDefaultAction" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Threats\ThreatSeverityDefaultAction" /v "1" /t REG_SZ /d "6" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Threats\ThreatSeverityDefaultAction" /v "2" /t REG_SZ /d "6" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Threats\ThreatSeverityDefaultAction" /v "4" /t REG_SZ /d "6" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Threats\ThreatSeverityDefaultAction" /v "5" /t REG_SZ /d "6" /f > nul

:: ?? random
net accounts /maxpwage:unlimited

echo [K?] Spectre Meltdown
:: new/catto
for /f "usebackq delims=" %%V in (`
powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Manufacturer).Trim()"
`) do set "CPU_MFG=%%V"

echo %CPU_MFG% | findstr /I "Intel GenuineIntel" >NUL
if not errorlevel 1 (
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettings" /t REG_DWORD /d "1" /f >NUL 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f >NUL 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f >NUL 2>&1
)

:: cleaner
rd /s /q "%programdata%\Microsoft\Windows\Start Menu\Programs\7-Zip"
rd /s /q "%programdata%\Microsoft\Windows\Start Menu\Programs\Lightshot"
reg delete "HKLM\SOFTWARE\WOW6432Node\Skillbrains\Updater" /f
rd /s /q "%programfiles% (x86)\Skillbrains\Updater"
rd /s /q "%programdata%\Microsoft\Windows\Start Menu\Programs\Open-Shell"
del "%programfiles%\Open-Shell\Start Screen.lnk"
Reg.exe delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Open-Shell Start Menu" /f >nul 2>&1
Reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "Open-Shell Start Menu" /f >nul 2>&1
del "%systemdrive%\Users\Public\Desktop\VLC media player.lnk"

:: Keyboard and Mouse Settings
echo [K?] Keyboard and Mouse Settings 
Reg.exe add "HKCU\Control Panel\Keyboard"   /v "InitialKeyboardIndicators" /t REG_SZ /d "0" /f >nul 2>&1
Reg.exe add "HKCU\Control Panel\Keyboard"   /v "KeyboardDelay" /t REG_SZ /d "0" /f >nul 2>&1
Reg.exe add "HKCU\Control Panel\Keyboard"   /v "KeyboardSpeed" /t REG_SZ /d "31" /f >nul 2>&1
Reg.exe add "HKCU\Control Panel\Mouse"      /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1
Reg.exe add "HKCU\Control Panel\Mouse"      /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1
Reg.exe add "HKCU\Control Panel\Mouse"      /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "DelayBeforeAcceptance" /t REG_SZ /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "AutoRepeatDelay" /t REG_SZ /d "500" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "AutoRepeatRate" /t REG_SZ /d "33" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "BounceTime" /t REG_SZ /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\StickyKeys"        /v "Flags" /t REG_SZ /d "506" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\ToggleKeys"        /v "Flags" /t REG_SZ /d "58" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f

:: visual effects
echo [K?] Visual Effects 
Reg.exe add "HKCU\Control Panel\Desktop"                                                        /v "DragFullWindows" /t REG_SZ /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Control Panel\Desktop"                                                        /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"                           /v "AltTabSettings" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"                           /v "HoverSelectDesktops" /t REG_DWORD /d "1" /f
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"                 /v "EnableTransparency" /t REG_DWORD /d "0" /f >nul 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"                  /v "ListviewShadow" /t REG_DWORD /d "0" /f >nul 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"                  /v "ListviewAlphaSelect" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"             /v "VisualFXSetting" /t REG_DWORD /d "3" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"                  /v "TaskbarAnimations" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\DWM"                                               /v "EnableAeroPeek" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\DWM"                                               /v "Blur" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\DWM"                                               /v "Animations" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\DWM"                                               /v "AlwaysHibernateThumbnails" /t REG_DWORD /d 0 /f
Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM"                                      /v "DWMA_TRANSITTIONS_FORCEDISABLED" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM"                                      /v "DisallowAnimations" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM"                                      /v "AnimationAttributionEnabled" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"                  /v "UseOLEDTaskbarTransparency" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"                  /v "IconsOnly" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Control Panel\Desktop\WindowMetrics"                                          /v "MinAnimate" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Control Panel\Desktop\WindowMetrics"                                          /v "MinAnimate" /t REG_SZ /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"                 /v "SystemUsesLightTheme" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"                 /v "AppsUseLightTheme" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"                  /v "Hidden" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer"                              /v "DisableNotificationCenter" /f >nul 2>&1
Reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer"                              /v "DisableNotificationCenter" /f >nul 2>&1

:: disable network adapters
echo [K?] Network Adapters
powershell -NoProfile -Command "Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6, ms_msclient, ms_server, ms_rspndr, ms_lltdio, ms_implat, ms_lldp" >nul 2>&1
cls

:: netbios
echo [K?] NetBIOS over TCP/IP
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "EnableLMHOSTS" /t REG_DWORD /d "0" /f
for /f "delims=" %%u in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    reg add "%%u" /v "NetbiosOptions" /t REG_DWORD /d "2" /f
)
cls

:: Delete Firewall Rules
echo [K?] Firewall Rules
Reg.exe delete "HKLM\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" /f > NUL 2>&1
Reg.exe add    "HKLM\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" /f > NUL 2>&1

:: autologgers
echo [K?] AutoLoggers and Firewall Rules
powerrun "powershell.exe" Remove-AutologgerConfig -Name "autologger-diagtrack-listener", "cellcore", "cloudexperiencehostoobe", "lwtnetlog", "mellanox-Kernel", "microsoft-windows-assignedaccess-trace", "microsoft-windows-rdp-graphics-rdpidd-trace"
cls

:: dma remapping
echo [K?] DMA Remapping
for %%a in (DmaRemappingCompatible) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%a" ^| findstr "HKEY"') do Reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "0" /f >nul 2>&1
cls

:: exclusive mode audio
echo [K?] Exclusive Mode On Audio Devices
for /f "delims=" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture') do PowerRun.exe /SW:0 Reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f >nul 2>&1
for /f "delims=" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture') do PowerRun.exe /SW:0 Reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f >nul 2>&1
for /f "delims=" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render') do PowerRun.exe /SW:0 Reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f >nul 2>&1
for /f "delims=" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render') do PowerRun.exe /SW:0 Reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f >nul 2>&1
cls

echo [K?] POW / Power Tweaks
powercfg /import "%windir%\co.pow" b0a71852-3be4-43b1-9aff-70d3c8430794
wevtutil set-log "Microsoft-Windows-SleepStudy/Diagnostic"             /e:false >nul 2>&1
wevtutil set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false >nul 2>&1
wevtutil set-log "Microsoft-Windows-UserModePowerService/Diagnostic"   /e:false >nul 2>&1
:: Unhide All Pow Settings | VantageOS/RaxOS
Powershell -noprofile -executionpolicy bypass -file "%programdata%\TheKOS\bin\2\UnhideAllPowSettings.ps1"
cls

echo [K?] HiperBoot
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t Reg_DWORD /d "0" /f  >nul 2>&1

for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_SystemEnclosure).ChassisTypes[0]"') do set "CHASSIS=%%A"
set "DEVICE_TYPE=PC"
for %%a in (8 9 10 11 12 13 14 18 21 30 31 32) do if "%CHASSIS%" == "%%a" (set "DEVICE_TYPE=LAPTOP")
if "%DEVICE_TYPE%" == "LAPTOP" (
    echo [K?] Laptop Detected
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\serenum"               /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\sermouse"              /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\serial"                /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dispbrokerdesktopsvc"  /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wmiacpi"               /v "Start" /t REG_DWORD /d "2" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"  /v "PowerThrottlingOff" /t REG_DWORD /d "0" /f
    Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v "ShowHibernateOption" /t REG_DWORD /d "1" /f  >nul 2>&1
    Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v "ShowLockOption" /t REG_DWORD /d "1" /f  >nul 2>&1
    Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /v "ShowSleepOption" /t REG_DWORD /d "1" /f >nul 2>&1
    powercfg /h on
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
    powercfg /d a1841308-3541-4fab-bc81-f71556f20b4a
    powercfg /d 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    cls
) else (
    echo [K?] Desktop Detected
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\sensorservice"                /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\sensordataservice"            /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\sensrsvc"                     /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DisplayEnhancementService"    /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wmiacpi"                      /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"         /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f >nul 2>&1
    Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power"                                       /v "HibernateEnabled"   /t REG_DWORD /d "0" /f >nul 2>&1
    Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power"                                       /v "HibernateEnabledDefault" /t REG_DWORD /d "0" /f  >nul 2>&1
    echo [K?] Driver PowerSaving 
    %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -Command "Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | ForEach-Object { $_.enable = $false; $_.psbase.put(); }"
    echo [K?] PowerSaving Features
    for %%a in (
	    EnhancedPowerManagementEnabled
	    AllowIdleIrpInD3
	    EnableSelectiveSuspend
	    DeviceSelectiveSuspended
	    SelectiveSuspendEnabled
	    SelectiveSuspendOn
	    WaitWakeEnabled
	    D3ColdSupported
	    WdfDirectedPowerTransitionEnable
	    EnableIdlePowerManagement
	    IdleInWorkingState
	    EnumerationRetryCount
	    ExtPropDescSemaphore
	    IoLatencyCap
    ) do for /f "delims=" %%b in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum" /s /f "%%a" ^| findstr "HKEY"') do Reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "0" /f > NUL 2>&1
    powercfg /h off
    powercfg /s b0a71852-3be4-43b1-9aff-70d3c8430794
    powercfg /d a1841308-3541-4fab-bc81-f71556f20b4a
    powercfg /d 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg /d 381b4222-f694-41f0-9685-ff5bb260df2e
    cls
)

:: Scheduled Tasks
echo [K?] Scheduled Tasks
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Diagnosis\Scheduled" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\DiskFootprint\Diagnostics" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\InstallService\ScanForUpdates" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\InstallService\ScanForUpdatesAsUser" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Registry\RegIdleBackup" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\StateRepository\MaintenanceTasks" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\SystemRestore\SR" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\WDI\ResolutionHost" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\ApplicationData\appuriverifierdaily" >nul 2>&11
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Application Experience\StartupAppTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Application Experience\MareBackup" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Autochk\Proxy" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Device Information\Device User" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Device Information\Device" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Input\InputSettingsRestoreDataAvailable" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Input\LocalUserSyncDataAvailable" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Input\MouseSyncDataAvailable" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Input\PenSyncDataAvailable" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Input\syncpensettings" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Input\TouchpadSyncDataAvailable" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Location\Notifications" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Location\WindowsActionDialog" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\ApplicationData\DsSvcCleanup" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Maintenance\WinSAT" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\PI\Sqm-Tasks" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Maps\MapsToastTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Maps\MapsUpdateTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Sysmain\ResPriStaticDbSync" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Sysmain\WsSwapAssessmentTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /delete /f /tn "\Microsoft\Windows\TaskScheduler" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Chkdsk\ProactiveScan" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Chkdsk\SyspartRepair" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Data Integrity Scan\Data Integrity Scan" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\DiskCleanup\SilentCleanup" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\DiskFootPrint\StorageSense" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\LanguageComponentsInstaller\Uninstallation" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Time Synchronization\ForceSynchronizeTime" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Time Synchronization\SynchronizeTime" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Time Zone\SynchronizeTimeZone" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UPnP\UPnPHostConfig" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\User Profile Service\HiveUploadTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Windows Filtering Platform\BfeOnServiceStartTypeChange" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /change /disable /TN "\Microsoft\Windows\Wininet\CacheTask" >nul 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\Application Experience\PcaPatchDbTask" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskLogon" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\RetailDemo\CleanupOfflineContent" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\InstallService\SmartRetry" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\International\Synchronize Language Settings" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\Multimedia\Microsoft\Windows\Multimedia" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\Printing\EduPrintProv" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\RemoteAssistance\RemoteAssistanceTask" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\Ras\MobilityManager" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\PushToInstall\LoginCheck" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "\Microsoft\Windows\Device Setup\Metadata Refresh" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "Microsoft\Windows\Customer Experience Improvement Program\Uploader" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "Microsoft\Windows\Shell\FamilySafetyRefresh" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "Microsoft\Windows\Shell\FamilySafetyUpload" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "Microsoft\Windows\Application Experience\AitAgent" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "Microsoft\Windows\AppID\SmartScreenSpecific" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "Microsoft\Windows\NetTrace\GatherNetworkInfo" >NUL 2>&1
powerrun /SW:0 "schtasks.exe" /Change /Disable /TN "Microsoft\Windows\FileHistory\File History (maintenance mode)" >NUL 2>&1
cls

echo [K?] NIC
for /f %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /v "*SpeedDuplex" /s ^| findstr "HKEY"') do (
    for /f %%i in ('reg query "%%a" /v "*DeviceSleepOnDisconnect" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*DeviceSleepOnDisconnect" /t REG_SZ /d "0" /f >nul 2>&1
    )
    for /f %%i in ('reg query "%%a" /v "*EEE" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*EEE" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*FlowControl" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*FlowControl" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*IPChecksumOffloadIPv4" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*IPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*InterruptModeration" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*InterruptModeration" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*LsoV2IPv4" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*LsoV2IPv4" /t REG_SZ /d "1" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*LsoV2IPv6" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*LsoV2IPv6" /t REG_SZ /d "1" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*NumRssQueues" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*NumRssQueues" /t REG_SZ /d "2" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*PMARPOffload" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*PMARPOffload" /t REG_SZ /d "1" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*PMNSOffload" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*PMNSOffload" /t REG_SZ /d "1" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*PriorityVLANTag" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*PriorityVLANTag" /t REG_SZ /d "1" /f >nul 2>&1  
    )
    for /f %%i in ('reg query "%%a" /v "*RSS" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*RSS" /t REG_SZ /d "1" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*WakeOnMagicPacket" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*WakeOnMagicPacket" /t REG_SZ /d "0" /f >nul 2>&1   
    )
	for /f %%i in ('reg query "%%a" /v "AutoPowerSaveModeEnabled" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d "0" /f >nul 2>&1
    )
    for /f %%i in ('reg query "%%a" /v "*WakeOnPattern" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*WakeOnPattern" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*ReceiveBuffers" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*ReceiveBuffers" /t REG_SZ /d "2048" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*TransmitBuffers" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*TransmitBuffers" /t REG_SZ /d "2048" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*TCPChecksumOffloadIPv4" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*TCPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*TCPChecksumOffloadIPv6" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*TCPChecksumOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*UDPChecksumOffloadIPv4" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*UDPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*UDPChecksumOffloadIPv6" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*UDPChecksumOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "DMACoalescing" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "DMACoalescing" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "EEELinkAdvertisement" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "EEELinkAdvertisement" /t REG_SZ /d "0" /f >nul 2>&1   
    )
	for /f %%i in ('reg query "%%a" /v "EeePhyEnable" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "EeePhyEnable" /t REG_SZ /d "0" /f >nul 2>&1
    )
    for /f %%i in ('reg query "%%a" /v "ITR" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "ITR" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "ReduceSpeedOnPowerDown" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d "0" /f >nul 2>&1   
    )
	for /f %%i in ('reg query "%%a" /v "PowerDownPll" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "PowerDownPll" /t REG_SZ /d "0" /f >nul 2>&1
    )
    for /f %%i in ('reg query "%%a" /v "WaitAutoNegComplete" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "WaitAutoNegComplete" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "WakeOnLink" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "WakeOnLink" /t REG_SZ /d "0" /f >nul 2>&1   
    )
	for /f %%i in ('reg query "%%a" /v "WakeOnSlot" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "WakeOnSlot" /t REG_SZ /d "0" /f >nul 2>&1
    )
	for /f %%i in ('reg query "%%a" /v "WakeUpModeCap" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "WakeUpModeCap" /t REG_SZ /d "0" /f >nul 2>&1
    )
    for /f %%i in ('reg query "%%a" /v "AdvancedEEE" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "AdvancedEEE" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "EnableGreenEthernet" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "GigaLite" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "GigaLite" /t REG_SZ /d "0" /f >nul 2>&1   
    )
	for /f %%i in ('reg query "%%a" /v "PnPCapabilities" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "PnPCapabilities" /t REG_DWORD /d "24" /f >nul 2>&1
    )
    for /f %%i in ('reg query "%%a" /v "PowerSavingMode" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "PowerSavingMode" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "S5WakeOnLan" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "S5WakeOnLan" /t REG_SZ /d "0" /f >nul 2>&1   
    )
	for /f %%i in ('reg query "%%a" /v "SavePowerNowEnabled" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "SavePowerNowEnabled" /t REG_SZ /d "0" /f >nul 2>&1
    )
	for /f %%i in ('reg query "%%a" /v "ULPMode" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "ULPMode" /t REG_SZ /d "0" /f >nul 2>&1
    )
    for /f %%i in ('reg query "%%a" /v "WolShutdownLinkSpeed" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "WolShutdownLinkSpeed" /t REG_SZ /d "2" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "LogLinkStateEvent" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "LogLinkStateEvent" /t REG_SZ /d "16" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "WakeOnMagicPacketFromS5" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "WakeOnMagicPacketFromS5" /t REG_SZ /d "0" /f >nul 2>&1   
	)
	for /f %%i in ('reg query "%%a" /v "Ultra Low Power Mode" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "Ultra Low Power Mode" /t REG_SZ /d "Disabled" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "System Idle Power Saver" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "System Idle Power Saver" /t REG_SZ /d "Disabled" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "Selective Suspend" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "Selective Suspend" /t REG_SZ /d "Disabled" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "Selective Suspend Idle Timeout" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "Selective Suspend Idle Timeout" /t REG_SZ /d "60" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "Link Speed Battery Saver" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "Link Speed Battery Saver" /t REG_SZ /d "Disabled" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*SelectiveSuspend" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*SelectiveSuspend" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "EnablePME" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "EnablePME" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "TxIntDelay" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "TxIntDelay" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "TxDelay" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "TxDelay" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "EnableModernStandby" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "EnableModernStandby" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*ModernStandbyWoLMagicPacket" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*ModernStandbyWoLMagicPacket" /t REG_SZ /d "0" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "EnableLLI" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "EnableLLI" /t REG_SZ /d "1" /f >nul 2>&1   
    )
    for /f %%i in ('reg query "%%a" /v "*SSIdleTimeout" ^| findstr "HKEY"') do (
        Reg.exe add "%%i" /v "*SSIdleTimeout" /t REG_SZ /d "60" /f >nul 2>&1   
    )
) >nul 2>&1
cls

echo [K?] MSI mode & Set to Undefined
powershell -NoProfile -ExecutionPolicy Bypass -File "%programdata%\TheKOS\bin\2\msi_mode.ps1"

:: Fix VMware
powershell -NoProfile -ExecutionPolicy Bypass -File "%programdata%\TheKOS\bin\2\vmware_fix.ps1"

cls
echo [K?] Remove Share from context menu
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{e2bf9676-5f8f-435c-97eb-11607a5bedf7}" /t REG_SZ /d "" /f > nul
reg add "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{e2bf9676-5f8f-435c-97eb-11607a5bedf7}" /t REG_SZ /d "" /f > nul
cls

echo [K?] Removing Quick access
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "HubMode" /t REG_DWORD /d "1" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\ShellFolder" /v "Attributes" /t REG_DWORD /d "2962489444" /f >nul 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKCR\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\ShellFolder" /v "Attributes" /t REG_DWORD /d "2962489444" /f >nul 2>&1
cls

echo [K?] Fsutil Behaviors
fsutil behavior set disable8dot3 1 > NUL 2>&1
fsutil behavior set disablelastaccess 1 > NUL 2>&1
fsutil behavior set disabledeletenotify 0 > NUL 2>&1
fsutil behavior set memoryusage 2 > NUL 2>&1
fsutil behavior set encryptpagingfile 0 > NUL 2>&1
cls

echo [K?] Legacy Photo Viewer
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".tif" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".tiff" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".bmp" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".dib" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".gif" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jfif" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpe" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpeg" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpg" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jxr" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".png" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.bmp" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.dib" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.gif" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.jxr" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.jpe" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.jpeg" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.jpg" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.png" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "PhotoViewer.FileAssoc.Tiff_.jfif" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.bmp\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.dib\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.gif\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jfif\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpe\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpeg\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpg\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jxr\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
Reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.png\UserChoice" /v "ProgId" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
cls

:: ren searchhost and crossdeviceresume
cd %systemdrive%\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy
takeown /f "SearchHost.exe"
icacls "%systemdrive%\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\SearchHost.exe" /grant Administrators:F
ren SearchHost.exe SearchHost.old
taskkill /f /im SearchHost.exe /t

takeown /f "CrossDeviceResume.exe"
icacls "%systemdrive%\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\CrossDeviceResume.exe" /grant Administrators:F
ren CrossDeviceResume.exe CrossDeviceResume.exe.old
taskkill /f /im CrossDeviceResume.exe /t

:: Disable HVCI-VBS
echo [K?] HVCI-VBS
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "RequirePlatformSecurityFeatures" /f
PowerRun.exe /SW:0 Reg.exe add "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d "0" /f
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "ConfigureSystemGuardLaunch" /f
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "ConfigureKernelShadowStacksLaunch" /f
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "HypervisorEnforcedCodeIntegrity" /f
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "LsaCfgFlags" /f
PowerRun.exe /SW:0 Reg.exe add "HKLM\System\ControlSet001\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d "0" /f
PowerRun.exe /SW:0 Reg.exe add "HKLM\System\ControlSet001\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d "0" /f
PowerRun.exe /SW:0 Reg.exe add "HKLM\System\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f
PowerRun.exe /SW:0 Reg.exe add "HKLM\System\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "HVCIMATRequired" /t REG_DWORD /d "0" /f
PowerRun.exe /SW:0 Reg.exe add "HKLM\System\ControlSet001\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d "0" /f

:: Backup TheKOS Services
set BACKUP="%ProgramData%\TheKOS\Setup\3-Support\Services\TheKOS.services.reg"
echo Windows Registry Editor Version 5.00 >>%BACKUP%

for /f "delims=" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services"') do (
    for /f "tokens=3" %%b in ('reg query "%%~a" /v "Start" 2^>nul') do (
        for /l %%c in (0,1,4) do (
            if "%%b"=="0x%%c" (
                echo. >>%BACKUP%
                echo [%%~a] >>%BACKUP%
                echo "Start"=dword:0000000%%c >>%BACKUP%
            ) 
        ) 
    ) 
) >nul 2>&1

:: KnownDLLs
echo [K?] KnownDLLs
powerrun /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64win" /f > NUL 2>&1
powerrun /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wowarmhw" /f > NUL 2>&1
powerrun /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64" /f > NUL 2>&1
powerrun /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64cpu" /f > NUL 2>&1

:: CSRSS to high priority / io (RESPONSIBLE FOR RAW INPUT)
:: echo [K?] CSRSS -> High Priority
:: Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f > NUL 2>&1
:: Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "IoPriority" /t REG_DWORD /d "3" /f > NUL 2>&1

:: Windows Explorer Slows Down Indexing
:: https://youtu.be/ctMyvJsBSzI?t=1172
echo [K?] Windows Explorer Slows Down Indexing
reg delete "HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f 
reg delete "HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f 
reg add "HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v "FolderType" /t REG_SZ /d "NotSpecified" /f > NUL 2>&1

:: config notepad
del "%localappdata%\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat" >nul 2>&1
move "%programdata%\TheKOS\bin\2\settings.dat" "%localappdata%\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings" >nul 2>&1

echo [K?] Remove SecHealthApp (ionuttbara)
Powershell -noprofile -executionpolicy bypass -file "%programdata%\TheKOS\bin\2\RemoveSecHealthApp.ps1"

:: new/catto
echo [K?] Background App Diagnostic Log
powershell Disable-AppBackgroundTaskDiagnosticLog >NUL 2>&1

echo [K?] Copilot 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"                                                 /v "DisableAIDataAnalysis" /t "REG_DWORD" /d 1 /f >NUL 2>&1
reg add "HKCU\Software\Microsoft\Windows\Shell\ClickToDo"                                                    /v "DisableClickToDo" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v "Value" /t REG_SZ /d "Deny" /f >NUL 2>&1

echo [K?] AI Features 
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\1546588812" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\1646260367" /v "EnabledState" /t REG_DWORD /d "2" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\1853569164" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\203105932"  /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\2381287564" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\3189581453" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\3389499533" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\3552646797" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\4027803789" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\4098520719" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\450471565" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\System\ControlSet001\Control\FeatureManagement\Overrides\8\929719951" /v "EnabledState" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentConnectors" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentWorkspaces" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableRemoteAgentConnectors" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Policies\WindowsNotepad" /v "DisableAIFeatures" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\Shell\Copilot" /v "CopilotDisabledReason" /t REG_SZ /d "FeatureIsDisabled" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\Shell\Copilot" /v "IsCopilotAvailable" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\Shell\Copilot\BingChat" /v "IsUserEligible" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\WindowsSettingHandlers" /v "A9HomeContentEnabled" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableImageCreator" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableCocreator" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableRemoveBackground" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableGenerativeFill" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableGenerativeErase" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization" /v "Value" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarCompanion" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "AutoOpenCopilotLargeScreens" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.Xbox.GamingAI.Companion.Host.GamingCompanionHostOptions" /v "Server" /t REG_SZ /d " " /f >NUL 2>&1
reg add "HKLM\Software\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.Xbox.GamingAI.Companion.Host.GamingCompanionHostOptions" /v "ActivationType" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessGenerativeAI" /t REG_DWORD /d "2" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessSystemAIModels" /t REG_DWORD /d "2" /f >NUL 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\Microsoft.Copilot_8wekyb3d8bbwe" /v "Value" /t REG_SZ /d "Deny" /f >NUL 2>&1

echo [K?] DirectX Global Settings
reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;" /f >NUL 2>&1

echo [K?] MS-Edge Remover
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "MicrosoftEdgeAutoLaunch_C09E690C3F322367E058F9F0FC90C11A" /f >NUL 2>&1
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" /f >NUL 2>&1
schtasks /delete /tn \MicrosoftEdgeUpdateBrowserReplacementTask /F >NUL 2>&1
schtasks /delete /tn \MicrosoftEdgeUpdateTaskMachineCore        /F >NUL 2>&1
schtasks /delete /tn \MicrosoftEdgeUpdateTaskMachineUA          /F >NUL 2>&1
sc delete edgeupdate >NUL 2>&1
sc delete edgeupdatem >NUL 2>&1
sc delete MicrosoftEdgeElevationService >NUL 2>&1
reg delete "HKLM\System\ControlSet001\Services\edgeupdate" /f >NUL 2>&1
reg delete "HKLM\System\ControlSet001\Services\edgeupdatem" /f >NUL 2>&1
reg delete "HKLM\System\ControlSet001\Services\MicrosoftEdgeElevationService" /f >NUL 2>&1
rmdir /S /Q "%systemdrive%\Program Files (x86)\Microsoft\Edge" >NUL 2>&1
rmdir /S /Q "%systemdrive%\Program Files (x86)\Microsoft\EdgeCore" >NUL 2>&1
rmdir /S /Q "%systemdrive%\Program Files (x86)\Microsoft\EdgeUpdate" >NUL 2>&1
rmdir /S /Q "%systemdrive%\Program Files (x86)\Microsoft\Temp" >NUL 2>&1

echo [K?] Windows Features (ViVeTool)
%windir%\ViVeTool /disable /name:SearchWebView2 >NUL 2>&1
%windir%\ViVeTool /disable /name:ExtendedTelemetry >NUL 2>&1
%windir%\ViVeTool /disable /name:CloudBackupRestoreSvc >NUL 2>&1
%windir%\ViVeTool /disable /name:SyncSettingForPersonalizationPolicy_42939444 >NUL 2>&1
%windir%\ViVeTool /disable /name:WindowsBackupComponent >NUL 2>&1
%windir%\ViVeTool /disable /name:TelemetryManager >NUL 2>&1
%windir%\ViVeTool /disable /name:SearchWebView2_Master >NUL 2>&1
%windir%\ViVeTool /disable /name:IrisBackupSignals_44597171 >NUL 2>&1
%windir%\ViVeTool /disable /name:EcoModeEnergySaver >NUL 2>&1
%windir%\ViVeTool /disable /name:EcoModeEnergySaver_AcOnly >NUL 2>&1
%windir%\ViVeTool /disable /name:DesktopSpotlightOEMContentDefaultImages >NUL 2>&1
%windir%\ViVeTool /disable /name:EcoModeEnergySaver_AcOnlyIcon >NUL 2>&1
%windir%\ViVeTool /disable /name:WingetUpdateInApplistBackup >NUL 2>&1
%windir%\ViVeTool /disable /name:OobePersonalizedOffers >NUL 2>&1
%windir%\ViVeTool /disable /name:POIrisClients >NUL 2>&1
%windir%\ViVeTool /disable /name:SettingsPersonalizedOffers >NUL 2>&1
%windir%\ViVeTool /disable /name:CopilotForImage >NUL 2>&1
%windir%\ViVeTool /disable /name:ConfigureRecallOC >NUL 2>&1
%windir%\ViVeTool /disable /name:HomepageCommercialSupport >NUL 2>&1
%windir%\ViVeTool /disable /name:HoverCards >NUL 2>&1
%windir%\ViVeTool /disable /name:MercuryADEPTAppBackup >NUL 2>&1
%windir%\ViVeTool /disable /name:Mercury_App_Backup_Shared >NUL 2>&1
%windir%\ViVeTool /disable /name:MercuryADEPTDeviceMetaDataBackup >NUL 2>&1
%windir%\ViVeTool /disable /name:MercuryADEPTUserIntentBackup >NUL 2>&1
%windir%\ViVeTool /disable /name:MercuryAppBackup_Post2309 >NUL 2>&1
%windir%\ViVeTool /disable /name:DirectCloudSync >NUL 2>&1
%windir%\ViVeTool /disable /name:OptimizationsInApplistBackup >NUL 2>&1
%windir%\ViVeTool /disable /name:SystrayCopilot_46874360 >NUL 2>&1
%windir%\ViVeTool /disable /name:GestureCopilot >NUL 2>&1
%windir%\ViVeTool /disable /name:IntelligenceInTextAndImage >NUL 2>&1
%windir%\ViVeTool /disable /name:SmartWorkflows >NUL 2>&1
%windir%\ViVeTool /disable /name:SmartWorkflowsAugLoopTelemetry >NUL 2>&1
%windir%\ViVeTool /disable /name:SpeakForMe >NUL 2>&1
%windir%\ViVeTool /disable /name:SystemLogEvents >NUL 2>&1
%windir%\ViVeTool /disable /name:ASRTest >NUL 2>&1
%windir%\ViVeTool /disable /name:WDSEnhancedData >NUL 2>&1
%windir%\ViVeTool /disable /name:FileExplorerInsights >NUL 2>&1
%windir%\ViVeTool /disable /id:56517033 >NUL 2>&1

echo [K?] Misc
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "WinStationsDisabled" /t REG_SZ /d "1" /f >NUL 2>&1
:: not sure what this does / test
reg add "HKLM\SYSTEM\ControlSet001\Control\GraphicsDrivers" /v "TdrLevel" /t REG_DWORD /d "0" /f >NUL 2>&1

:: Disabling RPC usage from a remote asset interacting with services
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "DisableRemoteScmEndpoints" /t REG_DWORD /d 1 /f >NUL 2>&1

:: Last Good Known Config Creation
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "ReportBootOk" /t REG_SZ /d "0" /f >NUL 2>&1

:: Media Player Usage Tracking
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\MediaPlayer\Preferences" /v "UsageTracking" /t REG_DWORD /d 0 /f >NUL 2>&1

:: Microsoft Diagnostic Tool from Registry
:: Mitigate CVE-2022-30190
reg delete "HKEY_CLASSES_ROOT\ms-msdt" /f >NUL 2>&1

reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "SecurityHealth" /f >NUL 2>&1
:: disable phishing protection
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\WTDS\Components" /v "ServiceEnabled" /t REG_DWORD /d "0" /f >NUL 2>&1

:: Password Expiration on Local Accounts
powershell "Get-LocalUser | Set-LocalUser -PasswordNeverExpires $true" >NUL 2>&1

:: UserAssist Hashes (TrackProgs)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecommendations" /t REG_DWORD /d "0" /f >NUL 2>&1
for /f "tokens=*" %%k in ('reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"') do (
	reg delete "%%k" /f >NUL 2>&1
)

powershell "Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*Windows.DevHome*" | Remove-AppxPackage -AllUsers"
powershell "Get-AppxPackage -AllUsers | Where-Object {$_.Name -Like '*OutlookForWindows*'} | Remove-AppxPackage -AllUsers -ErrorAction Continue"
powershell "Get-AppxPackage -AllUsers | Where-Object {$_.Name -Like '*Microsoft.Edge.GameAssist*'} | Remove-AppxPackage -AllUsers -ErrorAction Continue"
powershell "Get-AppxPackage -AllUsers | Where-Object {$_.Name -Like '*Microsoft.Services.Store.Engagement*'} | Remove-AppxPackage -AllUsers -ErrorAction Continue"
powershell "Get-AppxPackage -AllUsers | Where-Object {$_.Name -Like '*Microsoft.Advertising.Xaml*'} | Remove-AppxPackage -AllUsers -ErrorAction Continue"

:: re-enable taskmgr
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /f 

echo [K?] Replacing Screen Sketch with Lightshot 
:: disabling win shift s hotkeys
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisabledHotkeys" /t REG_SZ /d "S" /f 
reg add "HKCU\Control Panel\Keyboard"                                      /v "PrintScreenKeyForSnippingEnabled" /t REG_DWORD /d "0" /f
:: config lightshot to use win shift s
reg add "HKCU\Software\SkillBrains\Lightshot"                              /v "Hotkey_main_mod"  /t REG_DWORD /d "12" /f 
reg add "HKCU\Software\SkillBrains\Lightshot"                              /v "Hotkey_main_vk"   /t REG_DWORD /d "83" /f 
reg add "HKCU\Software\SkillBrains\Lightshot"                              /v "JpegQuality"      /t REG_DWORD /d "100" /f 
reg add "HKCU\Software\SkillBrains\Lightshot"                              /v "CaptureCursor"    /t REG_DWORD /d "0" /f 

:: Cleanup
cls
echo [K?] Cleanup
rmdir /s /q "%programdata%\TheKOS\bin\1" >nul 2>&1
rmdir /s /q "%programdata%\TheKOS\bin\2" >nul 2>&1
for %%a in (
    WindowsUpdate.log
    setuperr.log
    setupact.log
    lsasetup.log
    DtcInstall.log
    DirectX.log
    Logs\DirectX.log
) do (
    del "%windir%\%%a" >nul 2>&1
)
for %%a in (
    %windir%\SoftwareDistribution\Download\
    %windir%\Logs\
    %windir%\temp\
    %temp%\
) do (
    rd /s /q "%%a" 
)
del "%HOMEPATH%\AppData\Local\updater.log" >nul 2>&1
del "%HOMEPATH%\AppData\Local\UserProducts.xml" >nul 2>&1

echo [K?] Fix explorer white bar bug
cmd /c "start %windir%\explorer.exe"
taskkill /f /im explorer.exe >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
cmd /c "start %windir%\explorer.exe"

:: restart
timeout /t 3 /nobreak >nul 2>&1
shutdown /r /t 3 /c "restarting..."
start /b "" cmd /c del "%~f0"&exit /b