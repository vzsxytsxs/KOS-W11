@echo off
title Congestion Provider (Made by Syrusaki)
echo What congestionprovider you want?
echo newreno (focus on latency, recommended)
echo bbr2 (focus on bandwidth and balanced latency)
echo dctcp (focus on lowest latency)
echo 1. newreno
echo 2. BBR2
echo 3. dctcp

set /p choice=Enter the number of the desired option and press Enter: 

if "%choice%"=="1" (
    echo Applying internet tweaks and newreno congestion provider
    timeout /t 2 >nul
    powershell netsh int tcp set security profiles=disable
    netsh int tcp set global autotuninglevel=experimental
    netsh int tcp set supp internet congestionprovider=newreno
    exit /b
) else if "%choice%"=="2" (
    echo Applying internet tweaks and BBR2 congestion provider
    timeout /t 2 >nul
    powershell netsh int tcp set security profiles=disable
    netsh int tcp set global autotuninglevel=experimental
    netsh int tcp set supp internet congestionprovider=BBR2
    exit /b
) else if "%choice%"=="3" (
    echo Applying internet tweaks and dctcp congestion provider
    timeout /t 2 >nul
    powershell netsh int tcp set security profiles=disable
    netsh int tcp set global autotuninglevel=experimental
    netsh int tcp set supp internet congestionprovider=dctcp
    exit /b
)