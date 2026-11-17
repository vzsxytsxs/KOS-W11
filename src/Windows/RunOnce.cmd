@echo off
title "KOS-26H2 Post-Script / Don't close this Window"
SETLOCAL EnableDelayedExpansion
set "KOS_LOG_ENABLED=0"
set "KOS_LOG_WARN=0"
set "KOS_LOG_FAIL=0"
for /f %%I in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss-fff"') do set "KOS_RUN_ID=%%I"
if defined KOS_RUN_ID (
    set "KOS_LOG_DIR=%ProgramData%\TheKOS\Logs\PostSetup\RunOnce-!KOS_RUN_ID!"
    md "!KOS_LOG_DIR!" >nul 2>&1
    if exist "!KOS_LOG_DIR!\" (
        set "KOS_LOG_FILE=!KOS_LOG_DIR!\runonce.log"
        set "KOS_LOG_STATUS=!KOS_LOG_DIR!\status.txt"
        >"!KOS_LOG_STATUS!" echo INCOMPLETE
        if exist "!KOS_LOG_STATUS!" set "KOS_LOG_ENABLED=1"
    )
)
if "!KOS_LOG_ENABLED!"=="0" (
    echo [KOS] WARNING: Post-setup log could not be initialized.
    set "KOS_LOG_DIR=%TEMP%"
)
call :KOSLog "runonce" "START" "0" "Post-setup started"
if /i "%~1"=="--test-logging" (
    if /i "%~2"=="incomplete" exit /b 0
    call :KOSLog "selftest" "OK" "0" "Log write check"
    call :KOSLog "selftest" "WARN" "999" "Simulated warning; no system changes"
    if /i "%~2"=="fail" call :KOSLog "selftest" "FAIL" "998" "Simulated failure; no system changes" "999"
    call :KOSFinalize
    exit /b 0
)
:: Security profile (Basic or Advanced): chosen here, applied further down by the profile script.
call :KOSChooseProfile
call :KOSLog "profile" "INFO" "0" "Security profile !KOS_PROFILE!" "0"
setx POWERSHELL_TELEMETRY_OPTOUT 1 >NUL 2>&1
setx DOTNET_CLI_TELEMETRY_OPTOUT 1 >NUL 2>&1

taskkill /im explorer.exe /f >nul 2>&1
taskkill /im taskmgr.exe /f >nul 2>&1
Reg.exe add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t "REG_DWORD" /d "100" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /t REG_SZ /d "." /f >nul 2>&1

:: label bcdedit and c:
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "currentver" /t REG_SZ /d "400" /f >nul 2>&1
label C: KOS-26H2-4.0.0
bcdedit /set {current} description "KOS-26H2-4.0.0"

:: oem info
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"         /v "Model" /t REG_SZ /d "KOS-W11" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"         /v "Manufacturer" /t REG_SZ /d "made by sawkataz/k?" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"         /v "SupportURL" /t REG_SZ /d "https://github.com/vzsxytsxs" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"                     /v "EditionSubVersion" /t REG_SZ /d "KOS-W11" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"                     /v "RegisteredOrganization" /t REG_SZ /d "made by sawkataz/k?" /f
reg add "HKLM\System\CurrentControlSet\Control\ComputerName\ActiveComputerName" /v "ComputerName" /t REG_SZ /d "KOS-W11" /f
reg add "HKLM\System\CurrentControlSet\Control\ComputerName\ComputerName"       /v "ComputerName" /t REG_SZ /d "KOS-W11" /f
reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters"               /v "Hostname" /t REG_SZ /d "KOS-W11" /f
reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters"               /v "NV Hostname" /t REG_SZ /d "KOS-W11" /f
cls

:: startup scripts (bin\3\startup.vbs) at every logon: scheduled task with highest privileges. The Run key does not elevate
:: when UAC is on (Basic profile), and the startup scripts need administrator.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%programdata%\TheKOS\bin\2\Register-StartupTask.ps1" >nul 2>&1
set "KOS_RC=!errorlevel!"
call :KOSResult "startup-task" "!KOS_RC!" "213" "Startup logon task"
cls

