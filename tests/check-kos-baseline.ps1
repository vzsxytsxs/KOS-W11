# Checks src\ProgramData\TheKOS\bin\2\Capture-KosBaseline.ps1 against this PC's registry, read-only: nothing is written
# (the admin-only folder is left out). Usage: powershell -NoProfile -File tests\check-kos-baseline.ps1    exit 1 on a failure
$repo = Split-Path $PSScriptRoot
$bin2 = Join-Path $repo 'src\ProgramData\TheKOS\bin\2'
. (Join-Path $bin2 'Capture-KosBaseline.ps1')
$failed = 0
function Check([string]$what, [bool]$ok) { if ($ok) { Write-Host "ok   $what" } else { Write-Host "FAIL $what" -ForegroundColor Red; $script:failed++ } }

# Data written the way kos-expected.json writes it.
Check 'negative DWORD as unsigned' ((ConvertTo-RegData 'dword' -1) -eq '4294967295')
Check 'negative QWORD as unsigned' ((ConvertTo-RegData 'qword' ([int64]-1)) -eq '18446744073709551615')
Check 'binary in lower-case hex' ((ConvertTo-RegData 'binary' ([byte[]](1, 171))) -eq '01ab')
Check 'one-string MULTI_SZ stays a list' ((ConvertTo-JsonText ([ordered]@{ data = (ConvertTo-RegData 'multi_sz' ([string[]]@('a'))) })) -eq '{"data":["a"]}')
Check 'empty MULTI_SZ is an empty list' ((ConvertTo-JsonText ([ordered]@{ data = (ConvertTo-RegData 'multi_sz' ([string[]]@())) })) -eq '{"data":[]}')

$expected = Join-Path $bin2 'kos-expected.json'
$ignore = @(([IO.File]::ReadAllText($expected) | ConvertFrom-Json).ignore)
Check 'wallpaper ignored' (Test-Ignored 'HKCU\Control Panel\Desktop|WallPaper' $ignore)
Check 'other Desktop values kept' (-not (Test-Ignored 'HKCU\Control Panel\Desktop|MenuShowDelay' $ignore))

$k = Get-KeyEntry 'HKLM' 'SOFTWARE\Microsoft\Windows NT\CurrentVersion' $ignore
Check 'existing key read' ($k.exists -and ($k.values | Where-Object { $_.name -eq 'CurrentBuild' -and $_.type -eq 'sz' }))
$hkcr = Get-KeyEntry 'HKCR' '.txt' $ignore
$machine = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Classes\.txt')
Check 'HKCR read from HKLM\SOFTWARE\Classes' ($hkcr.exists -and @($hkcr.values).Count -eq $machine.ValueCount)
Check 'missing key recorded as absent' (-not (Get-KeyEntry 'HKLM' 'SOFTWARE\KOS-baseline-check-missing' $ignore).exists)

$b = Get-BaselineJson $expected | ConvertFrom-Json
$snapshot = @(([IO.File]::ReadAllText($expected) | ConvertFrom-Json).snapshotKeys)
Check 'one entry per snapshot key' ($b.keys.Count -eq $snapshot.Count)
Check 'Windows build recorded' ($b.windows.build -match '^\d+$')
Check 'expected file hash recorded' ($b.expectedSha256 -eq (Get-FileHash $expected -Algorithm SHA256).Hash.ToLowerInvariant())
Check 'task states read' ($null -ne $b.tasks -and @($b.tasks | Where-Object { $_.state -notin 'enabled', 'disabled', 'absent' }).Count -eq 0)
Write-Host ("keys {0} (absent {1}, unreadable {2}), values {3}, tasks {4}" -f $b.keys.Count, @($b.keys | Where-Object { $_.PSObject.Properties['exists'] -and -not $_.exists }).Count,
    @($b.keys | Where-Object { $_.PSObject.Properties['unreadable'] }).Count, (@($b.keys | Where-Object { $_.PSObject.Properties['values'] } | ForEach-Object { @($_.values).Count }) | Measure-Object -Sum).Sum, @($b.tasks).Count)

if ($failed) { exit 1 }
