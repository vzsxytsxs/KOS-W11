@echo off
title Nvidia Tool by vzsxytsxs
setlocal enabledelayedexpansion

:menu
cls
echo Choose an option: 
echo [1] Nvidia Profile Inspector
echo [2] Nvidia Control Panel (Disable/Enable)
echo [3] Dynamic Power State (P-State - Disable/Enable)
echo [4] High-Bandwidth Digital Content Protection (HDCP - Disable/Enable) 
echo [5] Driver Debloat and Basics Tweaks
echo [6] Misc 
set /p input=":"

if "%input%"=="1" (
    goto nvpi
) else if "%input%"=="2" (
    goto nvcp
) else if "%input%"=="3" (
    goto pstate
) else if "%input%"=="4" (
    goto hdcp 
) else if "%input%"=="5" (
    goto nv_tweaks_debloat
) else if "%input%"=="6" (
    goto misc 
) else (
    echo invalid choice. try again.
    pause
    goto menu
)

:nvpi
cls 
echo [1] Basic Profile 
echo [2] Latency Profile
echo [3] Fps Average
echo [4] Main Menu
set /p input=":"

if "%input%"=="1" (
    goto nvpi_basic
) else if "%input%"=="2" (
    goto nvpi_latency
) else if "%input%"=="3" (
    goto nvpi_fps
) else if "%input%"=="4" (
    goto menu
) else (
    echo invalid choice. try again.
    pause
    goto nvpi
)

:: apply .nips
:nvpi_basic
cls
powershell Invoke-WebRequest -Uri "https://github.com/vzsxytsxs/host/raw/refs/heads/main/nv/nvidiaProfileInspector.exe" -OutFile "C:\Windows\Temp\nvpi.exe"
powershell Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vzsxytsxs/host/refs/heads/main/nv/basic.nip" -OutFile "C:\Windows\Temp\basic.nip"
"C:\Windows\Temp\nvpi.exe" "C:\Windows\Temp\basic.nip" >nul 2>&1
cd /d C:\Windows\Temp >nul 2>&1
del /f /q nvpi.exe >nul 2>&1
del /f /q basic.nip >nul 2>&1
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:nvpi_latency
cls
powershell Invoke-WebRequest -Uri "https://github.com/vzsxytsxs/host/raw/refs/heads/main/nv/nvidiaProfileInspector.exe" -OutFile "C:\Windows\Temp\nvpi.exe"
powershell Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vzsxytsxs/host/refs/heads/main/nv/latency.nip" -OutFile "C:\Windows\Temp\latency.nip"
"C:\Windows\Temp\nvpi.exe" "C:\Windows\Temp\latency.nip" >nul 2>&1
cd /d C:\Windows\Temp >nul 2>&1
del /f /q nvpi.exe >nul 2>&1
del /f /q latency.nip >nul 2>&1
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:nvpi_fps
cls
powershell Invoke-WebRequest -Uri "https://github.com/vzsxytsxs/host/raw/refs/heads/main/nv/nvidiaProfileInspector.exe" -OutFile "C:\Windows\Temp\nvpi.exe"
powershell Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vzsxytsxs/host/refs/heads/main/nv/fps.nip" -OutFile "C:\Windows\Temp\fps.nip"
"C:\Windows\Temp\nvpi.exe" "C:\Windows\Temp\fps.nip" >nul 2>&1
cd /d C:\Windows\Temp >nul 2>&1
del /f /q nvpi.exe >nul 2>&1
del /f /q fps.nip >nul 2>&1
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:nvcp
cls 
echo [1] Enable NVCP 
echo [2] Disable NVCP 
echo [3] Main Menu
set /p input=":"

if "%input%"=="1" (
    goto nvcp_e
) else if "%input%"=="2" (
    goto nvcp_d
) else if "%input%"=="3" (
    goto menu
) else (
    echo invalid choice. try again.
    pause
    goto nvcp
)

:: disable/enable nvcp
:nvcp_e 
cls
sc config NVDisplay.ContainerLocalSystem start= auto >NUL 2>&1
sc start NVDisplay.ContainerLocalSystem >NUL 2>&1
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:nvcp_d 
cls
sc config NVDisplay.ContainerLocalSystem start= disabled >NUL 2>&1
sc stop NVDisplay.ContainerLocalSystem >NUL 2>&1
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:pstate 
cls 
echo [1] Enable Dynamic P-states
echo [2] Disable Dynamic P-states
echo [3] Main Menu
set /p input=":"