:: installers
echo [K?] Visual C++
if "!KOS_LOG_ENABLED!"=="1" (
    call "%programdata%\TheKOS\bin\1\Visual-C-Runtimes-All-in-One-Jun-2026\install_all.bat" >"!KOS_LOG_DIR!\vc-runtime.log" 2>&1
) else (
    call "%programdata%\TheKOS\bin\1\Visual-C-Runtimes-All-in-One-Jun-2026\install_all.bat"
)
set "KOS_RC=!errorlevel!"
call :KOSResult "vc-runtime" "!KOS_RC!" "201" "Visual C++ installer"
cls

echo [K?] DirectX
if "!KOS_LOG_ENABLED!"=="1" (
    call "%programdata%\TheKOS\bin\1\DirectX\install.bat" >"!KOS_LOG_DIR!\directx.log" 2>&1
) else (
    call "%programdata%\TheKOS\bin\1\DirectX\install.bat"
)
set "KOS_RC=!errorlevel!"
call :KOSResult "directx" "!KOS_RC!" "202" "DirectX installer"
timeout /t 5 /nobreak >NUL 2>&1
cls

echo [K?] 7z
if "!KOS_LOG_ENABLED!"=="1" (
    msiexec.exe /i "%programdata%\TheKOS\bin\1\7z2602-x64.msi" /passive /norestart /l*v "!KOS_LOG_DIR!\7zip.msi.log" >nul 2>&1
) else (
    msiexec.exe /i "%programdata%\TheKOS\bin\1\7z2602-x64.msi" /passive /norestart
)
set "KOS_RC=!errorlevel!"
call :KOSResult "7zip" "!KOS_RC!" "203" "7-Zip installer"
if not exist "%programfiles%\7-Zip\7z.exe" call :KOSLog "7zip-postcheck" "WARN" "1" "7z.exe not found after installer" "408"
cls

echo [K?] VLC 
"%programdata%\TheKOS\bin\1\vlc-3.0.23-win64.exe" /L=1033 /S
set "KOS_RC=!errorlevel!"
call :KOSResult "vlc" "!KOS_RC!" "204" "VLC installer"
cls

echo [K?] Lightshot 
call "%programdata%\TheKOS\bin\1\lightshot.exe" /VERYSILENT /NORESTART
set "KOS_RC=!errorlevel!"
call :KOSResult "lightshot" "!KOS_RC!" "205" "Lightshot installer"
cls

:: Open-Shell
echo [K?] Open-Shell
start /wait "" "%programdata%\TheKOS\bin\1\OpenShellSetup_4_4_198.exe" /qn ADDLOCAL=StartMenu
set "KOS_RC=!errorlevel!"
call :KOSResult "open-shell" "!KOS_RC!" "206" "Open-Shell installer"
timeout /t 2 /nobreak >NUL 2>&1
"%programfiles%\Open-Shell\StartMenu.exe" -xml "%programdata%\TheKOS\bin\2\config.xml"
PowerRun.exe /SW:0 taskkill.exe /im "StartMenuExperienceHost.exe" /t /f
PowerRun.exe /SW:0 powershell.exe Rename-Item -Path "%windir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" -NewName "StartMenuExperienceHost.old"

:: Notepad++ (configured and set as the default text editor further down)
echo [K?] Notepad++
start /wait "" "%programdata%\TheKOS\bin\1\npp.8.9.8.1.Installer.x64.exe" /S
set "KOS_RC=!errorlevel!"
call :KOSResult "notepadpp" "!KOS_RC!" "207" "Notepad++ installer"
:: no "Edit with Notepad++" in the context menu: its Windows 11 entry is a package that breaks when AppXSvc is disabled.
:: Done here because AppXSvc still runs; the wait is for the installer's regsvr32, which may still be registering it.
timeout /t 5 /nobreak >nul 2>&1
regsvr32 /u /s "%programfiles%\Notepad++\contextMenu\NppShell.dll"
powershell.exe -NoProfile -Command "Get-AppxPackage -AllUsers NotepadPlusPlus | Remove-AppxPackage -AllUsers" >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\*\shell\ANotepad++64" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\ANotepad++64" /f >nul 2>&1
rmdir /s /q "%programfiles%\Notepad++\contextMenu" >nul 2>&1

