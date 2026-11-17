# Removes WinRE (recovery environment, 605 MB): no automatic startup repair and no "Restart in recovery mode".
# winre.wim and ReAgent.xml leave System32\Recovery; without them Setup does not configure recovery.
param([string]$Mount, [string]$Iso)
Clear-ImageFolder (Join-Path $Mount 'Windows\System32\Recovery')
