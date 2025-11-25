@echo off
title Don't Close This Window / Updating....
taskkill /im explorer.exe /f >nul 2>&1

:: Change Ver 
Reg.exe add "HKLM\SOFTWARE\TheKOS" /v "currentver" /t REG_SZ /d "339" /f >nul 2>&1
label C: TheKOS-23H2-3.3.9
bcdedit /set {current} description "TheKOS-23H2-3.3.9"

:: updates





start /b "" cmd /c del "%~f0"&exit /b