# Regenerates src\ProgramData\TheKOS\bin\2\kos-expected.json (what a KOS install leaves on the system) from the files that
# apply it, before 10-copy-src puts it in the image. The KOS Toolbox embeds a copy (toolbox\src\KosToolbox.Core\KosState\kos-expected.json): copy it there when this one changes.
param([string]$Mount, [string]$Iso)
& (Join-Path $PSScriptRoot '..\..\Generate-KosExpected.ps1')
