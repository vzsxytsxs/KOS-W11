<#
Generates src\ProgramData\TheKOS\bin\2\kos-expected.json: the state a KOS install leaves on the system, read from the files
that apply it, in the order they run: ntlite.xml (services, autologgers, features, components), boot.bat (first .reg import),
RunOnce.cmd (with 7zip-pexp.bat and the second .reg import where they run) and prepareiso.cmd (deleted files and packages).
The last write of a value wins. The startup scripts (bin\3, every logon) come last. The KOS Toolbox embeds the same file to find what Windows Update,
SFC or DISM reverted.

Only what is the same on every PC goes in. Left out (counted at the end): lines under an if, lines a conditional goto skips,
for /f and for /d loops, and lines with a variable set at run time (they depend on hardware, profile or what is installed).
The NTLite tweaks other than services and autologgers are left out too: the preset names only the last key, not the path.

snapshotKeys lists every key the KOS files write or delete, the left-out lines and the hardware and profile scripts included
(read for their keys only, every branch). At the end of the setup bin\2\Capture-KosBaseline.ps1 saves what those keys hold on
that PC; ignore holds the patterns of values neither list checks.

Usage: powershell -NoProfile -File building\Generate-KosExpected.ps1            writes the file
       powershell -NoProfile -File building\Generate-KosExpected.ps1 -Check     exit 1 when the file is out of date
       -ListSkipped also lists the lines left out
#>
param([switch]$Check, [string]$Out, [switch]$ListSkipped)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$repo = Split-Path $PSScriptRoot
$bin2 = Join-Path $repo 'src\ProgramData\TheKOS\bin\2'
if (-not $Out) { $Out = Join-Path $bin2 'kos-expected.json' }

# Values Windows itself changes over time (state, counters, tips already shown): not a KOS setting, so never "reverted".
# Matched against "ROOT\key|name" (case-insensitive).
$Exclude = @(
    'hkcu\software\sysinternals\*'                                 # Process Explorer's own preferences (7zip-pexp.bat)
    'hkcu\software\skillbrains\*'                                  # Lightshot's preferences (hotkeys the user changes there)
    'hklm\software\classes\7-zip.*'                                # 7-Zip's file associations, rewritten by its installer
    'hkcu\software\microsoft\windows\currentversion\explorer\taskband|*' # taskbar pins
    'hkcu\control panel\desktop|wallpaper'                         # the user's wallpaper
    'hkcu\control panel\keyboard|initialkeyboardindicators'        # Num Lock state, saved by Windows at sign-out
    'hklm\software\microsoft\windows\currentversion\runonce|*'     # consumed when it runs
    # The active firewall rules belong to the security profile: Advanced deletes them all (the KOS blocks stay in Defaults).
    'hklm\system\currentcontrolset\services\sharedaccess\parameters\firewallpolicy\firewallrules|*'
    # Task Scheduler rebuilds a deleted TaskCache key from the task's file at the next start; the task itself is in the task list.
    'hklm\software\microsoft\windows nt\currentversion\schedule\taskcache\*'
    # Windows' own runtime state in keys the KOS also sets (found by applying every "other change" on a test VM, 2026-11-21):
    # counters, ids, boot and shutdown records, window positions. Named one by one: the KOS values in the same keys stay checked.
    'hklm\system\currentcontrolset\control|lastbootshutdown'
    'hklm\system\currentcontrolset\control|lastbootsucceeded'
    'hklm\system\currentcontrolset\control|systemstartoptions'     # the boot options, rewritten at each boot
    'hklm\system\currentcontrolset\control\lsa|lsapid'
    'hklm\system\currentcontrolset\control\session manager\power|posttime'
    'hklm\system\currentcontrolset\control\session manager\memory management|pagefileusage'
    'hklm\system\currentcontrolset\control\session manager\memory management\prefetchparameters|basetime'
    'hklm\system\currentcontrolset\control\session manager\memory management\prefetchparameters|bootid'
    'hklm\system\currentcontrolset\services\tcpip\parameters|health'
    'hklm\software\microsoft\windows nt\currentversion\winlogon|lastlogoffendtimeperfcounter'
    'hklm\software\microsoft\windows nt\currentversion\winlogon|shutdownflags'
    'hklm\software\microsoft\windows nt\currentversion\softwareprotectionplatform|actionlist'
    'hklm\software\microsoft\windows nt\currentversion\softwareprotectionplatform|servicesessionid'
    'hklm\software\microsoft\windows nt\currentversion\appcompatflags\telemetrycontroller|checksum'
    'hklm\software\microsoft\windows\currentversion\explorer|globalassocchangedcounter'
    'hkcu\software\microsoft\windows\currentversion\explorer|logoncount'
    'hkcu\software\microsoft\windows\currentversion\explorer\advanced|taskbarstatelastrun'
    'hkcu\software\microsoft\windows\currentversion\search|installedpackagedappsrevision'
    'hkcu\control panel\desktop|max*dimension'                     # MaxMonitorDimension, MaxVirtualDesktopDimension
    'hkcu\software\microsoft\notepad|f*'                           # classic Notepad's own options and window position
    'hkcu\software\microsoft\notepad|i*'
    'hkcu\software\classes\local settings\software\microsoft\windows\shell\bags\allfolders\shell|*pos*' # window positions
    'hkcu\software\classes\local settings\software\microsoft\windows\shell\bagmru|?*' # its values; the deleted key stays checked
)

