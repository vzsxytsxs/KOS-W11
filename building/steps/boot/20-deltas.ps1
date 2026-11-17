# Empties the reverse deltas (WinSxS\<component>\r) of boot.wim (128 MB in ISO 4.0.0). They are only needed to install
# updates into boot.wim itself, which Setup never does; WinPE runs the same. That is why this step runs after
# ResetBase: with the deltas gone, DISM can no longer touch the components of this image.
param([string]$Mount, [string]$Iso)
Get-ChildItem (Join-Path $Mount 'Windows\WinSxS') -Directory |
    ForEach-Object { Join-Path $_.FullName 'r' } |
    Where-Object { Test-Path -LiteralPath $_ } |
    ForEach-Object { Clear-ImageFolder $_ }
