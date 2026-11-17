# KOS ISO verification: runs on a clean install (first boot, after restarting) and checks the state of the
# system against what KOS should have left behind. Read-only: changes nothing. One line per item: [OK], [FAIL] or [INFO].
# Functional tests (the Store installing an app, an image opening in Photo Viewer) remain manual.
# Usage (PowerShell as administrator):
#   powershell -NoProfile -ExecutionPolicy Bypass -File verify-iso.ps1 [-OutputPath report.txt]
# Output: the exit code is the number of [FAIL] items (0 = all good). The report also goes to a file
# (by default %ProgramData%\TheKOS\Logs\verify-iso-<date>.txt).
param([string]$OutputPath = '')

$ErrorActionPreference = 'Continue'
if (-not $OutputPath) {
    $OutputPath = Join-Path $env:ProgramData ('TheKOS\Logs\verify-iso-{0}.txt' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
$script:Lines = New-Object System.Collections.Generic.List[string]
$script:Failed = 0
$script:Passed = 0

function Write-Result([string]$Status, [string]$Area, [string]$Message) {
    $line = '{0,-9} {1}: {2}' -f "[$Status]", $Area, $Message
    $script:Lines.Add($line)
    $color = switch ($Status) { 'OK' { 'Green' } 'FAIL' { 'Red' } default { 'Gray' } }
    Write-Host $line -ForegroundColor $color
    if ($Status -eq 'FAIL') { $script:Failed++ } elseif ($Status -eq 'OK') { $script:Passed++ }
}
function Test-Item([string]$Area, [bool]$Ok, [string]$Message) { Write-Result ($(if ($Ok) { 'OK' } else { 'FAIL' })) $Area $Message }
function Get-Reg([string]$Path, [string]$Name) { (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue).$Name }
function Get-ServiceStart([string]$Name) { Get-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" 'Start' }

# Each check runs in isolation: an unexpected error becomes [FAIL] for that area and does not stop the script.
function Invoke-Check([string]$Area, [scriptblock]$Check) {
    try { & $Check } catch { Write-Result 'FAIL' $Area "error while checking: $($_.Exception.Message)" }
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Result 'INFO' 'Environment' ("{0} build {1}.{2}, {3}, {4}" -f (Get-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'DisplayVersion'),
    (Get-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'CurrentBuild'), (Get-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'UBR'),
    $(if ($isAdmin) { 'administrator' } else { 'NOT administrator (some items may fail for lack of access)' }), (Get-Date -Format 'yyyy-MM-dd HH:mm'))

# Extras that building\build.ps1 removed from the image (edge-webview2, winre, winsxs): they change what is expected below
$buildExtras = @((Get-Reg 'HKLM:\SOFTWARE\TheKOS' 'BuildExtras') -split ',' | Where-Object { $_ })
Write-Result 'INFO' 'Build' ("build extras: {0}" -f $(if ($null -eq (Get-Reg 'HKLM:\SOFTWARE\TheKOS' 'BuildExtras')) { 'not recorded (ISO made without build.ps1)' } elseif ($buildExtras) { $buildExtras -join ', ' } else { 'none' }))
if ($buildExtras -contains 'winsxs') { Write-Result 'INFO' 'Build' 'WinSxS removed in the build: Windows Update, sfc, DISM /RestoreHealth and optional features do not work' }

Invoke-Check 'KOS version' {
    $ver = Get-Reg 'HKLM:\SOFTWARE\TheKOS' 'currentver'
    Test-Item 'KOS version' ($ver -eq '400') "HKLM\SOFTWARE\TheKOS currentver = $ver (expected 400)"
}

# ---------- post-setup logs ----------
Invoke-Check 'Post-setup' {
    $root = Join-Path $env:ProgramData 'TheKOS\Logs\PostSetup'
    $run = Get-ChildItem -LiteralPath $root -Directory -Filter 'RunOnce-*' -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
    if (-not $run) { Test-Item 'Post-setup' $false "no RunOnce-* folder in $root"; return }
    $status = (Get-Content -LiteralPath (Join-Path $run.FullName 'status.txt') -ErrorAction SilentlyContinue | Select-Object -First 1)
    Test-Item 'Post-setup' ($status -like 'COMPLETED*') "$($run.Name): status.txt = $status"
    foreach ($line in Get-Content -LiteralPath (Join-Path $run.FullName 'runonce.log') -ErrorAction SilentlyContinue) {
        if ($line -match 'event=(\S+) status=(WARN|FAIL|ERROR) native_exit=(\S*) kos_code=(\S*) detail=(.*)$') {
            Write-Result 'FAIL' 'Post-setup' ("step {0}: {1} (KOS code {2}, native exit {3})" -f $Matches[1], $Matches[5], $Matches[4], $Matches[3])
        }
    }
    foreach ($log in 'vc-runtime.log', 'directx.log', '7zip.msi.log', 'services-before.log', 'services-after.log', 'services-compare.log', 'onedrive.log') {
        Test-Item 'Post-setup' (Test-Path -LiteralPath (Join-Path $run.FullName $log)) "auxiliary log $log"
    }
}

# ---------- programs installed by the post-setup ----------
Invoke-Check 'Installers' {
    $vc = Get-Reg 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' 'Installed'
    Test-Item 'Installers' ($vc -eq 1) "Visual C++ 2015-2022 x64 (Installed = $vc)"
    Test-Item 'Installers' (Test-Path "$env:windir\System32\d3dx9_43.dll") 'DirectX (d3dx9_43.dll in System32)'
    Test-Item 'Installers' (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") '7-Zip (7z.exe)'
    Test-Item 'Installers' (Test-Path "$env:ProgramFiles\VideoLAN\VLC\vlc.exe") 'VLC'
    Test-Item 'Installers' (Test-Path "$env:ProgramFiles\Open-Shell\StartMenu.exe") 'Open-Shell'
    Test-Item 'Installers' ((Test-Path "${env:ProgramFiles(x86)}\Skillbrains\lightshot\Lightshot.exe") -or (Test-Path "$env:ProgramFiles\Skillbrains\lightshot\Lightshot.exe")) 'Lightshot'
    Test-Item 'Installers' (Test-Path "$env:ProgramFiles\Notepad++\notepad++.exe") 'Notepad++'
    Test-Item 'Installers' (-not (Test-Path "$env:ProgramFiles\Notepad++\contextMenu") -and -not (Test-Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\*\shell\ANotepad++64')) 'Notepad++ without its context menu entry'
}

# ---------- post-setup cleanup ----------
Invoke-Check 'Cleanup' {
    Test-Item 'Cleanup' (-not (Test-Path "$env:ProgramData\TheKOS\bin\1")) 'bin\1 removed'
    Test-Item 'Cleanup' (-not (Test-Path "$env:ProgramData\TheKOS\bin\2")) 'bin\2 removed'
    $task = Get-ScheduledTask -TaskPath '\TheKOS\' -TaskName 'Startup' -ErrorAction SilentlyContinue
    $taskOk = $task -and $task.Principal.RunLevel -eq 'Highest' -and $task.Actions[0].Arguments -like '*startup.vbs*' -and (Test-Path "$env:ProgramData\TheKOS\bin\3\startup.vbs")
    Test-Item 'Cleanup' $taskOk "logon task \TheKOS\Startup (startup.vbs, highest privileges)$(if ($task) { ': ' + $task.State })"
    Test-Item 'Cleanup' (-not (Get-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' 'KOS Cleanup')) "no old 'KOS Cleanup' value in the Run key (it does not elevate with UAC on)"
}

# ---------- Windows Update (forceDisableWup and the five services) ----------
Invoke-Check 'Windows Update' {
    $mode = Get-Reg 'HKLM:\SOFTWARE\TheKOS' 'forceDisableWup'
    $s = [ordered]@{}
    foreach ($n in 'wuauserv', 'bits', 'UsoSvc', 'WaaSMedicSvc', 'dosvc') { $s[$n] = Get-ServiceStart $n }
    $text = ($s.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' '
    switch ($mode) {
        '1' { Test-Item 'Windows Update' (@($s.Values | Where-Object { $_ -ne 4 }).Count -eq 0) "mode 3 (strong block, KOS default): $text; expected all 4" }
        'store' {
            $ok = $s.wuauserv -eq 4 -and $s.WaaSMedicSvc -eq 4 -and $s.bits -eq 2 -and $s.UsoSvc -eq 2 -and $s.dosvc -in 2, 3
            Test-Item 'Windows Update' $ok "mode 4 (Store): $text; expected wuauserv/WaaSMedicSvc=4, bits/UsoSvc=2, dosvc=2 or 3"
        }
        '0' {
            $mode1 = $s.UsoSvc -eq 2 -and $s.wuauserv -eq 3 -and $s.bits -eq 3 -and $s.WaaSMedicSvc -eq 3 -and $s.dosvc -eq 3
            $mode2 = @($s.Values | Where-Object { $_ -ne 2 }).Count -eq 0
            Test-Item 'Windows Update' ($mode1 -or $mode2) "mode 1 or 2 (enabled/moderate): $text"
        }
        default { Test-Item 'Windows Update' $false "forceDisableWup = '$mode' (expected 1, 0 or store); $text" }
    }
}

# ---------- services backup ----------
Invoke-Check 'Services' {
    $dir = "$env:ProgramData\TheKOS\Setup\3-Support\Services\Backups"
    foreach ($name in 'Windows.Default.Services', 'TheKOS.services') {
        $json = Join-Path $dir "$name.json"
        $reg = Join-Path $dir "$name.reg"
        if (-not ((Test-Path $json) -and (Test-Path $reg))) { Test-Item 'Services' $false "snapshot $name (.json and .reg) in $dir"; continue }
        $count = (Get-Content -LiteralPath $json -Raw -Encoding UTF8 | ConvertFrom-Json).ServiceCount
        $starts = (Select-String -LiteralPath $reg -Pattern '^"Start"=dword:' -Encoding Unicode).Count
        Test-Item 'Services' ($count -gt 0 -and $count -eq $starts) "snapshot ${name}: $count services in the JSON, $starts Start entries in the .reg"
    }
    $csv = Join-Path $dir 'TheKOS.Services.Diff.csv'
    Test-Item 'Services' ((Test-Path $csv) -and @(Import-Csv -LiteralPath $csv).Count -gt 0) 'differences TheKOS.Services.Diff.csv'
}

# ---------- Photo Viewer ----------
Invoke-Check 'Photo Viewer' {
    if (-not ('KOSAssocQuery' -as [type])) {
        Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class KOSAssocQuery {
    [DllImport("Shlwapi.dll", CharSet = CharSet.Unicode)]
    public static extern int AssocQueryString(int flags, int str, string assoc, string extra, StringBuilder output, ref int length);
}
'@
    }
    foreach ($ext in '.jpg', '.png', '.gif', '.bmp', '.tif') {
        $buffer = New-Object System.Text.StringBuilder 1024
        $length = $buffer.Capacity
        [void][KOSAssocQuery]::AssocQueryString(0, 20, $ext, $null, $buffer, [ref]$length) # ASSOCSTR_PROGID
        $progId = $buffer.ToString()
        Test-Item 'Photo Viewer' ($progId -like 'PhotoViewer.FileAssoc*') "$ext opens with $progId"
    }
}

# ---------- Edge and WebView2 ----------
Invoke-Check 'Edge/WebView2' {
    $ms = Join-Path ${env:ProgramFiles(x86)} 'Microsoft'
    Test-Item 'Edge/WebView2' (-not (Test-Path (Join-Path $ms 'Edge\Application\msedge.exe'))) 'Edge browser absent'
    $webView = @(Get-ChildItem -LiteralPath (Join-Path $ms 'EdgeWebView\Application') -Filter msedgewebview2.exe -Recurse -ErrorAction SilentlyContinue).Count -gt 0
    if ($buildExtras -contains 'edge-webview2') { Test-Item 'Edge/WebView2' (-not $webView) 'WebView2 absent (removed in the build, edge-webview2 extra)' }
    else { Test-Item 'Edge/WebView2' $webView 'WebView2 present (msedgewebview2.exe)' }
    foreach ($name in 'edgeupdate', 'edgeupdatem') {
        $svc = Get-CimInstance Win32_Service -Filter "Name='$name'" -ErrorAction SilentlyContinue
        Test-Item 'Edge/WebView2' (-not $svc -or $svc.StartMode -eq 'Disabled') "service ${name}: $(if ($svc) { $svc.StartMode } else { 'absent' })"
    }
    foreach ($task in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like '*EdgeUpdate*' })) {
        Test-Item 'Edge/WebView2' ($task.State -eq 'Disabled') "task $($task.TaskName): $($task.State)"
    }
    $appx = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -like 'Microsoft.MicrosoftEdge.Stable*' }
    if ($appx) { Write-Result 'INFO' 'Edge/WebView2' "leftover Appx entry: $($appx.PSChildName -join ', ') (roadmap: check whether it brings Edge back)" }
}

# ---------- OneDrive ----------
Invoke-Check 'OneDrive' {
    $clients = @("$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe", "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe", "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe") | Where-Object { Test-Path $_ }
    Test-Item 'OneDrive' (-not $clients) "client absent$(if ($clients) { ': found in ' + ($clients -join ', ') })"
    Test-Item 'OneDrive' (-not (Get-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'OneDrive')) 'no OneDrive entry at user logon'
    $tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'OneDrive*' })
    Test-Item 'OneDrive' ($tasks.Count -eq 0) "OneDrive tasks: $($tasks.Count)"
}

# ---------- WinRE ----------
Invoke-Check 'WinRE' {
    if ($buildExtras -contains 'winre') { Write-Result 'INFO' 'WinRE' 'removed in the build (winre extra)'; return }
    # ReAgent.xml does not depend on the Windows language (the reagentc /info text does).
    $xmlPath = "$env:windir\System32\Recovery\ReAgent.xml"
    if (-not (Test-Path $xmlPath)) { Test-Item 'WinRE' $false "$xmlPath absent"; return }
    $state = ([xml](Get-Content -LiteralPath $xmlPath -Raw)).WindowsRE.InstallState.state
    # The image path (\Recovery\WindowsRE) is not translated; without the image reagentc shows no location at all.
    $location = (reagentc.exe /info 2>$null | Select-String -Pattern '\\Recovery\\WindowsRE' | Select-Object -First 1).Line
    Test-Item 'WinRE' ($state -eq '1' -and $location) "recovery environment enabled (ReAgent.xml InstallState = $state; image: $(if ($location) { $location.Trim() } else { 'not found' }))"
}

# ---------- PowerShell logging ----------
Invoke-Check 'PowerShell logging' {
    $sb = Get-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' 'EnableScriptBlockLogging'
    $ml = Get-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' 'EnableModuleLogging'
    Test-Item 'PowerShell logging' ($sb -eq 1 -and $ml -eq 1) "script block = $sb, module = $ml (KOS default: 1 and 1)"
}

# ---------- device profile ----------
Invoke-Check 'Device profile' {
    $chassis = @((Get-CimInstance Win32_SystemEnclosure).ChassisTypes)
    $laptop = @($chassis | Where-Object { $_ -in 8, 9, 10, 11, 14, 30, 31, 32 }).Count -gt 0
    $desktop = @($chassis | Where-Object { $_ -in 3, 4, 5, 6, 7, 13, 15, 16, 17, 23, 24 }).Count -gt 0
    $plan = (powercfg /getactivescheme) -replace '.*:\s*([0-9a-f-]{36}).*', '$1'
    $radios = "WlanSvc=$(Get-ServiceStart WlanSvc) vwififlt=$(Get-ServiceStart vwififlt) bthserv=$(Get-ServiceStart bthserv) BTHPORT=$(Get-ServiceStart BTHPORT)"
    if ($laptop) {
        $ok = (Get-ServiceStart WlanSvc) -eq 2 -and (Get-ServiceStart bthserv) -eq 3 -and (Get-ServiceStart BTHPORT) -eq 3
        Test-Item 'Device profile' $ok "laptop (chassis $($chassis -join ',')): Wi-Fi/Bluetooth on: $radios"
        Test-Item 'Device profile' ($plan -eq '381b4222-f694-41f0-9685-ff5bb260df2e') "laptop: active plan $plan (expected Balanced 381b4222-...)"
    } else {
        $ok = @('WlanSvc', 'vwififlt', 'bthserv', 'BTHPORT' | Where-Object { (Get-ServiceStart $_) -ne 4 }).Count -eq 0
        $kind = if ($desktop) { 'desktop' } else { 'unknown chassis, defaulting to desktop' }
        Test-Item 'Device profile' $ok "${kind} (chassis $($chassis -join ',')): Wi-Fi/Bluetooth off: $radios"
        Test-Item 'Device profile' ($plan -eq 'b0a71852-3be4-43b1-9aff-70d3c8430794') "${kind}: active plan $plan (expected co.pow b0a71852-...)"
    }
}

# ---------- security profile (Basic or Advanced) ----------
Invoke-Check 'Security profile' {
    $area = 'Security profile'
    $profileName = Get-Reg 'HKLM:\SOFTWARE\TheKOS' 'Profile'
    if ($profileName -notin 'basic', 'advanced', 'extreme') { Test-Item $area $false "HKLM\SOFTWARE\TheKOS Profile = '$profileName' (expected basic or advanced)"; return }
    Write-Result 'INFO' $area "saved profile: $profileName"
    $basic = $profileName -eq 'basic'
    $pol = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    $lua = Get-Reg $pol 'EnableLUA'
    $consent = Get-Reg $pol 'ConsentPromptBehaviorAdmin'
    $luafv = Get-ServiceStart 'luafv'
    if ($basic) { Test-Item $area ($lua -eq 1 -and $consent -eq 5 -and $luafv -eq 2) "UAC on: EnableLUA=$lua ConsentPromptBehaviorAdmin=$consent luafv=$luafv" }
    else { Test-Item $area ($lua -eq 0 -and $luafv -eq 4) "UAC off: EnableLUA=$lua luafv=$luafv" }

    $bcd = bcdedit /enum '{current}'
    $nx = (($bcd | Select-String '^nx\s+(\S+)').Matches | Select-Object -First 1).Groups[1].Value
    $hv = (($bcd | Select-String '^hypervisorlaunchtype\s+(\S+)').Matches | Select-Object -First 1).Groups[1].Value
    Test-Item $area ($(if ($basic) { $nx -eq 'OptIn' } else { $nx -eq 'AlwaysOff' })) "DEP (bcdedit nx) = $nx"
    Test-Item $area ($(if ($basic) { $hv -in 'Auto', '' } else { $hv -eq 'Off' })) "hypervisorlaunchtype = $(if ($hv) { $hv } else { 'default' })"

    $cfg = try { (Get-ProcessMitigation -System -ErrorAction Stop).CFG.Enable.ToString() } catch { 'unavailable' }
    Test-Item $area ($(if ($basic) { $cfg -in 'ON', 'NOTSET' } else { $cfg -eq 'OFF' })) "system CFG = $cfg"

    $override = Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'FeatureSettingsOverride'
    $intel = (Get-Reg 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' 'VendorIdentifier') -eq 'GenuineIntel'
    if ($basic) { Test-Item $area ($null -eq $override) "Spectre/Meltdown at the Windows default (FeatureSettingsOverride = $(if ($null -eq $override) { 'absent' } else { $override }))" }
    elseif ($intel) { Test-Item $area ($override -eq 3) "Spectre/Meltdown off (FeatureSettingsOverride = $override)" }

    $mask = Get-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dwm.exe' 'MitigationOptions'
    Test-Item $area ($(if ($basic) { $null -eq $mask } else { $null -ne $mask })) "per-process mitigation mask (dwm.exe): $(if ($null -ne $mask) { 'present' } else { 'absent' })"

    $vbsPolicy = Get-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' 'EnableVirtualizationBasedSecurity'
    $dg = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue
    $hvci = if ($dg) { @($dg.SecurityServicesRunning) -contains 2 } else { 'unknown' } # 2 = memory integrity
    if ($basic) {
        Test-Item $area ($vbsPolicy -ne 0) "VBS without the KOS block (policy = $(if ($null -eq $vbsPolicy) { 'absent' } else { $vbsPolicy }))"
        Write-Result 'INFO' $area "memory integrity (HVCI) running: $hvci (on Basic it stays as Windows left it at OOBE)"
    } else {
        Test-Item $area ($vbsPolicy -eq 0 -and $hvci -ne $true) "VBS off (policy = $vbsPolicy, HVCI running = $hvci)"
    }

    $dma = @(reg query 'HKLM\SYSTEM\CurrentControlSet\Services' /s /v DmaRemappingCompatible 2>$null | Select-String 'REG_DWORD\s+(0x[0-9a-f]+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
    $nonZero = @($dma | Where-Object { $_ -ne '0x0' }).Count
    if ($basic) { Write-Result 'INFO' $area "DMA remapping: $($dma.Count) driver(s) declare the value, $nonZero with remapping allowed (driver default)" }
    else { Test-Item $area ($nonZero -eq 0) "DMA remapping off in $($dma.Count) driver(s) ($nonZero still with a non-zero value)" }

    $rules = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules' -ErrorAction SilentlyContinue).ValueCount
    if ($basic) { Test-Item $area ($rules -gt 50) "firewall rules kept: $rules" }
    else { Write-Result 'INFO' $area "firewall rules: $rules (Advanced deletes them all; Windows recreates some later)" }
}

# ---------- apps that come back through Windows Update (UScheduler) ----------
Invoke-Check 'UScheduler' {
    $left = foreach ($root in 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler') {
        foreach ($id in 'DevHomeUpdate', 'OutlookUpdate', 'CrossDeviceUpdate', 'EdgeUpdate', 'MS_AutoSuperRes') {
            if (Test-Path "$root\$id") { "$($root.Split('\')[-1])\$id" }
        }
    }
    Test-Item 'UScheduler' (-not $left) "reinstall entries removed$(if ($left) { '; remaining: ' + ($left -join ', ') })"
    $other = foreach ($root in 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler') {
        Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object { $_.PSChildName }
    }
    if ($other) { Write-Result 'INFO' 'UScheduler' "other entries (check whether they are bloatware):$(($other | Sort-Object -Unique) -join ', ')" }
}

# ---------- summary ----------
$summary = "Summary: $script:Passed OK, $script:Failed FAIL."
$script:Lines.Add('')
$script:Lines.Add($summary)
Write-Host ''
Write-Host $summary -ForegroundColor $(if ($script:Failed) { 'Red' } else { 'Green' })
try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPath) -Force | Out-Null
    $script:Lines | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    Write-Host "Report: $OutputPath"
} catch { Write-Host "Could not write the report to ${OutputPath}:$($_.Exception.Message)" -ForegroundColor Yellow }
exit [Math]::Min($script:Failed, 255)