$Reg = [ordered]@{}        # "root\key|name" (lower) -> entry
$KeysAbsent = [ordered]@{} # "root\key" (lower) -> entry
$Tasks = [ordered]@{}
$Packages = [ordered]@{}
$Components = [ordered]@{}
$Features = [ordered]@{}
$Files = [ordered]@{}
$Skipped = [ordered]@{}
$Locked = @() # variables a script sets that the generator replaces with a fixed value
$NotParsed = [ordered]@{}
# Every key a KOS file writes or deletes, also on lines left out (if, goto, hardware and profile scripts): the setup's
# baseline (bin\2\Capture-KosBaseline.ps1) saves what each one holds on that PC.
$SnapshotKeys = [ordered]@{}
$KeysOnly = $false # parsing a hardware or profile script: only its keys are noted

function Skip([string]$reason, [string]$source) {
    if ($KeysOnly) { return }
    if (-not $Skipped.Contains($reason)) { $Skipped[$reason] = New-Object System.Collections.Generic.List[string] }
    $Skipped[$reason].Add($source)
}

# ---------- registry model ----------

$Roots = @{ HKEY_LOCAL_MACHINE = 'HKLM'; HKLM = 'HKLM'; HKEY_CURRENT_USER = 'HKCU'; HKCU = 'HKCU'; HKEY_CLASSES_ROOT = 'HKCR'; HKCR = 'HKCR'; HKEY_USERS = 'HKU'; HKU = 'HKU' }

