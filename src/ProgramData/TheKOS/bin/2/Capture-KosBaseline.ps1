<#
Saves what the KOS keys hold at the end of the setup to %ProgramData%\TheKOS\Baseline\kos-baseline.json: for every key in
kos-expected.json's snapshotKeys, whether it exists and its values, and the state of each scheduled task the KOS changes.
This is the PC's own result, so it includes what depends on its hardware and security profile. The KOS Toolbox compares the
system with it to find what Windows Update, SFC or DISM changed in those keys besides the values kos-expected.json lists.

RunOnce.cmd runs it before bin\2 is deleted and the PC restarts. Exit 0 when the file is written, 1 when it isn't (logged as
code 304). The startup scripts (bin\3) run at each logon after the restart; what they set is in kos-expected.json.
#>
param(
    [string]$Expected = (Join-Path $PSScriptRoot 'kos-expected.json'),
    [string]$Out = (Join-Path $env:ProgramData 'TheKOS\Baseline\kos-baseline.json')
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$Hives = @{}
# HKCR is read as the machine's classes (HKLM\SOFTWARE\Classes), where the KOS writes it and the toolbox compares it: the merged
# HKEY_CLASSES_ROOT view would mix in this user's own classes.
foreach ($h in @{ HKLM = 'LocalMachine'; HKCU = 'CurrentUser'; HKU = 'Users' }.GetEnumerator()) {
    $Hives[$h.Key] = [Microsoft.Win32.RegistryKey]::OpenBaseKey($h.Value, 'Registry64')
}
$Types = @{ DWord = 'dword'; QWord = 'qword'; String = 'sz'; ExpandString = 'expand_sz'; MultiString = 'multi_sz'; Binary = 'binary'; None = 'none' }

# Same writer as building\Generate-KosExpected.ps1: ASCII, everything else as \u escapes.
function ConvertTo-JsonText($v) {
    if ($null -eq $v) { return 'null' }
    if ($v -is [bool]) { return $(if ($v) { 'true' } else { 'false' }) }
    if ($v -is [System.Collections.IDictionary]) { return '{' + (($v.Keys | ForEach-Object { (ConvertTo-JsonText ([string]$_)) + ':' + (ConvertTo-JsonText $v[$_]) }) -join ',') + '}' }
    if ($v -is [System.Collections.IEnumerable] -and $v -isnot [string]) { return '[' + ((@($v) | ForEach-Object { ConvertTo-JsonText $_ }) -join ',') + ']' }
    $sb = New-Object Text.StringBuilder '"'
    foreach ($c in ([string]$v).ToCharArray()) {
        switch ($c) {
            '"' { [void]$sb.Append('\"') } '\' { [void]$sb.Append('\\') }
            default { if ([int]$c -lt 32 -or [int]$c -gt 126) { [void]$sb.Append(('\u{0:x4}' -f [int]$c)) } else { [void]$sb.Append($c) } }
        }
    }
    [void]$sb.Append('"'); $sb.ToString()
}

# A value's data as kos-expected.json writes it: DWORD and QWORD in decimal, binary and other types in hex, strings as stored.
function ConvertTo-RegData([string]$type, $v) {
    switch ($type) {
        'dword' { return [BitConverter]::ToUInt32([BitConverter]::GetBytes([int32]$v), 0).ToString() }
        'qword' { return [BitConverter]::ToUInt64([BitConverter]::GetBytes([int64]$v), 0).ToString() }
        'multi_sz' { return , @($v) }
        'sz' { return [string]$v }
        'expand_sz' { return [string]$v }
        default { if ($null -eq $v) { return '' }; return [BitConverter]::ToString([byte[]]$v).Replace('-', '').ToLowerInvariant() }
    }
}

function Test-Ignored([string]$id, $patterns) {
    foreach ($p in $patterns) { if ($id -like $p) { return $true } }
    $false
}

function Get-KeyEntry([string]$root, [string]$key, $ignore) {
    $e = [ordered]@{ root = $root; key = $key }
    try {
        $k = if ($root -eq 'HKCR') { $Hives.HKLM.OpenSubKey("SOFTWARE\Classes\$key") } else { $Hives[$root].OpenSubKey($key) }
        if (-not $k) { $e.exists = $false; return $e }
        try {
            $e.exists = $true
            [string[]]$names = $k.GetValueNames()
            [Array]::Sort($names, [StringComparer]::Ordinal)
            $values = New-Object System.Collections.Generic.List[object]
            foreach ($n in $names) {
                if (Test-Ignored "$root\$key|$n" $ignore) { continue }
                $kind = $k.GetValueKind($n)
                $type = $Types["$kind"]; if (-not $type) { $type = 'unknown' }
                $values.Add([ordered]@{ name = $n; type = $type; data = (ConvertTo-RegData $type $k.GetValue($n, $null, 'DoNotExpandEnvironmentNames')) })
            }
            $e.values = $values.ToArray() # @() on a List[object] trips a PowerShell 5.1 binder bug
        } finally { $k.Close() }
    } catch {
        Write-Host "unreadable: $root\$key ($($_.Exception.Message))"
        $e.unreadable = $true
    }
    $e
}

# The baseline as JSON text (one key or task per line).
function Get-BaselineJson([string]$expectedPath) {
    $j = [IO.File]::ReadAllText($expectedPath) | ConvertFrom-Json
    $ignore = @($j.ignore)
    $cv = $Hives.HKLM.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion')
    $windows = [ordered]@{ build = [string]$cv.GetValue('CurrentBuild'); ubr = [string]$cv.GetValue('UBR'); displayVersion = [string]$cv.GetValue('DisplayVersion') }
    $cv.Close()

    $sb = New-Object Text.StringBuilder "{`r`n  ""format"": 1,`r`n"
    [void]$sb.Append('  "capturedAt": ' + (ConvertTo-JsonText ([DateTime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture))) + ",`r`n")
    [void]$sb.Append('  "windows": ' + (ConvertTo-JsonText $windows) + ",`r`n")
    # HKCU is the hive of the user who ran the setup.
    [void]$sb.Append('  "userSid": ' + (ConvertTo-JsonText ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) + ",`r`n")
    [void]$sb.Append('  "expectedSha256": ' + (ConvertTo-JsonText (Get-FileHash -LiteralPath $expectedPath -Algorithm SHA256).Hash.ToLowerInvariant()) + ",`r`n")

    $keys = @($j.snapshotKeys | ForEach-Object { ConvertTo-JsonText (Get-KeyEntry $_.root $_.key $ignore) })
    [void]$sb.Append("  ""keys"": [`r`n    " + ($keys -join ",`r`n    ") + "`r`n  ],`r`n")

    try {
        $state = @{}
        foreach ($t in Get-ScheduledTask) { $state[($t.TaskPath + $t.TaskName).ToLowerInvariant()] = if ("$($t.State)" -eq 'Disabled') { 'disabled' } else { 'enabled' } }
        $tasks = @($j.tasks | ForEach-Object {
            $s = $state[$_.path.ToLowerInvariant()]
            ConvertTo-JsonText ([ordered]@{ path = $_.path; state = $(if ($s) { $s } else { 'absent' }) })
        })
        [void]$sb.Append("  ""tasks"": [`r`n    " + ($tasks -join ",`r`n    ") + "`r`n  ]`r`n")
    } catch {
        Write-Host "tasks not read: $($_.Exception.Message)"
        [void]$sb.Append("  ""tasks"": null`r`n")
    }
    [void]$sb.Append("}`r`n")
    $sb.ToString()
}

# Like the KOS Toolbox's admin-only folders (GpuTuner.PrepareDirectory): owned by Administrators, protected ACL, SYSTEM and
# Administrators full control, Users read. Refuses a link, or a folder neither SYSTEM nor Administrators owns.
function New-AdminFolder([string]$dir) {
    $parent = Split-Path $dir
    foreach ($p in $parent, $dir) {
        if ((Test-Path -LiteralPath $p) -and ((Get-Item -LiteralPath $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "$p is a link" }
    }
    if (-not (Test-Path -LiteralPath $dir)) {
        $admins = New-Object Security.Principal.SecurityIdentifier 'S-1-5-32-544'
        $inherit = [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
        $acl = New-Object Security.AccessControl.DirectorySecurity
        $acl.SetOwner($admins)
        $acl.SetAccessRuleProtection($true, $false)
        foreach ($r in @(@('S-1-5-18', 'FullControl'), @('S-1-5-32-544', 'FullControl'), @('S-1-5-32-545', 'ReadAndExecute, Synchronize'))) {
            $sid = New-Object Security.Principal.SecurityIdentifier $r[0]
            $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule -ArgumentList $sid, ([Security.AccessControl.FileSystemRights]$r[1]), $inherit, 'None', 'Allow'))
        }
        [void][IO.Directory]::CreateDirectory($dir, $acl)
    }
    if ((Get-Item -LiteralPath $dir -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "$dir is a link" }
    $owner = (Get-Acl -LiteralPath $dir).GetOwner([Security.Principal.SecurityIdentifier]).Value
    if ($owner -notin 'S-1-5-32-544', 'S-1-5-18') { throw "$dir is owned by $owner" }
}

# Dot-sourced by tests\check-kos-baseline.ps1: the functions only.
if ($MyInvocation.InvocationName -eq '.') { return }

try {
    $json = Get-BaselineJson $Expected
    New-AdminFolder (Split-Path $Out)
    [IO.File]::WriteAllText($Out, $json, (New-Object Text.UTF8Encoding $false))
    Write-Host "written: $Out"
    exit 0
} catch {
    Write-Host "baseline not saved: $($_.Exception.Message)"
    exit 1
}
