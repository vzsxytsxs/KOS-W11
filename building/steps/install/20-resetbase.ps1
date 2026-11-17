# Deletes the superseded versions of the components (2.7 GB in ISO 4.0.0). The updates already integrated can no
# longer be uninstalled; Windows Update, sfc and DISM keep working.
param([string]$Mount, [string]$Iso)
if ($BuildExtras -contains 'winsxs') { Write-Host 'Skipped: the winsxs extra deletes the whole WinSxS.'; return }
# With a pending operation DISM refuses ResetBase (0x800f0806). The cause is usually .NET 3.5 enabled by NTLite,
# which stays pending until the first boot; without NetFX3 in the preset, the next step enables it after ResetBase.
if (Test-Path (Join-Path $Mount 'Windows\WinSxS\pending.xml')) {
    Write-Host 'Skipped: the image has pending operations (WinSxS\pending.xml), usually .NET 3.5 enabled by NTLite.' -ForegroundColor Yellow
    return
}
Dism /Image:$Mount /Cleanup-Image /StartComponentCleanup /ResetBase
