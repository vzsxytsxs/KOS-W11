@echo off

:: maybe fixed, idk tbh
set "mountDir=%temp%\MOUNT_DIR"

echo system32\
for %%a in (
    mobsync.exe 
    smartscreen.exe
    smartscreen.dll 
    mblctr.exe 
    gamebarpresencewriter.exe 
    gamebarpresencewriter.proxy.dll 
    onedrive.ico 
    onedrivesetup.exe
) do (
    powerrun cmd.exe /c del /f "%mountDir%\Windows\system32\%%a" 
)

echo systemapps\
PowerRun cmd.exe /c rmdir /s /q "%mountDir%\Windows\systemapps\MicrosoftWindows.Client.Photon_cw5n1h2txyewy"
PowerRun cmd.exe /c rmdir /s /q "%mountDir%\Windows\systemapps\MicrosoftWindows.Client.CoreAI_cw5n1h2txyewy"

:: rmdir /s /q %mountDir%\Windows\systemapps\MicrosoftWindows.Client.Photon_cw5n1h2txyewy
:: rmdir /s /q %mountDir%\Windows\systemapps\MicrosoftWindows.Client.CoreAI_cw5n1h2txyewy

echo win def 
for %%d in ("%mountDir%\Windows\WinSxS\FileMaps\wow64_windows-defender*.manifest" "%mountDir%\Windows\WinSxS\FileMaps\x86_windows-defender*.manifest" "%mountDir%\Windows\WinSxS\FileMaps\amd64_windows-defender*.manifest" "%mountDir%\Windows\System32\SecurityAndMaintenance_Error.png" "%mountDir%\Windows\System32\SecurityAndMaintenance.png" "%mountDir%\Windows\System32\SecurityHealthSystray.exe" "%mountDir%\Windows\System32\SecurityHealthService.exe" "%mountDir%\Windows\System32\SecurityHealthHost.exe" "%mountDir%\Windows\System32\drivers\SgrmAgent.sys" "%mountDir%\Windows\System32\drivers\WdDevFlt.sys" "%mountDir%\Windows\System32\drivers\WdBoot.sys" "%mountDir%\Windows\System32\drivers\WdFilter.sys" "%mountDir%\Windows\System32\wscsvc.dll" "%mountDir%\Windows\System32\drivers\WdNisDrv.sys" "%mountDir%\Windows\System32\wscsvc.dll" "%mountDir%\Windows\System32\wscproxystub.dll" "%mountDir%\Windows\System32\wscisvif.dll" "%mountDir%\Windows\System32\SecurityHealthProxyStub.dll" "%mountDir%\Windows\System32\smartscreen.dll" "%mountDir%\Windows\SysWOW64\smartscreen.dll" "%mountDir%\Windows\System32\smartscreen.exe" "%mountDir%\Windows\SysWOW64\smartscreen.exe" "%mountDir%\Windows\System32\DWWIN.EXE" "%mountDir%\Windows\SysWOW64\smartscreenps.dll" "%mountDir%\Windows\System32\smartscreenps.dll" "%mountDir%\Windows\System32\SecurityHealthCore.dll" "%mountDir%\Windows\System32\SecurityHealthSsoUdk.dll" "%mountDir%\Windows\System32\SecurityHealthUdk.dll" "%mountDir%\Windows\System32\SecurityHealthAgent.dll" "%mountDir%\Windows\System32\wscapi.dll" "%mountDir%\Windows\System32\wscadminui.exe" "%mountDir%\Windows\SysWOW64\GameBarPresenceWriter.exe" "%mountDir%\Windows\System32\GameBarPresenceWriter.exe" "%mountDir%\Windows\SysWOW64\DeviceCensus.exe" "%mountDir%\Windows\SysWOW64\CompatTelRunner.exe" "%mountDir%\Windows\system32\drivers\msseccore.sys" "%mountDir%\Windows\system32\drivers\MsSecFltWfp.sys" "%mountDir%\Windows\system32\drivers\MsSecFlt.sys") DO PowerRun cmd.exe /c del /f "%%d"
for %%d in ("%mountDir%\Windows\WinSxS\amd64_security-octagon*" "%mountDir%\Windows\WinSxS\x86_windows-defender*" "%mountDir%\Windows\WinSxS\wow64_windows-defender*" "%mountDir%\Windows\WinSxS\amd64_windows-defender*" "%mountDir%\Windows\SystemApps\Microsoft.Windows.AppRep.ChxApp_cw5n1h2txyewy" "%mountDir%\ProgramData\Microsoft\Windows Defender" "%mountDir%\ProgramData\Microsoft\Windows Defender Advanced Threat Protection" "%mountDir%\Program Files (x86)\Windows Defender Advanced Threat Protection" "%mountDir%\Program Files\Windows Defender Advanced Threat Protection" "%mountDir%\ProgramData\Microsoft\Windows Security Health" "%mountDir%\ProgramData\Microsoft\Storage Health" "%mountDir%\WINDOWS\System32\drivers\wd" "%mountDir%\Program Files (x86)\Windows Defender" "%mountDir%\Program Files\Windows Defender" "%mountDir%\Windows\System32\SecurityHealth" "%mountDir%\Windows\System32\WebThreatDefSvc" "%mountDir%\Windows\System32\Sgrm" "%mountDir%\Windows\Containers\WindowsDefenderApplicationGuard.wim" "%mountDir%\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "%mountDir%\Windows\System32\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "%mountDir%\Windows\System32\WindowsPowerShell\v1.0\Modules\Defender" "%mountDir%\Windows\System32\Tasks_Migrated\Microsoft\Windows\Windows Defender" "%mountDir%\Windows\System32\Tasks\Microsoft\Windows\Windows Defender" "%mountDir%\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Defender" "%mountDir%\Windows\System32\HealthAttestationClient" "%mountDir%\Windows\GameBarPresenceWriter" "%mountDir%\Windows\bcastdvr" "%mountDir%\Windows\Containers\serviced\WindowsDefenderApplicationGuard.wim") do PowerRun cmd.exe /c rmdir "%%~d" /s /q

echo inboxapps\
powerrun cmd.exe /c rmdir /s /q "%mountDir%\Windows\inboxapps"

echo done.
pause
