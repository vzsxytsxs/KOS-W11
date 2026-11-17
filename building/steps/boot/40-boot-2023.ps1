# Replaces the ISO boot with the one signed by the new Secure Boot certificate (Windows UEFI CA 2023), as Microsoft's
# Make2023BootableMedia.ps1 does (KB5053484). The official ISO still boots through the 2011 certificate, which expires in
# October 2026 and is being revoked. PCs without the 2023 certificate in the firmware cannot boot this ISO with Secure Boot
# on: to keep the 2011 boot, change this file's extension to .off.
param([string]$Mount, [string]$Iso)
$boot = Join-Path $Mount 'Windows\Boot'
foreach ($dir in 'EFI_EX', 'FONTS_EX', 'DVD_EX') {
    if (-not (Test-Path (Join-Path $boot $dir))) { throw "boot.wim has no Windows\Boot\${dir}: the base ISO needs the April 2024 updates or newer." }
}
$efi = Join-Path $Iso 'efi\microsoft\boot'
Copy-Item (Join-Path $boot 'EFI_EX\bootmgfw_EX.efi') (Join-Path $Iso 'efi\boot\bootx64.efi') -Force
if (Test-Path (Join-Path $boot 'EFI_EX\bootmgr_EX.efi')) { Copy-Item (Join-Path $boot 'EFI_EX\bootmgr_EX.efi') (Join-Path $Iso 'bootmgr.efi') -Force }
Copy-Item (Join-Path $boot 'DVD_EX\EFI\en-US\efisys_EX.bin') (Join-Path $efi 'efisys_ex.bin') -Force
foreach ($font in Get-ChildItem (Join-Path $boot 'FONTS_EX') -File) { Copy-Item $font.FullName (Join-Path $efi ('fonts\' + ($font.Name -replace '_EX'))) -Force }
if (Test-Path (Join-Path $boot 'EFI\boot.stl')) { Copy-Item (Join-Path $boot 'EFI\boot.stl') (Join-Path $efi 'boot.stl') -Force }
Write-Host 'ISO boot: Windows UEFI CA 2023.'
