# Removes the 32-bit programs from boot.wim (SysWOW64 and the x86/wow64 components of WinSxS, 134 MB in ISO 4.0.0).
# Setup is 64-bit and does not use them.
param([string]$Mount, [string]$Iso)
Clear-ImageFolder (Join-Path $Mount 'Windows\SysWOW64')
Get-ChildItem (Join-Path $Mount 'Windows\WinSxS') -Directory |
    Where-Object { $_.Name -match '^(x86|wow64)_' } |
    ForEach-Object { Clear-ImageFolder $_.FullName }
