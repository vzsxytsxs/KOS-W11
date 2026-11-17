param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Capture', 'Compare', 'Restore', 'Organize')]
    [string]$Mode,
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$Snapshot,
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$From = 'Windows.Default.Services',
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$To = 'TheKOS.services',
    [string[]]$Services,
    [string]$OutputDirectory,
    [switch]$Full,
    [switch]$Force,
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$root = 'HKLM:\SYSTEM\CurrentControlSet\Services'
$directory = if ($OutputDirectory) { $OutputDirectory } else { Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Backups' }
if (-not $OutputDirectory) {
    # Snapshots live in .\Backups; move any left in the script folder by older versions.
    $scriptDir = Split-Path -Parent $directory
    if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory | Out-Null }
    Get-ChildItem -LiteralPath $scriptDir -File | Where-Object { $_.Name -match '\.(json|reg|csv)(\.previous)?$' } | ForEach-Object {
        if (-not (Test-Path -LiteralPath (Join-Path $directory $_.Name))) { Move-Item -LiteralPath $_.FullName -Destination $directory }
    }
}
if (-not (Test-Path -LiteralPath $directory -PathType Container)) { throw "Output directory does not exist: $directory" }

function Get-SnapshotPath([string]$name, [string]$extension) {
    Join-Path $directory ($name + $extension)
}

function Read-ServiceState {
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($key in Get-ChildItem -LiteralPath $root -ErrorAction Stop) {
        $name = $key.PSChildName
        try {
            $start = $key.GetValue('Start', $null)
            if ($null -eq $start) { continue }
            if ($key.GetValueKind('Start').ToString() -ne 'DWord') { throw 'Start is not REG_DWORD' }

            $delayed = $key.GetValue('DelayedAutoStart', $null)
            if ($null -ne $delayed -and $key.GetValueKind('DelayedAutoStart').ToString() -ne 'DWord') {
                throw 'DelayedAutoStart is not REG_DWORD'
            }

            $overrides = @{}
            $overridePath = Join-Path $key.PSPath 'StartOverride'
            if (Test-Path -LiteralPath $overridePath) {
                $overrideKey = Get-Item -LiteralPath $overridePath -ErrorAction Stop
                foreach ($valueName in $overrideKey.GetValueNames()) {
                    if ($overrideKey.GetValueKind($valueName).ToString() -eq 'DWord') {
                        $overrides[$valueName] = [int]$overrideKey.GetValue($valueName)
                    }
                }
            }

            $items.Add([pscustomobject]@{
                Name = $name
                Start = [int]$start
                DelayedAutoStart = if ($null -eq $delayed) { $null } else { [int]$delayed }
                StartOverride = [pscustomobject]$overrides
            })
        } catch {
            throw "Could not read service '$name': $($_.Exception.Message)"
        }
    }
    if ($items.Count -lt 20) { throw "Only $($items.Count) service entries were read; refusing incomplete backup." }
    return @($items | Sort-Object Name)
}

function Read-Snapshot([string]$name) {
    if ($name -eq 'Current') {
        $live = @(Read-ServiceState)
        return [pscustomobject]@{ Snapshot = 'Current'; CapturedAt = (Get-Date).ToString('o'); ServiceCount = $live.Count; Services = $live }
    }
    $path = Get-SnapshotPath $name '.json'
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing snapshot: $path" }
    $data = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($data.SchemaVersion -ne 1 -or @($data.Services).Count -lt 20 -or $data.ServiceCount -ne @($data.Services).Count) {
        throw "Invalid or incomplete snapshot: $path"
    }
    return $data
}

