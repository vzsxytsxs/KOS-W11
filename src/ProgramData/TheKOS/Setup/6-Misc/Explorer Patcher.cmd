@echo off

:menu
cls
echo [1] Install Explorer Patcher
echo [2] Install Explorer Patcher DWM (It only works if Explorer Patcher is installed)
echo [3] Uninstall Explorer Patcher 
echo [4] Uninsatll Explorer Patcher DWM
echo [5] What is Explorer Patcher?
echo [C] Credits -> www.github.com/valinet

set /p input=":"

if "%input%"=="1" (
    goto :installEP
) else if "%input%"=="2" (
    goto :installEPDWM
) else if "%input%"=="3" (
    goto :uninstallEP
) else if "%input%"=="4" (
    goto :uninstallEPDWM
) else if "%input%"=="5" (
    goto :whatis
) else (
    exit
)

:installEP
cls
start /b /wait "" "%programdata%\TheKOS\bin\explorerPatcher\ep_setup.exe"
regedit /s "%programdata%\TheKOS\bin\explorerPatcher\explorerPatcherConfig.reg"
start explorer.exe
goto :menu

:installEPDWM
cls 
if exist "%programfiles%\ExplorerPatcher\ep_dwm_svc.exe" (
    sc.exe create ep_dwm binPath= "\"C:\Program Files\ExplorerPatcher\ep_dwm_svc.exe\" ep_dwm Global\ep_dwm" DisplayName= "ep_dwm" start= auto
    sc.exe description ep_dwm "ep_dwm Service"
    sc.exe start ep_dwm
    cls 
    echo Done.
    timeout /t 2 >nul 
    goto :menu
) else (
    echo install explorer patcher first. 
    timeout /t 5 >nul 
    goto :menu
)

:uninstallEP
cls 
start /b /wait "" "%programdata%\TheKOS\bin\explorerPatcher\ep_setup.exe" /uninstall
timeout /t 3 >nul 
start explorer.exe 
goto :menu 

:uninstallEPDWM
cls 
sc stop ep_dwm 
sc delete ep_dwm
goto :menu

:whatis 
cls
echo ExplorerPatcher is a free and open-source tool that customizes the Windows interface, mainly on Windows 11.
echo It restores classic features from older versions of Windows, such as the Windows 10-style taskbar, Start menu, and File Explorer.
echo The program works by modifying how the Windows shell (Explorer) behaves, allowing users to bring back removed features and improve usability without permanently changing system files.
pause
goto :menu