:: TheKOS Reg 
cls
call :KOSLog "tweaks" "START" "0" "Registry and system tweaks started"
echo [K?] 7z Config
start /b /wait "" "%programdata%\TheKOS\bin\2\7zip-pexp.bat" >NUL 2>&1
regedit /s "%programdata%\TheKOS\bin\2\TheKOS_reg.reg"
regedit /s "%programdata%\TheKOS\bin\2\legalnotice.reg"

:: Process mitigations, DEP, hypervisor, Spectre/Meltdown, VBS, DMA remapping and firewall rules: security
:: profile (Setup\3-Support\Windows Features\Security Profile Basic-Advanced.cmd), called before the services backup.

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
:: nx (DEP) and hypervisorlaunchtype: security profile.
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
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ProgramData%\TheKOS\Setup\3-Support\Services\ServiceBackup.ps1" -Mode Capture -Snapshot Windows.Default.Services -Full >"!KOS_LOG_DIR!\services-before.log" 2>&1
set "KOS_RC=!errorlevel!"
if not "!KOS_RC!"=="0" (
    call :KOSLog "services-before" "FAIL" "!KOS_RC!" "Default service capture failed" "301"
    echo [K?] WARNING: Services backup before tweaks failed.
) else (
    call :KOSLog "services-before" "OK" "0" "Default service capture completed" "0"
)

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
:: No comments inside the list below: in the for, each word of a :: line becomes a disabled service.
:: Notes: dispbrokerdesktopsvc is left out (with 4 the display configuration is not saved); CLFS too (the Common Log File
:: System under registry and file transactions: without it every DISM/CBS change fails with 0x80071A91, ERROR_RM_NOT_ACTIVE,
:: so optional features, Hyper-V, updates and repairs stop working); wuauserv, bits, dosvc, UsoSvc and
:: WaaSMedicSvc = Windows Update (dosvc breaks the Store); CDPSvc, CDPUserSvc and wlidsvc = GDID tracking; whesvc = Windows
:: Health and Optimized Experiences; WSAIFabricSvc = Windows AI Fabric, the AI runtime (the AIFabric package goes in prepareiso).
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
      TsUsbFlt
      tsusbhub
      storflt
      RDPDR
      hvservice
      HvHost     
      defragsvc
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
      lltdsvc
      gencounter
      scardsvr
      scdeviceenum
      scpolicysvc
      DPS
      DusmSvc
      wisvc
      Trkwks
      wuauserv
      bits
      dosvc
      UsoSvc
      WaaSMedicSvc
      CDPSvc
      CDPUserSvc
      wlidsvc
      whesvc
      WSAIFabricSvc
) do (
    PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%z" /v "Start" /t REG_DWORD /d "4" /f
)
:: Same, for services that not every build has (only where they exist, so no empty service key is created). They match
:: the toolbox defaults: DiagTrack = FiveM services; SessionEnv = Remote Desktop; cbdhsvc = Clipboard history (history off,
:: notifications kept); diagsvc, WdiServiceHost, WdiSystemHost = System usage and diagnostics; RasMan, RasAuto, PolicyAgent,
:: RASSSTP = VPN services; StiSvc and the Print* services, usbprint = Printing.
for %%z in (DiagTrack SessionEnv cbdhsvc diagsvc WdiServiceHost WdiSystemHost RasMan RasAuto PolicyAgent RASSSTP StiSvc PrintNotify usbprint PrintScanBrokerService PrintDeviceConfigurationService) do (
    reg query "HKLM\SYSTEM\CurrentControlSet\Services\%%z" >nul 2>&1 && PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%z" /v "Start" /t REG_DWORD /d "4" /f
)
cls

