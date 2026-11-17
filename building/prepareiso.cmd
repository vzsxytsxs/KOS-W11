@echo off

:: %1 = mounted image folder (build.ps1 passes it); without an argument it uses the usual one and pauses at the end
set "mountDir=%~1"
if not defined mountDir set "mountDir=%temp%\MOUNT_DIR"
where powerrun >nul 2>&1 || (echo PowerRun not found in PATH. & exit /b 1)

:: remove the new Notepad (the classic notepad.exe stays) and the Windows Security app
echo appx\
set "appxFailed=0"
call :removeAppx Microsoft.WindowsNotepad
call :removeAppx Microsoft.SecHealthUI
if "%appxFailed%"=="1" exit /b 1
:: notepad.exe redirects to the new Notepad's alias: without this key it always opens the classic one
reg load HKLM\KOS_SOFTWARE "%mountDir%\Windows\System32\config\SOFTWARE" >nul || exit /b 1
reg delete "HKLM\KOS_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /f >nul 2>&1
reg unload HKLM\KOS_SOFTWARE >nul

:: the KOS wallpaper (src\Windows\Web\Wallpaper\Windows\img0.jpg) is the only one: other wallpapers and the themes that use them go
echo wallpapers\
for /d %%d in ("%mountDir%\Windows\Web\Wallpaper\*") do if /i not "%%~nxd"=="Windows" powerrun cmd.exe /c rmdir /s /q "%%~d"
powerrun cmd.exe /c rmdir /s /q "%mountDir%\Windows\Web\4K"
for %%a in (img19.jpg img0.png) do powerrun cmd.exe /c del /f "%mountDir%\Windows\Web\Wallpaper\Windows\%%a"
for %%a in (dark spotlight themeA themeB themeC themeD) do powerrun cmd.exe /c del /f "%mountDir%\Windows\Resources\Themes\%%a.theme"

:: remove useless/bloat system32 files
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
    CompatTelRunner.exe
    msra.exe
    dtdump.exe
    DeviceCensus.exe
) do (
    powerrun cmd.exe /c del /f "%mountDir%\Windows\system32\%%a" 
)

:: cleanup systemapps
echo systemapps\
PowerRun cmd.exe /c rmdir /s /q "%mountDir%\Windows\systemapps\MicrosoftWindows.Client.Photon_cw5n1h2txyewy"
PowerRun cmd.exe /c rmdir /s /q "%mountDir%\Windows\systemapps\MicrosoftWindows.Client.CoreAI_cw5n1h2txyewy"

PowerRun cmd.exe /c rmdir /s /q "%mountDir%\Windows\systemapps\Microsoft.AIFabric.CBS.1.6_8wekyb3d8bbwe"
PowerRun cmd.exe /c rmdir /s /q "%mountDir%\Windows\systemapps\MicrosoftWindows.Client.AIX_cw5n1h2txyewy"
PowerRun cmd.exe /c rmdir /s /q "%mountDir%\Windows\systemapps\Microsoft.Windows.AugLoop.CBS_8wekyb3d8bbwe"

:: CrossDeviceResume and SoftLanding are apps inside the Client.CBS package, which can't be removed: only their files go.
:: The CrossDeviceResume*.dll stay: the package declares them as a taskbar extension, and removing them is untested.
set "cbs=%mountDir%\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy"
for %%d in (CrossDeviceResume SoftLanding SoftLandingTask) do PowerRun cmd.exe /c rmdir /s /q "%cbs%\%%d"
PowerRun cmd.exe /c del /f "%cbs%\CrossDeviceResume.exe"

