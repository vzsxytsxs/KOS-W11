@echo off
:: Edge Update is shared with WebView2. Keep its binaries and registrations,
:: but disable its scheduled/background activity and remove only the browser.
:: Task Scheduler appends GUIDs to these task names on some installations.
powershell.exe -NoProfile -Command "Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'MicrosoftEdgeUpdateBrowserReplacementTask*' } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue" >NUL 2>&1
powershell.exe -NoProfile -Command "Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'MicrosoftEdgeUpdateTaskMachineCore*' -or $_.TaskName -like 'MicrosoftEdgeUpdateTaskMachineUA*' -or $_.TaskName -like 'MicrosoftEdgeUpdateTaskUser*' } | Disable-ScheduledTask -ErrorAction SilentlyContinue" >NUL 2>&1
sc stop edgeupdate >NUL 2>&1
sc stop edgeupdatem >NUL 2>&1
sc config edgeupdate start= disabled >NUL 2>&1
sc config edgeupdatem start= disabled >NUL 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >NUL 2>&1
taskkill /f /im msedge.exe >NUL 2>&1
rmdir /S /Q "%systemdrive%\Program Files (x86)\Microsoft\Edge" >NUL 2>&1
exit /b 0