function Format-State($item) {
    if ($null -eq $item) { return 'missing' }
    $delayed = if ($null -eq $item.DelayedAutoStart) { '-' } else { $item.DelayedAutoStart }
    $overrides = @($item.StartOverride.PSObject.Properties | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ';'
    return "Start=$($item.Start);Delayed=$delayed;Override=$overrides"
}

function Save-Snapshot([string]$Snapshot, [bool]$WithFull) {
    $entries = @(Read-ServiceState)
    $data = [pscustomobject]@{
        SchemaVersion = 1
        Snapshot = $Snapshot
        CapturedAt = (Get-Date).ToString('o')
        Computer = $env:COMPUTERNAME
        ServiceCount = $entries.Count
        Services = $entries
    }
    $regLines = New-Object System.Collections.Generic.List[string]
    $regLines.Add('Windows Registry Editor Version 5.00')
    foreach ($entry in $entries) {
        if ($entry.Start -lt 0 -or $entry.Start -gt 4) { throw "Unexpected Start value for $($entry.Name)" }
        $regLines.Add('')
        $regLines.Add("[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$($entry.Name)]")
        $regLines.Add(('"Start"=dword:{0:x8}' -f $entry.Start))
    }

    $jsonPath = Get-SnapshotPath $Snapshot '.json'
    $regPath = Get-SnapshotPath $Snapshot '.reg'
    $tempJson = $jsonPath + '.tmp'
    $tempReg = $regPath + '.tmp'
    $data | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $tempJson -Encoding UTF8
    $regLines | Set-Content -LiteralPath $tempReg -Encoding Unicode
    if ((Get-Content -LiteralPath $tempJson -Raw -Encoding UTF8 | ConvertFrom-Json).ServiceCount -ne $entries.Count) {
        throw 'Snapshot validation failed.'
    }
    if ((Select-String -LiteralPath $tempReg -Pattern '^"Start"=dword:' -Encoding Unicode).Count -ne $entries.Count) {
        throw 'Registry backup validation failed.'
    }

    $pairs = @(@($tempJson, $jsonPath), @($tempReg, $regPath))
    if ($WithFull) {
        # Whole Services hive: the only way to bring back services that TheKOS deletes.
        $fullPath = Get-SnapshotPath $Snapshot '.full.reg'
        & reg.exe export 'HKLM\SYSTEM\CurrentControlSet\Services' ($fullPath + '.tmp') /y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Full registry export failed.' }
        $pairs += ,@(($fullPath + '.tmp'), $fullPath)
    }
    foreach ($pair in $pairs) {
        if (Test-Path -LiteralPath $pair[1]) { Copy-Item -LiteralPath $pair[1] -Destination ($pair[1] + '.previous') -Force }
        Move-Item -LiteralPath $pair[0] -Destination $pair[1] -Force
    }
    return $entries.Count
}

try {
    switch ($Mode) {
        'Capture' {
            if (-not $Snapshot) { throw 'Specify -Snapshot.' }
            # The default-Windows baseline is taken once; a rerun must not replace it with an already-tweaked state.
            if ($Snapshot -eq 'Windows.Default.Services' -and -not $Force -and (Test-Path -LiteralPath (Get-SnapshotPath $Snapshot '.json'))) {
                Write-Host "Baseline already exists, keeping it (use -Force to replace): $Snapshot"
                break
            }
            $count = Save-Snapshot $Snapshot $Full.IsPresent
            Write-Host "Captured $count services: $Snapshot"
            break
        }
        'Organize' { break }
        'Compare' {
            $before = Read-Snapshot $From
            $after = Read-Snapshot $To
            $beforeMap = @{}; foreach ($item in $before.Services) { $beforeMap[$item.Name] = $item }
            $afterMap = @{}; foreach ($item in $after.Services) { $afterMap[$item.Name] = $item }
            $names = @(@($beforeMap.Keys) + @($afterMap.Keys) | Sort-Object -Unique)
            $changes = @(foreach ($name in $names) {
                $old = $beforeMap[$name]; $new = $afterMap[$name]
                $oldState = Format-State $old; $newState = Format-State $new
                if ($oldState -ne $newState) {
                    [pscustomobject]@{ Name = $name; Before = $oldState; After = $newState }
                }
            })
            if ($PassThru) { $changes; break }
            $csvName = if ($From -eq 'Windows.Default.Services' -and $To -eq 'TheKOS.services') { 'TheKOS.Services.Diff.csv' } else { "Diff.$From.vs.$To.csv" }
            $path = Join-Path $directory $csvName
            if (@($changes).Count -gt 0) {
                $changes | Export-Csv -LiteralPath ($path + '.tmp') -NoTypeInformation -Encoding UTF8
            } else {
                '"Name","Before","After"' | Set-Content -LiteralPath ($path + '.tmp') -Encoding UTF8
            }
            Move-Item -LiteralPath ($path + '.tmp') -Destination $path -Force
            Write-Host "Compared snapshots: $(@($changes).Count) changes. Report: $path"
            break
        }
        'Restore' {
            $serviceNames = @($Services | ForEach-Object { $_ -split '[,;\s]+' } | Where-Object { $_ } | Select-Object -Unique)
            if (-not $Snapshot -or $serviceNames.Count -eq 0) {
                throw 'Specify -Snapshot and explicit -Services. Nothing is restored by default.'
            }
            if ($Snapshot -eq 'Current') { throw 'Cannot restore from Current.' }
            $data = Read-Snapshot $Snapshot
            $map = @{}; foreach ($item in $data.Services) { $map[$item.Name] = $item }
            foreach ($name in $serviceNames) {
                if ($name -notmatch '^[A-Za-z0-9_.-]+$') { throw "Invalid service name: $name" }
                if (-not $map.ContainsKey($name)) { throw "Service absent from snapshot: $name" }
                $path = Join-Path $root $name
                if (-not (Test-Path -LiteralPath $path)) { throw "Service no longer exists; not recreating: $name" }
            }
            $safety = 'PreRestore.' + (Get-Date -Format 'yyyyMMdd-HHmmss')
            [void](Save-Snapshot $safety $false)
            Write-Host "Safety snapshot of the current state saved: $safety"
            foreach ($name in $serviceNames) {
                $item = $map[$name]
                $path = Join-Path $root $name
                New-ItemProperty -LiteralPath $path -Name Start -Value ([int]$item.Start) -PropertyType DWord -Force | Out-Null
                if ($null -eq $item.DelayedAutoStart) {
                    $serviceKey = Get-Item -LiteralPath $path
                    if ($null -ne $serviceKey.GetValue('DelayedAutoStart', $null)) {
                        Remove-ItemProperty -LiteralPath $path -Name DelayedAutoStart -ErrorAction Stop
                    }
                } else {
                    New-ItemProperty -LiteralPath $path -Name DelayedAutoStart -Value ([int]$item.DelayedAutoStart) -PropertyType DWord -Force | Out-Null
                }
                $overridePath = Join-Path $path 'StartOverride'
                $wanted = @{}; foreach ($property in $item.StartOverride.PSObject.Properties) { $wanted[$property.Name] = [int]$property.Value }
                if ((Test-Path -LiteralPath $overridePath) -or $wanted.Count -gt 0) {
                    if (-not (Test-Path -LiteralPath $overridePath)) { New-Item -Path $overridePath -Force | Out-Null }
                    $overrideKey = Get-Item -LiteralPath $overridePath
                    foreach ($valueName in $overrideKey.GetValueNames()) {
                        if ($overrideKey.GetValueKind($valueName).ToString() -eq 'DWord' -and -not $wanted.ContainsKey($valueName)) {
                            Remove-ItemProperty -LiteralPath $overridePath -Name $valueName
                        }
                    }
                    foreach ($valueName in $wanted.Keys) {
                        New-ItemProperty -LiteralPath $overridePath -Name $valueName -Value $wanted[$valueName] -PropertyType DWord -Force | Out-Null
                    }
                }
                Write-Host "Restored startup settings: $name"
            }
            Write-Warning 'A startup script or application may change these values later. Deleted services are never recreated.'
            break
        }
    }
} catch {
    Write-Error $_
    exit 1
}
