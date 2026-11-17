# Empties catroot2 (26 MB in ISO 4.0.0): it is the CryptSvc catalog database, which it recreates by itself.
param([string]$Mount, [string]$Iso)
Clear-ImageFolder (Join-Path $Mount 'Windows\System32\catroot2')
