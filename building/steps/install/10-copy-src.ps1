# Copies the repository's src\ to the root of the mounted image (Windows, ProgramData, Program Files, Users).
# /B (backup mode) writes into TrustedInstaller folders without changing the ACL; new files inherit the folder's ACL.
param([string]$Mount, [string]$Iso)
$src = Join-Path $PSScriptRoot '..\..\..\src'
# With LF-only line endings cmd gets the target of call/goto :label wrong: the 26H2 RunOnce skipped the installers and
# jumped to the cleanup and the reboot. Refuses before copying.
$lf = Get-ChildItem $src -Recurse -File -Include *.cmd, *.bat | Where-Object { [IO.File]::ReadAllText($_.FullName) -match '(?<!\r)\n' }
if ($lf) { throw "Convert these to CRLF before building the image:`n$($lf.FullName -join "`n")" }
robocopy $src $Mount /E /B /R:0 /W:0 /NFL /NDL /NP /NJH
if ($LASTEXITCODE -ge 8) { throw "robocopy exited with code $LASTEXITCODE." }
