# Removes Edge, WebView2 and Edge Update (apps that use WebView2, like the new Outlook and Teams, stop opening until WebView2 is installed again).
# RunOnce sees that they are already gone and skips its own removal. OOBE doesn't need any of them.
param([string]$Mount, [string]$Iso)
$ms = Join-Path $Mount 'Program Files (x86)\Microsoft'
foreach ($name in 'Edge', 'EdgeCore', 'EdgeUpdate', 'EdgeWebView') {
    Clear-ImageFolder (Join-Path $ms $name)
    Remove-Item -LiteralPath (Join-Path $ms $name) -Force -ErrorAction SilentlyContinue
}
Clear-ImageFolder (Join-Path $Mount 'Windows\System32\Microsoft-Edge-Webview')
Get-ChildItem (Join-Path $Mount 'Windows\WinSxS') -Directory -Filter '*_microsoft-edge-webview_*' | ForEach-Object { Clear-ImageFolder $_.FullName }
Remove-ImageFiles (Join-Path $Mount 'ProgramData\Microsoft\Windows\Start Menu\Programs') 'Microsoft Edge.lnk'
Remove-ImageFiles (Join-Path $Mount 'Users\Public\Desktop') 'Microsoft Edge.lnk'

Edit-ImageRegistry $Mount 'SYSTEM' {
    param($root)
    foreach ($svc in 'edgeupdate', 'edgeupdatem', 'MicrosoftEdgeElevationService') {
        $key = "$root\ControlSet001\Services\$svc"
        if (Test-Path $key) { Remove-Item $key -Recurse -Force }
    }
}
Edit-ImageRegistry $Mount 'SOFTWARE' {
    param($root)
    # Edge Update tasks: the entry in TaskCache\Tree points, by Id, to the ones in Tasks, Plain, Boot, Logon and Maintenance.
    # If one is left, it only fails when it runs (the exe no longer exists): warn and carry on.
    $cache = "$root\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache"
    foreach ($task in @(Get-ChildItem "$cache\Tree" | Where-Object { $_.PSChildName -like 'MicrosoftEdgeUpdate*' })) {
        try {
            $id = (Get-ItemProperty $task.PSPath).Id
            foreach ($list in 'Tasks', 'Plain', 'Boot', 'Logon', 'Maintenance') { if ($id -and (Test-Path "$cache\$list\$id")) { Remove-Item "$cache\$list\$id" -Recurse -Force } }
            Remove-Item $task.PSPath -Recurse -Force
            Remove-ImageFiles (Join-Path $Mount 'Windows\System32\Tasks') $task.PSChildName
        }
        catch { Write-Host "Warning: task $($task.PSChildName) was left behind: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
    foreach ($key in 'WOW6432Node\Microsoft\EdgeUpdate', 'WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
        'WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update', 'WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView',
        'Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}', 'Microsoft\Windows\CurrentVersion\App Paths\msedge.exe',
        'Clients\StartMenuInternet\Microsoft Edge') {
        if (Test-Path "$root\$key") { Remove-Item "$root\$key" -Recurse -Force }
    }
    Remove-ItemProperty "$root\RegisteredApplications" 'Microsoft Edge' -ErrorAction SilentlyContinue
}