if "%input%"=="1" (
    goto pstate_e
) else if "%input%"=="2" (
    goto pstate_d
) else if "%input%"=="3" (
    goto menu
) else (
    echo invalid choice. try again.
    pause
    goto pstate
)

:: enable/disable pstates
:pstate_e
cls
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\ControlSet001\Enum\%%i" /v "Driver"') do (
		for /f %%i in ('echo %%a ^| findstr "{"') do (
		     reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "DisableDynamicPstate" /t REG_DWORD /d "0" /f
                   )
                )
             )
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:pstate_d 
cls
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\ControlSet001\Enum\%%i" /v "Driver"') do (
		for /f %%i in ('echo %%a ^| findstr "{"') do (
		     reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f
                   )
                )
             )
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:hdcp  
cls 
echo [1] Enable HDCP 
echo [2] Disable HDCP 
echo [3] Main Menu 
set /p input=":"

if "%input%"=="1" (
    goto hdcp_e
) else if "%input%"=="2" (
    goto hdcp_d
) else if "%input%"=="3" (
    goto menu
) else (
    echo invalid choice. try again.
    pause
    goto hdcp
)

:: enable/disable hdcp
:hdcp_e 
cls
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\ControlSet001\Enum\%%i" /v "Driver"') do (
		for /f %%i in ('echo %%a ^| findstr "{"') do (
		     Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "0" /f > nul 2>&1
                   )
                )
             )
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:hdcp_d 
cls
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\ControlSet001\Enum\%%i" /v "Driver"') do (
		for /f %%i in ('echo %%a ^| findstr "{"') do (
		     Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1" /f > nul 2>&1
                   )
                )
             ) 
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu

:nv_tweaks_debloat
cls
echo [1] Basics Tweaks
echo [2] Driver Debloat (Advanced)
echo [3] Main Menu 
set /p input=":"

if "%input%"=="1" (
    goto nv_tweaks
) else if "%input%"=="2" (
    goto nv_debloat
) else if "%input%"=="3" (
    goto menu
) else (
    echo invalid choice. try again.
    pause
    goto misc
)

:nv_tweaks 
cls
echo [+] Enabling Message Signaled Interrupt Mode (MSI)
for /f %%g in ('wmic path win32_videocontroller get PNPDeviceID ^| findstr /L "VEN_"') do (
reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%g\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f  
reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%g\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "0" /f 
)

echo [+] Disabling Crash Report 
schtasks /change /disable /tn "NvTmRep_CrashReport1_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" 
schtasks /change /disable /tn "NvTmRep_CrashReport2_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" 
schtasks /change /disable /tn "NvTmRep_CrashReport3_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" 
schtasks /change /disable /tn "NvTmRep_CrashReport4_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" 
echo [+] Disabling Driver Update Check (Geforce Experience)
schtasks /change /disable /tn "NvDriverUpdateCheckDaily_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" 
echo [+] Disabling Geforce Experience Self Update
schtasks /change /disable /tn "NVIDIA GeForce Experience SelfUpdate_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" 

echo [+] Disabling Write Combining
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisableWriteCombining" /t REG_DWORD /d "1" /f 

echo [+] Disabling Telemetry through the Registry (SendTelemetryData)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup" /v "SendTelemetryData" /t REG_DWORD /d "0" /f

echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu 

:nv_debloat 
:: all from catgamerop
cls
echo Do you have Geforce Experience installed? (y/n)
:choice
set /p userChoice=
if /i "%userChoice%"=="n" (
    cls
    echo [+] Removing GeForce components.
    rmdir /s /q "C:\Program Files\NVIDIA Corporation">nul 2>&1
    cd /d "C:\Windows\System32\DriverStore\FileRepository\nv_*" >nul 2>&1
    del /f nvFBC*.dll, nvIFR*.dll >nul 2>&1
    cd /d ".\Display.NvContainer\plugins\LocalSystem" >nul 2>&1
    takeown /r /d Y /f * >nul 2>&1
    icacls * /grant "%USERNAME%":F >nul 2>&1
    @REM del /f NvcDispWatchdog.dll >nul 2>&1 maybe breaks control panel
    cd /d "../Session" >nul 2>&1
    takeown /f * /r /d Y >nul 2>&1
    icacls * /grant "%USERNAME%":F >nul 2>&1
    del /f _NvGSTPlugin.dll >nul 2>&1
    cd /d "C:\Windows\System32" >nul 2>&1
    takeown /r /d Y /f "nv*.*" >nul 2>&1
    icacls "nv*.*" /grant "%USERNAME%":F /t >nul 2>&1
    del /f NvFBC64.dll, NvIFR64.dll >nul 2>&1
    cd /d "C:\Windows\SysWOW64" >nul 2>&1
    takeown /r /d Y /f "nv*.*" >nul 2>&1
    del /f NvFBC.dll, NvIFR.dll >nul 2>&1
    goto start
) else if /i "%userChoice%"=="y" (
    cls
    echo [-] Skipping GeForce components.
    timeout /t 2 /nobreak >NUL 2>&1
    goto start
) else (
    cls
    echo Invalid choice. Please type 'y' or 'n'.
    timeout /t 2 /nobreak >NUL 2>&1
    goto choice
)

