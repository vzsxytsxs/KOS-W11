# Checks building\Generate-KosExpected.ps1: the committed kos-expected.json is up to date, and a few entries whose final value
# depends on the order the KOS files run (or on how the generator reads them) come out right.
# Usage: powershell -NoProfile -File tests\check-kos-expected.ps1        exit 1 on the first failure
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'building\Generate-KosExpected.ps1') -Check | Out-Null
if ($LASTEXITCODE) { Write-Host 'kos-expected.json is out of date: run building\Generate-KosExpected.ps1.' -ForegroundColor Red; exit 1 }

$j = Get-Content (Join-Path $repo 'src\ProgramData\TheKOS\bin\2\kos-expected.json') -Raw | ConvertFrom-Json
$failed = 0
function Check([string]$what, [bool]$ok) { if ($ok) { Write-Host "ok   $what" } else { Write-Host "FAIL $what" -ForegroundColor Red; $script:failed++ } }
function Value([string]$key, [string]$name) { $j.registry | Where-Object { $_.key -eq $key -and $_.name -eq $name } }

# RunOnce sets Start=4 and then deletes the key: the key ends up absent, with no Start left for it.
Check 'Defender service key absent' ([bool]($j.keysAbsent | Where-Object { $_.key -eq 'SYSTEM\CurrentControlSet\Services\WinDefend' }))
Check 'no Start for a deleted service' (-not (Value 'SYSTEM\CurrentControlSet\Services\WinDefend' 'Start'))
# Multi-line for list in RunOnce.
Check 'UsoSvc Start 4 (for list)' ((Value 'SYSTEM\CurrentControlSet\Services\UsoSvc' 'Start').data -eq '4')
# startuptweaks.cmd (every logon) runs after RunOnce's Start=4.
Check 'W32Time Start 3 (startup wins)' ((Value 'SYSTEM\CurrentControlSet\Services\W32Time' 'Start').data -eq '3')
# windows-update-policy.cmd only runs its :hard or :store part on some PCs: neither may leak in.
Check 'no Windows Update mode values' (-not ($j.registry | Where-Object { $_.source -like 'windows-update-policy.cmd*' }))
# "reg query X && reg add" only where the service exists.
Check 'ifKeyExists guard' ((Value 'SYSTEM\CurrentControlSet\Services\DiagTrack' 'Start').ifKeyExists -eq 'HKLM\SYSTEM\CurrentControlSet\Services\DiagTrack')
# The .reg's DWORD in decimal, and the second .reg import wins over 7zip-pexp.bat.
Check '.reg DWORD in decimal' ((Value 'Control Panel\Accessibility\StickyKeys' 'Flags').data -eq '506')
# Profile and hardware scripts stay out.
Check 'no security profile values' (-not ($j.registry | Where-Object { $_.source -like 'security profile*' }))
# prepareiso: the image folder becomes C:, for tokens lose their quotes.
Check 'prepareiso file path' ([bool]($j.files | Where-Object { $_.path -eq 'C:\Windows\system32\smartscreen.exe' }))
# Excluded app preferences.
Check 'Process Explorer preferences excluded' (-not ($j.registry | Where-Object { $_.key -like 'SOFTWARE\Sysinternals*' }))
# schtasks paths with and without the leading \ come out the same.
Check 'task paths start with \' (-not ($j.tasks | Where-Object { -not $_.path.StartsWith('\') }))

# Snapshot keys: the hardware and profile scripts give their keys (every branch, the scripts they call by variable too),
# a deleted key stays listed, excluded keys don't.
function Snapshot([string]$key) { [bool]($j.snapshotKeys | Where-Object { $_.root -eq 'HKLM' -and $_.key -eq $key }) }
Check 'laptop branch key (DeviceProfile.cmd)' (Snapshot 'SYSTEM\CurrentControlSet\Services\serenum')
Check 'desktop for list key (DeviceProfile.cmd)' (Snapshot 'SYSTEM\CurrentControlSet\Services\sensorservice')
Check 'key of a script called by variable' (Snapshot 'SYSTEM\CurrentControlSet\Services\usbccgp\Parameters')
Check 'security profile key' (Snapshot 'SYSTEM\CurrentControlSet\Services\luafv')
Check 'deleted key listed' (Snapshot 'SYSTEM\CurrentControlSet\Services\WinDefend')
Check 'excluded key not listed' (-not ($j.snapshotKeys | Where-Object { $_.key -like 'Software\Sysinternals\*' }))
Check 'no key with a variable left' (-not ($j.snapshotKeys | Where-Object { $_.key -match '%|!' }))

if ($failed) { exit 1 }