:: remove anything related to windows defender
echo win def 
for %%d in ("%mountDir%\Windows\System32\SecurityAndMaintenance_Error.png" "%mountDir%\Windows\System32\SecurityAndMaintenance.png" "%mountDir%\Windows\System32\SecurityHealthSystray.exe" "%mountDir%\Windows\System32\SecurityHealthService.exe" "%mountDir%\Windows\System32\SecurityHealthHost.exe" "%mountDir%\Windows\System32\drivers\WdDevFlt.sys" "%mountDir%\Windows\System32\drivers\WdBoot.sys" "%mountDir%\Windows\System32\drivers\WdFilter.sys" "%mountDir%\Windows\System32\wscsvc.dll" "%mountDir%\Windows\System32\drivers\WdNisDrv.sys" "%mountDir%\Windows\System32\wscsvc.dll" "%mountDir%\Windows\System32\wscproxystub.dll" "%mountDir%\Windows\System32\wscisvif.dll" "%mountDir%\Windows\System32\SecurityHealthProxyStub.dll" "%mountDir%\Windows\System32\smartscreen.dll" "%mountDir%\Windows\SysWOW64\smartscreen.dll" "%mountDir%\Windows\System32\smartscreen.exe" "%mountDir%\Windows\System32\DWWIN.EXE" "%mountDir%\Windows\SysWOW64\smartscreenps.dll" "%mountDir%\Windows\System32\smartscreenps.dll" "%mountDir%\Windows\System32\SecurityHealthCore.dll" "%mountDir%\Windows\System32\SecurityHealthSsoUdk.dll" "%mountDir%\Windows\System32\SecurityHealthUdk.dll" "%mountDir%\Windows\System32\SecurityHealthAgent.dll" "%mountDir%\Windows\System32\wscapi.dll" "%mountDir%\Windows\System32\wscadminui.exe" "%mountDir%\Windows\SysWOW64\GameBarPresenceWriter.exe" "%mountDir%\Windows\System32\GameBarPresenceWriter.exe" "%mountDir%\Windows\system32\drivers\msseccore.sys" "%mountDir%\Windows\system32\drivers\MsSecFlt.sys") DO PowerRun cmd.exe /c del /f "%%d"
:: /d: the items with wildcards are folders (without /d, for only finds files and nothing was deleted)
for /d %%d in ("%mountDir%\Windows\WinSxS\amd64_security-octagon*" "%mountDir%\Windows\WinSxS\x86_windows-defender*" "%mountDir%\Windows\WinSxS\wow64_windows-defender*" "%mountDir%\Windows\WinSxS\amd64_windows-defender*" "%mountDir%\Windows\SystemApps\Microsoft.Windows.AppRep.ChxApp_cw5n1h2txyewy" "%mountDir%\ProgramData\Microsoft\Windows Defender" "%mountDir%\ProgramData\Microsoft\Windows Defender Advanced Threat Protection" "%mountDir%\Program Files\Windows Defender Advanced Threat Protection" "%mountDir%\ProgramData\Microsoft\Windows Security Health" "%mountDir%\ProgramData\Microsoft\Storage Health" "%mountDir%\Program Files (x86)\Windows Defender" "%mountDir%\Program Files\Windows Defender" "%mountDir%\Windows\System32\SecurityHealth" "%mountDir%\Windows\System32\WebThreatDefSvc" "%mountDir%\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "%mountDir%\Windows\System32\WindowsPowerShell\v1.0\Modules\DefenderPerformance" "%mountDir%\Windows\System32\WindowsPowerShell\v1.0\Modules\Defender" "%mountDir%\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Defender" "%mountDir%\Windows\System32\HealthAttestationClient" "%mountDir%\Windows\GameBarPresenceWriter" "%mountDir%\Windows\bcastdvr") DO PowerRun cmd.exe /c rmdir "%%~d" /s /q

echo inboxapps\
powerrun cmd.exe /c rmdir /s /q "%mountDir%\Windows\inboxapps"

echo removing edge
:: Keep EdgeWebView, EdgeUpdate and EdgeCore for the inbox WebView2 runtime.
powerrun cmd.exe /c rmdir /S /Q "%mountDir%\Program Files (x86)\Microsoft\Edge" >NUL 2>&1

echo done.
if "%~1"=="" pause
exit /b 0

:: %1 = package name. Lifts the non-removable policy, removes the provisioned package and marks it as deprovisioned, so updates don't bring it back.
:removeAppx
set "appxFull="
for /f "tokens=2 delims=: " %%n in ('dism /English /Image:"%mountDir%" /Get-ProvisionedAppxPackages ^| findstr /i /c:"PackageName : %~1_"') do set "appxFull=%%n"
if not defined appxFull (echo %~1 is not in the image. & exit /b 0)
dism /English /Image:"%mountDir%" /Set-NonRemovableAppPolicy /PackageFamily:%~1_8wekyb3d8bbwe /NonRemovable:0 >nul 2>&1
dism /English /Image:"%mountDir%" /Remove-ProvisionedAppxPackage /PackageName:%appxFull% >nul || (echo Removing %~1 failed. & set "appxFailed=1" & exit /b 1)
reg load HKLM\KOS_SOFTWARE "%mountDir%\Windows\System32\config\SOFTWARE" >nul || (set "appxFailed=1" & exit /b 1)
reg add "HKLM\KOS_SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\%~1_8wekyb3d8bbwe" /f >nul
reg unload HKLM\KOS_SOFTWARE >nul
echo %~1 removed.
exit /b 0