:start
cls
rmdir /s /q "C:\Windows\System32\drivers\NVIDIA Corporation" >nul 2>&1
cd /d "C:\Windows\System32\DriverStore\FileRepository\" >nul 2>&1
dir NvTelemetry64.dll /a /b /s >nul 2>&1
del NvTelemetry64.dll /a /s >nul 2>&1
reg add "HKCU\SOFTWARE\NVIDIA Corporation\NVControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d "0" /f >nul 2>&1
cd /d "C:\Windows\System32\DriverStore\FileRepository\nv_*" >nul 2>&1
takeown /r /d Y /f * >nul 2>&1
takeown /f NVWMI /R /D Y >nul 2>&1
icacls "NVWMI" /grant "%USERDOMAIN%\%USERNAME%":F /t >nul 2>&1
rmdir /s /q NVWMI >nul 2>&1
echo [+] Deleting NvCamera
takeown /f NvCamera /R /D Y >nul 2>&1
icacls "NvCamera" /grant "%USERDOMAIN%\%USERNAME%":F /t >nul 2>&1
rmdir /s /q NvCamera >nul 2>&1
reg delete "HKLM\System\ControlSet001\Services\nvlddmkm\NvCamera" /f >nul 2>&1
icacls * /grant "%USERDOMAIN%\%USERNAME%":(F) /t >nul 2>&1
echo [+] Deleting NvTelemetry64.dll 
del /f "NvTelemetry64.dll" >nul 2>&1
del /f nvptxJitCompiler32.dll, nvptxJitCompiler64.dll >nul 2>&1
del /f nvsmartmax*.*,  nvinfo.pb >nul 2>&1
del /f nvIccAdvancedColorIdentity.icm, nvEncMFT*.dll, nvDevMFT*.dll >nul 2>&1
cd /d "./Display.NvContainer" >nul 2>&1
takeown /f * /R /D Y >nul 2>&1
icacls * /grant "%USERNAME%":F >nul 2>&1
del /f "nvtopps.db3" >nul 2>&1
cd /d "./plugins/LocalSystem/" >nul 2>&1
takeown /f _DisplayDriverR*.dll /R /D Y >nul 2>&1
icacls "_DisplayDriverRAS.dll" /grant "%USERNAME%":F >nul 2>&1
del /f _DisplayDriverRAS.dll >nul 2>&1
:: del /f _NvMsgBusBroadcast.dll >nul 2>&1
del /f _nvtopps.dll >nul 2>&1
cd /d "../Session" >nul 2>&1
takeown /f * /R /D Y >nul 2>&1
icacls * /grant "%USERNAME%":F >nul 2>&1
del /f nvprofileupdaterplugin.dll >nul 2>&1
cd /d "C:\Windows\System32" >nul 2>&1
del /f nvinfo.pb >nul 2>&1
rmdir /s /q lxss >nul 2>&1
del MCU.exe, nvcudadebugger.dll, nvdebugdump.exe /f >nul 2>&1
sc config NVDisplay.ContainerLocalSystem start= auto >NUL 2>&1
sc start NVDisplay.ContainerLocalSystem >NUL 2>&1
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto menu 

:misc 
cls
echo [1] Enable/Disable Nvidia Tray Icon
echo [2] Enable/Disable Nvidia Logging
echo [3] Enable/Disable Display Power Saving
echo [4] Enable/Disable DLSS Indicator
echo [5] Enable/Disable Error Correcting Code (ECC) 
echo [6] Main Menu
set /p input=":"

