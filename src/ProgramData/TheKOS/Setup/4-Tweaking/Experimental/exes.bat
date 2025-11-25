@echo off
taskkill /f /im ctfmon.exe
NSudoLG.exe -U:S -P:E cmd.exe /c ren "%WINDIR%\System32\ctfmon.exe" "ctfmon.exee"
taskkill /f /im TextInputHost.exe
NSudoLG.exe -U:S -P:E cmd.exe /c ren "%WINDIR%\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\TextInputHost.exe" "TextInputHost.exee"
taskkill /f /im backgroundTaskHost.exe
NSudoLG.exe -U:S -P:E cmd.exe /c ren "%WINDIR%\System32\backgroundTaskHost.exe" "backgroundTaskHost.exee"