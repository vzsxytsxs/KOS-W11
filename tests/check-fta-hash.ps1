# Checks the UserChoice hash of bin\2\PhotoViewer-FTA.ps1 against hashes Windows computed itself (Shell-Core/AppDefaults
# events of a 26H2 test install). The first two used to come out wrong: an Int32 + Int32 overflow turned into a [double].
# Usage: powershell -NoProfile -File tests\check-fta-hash.ps1        exit 1 on a mismatch
$ErrorActionPreference = 'Stop'
$fta = Join-Path (Split-Path $PSScriptRoot) 'src\ProgramData\TheKOS\bin\2\PhotoViewer-FTA.ps1'
$ast = [Management.Automation.Language.Parser]::ParseFile($fta, [ref]$null, [ref]$null)
Invoke-Expression $ast.Find({ param($a) $a -is [Management.Automation.Language.FunctionDefinitionAst] -and $a.Name -eq 'Get-Hash' }, $true).Extent.Text

$sid = 's-1-5-21-180781130-3585935378-610159755-1000'
$experience = 'User Choice set via Windows User Experience {D18B6DD5-6124-4341-9318-804003BAFA0B}'
$failed = 0
foreach ($c in @(
        @('.png', 'PhotoViewer.FileAssoc.Tiff', 38, 'VgZX8tIqqQs='),
        @('.cfg', 'Notepad++_file', 39, 'GBcrPogcDFE='),
        @('.png', 'AppX43hnxtbyyps62jhe9sqpdzxn1790zetc', 38, 'ITKUAbyOqAo='),
        @('.tif', 'AppX43hnxtbyyps62jhe9sqpdzxn1790zetc', 31, '2EaHngYP5BI='))) {
    $fileTime = [datetime]::new(2026, 11, 17, 15, $c[2], 0, [DateTimeKind]::Utc).ToFileTimeUtc()
    $time = (($fileTime -shr 32).ToString('X8') + ($fileTime -band 0xFFFFFFFFL).ToString('X8')).ToLower()
    $hash = Get-Hash "$($c[0])$sid$($c[1])$time$experience".ToLower()
    if ($hash -eq $c[3]) { Write-Host "ok   $($c[0]) $($c[1])" } else { Write-Host "FAIL $($c[0]) $($c[1]): $hash, Windows $($c[3])" -ForegroundColor Red; $failed++ }
}
if ($failed) { exit 1 }