if "%input%"=="1" (
    goto nv_tray
) else if "%input%"=="2" (
    goto nv_log
) else if "%input%"=="3" (
    goto nv_display
) else if "%input%"=="4" (
    goto nv_dlss
) else if "%input%"=="5" (
    goto nv_ecc
) else if "%input%"=="6" (
    goto menu
) else (
    echo invalid choice. try again.
    pause
    goto misc
)

:nv_tray
cls
echo [1] Enable Tray Icon
echo [2] Disable Tray Icon
echo [3] Misc Menu
set /p input=":"

if "%input%"=="1" (
    call tray_e
) else if "%input%"=="2" (
    goto tray_d
) else if "%input%"=="3" (
    goto misc 
) else (
    echo invalid choice. try again.
    pause
    goto misc
)

:: enable/disable tray icon
:tray_e
cls
reg delete "HKLM\SOFTWARE\NVIDIA Corporation\Global\CoProcManager" /v ShowTrayIcon /f
reg delete "HKLM\SOFTWARE\NVIDIA Corporation\NvTray" /v StartOnLogin /f 
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v HideXGpuTrayIcon /f 
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc

:tray_d 
cls
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvTray" /v StartOnLogin /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v HideXGpuTrayIcon /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\CoProcManager" /v ShowTrayIcon /t REG_DWORD /d 0 /f
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 

:nv_log
cls
echo [1] Enable Nvidia Logging
echo [2] Disable Nvidia Logging
echo [3] Misc Menu
set /p input=":"

if "%input%"=="1" (
    goto log_e
) else if "%input%"=="2" (
    goto log_d
) else if "%input%"=="3" (
    goto misc
) else (
    echo invalid choice. try again.
    pause
    goto misc
)

:: disable/enable logging
:log_e
cls
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v LogWarningEntries /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v LogPagingEntries /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v LogEventEntries /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v LogErrorEntries /t REG_DWORD /d 1 /f
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 

:log_d
cls
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v LogWarningEntries /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v LogPagingEntries /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v LogEventEntries /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v LogErrorEntries /t REG_DWORD /d 0 /f
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 

:nv_display
cls
echo [1] Enable Display Power Saving
echo [2] Disable Display power Saving 
echo [3] Misc Menu 
set /p input=":"

if "%input%"=="1" (
    goto display_e
) else if "%input%"=="2" (
    goto display_d
) else if "%input%"=="3" (
    goto misc
) else (
    echo invalid choice. try again.
    pause
    goto misc
)

:: disable/enable display power saving
:display_e
cls
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v DisplayPowerSaving /t REG_DWORD /d 1 /f
reg add "HKLM\Software\NVIDIA Corporation\Global\NVTweak" /v DisplayPowerSaving /t REG_DWORD /d 1 /f
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 

:display_d
cls
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v DisplayPowerSaving /t REG_DWORD /d 0 /f
reg add "HKLM\Software\NVIDIA Corporation\Global\NVTweak" /v DisplayPowerSaving /t REG_DWORD /d 0 /f
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 

:nv_dlss
cls
echo [1] Enable DLSS Indicator
echo [2] Disable DLSS Indicator
echo [3] Misc Menu 
set /p input=":"

if "%input%"=="1" (
    goto dlss_e
) else if "%input%"=="2" (
    goto dlss_d
) else if "%input%"=="3" (
    goto misc
) else (
    echo invalid choice. try again.
    pause
    goto misc
)

:: disable/enable dlss indicator
:dlss_e
cls
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NGXCore" /v ShowDlssIndicator /t REG_DWORD /d 1024 /f
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 

:dlss_d
cls
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NGXCore" /v ShowDlssIndicator /t REG_DWORD /d 0 /f
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 

:nv_ecc
cls 
echo [1] Enable Error Correcting Code (ECC) 
echo [2] Disable Error Correcting Code (ECC) 
echo [3] Misc Menu 
set /p input=":"

if "%input%"=="1" (
    goto ecc_e
) else if "%input%"=="2" (
    goto ecc_d
) else if "%input%"=="3" (
    goto misc
) else (
    echo invalid choice. try again.
    pause
    goto misc
)

:: disable/enable ecc
:ecc_e
cls
C:\Windows\System32\nvidia-smi.exe -e 1
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 

:ecc_d
cls
C:\Windows\System32\nvidia-smi.exe -e 0
echo [=] All done.
timeout /t 2 /nobreak >NUL 2>&1
goto misc 