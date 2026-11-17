param([string]$OutputPath = 'C:\Users\Public\edge-webview-state.json')

$microsoftDir = Join-Path ${env:ProgramFiles(x86)} 'Microsoft'
$webViewDir = Join-Path $microsoftDir 'EdgeWebView\Application'
$clientGuid = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
$clientPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$clientGuid",
    "HKCU:\Software\Microsoft\EdgeUpdate\Clients\$clientGuid"
)
$registeredVersion = $null
foreach ($clientPath in $clientPaths) {
    $client = Get-ItemProperty -LiteralPath $clientPath -ErrorAction SilentlyContinue
    if ($client -and $client.pv -and $client.pv -ne '0.0.0.0') {
        $registeredVersion = $client.pv
        break
    }
}

$services = @{}
foreach ($name in 'edgeupdate', 'edgeupdatem') {
    $service = Get-CimInstance Win32_Service -Filter "Name='$name'" -ErrorAction SilentlyContinue
    $services[$name] = if ($service) {
        @{ State = $service.State; StartMode = $service.StartMode }
    } else {
        $null
    }
}

$tasks = @{}
foreach ($name in 'MicrosoftEdgeUpdateTaskMachineCore', 'MicrosoftEdgeUpdateTaskMachineUA', 'MicrosoftEdgeUpdateBrowserReplacementTask') {
    $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
    $tasks[$name] = if ($task) { $task.State.ToString() } else { $null }
}

$uninstall = Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like '*WebView2*' } |
    Select-Object DisplayName, UninstallString, NoRemove
$updaterProcesses = @(Get-CimInstance Win32_Process -Filter "Name='MicrosoftEdgeUpdate.exe'" -ErrorAction SilentlyContinue |
    Select-Object ProcessId, ParentProcessId, CommandLine, CreationDate)
$allUpdateTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -like '*EdgeUpdate*' } |
    Select-Object TaskName, TaskPath, @{ Name = 'State'; Expression = { $_.State.ToString() } })

[pscustomobject]@{
    Time = (Get-Date).ToString('o')
    EdgeBrowserPresent = Test-Path -LiteralPath (Join-Path $microsoftDir 'Edge\Application\msedge.exe')
    EdgeWebViewPresent = Test-Path -LiteralPath $webViewDir
    WebViewExecutablePresent = @(Get-ChildItem -LiteralPath $webViewDir -Filter msedgewebview2.exe -Recurse -ErrorAction SilentlyContinue).Count -gt 0
    EdgeUpdatePresent = Test-Path -LiteralPath (Join-Path $microsoftDir 'EdgeUpdate\MicrosoftEdgeUpdate.exe')
    WebViewRegisteredVersion = $registeredVersion
    WebViewUninstall = $uninstall
    Services = $services
    Tasks = $tasks
    AllEdgeUpdateTasks = $allUpdateTasks
    UpdaterProcesses = $updaterProcesses
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