echo [K?] Deleting Windows Defender Services
for %%z in (
    Sense
    WinDefend
    MsSecCore
    wscsvc
    WdFilter
    WdBoot
    WdNisDrv
    WdNisSvc
    MsSecWfp
    MsSecFlt
    wtd
    webthreatdefusersvc
    webthreatdefsvc
    SecurityHealthService
) do ( 
    PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%z" /v "Start" /t REG_DWORD /d "4" /f
    PowerRun.exe /SW:0 Reg.exe delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%z" /f    
)
:: Windows Update
echo [K?] Windows Update - VantageOS/RaxOS
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "forceDisableWup" /t REG_SZ /d "1" /f >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Report policies" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Work" >nul 2>&1
powerrun "schtasks.exe" /change /disable /TN "\Microsoft\Windows\UpdateOrchestrator\Start Oobe Expedite Work" >nul 2>&1
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
:: The rest of the Off mode of Windows Update Enable-Disable.cmd (the toolbox's "Windows Update").
reg query "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" >nul 2>&1 && PowerRun.exe /SW:0 Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\uhssvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v UseWUServer /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 99 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f >nul
for %%v in (IsContinuousInnovationOptedIn AllowMUUpdateService IsExpedited) do reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v %%v /t REG_DWORD /d 0 /f >nul

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

:: Spectre/Meltdown: security profile.

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

:: Firewall rules: security profile (Advanced deletes them; Basic keeps the Windows ones and the KOS blocks).

:: autologgers
echo [K?] AutoLoggers and Firewall Rules
powerrun "powershell.exe" Remove-AutologgerConfig -Name "autologger-diagtrack-listener", "cellcore", "cloudexperiencehostoobe", "lwtnetlog", "mellanox-Kernel", "microsoft-windows-assignedaccess-trace", "microsoft-windows-rdp-graphics-rdpidd-trace"
cls

:: DMA remapping: security profile.

:: exclusive mode audio
echo [K?] Exclusive Mode On Audio Devices
for /f "delims=" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture') do PowerRun.exe /SW:0 Reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f >nul 2>&1
for /f "delims=" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture') do PowerRun.exe /SW:0 Reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f >nul 2>&1
for /f "delims=" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render') do PowerRun.exe /SW:0 Reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f >nul 2>&1
for /f "delims=" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render') do PowerRun.exe /SW:0 Reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f >nul 2>&1
cls

echo [K?] POW / Power Tweaks
:: Unhide All Pow Settings | VantageOS/RaxOS
Powershell -noprofile -executionpolicy bypass -file "%programdata%\TheKOS\bin\2\UnhideAllPowSettings.ps1"
cls

echo [K?] HiperBoot
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t Reg_DWORD /d "0" /f  >nul 2>&1

call "%programdata%\TheKOS\bin\2\DeviceProfile.cmd"
set "KOS_RC=!errorlevel!"
call :KOSLog "device-profile-type" "INFO" "0" "!KOS_DEVICE_TYPE!" "0"
call :KOSResult "device-profile" "!KOS_RC!" "211" "Laptop/desktop services and power defaults"
cls

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
if /i not "!KOS_DEVICE_TYPE!"=="DESKTOP" goto skipDesktopNicTweaks
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
:skipDesktopNicTweaks
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
Reg.exe add "HKLM\SOFTWARE\RegisteredApplications" /v "Windows Photo Viewer" /t REG_SZ /d "Software\Microsoft\Windows Photo Viewer\Capabilities" /f
powershell -NoProfile -ExecutionPolicy Bypass -File "%programdata%\TheKOS\bin\2\PhotoViewer-SetDefaults.ps1"
set "KOS_RC=!errorlevel!"
if not "!KOS_RC!"=="0" (
    call :KOSLog "photo-viewer" "WARN" "!KOS_RC!" "Check PhotoViewer-Defaults.log in LocalAppData" "401"
    echo [K?] Photo Viewer defaults failed; check %LOCALAPPDATA%\TheKOS\PhotoViewer-Defaults.log
) else (
    call :KOSLog "photo-viewer" "OK" "0" "Photo Viewer associations verified" "0"
)
cls

:: cross-device resume off (prepareiso removes its exe, so the shell doesn't try to start it)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" /v "IsResumeAllowed" /t REG_DWORD /d "0" /f >nul 2>&1

:: ren searchhost
cd %systemdrive%\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy
takeown /f "SearchHost.exe"
icacls "%systemdrive%\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\SearchHost.exe" /grant Administrators:F
ren SearchHost.exe SearchHost.old
taskkill /f /im SearchHost.exe /t

:: Security profile chosen at the start. Before the services backup, so luafv gets into the diff. The Basic UAC
:: only takes effect after the final reboot: the rest of RunOnce keeps running as administrator.
echo [K?] Security profile: !KOS_PROFILE!
call "%ProgramData%\TheKOS\Setup\3-Support\Windows Features\Security Profile Basic-Advanced.cmd" !KOS_PROFILE! --first-boot
set "KOS_RC=!errorlevel!"
call :KOSResult "security-profile" "!KOS_RC!" "212" "Security profile !KOS_PROFILE!"

:: Backup TheKOS Services
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ProgramData%\TheKOS\Setup\3-Support\Services\ServiceBackup.ps1" -Mode Capture -Snapshot TheKOS.services >"!KOS_LOG_DIR!\services-after.log" 2>&1
set "KOS_RC=!errorlevel!"
if not "!KOS_RC!"=="0" (
    call :KOSLog "services-after" "FAIL" "!KOS_RC!" "TheKOS service capture failed" "302"
    echo [K?] WARNING: Services backup after tweaks failed.
) else (
    call :KOSLog "services-after" "OK" "0" "TheKOS service capture completed" "0"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ProgramData%\TheKOS\Setup\3-Support\Services\ServiceBackup.ps1" -Mode Compare >"!KOS_LOG_DIR!\services-compare.log" 2>&1
    set "KOS_RC=!errorlevel!"
    if not "!KOS_RC!"=="0" (
        call :KOSLog "services-compare" "WARN" "!KOS_RC!" "Service comparison failed" "303"
        echo [K?] WARNING: Services comparison failed.
    ) else (
        call :KOSLog "services-compare" "OK" "0" "Service comparison completed" "0"
    )
)

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

:: wallpaper: the only one in the image (prepareiso removes the others)
reg add "HKCU\Control Panel\Desktop" /v "Wallpaper" /t REG_SZ /d "%windir%\Web\Wallpaper\Windows\img0.jpg" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "WallpaperStyle" /t REG_SZ /d "10" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "TileWallpaper" /t REG_SZ /d "0" /f >nul 2>&1

:: classic notepad.exe registration (the new Notepad is removed from the image by prepareiso)
call "%programdata%\TheKOS\Setup\6-Misc\Restore Classic Notepad.bat" <nul >nul 2>&1

:: Notepad++: dark mode, no restored tabs, default text editor
echo [K?] Notepad++ config
md "%appdata%\Notepad++" >nul 2>&1
copy /y "%programdata%\TheKOS\bin\2\notepadpp-config.xml" "%appdata%\Notepad++\config.xml" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -File "%programdata%\TheKOS\bin\2\NotepadPP-SetDefaults.ps1"
set "KOS_RC=!errorlevel!"
call :KOSResult "notepadpp-defaults" "!KOS_RC!" "405" "Notepad++ as the default text editor"

:: OneDrive: removes the client, the packages and the startup entries of all profiles; synced data stays.
echo [K?] Remove OneDrive
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%programdata%\TheKOS\bin\2\Remove-OneDrive.ps1" -LogPath "!KOS_LOG_DIR!\onedrive.log" >nul 2>&1
set "KOS_RC=!errorlevel!"
call :KOSResult "onedrive" "!KOS_RC!" "404" "OneDrive removal; see onedrive.log"

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
:: 26H2: Settings agent, Recall (2 = not even installed), Click to Do and the new name of the connectors policy
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableSettingsAgent" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d "0" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableClickToDo" /t REG_DWORD /d "1" /f >NUL 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "ConfigureAgentConnectors" /t REG_DWORD /d "2" /f >NUL 2>&1
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
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0" /f >NUL 2>&1
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
:: The build may have already removed Edge, Edge Update and WebView2 from the image (edge-webview2 extra): without them there is nothing to remove
set "KOS_EDGE="
for %%d in ("%ProgramFiles(x86)%\Microsoft\Edge\Application" "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" "%ProgramFiles(x86)%\Microsoft\EdgeWebView\Application") do if exist "%%~d\*" set "KOS_EDGE=1"
if defined KOS_EDGE (
    call "%programdata%\TheKOS\bin\3\edge-webview.cmd"
    set "KOS_RC=!errorlevel!"
    call :KOSResult "edge-webview" "!KOS_RC!" "403" "Edge/WebView script invocation; exit code is not a postcondition"
) else (
    call :KOSLog "edge-webview" "INFO" "0" "Edge, Edge Update and WebView2 already removed from the image" "0"
)

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
powershell "Get-AppxPackage -AllUsers | Where-Object {$_.Name -Like '*Microsoft.AutoSuperResolution*'} | Remove-AppxPackage -AllUsers -ErrorAction Continue"

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

:: explorer titlebar full path
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v "FullPath" /t REG_DWORD /d 1 /f

echo [K?] Suspend ctfmon fix 
:: https://ctfmon.vercel.app/
reg add "HKLM\Software\Microsoft\Input" /v "InputServiceEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Microsoft\Input" /v "InputServiceEnabledForCCI" /t REG_DWORD /d "0" /f

:: block gdid tracking
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "GDIDTRACKING" /t REG_SZ /d "1" /f >nul 2>&1
:: %programdata%\TheKOS\bin\3\cleanup.cmd

:: Baseline for the KOS Toolbox's state check: what the KOS keys hold now, before bin\2 is deleted.
echo [K?] Saving the KOS baseline
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ProgramData%\TheKOS\bin\2\Capture-KosBaseline.ps1" >"!KOS_LOG_DIR!\kos-baseline.log" 2>&1
set "KOS_RC=!errorlevel!"
if not "!KOS_RC!"=="0" (
    call :KOSLog "kos-baseline" "FAIL" "!KOS_RC!" "KOS baseline capture failed" "304"
) else (
    call :KOSLog "kos-baseline" "OK" "0" "KOS baseline saved" "0"
)

:: Cleanup
cls
echo [K?] Cleanup
call :KOSLog "cleanup" "START" "0" "One-time dependency cleanup started"
rmdir /s /q "%programdata%\TheKOS\bin\1" >nul 2>&1
rmdir /s /q "%programdata%\TheKOS\bin\2" >nul 2>&1
if exist "%programdata%\TheKOS\bin\1\" call :KOSLog "cleanup-bin1" "WARN" "1" "Dependency directory remains" "501"
if exist "%programdata%\TheKOS\bin\2\" call :KOSLog "cleanup-bin2" "WARN" "1" "One-time script directory remains" "502"
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
call :KOSLog "cleanup" "OK" "0" "One-time cleanup commands completed"

echo [K?] Fix explorer white bar bug
cmd /c "start %windir%\explorer.exe"
taskkill /f /im explorer.exe >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
cmd /c "start %windir%\explorer.exe"

:: restart
timeout /t 3 /nobreak >nul 2>&1
shutdown /r /t 3 /c "restarting..."
set "KOS_RC=!errorlevel!"
if not "!KOS_RC!"=="0" (
    call :KOSLog "reboot-request" "FAIL" "!KOS_RC!" "Windows rejected restart request" "503"
) else (
    call :KOSLog "reboot-request" "OK" "0" "Restart scheduled; boot completion not yet verified"
)
call :KOSFinalize
start /b "" cmd /c del "%~f0"&exit /b

:KOSResult
if "%~2"=="0" (
    call :KOSLog "%~1" "OK" "%~2" "%~4" "0"
    exit /b 0
)
if "%~2"=="3010" (
    call :KOSLog "%~1" "INFO" "%~2" "Restart requested by installer" "0"
    exit /b 0
)
call :KOSLog "%~1" "WARN" "%~2" "%~4" "%~3"
exit /b 0

:KOSLog
if /i "%~2"=="WARN" set /a KOS_LOG_WARN+=1 >nul
if /i "%~2"=="FAIL" set /a KOS_LOG_FAIL+=1 >nul
if "!KOS_LOG_ENABLED!"=="1" >>"!KOS_LOG_FILE!" echo [%date% %time%] event=%~1 status=%~2 native_exit=%~3 kos_code=%~5 detail=%~4
exit /b 0

:KOSFinalize
set "KOS_FINAL_STATUS=COMPLETED"
if not "!KOS_LOG_WARN!"=="0" set "KOS_FINAL_STATUS=COMPLETED_WITH_WARNINGS"
if not "!KOS_LOG_FAIL!"=="0" set "KOS_FINAL_STATUS=COMPLETED_WITH_ERRORS"
call :KOSLog "runonce" "INFO" "0" "Final status !KOS_FINAL_STATUS!; warnings !KOS_LOG_WARN!; errors !KOS_LOG_FAIL!" "0"
if "!KOS_LOG_ENABLED!"=="1" >"!KOS_LOG_STATUS!" echo !KOS_FINAL_STATUS! warnings=!KOS_LOG_WARN! errors=!KOS_LOG_FAIL!
exit /b 0

:KOSChooseProfile
:: A profile already saved in HKLM\SOFTWARE\TheKOS\Profile (e.g. test image) skips the question.
set "KOS_PROFILE="
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\TheKOS" /v Profile 2^>nul ^| findstr /i "REG_SZ"') do set "KOS_PROFILE=%%B"
if /i "!KOS_PROFILE!"=="basic" exit /b 0
if /i "!KOS_PROFILE!"=="advanced" exit /b 0
if /i "!KOS_PROFILE!"=="extreme" (set "KOS_PROFILE=advanced" & exit /b 0)
cls
echo.
echo  KOS security profile
echo  ====================
echo.
echo  [B] Basic - default
echo      Keeps the Windows protections that anti-cheats and some apps expect:
echo      UAC on, DEP on, CFG on, Spectre/Meltdown and process mitigations on,
echo      VBS / memory integrity as Windows sets it, hypervisor available,
echo      DMA remapping and the default firewall rules kept.
echo.
echo  [A] Advanced
echo      Turns those protections off for the lowest overhead:
echo      UAC off, DEP off, CFG off, Spectre/Meltdown and process mitigations off,
echo      VBS and memory integrity off, hypervisor off, DMA remapping off,
echo      firewall rules cleared. Some anti-cheats such as FACEIT and Vanguard
echo      may refuse to run.
echo.
echo  Both get the same debloat, privacy, services and performance tweaks.
echo  Defender and SmartScreen are removed in both.
echo  To switch later: Setup\3-Support\Windows Features\Security Profile Basic-Advanced.cmd
echo.
choice /c BA /n /t 80 /d B /m "Choose B or A - Basic in 80 seconds: "
if errorlevel 2 (set "KOS_PROFILE=advanced") else set "KOS_PROFILE=basic"
cls
exit /b 0