# "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\X" -> @('HKLM', 'SYSTEM\CurrentControlSet\X'); $null for other roots.
function Split-RegPath([string]$path) {
    $p = $path.Trim().Trim('"').TrimEnd('\')
    $i = $p.IndexOf('\')
    $root = if ($i -lt 0) { $p } else { $p.Substring(0, $i) }
    $rest = if ($i -lt 0) { '' } else { $p.Substring($i + 1) }
    $r = $Roots[$root]
    if (-not $r) { return $null }
    # prepareiso edits the image's hives loaded as HKLM\KOS_SOFTWARE and HKLM\KOS_SYSTEM.
    $rest = $rest -replace '(?i)^KOS_(SOFTWARE|SYSTEM)\\', '$1\' -replace '(?i)^SYSTEM\\ControlSet001\\', 'SYSTEM\CurrentControlSet\'
    return , @($r, $rest)
}

function Test-Under([string]$id, [string]$keyId) { $id -eq $keyId -or $id.StartsWith($keyId + '\') }

function Add-SnapshotKey([string]$root, [string]$key) { $SnapshotKeys["$root\$key".ToLowerInvariant()] = [ordered]@{ root = $root; key = $key } }

# Writing under a key the KOS deleted earlier means the key exists again.
function Clear-AbsentAbove([string]$root, [string]$key) {
    $keyId = "$root\$key".ToLowerInvariant()
    foreach ($k in @($KeysAbsent.Keys)) { if (Test-Under $keyId $k) { $KeysAbsent.Remove($k) } }
}

function Set-RegValue([string]$root, [string]$key, [string]$name, [string]$type, $data, [string]$source, [string]$ifKeyExists, [bool]$expand) {
    Add-SnapshotKey $root $key
    Clear-AbsentAbove $root $key
    $e = [ordered]@{ root = $root; key = $key; name = $name; type = $type; data = $data; source = $source }
    if ($ifKeyExists) { $e.ifKeyExists = $ifKeyExists }
    if ($expand) { $e.expandData = $true }
    $Reg["$root\$key|$name".ToLowerInvariant()] = $e
}

function Remove-RegKey([string]$root, [string]$key, [string]$source) {
    Add-SnapshotKey $root $key
    $keyId = "$root\$key".ToLowerInvariant()
    foreach ($k in @($Reg.Keys)) { if (Test-Under $k.Substring(0, $k.IndexOf('|')) $keyId) { $Reg.Remove($k) } }
    foreach ($k in @($KeysAbsent.Keys)) { if (Test-Under $k $keyId) { $KeysAbsent.Remove($k) } }
    $KeysAbsent[$keyId] = [ordered]@{ root = $root; key = $key; source = $source }
}

# ---------- .reg files ----------

function ConvertFrom-HexBytes([string]$hex) {
    $b = [byte[]]@($hex -split '[,\s]+' | Where-Object { $_ } | ForEach-Object { [Convert]::ToByte($_, 16) })
    , $b
}

function Import-RegFile([string]$path) {
    $label = Split-Path $path -Leaf
    $lines = [IO.File]::ReadAllLines($path)
    $root = $null; $key = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $n = $i + 1
        $line = $lines[$i]
        while ($line.TrimEnd().EndsWith('\') -and $i + 1 -lt $lines.Count -and $line -match '^\s*("|@).*=\s*hex') {
            $i++; $line = $line.TrimEnd().TrimEnd('\') + $lines[$i].Trim()
        }
        $t = $line.Trim()
        if (-not $t -or $t.StartsWith(';') -or $t -match '^(Windows Registry Editor|REGEDIT4)') { continue }
        if ($t -match '^\[-(.+)\]$') {
            $sp = Split-RegPath $Matches[1]
            if ($sp) { Remove-RegKey $sp[0] $sp[1] "${label}:$n" }
            $root = $null; $key = $null; continue
        }
        if ($t -match '^\[(.+)\]$') {
            $sp = Split-RegPath $Matches[1]
            if ($sp) { $root = $sp[0]; $key = $sp[1]; Clear-AbsentAbove $root $key } else { $root = $null; $key = $null }
            continue
        }
        if (-not $key) { continue }
        if ($t -match '^@=(.*)$') { $name = ''; $value = $Matches[1] }
        elseif ($t -match '^"((?:[^"\\]|\\.)*)"=(.*)$') { $name = $Matches[1] -replace '\\(.)', '$1'; $value = $Matches[2] }
        else { Skip 'malformed .reg line' "${label}:$n"; continue }
        $src = "${label}:$n"
        if ($value -eq '-') { Set-RegValue $root $key $name 'absent' $null $src; continue }
        if ($value -match '^"((?:[^"\\]|\\.)*)"$') { Set-RegValue $root $key $name 'sz' ($Matches[1] -replace '\\(.)', '$1') $src; continue }
        if ($value -match '^dword:([0-9a-fA-F]{1,8})$') { Set-RegValue $root $key $name 'dword' ([Convert]::ToUInt32($Matches[1], 16).ToString()) $src; continue }
        if ($value -match '^hex(?:\((\w+)\))?:(.*)$') {
            $kind = if ($Matches[1]) { $Matches[1].ToLowerInvariant() } else { '3' }
            $bytes = ConvertFrom-HexBytes $Matches[2]
            switch ($kind) {
                '3' { Set-RegValue $root $key $name 'binary' (($bytes | ForEach-Object { $_.ToString('x2') }) -join '') $src }
                'b' { Set-RegValue $root $key $name 'qword' ([BitConverter]::ToUInt64([byte[]](@($bytes) + @(0, 0, 0, 0, 0, 0, 0, 0))[0..7], 0).ToString()) $src }
                '2' { Set-RegValue $root $key $name 'expand_sz' ([Text.Encoding]::Unicode.GetString($bytes).TrimEnd([char]0)) $src }
                '7' { Set-RegValue $root $key $name 'multi_sz' @([Text.Encoding]::Unicode.GetString($bytes).TrimEnd([char]0) -split [char]0 | Where-Object { $_ }) $src }
                default { Set-RegValue $root $key $name "hex($kind)" (($bytes | ForEach-Object { $_.ToString('x2') }) -join '') $src }
            }
            continue
        }
        Skip 'malformed .reg line' $src
    }
}

# ---------- batch files ----------

# Lines with ^ continuations joined, :: and rem comments dropped; each keeps its first line number.
function Read-Batch([string]$path) {
    $lines = [IO.File]::ReadAllLines($path)
    $items = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $n = $i + 1; $t = $lines[$i]
        while ($t.EndsWith('^') -and $i + 1 -lt $lines.Count) { $i++; $t = $t.Substring(0, $t.Length - 1) + $lines[$i] }
        if ($t.Trim() -match '^(::|rem\b|@?echo\b|cls\b|title\b|timeout\b|pause\b)') { continue }
        $items.Add([pscustomobject]@{ Text = $t; Line = $n })
    }
    , $items
}

# Opening minus closing parentheses outside quotes.
function Get-ParenDepth([string]$s) {
    $d = 0; $q = $false
    foreach ($c in $s.ToCharArray()) {
        if ($c -eq '"') { $q = -not $q } elseif (-not $q) { if ($c -eq '(') { $d++ } elseif ($c -eq ')') { $d-- } }
    }
    $d
}

# From the item at $start (which opens a block), the index after the block and the items inside it.
function Get-Block($items, [int]$start, [int]$depth = -1) {
    if ($depth -lt 0) { $depth = Get-ParenDepth $items[$start].Text }
    $inner = New-Object System.Collections.Generic.List[object]
    $j = $start + 1
    while ($j -lt $items.Count -and $depth -gt 0) {
        $d = Get-ParenDepth $items[$j].Text
        if ($depth + $d -le 0) { $j++; $depth = 0; break }
        $depth += $d
        if ($items[$j].Text.Trim() -match '^\)\s*else\s*\($') { $j++; continue }
        $inner.Add($items[$j]); $j++
    }
    return @{ Next = $j; Inner = $inner }
}

function Test-Writes([string]$t) { $t -match '(?i)\breg(\.exe)?"?\s+(add|delete)\b|schtasks|Remove-AppxPackage|regedit|\bdel\b|\brmdir\b|:removeAppx' }

# A line left out: its static keys still go to the snapshot list.
function Skip-Line([string]$reason, [string]$text, [string]$source, $vars) {
    if (-not (Test-Writes $text)) { return }
    Skip $reason $source
    foreach ($m in [regex]::Matches($text, '(?i)\breg(?:\.exe)?"?\s+(?:add|delete)\s+("[^"]+"|\S+)')) {
        $k = Resolve-Vars (Unquote $m.Groups[1].Value) $vars
        $sp = if ($k) { Split-RegPath $k } else { $null }
        if ($sp) { Add-SnapshotKey $sp[0] $sp[1] }
    }
}

# Tokens split on spaces outside quotes; quotes kept.
function Split-Args([string]$s) {
    $tokens = New-Object System.Collections.Generic.List[string]
    $cur = New-Object Text.StringBuilder; $q = $false
    foreach ($c in $s.ToCharArray()) {
        if ($c -eq '"') { $q = -not $q; [void]$cur.Append($c) }
        elseif (-not $q -and ($c -eq ' ' -or $c -eq "`t")) { if ($cur.Length) { $tokens.Add($cur.ToString()); [void]$cur.Clear() } }
        else { [void]$cur.Append($c) }
    }
    if ($cur.Length) { $tokens.Add($cur.ToString()) }
    , $tokens
}

function Unquote([string]$s) { if ($s.Length -ge 2 -and $s.StartsWith('"') -and $s.EndsWith('"')) { $s.Substring(1, $s.Length - 2) } else { $s } }

# Segments of "a && b || c & d" outside quotes, each with the operator before it.
function Split-Chain([string]$s) {
    $parts = New-Object System.Collections.Generic.List[object]
    $cur = New-Object Text.StringBuilder; $q = $false; $op = ''
    for ($k = 0; $k -lt $s.Length; $k++) {
        $c = $s[$k]
        if ($c -eq '"') { $q = -not $q; [void]$cur.Append($c); continue }
        if (-not $q -and ($c -eq '&' -or $c -eq '|')) {
            if ($k -gt 0 -and $s[$k - 1] -eq '>') { [void]$cur.Append($c); continue } # 2>&1
            $two = $k + 1 -lt $s.Length -and $s[$k + 1] -eq $c
            $parts.Add([pscustomobject]@{ Op = $op; Text = $cur.ToString().Trim() }); [void]$cur.Clear()
            $op = if ($two) { "$c$c" } else { "$c" }
            if ($two) { $k++ }
            continue
        }
        [void]$cur.Append($c)
    }
    $parts.Add([pscustomobject]@{ Op = $op; Text = $cur.ToString().Trim() })
    , $parts
}

$EnvNames = 'windir', 'systemroot', 'systemdrive', 'programdata', 'programfiles', 'programfiles(x86)', 'userprofile', 'localappdata', 'appdata', 'public'

# %name% of the script's own constant variables replaced. Null when a run-time variable is left (!x!, %~1, %%x, %other%).
function Resolve-Vars([string]$s, $vars, [switch]$AllowEnv) {
    $r = [regex]::Replace($s, '%(\w+)%', { param($m) if ($vars.Contains($m.Groups[1].Value.ToLowerInvariant())) { $vars[$m.Groups[1].Value.ToLowerInvariant()] } else { $m.Value } }.GetNewClosure())
    if ($r -match '![\w]+!|%~|%%|%\d') { return $null }
    foreach ($m in [regex]::Matches($r, '%([\w()]+)%')) {
        if (-not $AllowEnv -or $EnvNames -notcontains $m.Groups[1].Value.ToLowerInvariant()) { return $null }
    }
    $r
}

function Get-Switch($tokens, [string]$name) {
    for ($k = 0; $k -lt $tokens.Count - 1; $k++) { if ($tokens[$k] -ieq $name) { return Unquote $tokens[$k + 1] } }
    $null
}

$RegTypes = @{ REG_SZ = 'sz'; REG_EXPAND_SZ = 'expand_sz'; REG_MULTI_SZ = 'multi_sz'; REG_DWORD = 'dword'; REG_QWORD = 'qword'; REG_BINARY = 'binary'; REG_NONE = 'none' }

function Invoke-RegCommand($tokens, [string]$source, [string]$ifKeyExists, $vars) {
    $verb = $tokens[1].ToLowerInvariant()
    $rawKey = Resolve-Vars (Unquote $tokens[2]) $vars
    if (-not $rawKey) { Skip 'run-time variable' $source; return }
    $sp = Split-RegPath $rawKey
    if (-not $sp) { Skip 'unsupported registry root' $source; return }
    $root = $sp[0]; $key = $sp[1]
    Add-SnapshotKey $root $key
    if ($KeysOnly) { return }
    $ve = $tokens | Where-Object { $_ -ieq '/ve' }
    $name = if ($ve) { '' } else { Get-Switch $tokens '/v' }
    if ($null -ne $name) { $name = Resolve-Vars $name $vars; if ($null -eq $name) { Skip 'run-time variable' $source; return } }
    if ($verb -eq 'delete') {
        if ($tokens | Where-Object { $_ -ieq '/va' }) { Skip 'reg delete /va' $source; return }
        if ($null -eq $name) { Remove-RegKey $root $key $source } else { Set-RegValue $root $key $name 'absent' $null $source $ifKeyExists }
        return
    }
    if ($null -eq $name) { Skip 'reg add without a value' $source; return }
    $t = Get-Switch $tokens '/t'; if (-not $t) { $t = 'REG_SZ' }
    $type = $RegTypes[$t.ToUpperInvariant()]
    if (-not $type) { Skip "type $t" $source; return }
    $raw = Get-Switch $tokens '/d'; if ($null -eq $raw) { $raw = '' }
    $data = Resolve-Vars $raw $vars -AllowEnv
    if ($null -eq $data) { Skip 'run-time variable' $source; return }
    $expand = $data -match '%[\w()]+%'
    try {
    switch ($type) {
        'dword' { $data = if ($data -match '^0x([0-9a-f]+)$') { [Convert]::ToUInt32($Matches[1], 16).ToString() } else { ([uint32]$data).ToString() } }
        'qword' { $data = if ($data -match '^0x([0-9a-f]+)$') { [Convert]::ToUInt64($Matches[1], 16).ToString() } else { ([uint64]$data).ToString() } }
        'binary' { $data = $data.ToLowerInvariant() }
        'multi_sz' { $sep = Get-Switch $tokens '/s'; $data = @($(if ($sep) { $data -split [regex]::Escape($sep) } else { $data -split '\\0' }) | Where-Object { $_ }) }
    }
    } catch { Skip 'unreadable data' $source; return }
    Set-RegValue $root $key $name $type $data $source $ifKeyExists $expand
}

function Add-File([string]$path, [string]$kind, [string]$source) {
    $p = $path.Trim('"')
    if (-not $p -or $p -match '%|!') { Skip 'run-time variable' $source; return }
    $Files[$p.ToLowerInvariant()] = [ordered]@{ path = $p; kind = $kind; source = $source }
}

function Add-Package([string]$name, [string]$source) { $Packages[$name.ToLowerInvariant()] = [ordered]@{ name = $name; source = $source } }

# One command of a chain (what && and || separate).
function Invoke-Command1([string]$text, [string]$source, [string]$ifKeyExists, $vars, [string]$file) {
    $t = $text.Trim() -replace '(?i)^(PowerRun(\.exe)?\s+(/SW:\d\s+)?|start\s+/b\s+/wait\s+""\s+|call\s+(?=")|cmd(\.exe)?\s+/c\s+)', ''
    $t = $t -replace '(?i)^(PowerRun(\.exe)?\s+(/SW:\d\s+)?|cmd(\.exe)?\s+/c\s+)', ''
    $tokens = Split-Args $t
    $kept = New-Object System.Collections.Generic.List[string]
    $drop = $false
    foreach ($tok in $tokens) {
        if ($drop) { $drop = $false; continue }
        if ($tok -match '^\d?>$') { $drop = $true; continue }
        if ($tok -notmatch '^\d?>') { $kept.Add($tok) }
    }
    $tokens = $kept
    if ($tokens.Count -eq 0) { return }
    $first = Unquote $tokens[0]
    # call "%script%": the script's path kept in a variable (the profile scripts do this).
    if ($first -match '^%\w+%') { $r = Resolve-Vars $first $vars -AllowEnv; if ($r) { $first = $r } }
    $cmd = [IO.Path]::GetFileNameWithoutExtension($first).ToLowerInvariant()
    $leaf = [IO.Path]::GetFileName($first).ToLowerInvariant()
    if ($cmd -eq 'reg' -and $tokens.Count -ge 3 -and $tokens[1] -match '^(?i)(add|delete)$') { Invoke-RegCommand $tokens $source $ifKeyExists $vars; return }
    if ($KeysOnly -and $leaf -notmatch '\.(cmd|bat)$') { return }
    if ($cmd -eq 'schtasks') {
        $tn = Get-Switch $tokens '/tn'
        if (-not $tn) { return }
        $tn = '\' + $tn.TrimStart('\') # schtasks takes the path with or without the leading \
        $state = if ($tokens -contains '/disable') { 'disabled' } elseif ($tokens -contains '/enable') { 'enabled' } elseif ($tokens -contains '/delete') { 'absent' } else { $null }
        if ($state) { $Tasks[$tn.ToLowerInvariant()] = [ordered]@{ path = $tn; state = $state; source = $source } }
        return
    }
    if ($cmd -eq 'regedit') {
        $f = $tokens | Select-Object -Last 1
        $f = Unquote $f
        if ($f -match '(?i)^%programdata%\\TheKOS\\bin\\2\\([^\\]+\.reg)$' -and (Test-Path (Join-Path $bin2 $Matches[1]))) { Import-RegFile (Join-Path $bin2 $Matches[1]) }
        else { $NotParsed[$f] = $source }
        return
    }
    if ($cmd -eq 'sc' -and $tokens.Count -ge 5 -and $tokens[1] -ieq 'config' -and $tokens[3] -ieq 'start=') {
        $start = @{ boot = 0; system = 1; auto = 2; 'delayed-auto' = 2; demand = 3; disabled = 4 }[$tokens[4].ToLowerInvariant()]
        if ($null -eq $start) { Skip 'sc config start' $source; return }
        Set-RegValue 'HKLM' "SYSTEM\CurrentControlSet\Services\$($tokens[2])" 'Start' 'dword' ([string]$start) $source $null $false
        return
    }
    if ($leaf -match '\.(cmd|bat)$') {
        # Another KOS script runs inline: parsed in place (its own if, goto and %1 lines are left out as usual).
        $called = $first
        if ($called -match '(?i)^%programdata%\\TheKOS\\(.+)$' -and (Test-Path -LiteralPath (Join-Path $repo "src\ProgramData\TheKOS\$($Matches[1])"))) {
            $path = Join-Path $repo "src\ProgramData\TheKOS\$($Matches[1])"
            if ($leaf -in 'deviceprofile.cmd', 'security profile basic-advanced.cmd') {
                # Per hardware (desktop or laptop) and per security profile: the toolbox's own settings, with their per-profile
                # defaults, cover the values; only the keys are noted, for the baseline.
                $NotParsed["$called (depends on hardware or profile; keys only)"] = $source
                $was = $KeysOnly; $script:KeysOnly = $true
                try { Invoke-Batch (Read-Batch $path) $leaf @{} } finally { $script:KeysOnly = $was }
            } else { Invoke-Batch (Read-Batch $path) $leaf @{} }
        } else { $NotParsed[$called] = $source }
        return
    }
    if ($leaf -match '\.ps1$') { $NotParsed[(Unquote $tokens[0])] = $source; return }
    if ($t -match '(?i)Remove-AppxPackage') {
        foreach ($m in [regex]::Matches($t, "(?i)-Name\s+[""']([^""']+)[""']|-Like\s+'([^']+)'")) { Add-Package ($m.Groups[1].Value + $m.Groups[2].Value) $source }
        return
    }
    if ($file -eq 'prepareiso.cmd') {
        if ($cmd -eq 'del') { Add-File (Resolve-Vars (Unquote ($tokens | Select-Object -Last 1)) $vars) 'file' $source; return }
        if ($cmd -in 'rmdir', 'rd') { Add-File (Resolve-Vars (Unquote ($tokens | Select-Object -Last 1)) $vars) 'folder' $source; return }
        if ($t -match '(?i)^call\s+:removeAppx\s+(\S+)') { Add-Package $Matches[1] $source; return }
    }
}

function Invoke-Line([string]$text, [string]$source, $vars, [string]$file) {
    $chain = Split-Chain $text
    $guard = $null
    foreach ($seg in $chain) {
        if ($seg.Op -eq '||' -or $seg.Op -eq '|') { break } # error handlers and pipes into findstr
        if ($seg.Text -match '(?i)^reg(\.exe)?\s+query\s+("[^"]+"|\S+)' -and $seg.Op -ne '&&') { $g = Resolve-Vars (Unquote $Matches[2]) $vars; $sp = if ($g) { Split-RegPath $g } else { $null }; $guard = if ($sp) { "$($sp[0])\$($sp[1])" } else { $null }; continue }
        Invoke-Command1 $seg.Text $source $(if ($seg.Op -eq '&&') { $guard } else { $null }) $vars $file
    }
}

function Invoke-Batch($items, [string]$file, $vars) {
    # What runs on every PC: $skipTo = the label a conditional goto jumps to (the lines before it run only when the condition
    # is false); $dead = after exit or a plain goto, until a label a plain goto jumps to (a label reached only through a
    # conditional goto or a call is conditional too); $jumpOnly = the skipped lines ended in exit or goto.
    $skipTo = $null; $jumpOnly = $false; $dead = $false; $plainTargets = @{}
    $i = 0
    while ($i -lt $items.Count) {
        $it = $items[$i]; $t = $it.Text.Trim(); $src = "${file}:$($it.Line)"
        if ($t -match '^:(\w+)') {
            $label = $Matches[1].ToLowerInvariant()
            if ($skipTo -and $label -eq $skipTo) { $skipTo = $null; $dead = $jumpOnly; $jumpOnly = $false }
            elseif ($dead -and $plainTargets.ContainsKey($label)) { $dead = $false }
            $i++; continue
        }
        # Noting keys only: every path through the script counts, so jumps and exits are ignored.
        if ($KeysOnly -and $t -match '(?i)\bgoto\b|^exit\b') { $i++; continue }
        # Setup runs as administrator: "fltmc && goto admin" (the elevation check) always jumps.
        if ($t -match '(?i)^(fltmc|net\s+session|openfiles)\b.*&&\s*goto\s+:?(\w+)\s*$') { $plainTargets[$Matches[2].ToLowerInvariant()] = $true; $dead = $true; $i++; continue }
        if ($t -match '(?i)(&&|\|\|)\s*goto\s+:?(\w+)\s*$' -and $Matches[2] -ine 'eof') { $skipTo = $Matches[2].ToLowerInvariant(); $i++; continue }
        $isExit = $t -match '(?i)^(exit\b|goto\s+:?eof\b)'
        $plainGoto = if (-not $isExit -and $t -match '(?i)^goto\s+:?(\w+)') { $Matches[1].ToLowerInvariant() } else { $null }
        if ($skipTo) { if ($isExit -or $plainGoto) { $jumpOnly = $true }; Skip-Line 'conditional (goto)' $t $src $vars; $i++; continue }
        if ($dead) { Skip-Line 'conditional (label)' $t $src $vars; $i++; continue }
        if ($isExit) { $dead = $true; $i++; continue }
        if ($plainGoto) { $plainTargets[$plainGoto] = $true; $dead = $true; $i++; continue }
        if ($t -match '(?i)^for\s+/[fdr]\b') {
            $end = if ((Get-ParenDepth $t) -gt 0) { (Get-Block $items $i).Next } else { $i + 1 }
            for ($k = $i; $k -lt $end; $k++) { Skip-Line 'for /f, /d or /r loop' $items[$k].Text "${file}:$($items[$k].Line)" $vars }
            $i = $end; continue
        }
        if ($t -match '(?i)^for\s+%%(\w)\s+in\s*\(') {
            $var = $Matches[1]
            # The list can span lines: gather until the in ( ... ) closes.
            $header = $t; $j = $i
            while ((Get-ParenDepth ($header -replace '(?i)\)\s*do\s*\($', ')')) -gt 0 -and $j + 1 -lt $items.Count) { $j++; $header += ' ' + $items[$j].Text.Trim() }
            if ($header -notmatch '(?i)^for\s+%%\w\s+in\s*\((.*?)\)\s*do\s*(.*)$') { Skip 'unreadable for' $src; $i = $j + 1; continue }
            $list = Split-Args $Matches[1].Trim(); $rest = $Matches[2].Trim()
            if ($rest -eq '(') {
                $blk = Get-Block $items $j 1
                $body = $blk.Inner; $i = $blk.Next
            } else {
                if ($rest -match '^\((.*)\)$') { $rest = $Matches[1] }
                $body = @([pscustomobject]@{ Text = $rest; Line = $items[$j].Line }); $i = $j + 1
            }
            foreach ($tok in $list) {
                $expanded = foreach ($b in $body) { [pscustomobject]@{ Text = $b.Text.Replace("%%~$var", (Unquote $tok)).Replace("%%$var", $tok); Line = $b.Line } }
                Invoke-Batch @($expanded) $file $vars
            }
            continue
        }
        if ($t -match '(?i)^if\b') {
            if ($t -match '(?i)\bgoto\s+:?(\w+)\s*$' -and $Matches[1] -ine 'eof') { $skipTo = $Matches[1].ToLowerInvariant(); $i++; continue }
            if ((Get-ParenDepth $t) -gt 0) {
                $blk = Get-Block $items $i
                # Noting keys only: every branch counts, so the block is read like any other lines (its for lists expanded).
                if ($KeysOnly) { Invoke-Batch $blk.Inner.ToArray() $file $vars; $i = $blk.Next; continue }
                foreach ($b in $blk.Inner) { Skip-Line 'conditional (if)' $b.Text "${file}:$($b.Line)" $vars }
                Skip-Line 'conditional (if)' $t $src $vars
                $i = $blk.Next; continue
            }
            Skip-Line 'conditional (if)' $t $src $vars
            $i++; continue
        }
        if ($t -match '(?i)^set\s+"?(\w+)=([^"]*)"?\s*$') {
            $vn = $Matches[1].ToLowerInvariant(); $vv = $Matches[2]
            if ($Locked -contains $vn) { $i++; continue }
            # Noting keys only, a path like %ProgramData%\TheKOS\x.bat is kept: it names a script to follow.
            $v = if ($KeysOnly) { Resolve-Vars $vv $vars -AllowEnv } else { Resolve-Vars $vv $vars }
            if ($null -ne $v -and ($KeysOnly -or $v -notmatch '%')) { $vars[$vn] = $v } else { $vars.Remove($vn) }
            $i++; continue
        }
        Invoke-Line $t $src $vars $file
        $i++
    }
}

# ---------- NTLite preset ----------

function Import-NTLite([string]$path) {
    # Without the default namespace, so plain XPath works.
    [xml]$x = [IO.File]::ReadAllText($path) -replace ' xmlns="[^"]*"', ''
    foreach ($tw in $x.SelectNodes('//Services//Tweak')) {
        $svc = ($tw.name -split '\\')[0]
        Set-RegValue 'HKLM' "SYSTEM\CurrentControlSet\Services\$svc" 'Start' 'dword' ([uint32]$tw.InnerText).ToString() 'ntlite.xml' $null $false
    }
    foreach ($tw in $x.SelectNodes('//Events//TweakGroup[@name="AutoLogger"]/Tweak')) {
        $parts = $tw.name -split '\\'
        Set-RegValue 'HKLM' "SYSTEM\CurrentControlSet\Control\WMI\Autologger\$($parts[0])" $parts[1] 'dword' ([uint32]$tw.InnerText).ToString() 'ntlite.xml' $null $false
    }
    $other = $x.SelectNodes('//Tweaks//Tweak').Count - $x.SelectNodes('//Services//Tweak').Count - $x.SelectNodes('//Events//TweakGroup[@name="AutoLogger"]/Tweak').Count
    for ($k = 0; $k -lt $other; $k++) { Skip 'NTLite tweak without a full path' 'ntlite.xml' }
    foreach ($f in $x.SelectNodes('/Preset/Features/Feature')) {
        $name = $f.name
        $Features[$name.ToLowerInvariant()] = [ordered]@{ name = $name; capability = $name.Contains('~'); enabled = ($f.InnerText -eq 'true'); source = 'ntlite.xml' }
    }
    foreach ($c in $x.SelectNodes('/Preset/RemoveComponents/c')) {
        if ($c.InnerText -match "^(\S+)(?:\s+'(.*)')?$") { $Components[$Matches[1].ToLowerInvariant()] = [ordered]@{ id = $Matches[1]; label = $Matches[2]; source = 'ntlite.xml' } }
    }
}

# ---------- run ----------

Import-NTLite (Join-Path $PSScriptRoot 'ntlite.xml')
Invoke-Batch (Read-Batch (Join-Path $repo 'src\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\boot.bat')) 'boot.bat' @{}
Invoke-Batch (Read-Batch (Join-Path $repo 'src\Windows\RunOnce.cmd')) 'RunOnce.cmd' @{}
# Every logon after the RunOnce reboot (startup.vbs): what these set last is what stays.
foreach ($f in 'cleanup.cmd', 'startuptweaks.cmd') { Invoke-Batch (Read-Batch (Join-Path $repo "src\ProgramData\TheKOS\bin\3\$f")) $f @{} }
# The image's folder (prepareiso's %mountDir%) is C: once installed.
$Locked = @('mountdir')
Invoke-Batch (Read-Batch (Join-Path $PSScriptRoot 'prepareiso.cmd')) 'prepareiso.cmd' @{ mountdir = 'C:' }

$excluded = 0
foreach ($k in @($Reg.Keys)) { foreach ($p in $Exclude) { if ($k -like $p.ToLowerInvariant()) { $Reg.Remove($k); $excluded++; break } } }
foreach ($k in @($KeysAbsent.Keys)) { foreach ($p in $Exclude) { if ("$k\" -like $p -or "$k|" -like $p) { $KeysAbsent.Remove($k); $excluded++; break } } }
# A key whose every value is excluded (a pattern ending in "\*" or "|*") stays out of the snapshot list too.
foreach ($k in @($SnapshotKeys.Keys)) { foreach ($p in $Exclude) { if ("$k\|" -like $p -or "$k|" -like $p) { $SnapshotKeys.Remove($k); break } } }
$Ignore = [ordered]@{}; foreach ($p in $Exclude) { $Ignore[$p] = $p }

# ---------- JSON (one entry per line, sorted, ASCII: stable diffs) ----------

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

function Write-Section([System.Text.StringBuilder]$sb, [string]$name, $dict, [bool]$last) {
    [void]$sb.Append("  ""$name"": [")
    [string[]]$keys = @($dict.Keys)
    [Array]::Sort($keys, [StringComparer]::Ordinal)
    for ($k = 0; $k -lt $keys.Count; $k++) { [void]$sb.Append("`r`n    " + (ConvertTo-JsonText $dict[$keys[$k]]) + $(if ($k -lt $keys.Count - 1) { ',' } else { '' })) }
    [void]$sb.Append($(if ($keys.Count) { "`r`n  ]" } else { ']' }) + $(if ($last) { '' } else { ',' }) + "`r`n")
}

$sb = New-Object Text.StringBuilder "{`r`n  ""format"": 1,`r`n"
Write-Section $sb 'registry' $Reg $false
Write-Section $sb 'keysAbsent' $KeysAbsent $false
Write-Section $sb 'tasks' $Tasks $false
Write-Section $sb 'packages' $Packages $false
Write-Section $sb 'components' $Components $false
Write-Section $sb 'features' $Features $false
Write-Section $sb 'files' $Files $false
Write-Section $sb 'snapshotKeys' $SnapshotKeys $false
# "ROOT\key|name" patterns (case-insensitive, * wildcard) of values Windows itself changes: neither checked nor saved.
Write-Section $sb 'ignore' $Ignore $true
[void]$sb.Append("}`r`n")
$json = $sb.ToString()

Write-Host ("registry {0}, keys absent {1}, tasks {2}, packages {3}, components {4}, features {5}, files {6}, snapshot keys {7}; excluded {8}" -f $Reg.Count, $KeysAbsent.Count, $Tasks.Count, $Packages.Count, $Components.Count, $Features.Count, $Files.Count, $SnapshotKeys.Count, $excluded)
foreach ($r in $Skipped.Keys) { Write-Host ("  left out ({0}): {1}" -f $r, $Skipped[$r].Count); if ($ListSkipped) { Write-Host ("    " + (($Skipped[$r] | Select-Object -Unique) -join ", ")) } }
foreach ($f in $NotParsed.Keys) { Write-Host "  not parsed: $f ($($NotParsed[$f]))" }

$current = if (Test-Path -LiteralPath $Out) { [IO.File]::ReadAllText($Out) } else { '' }
if ($Check) {
    if ($current -ne $json) { Write-Host "$Out is out of date: run building\Generate-KosExpected.ps1." -ForegroundColor Red; exit 1 }
    Write-Host "$Out is up to date."
    exit 0
}
if ($current -eq $json) { Write-Host "$Out unchanged." }
else { [IO.File]::WriteAllText($Out, $json, (New-Object Text.UTF8Encoding $false)); Write-Host "$Out written: copy it to the KOS Toolbox (toolbox\src\KosToolbox.Core\KosState\kos-expected.json), which embeds the same list." }
