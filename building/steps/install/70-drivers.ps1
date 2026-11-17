# Removes the modem, IrDA and smart card drivers that ship with Windows (about 17 MB in ISO 4.0.0): DriverStore,
# Windows\INF and WinSxS. The Bluetooth modem one (mdmbtmdm) stays, because it is part of Bluetooth; the Wi-Fi ones stay.
param([string]$Mount, [string]$Iso)
$pattern = '^(mdm(?!btmdm)\w*|modemcsa|netirda|c_infrared|c_smartcard|c_smartcardfilter|c_smartcardreader|usbcciddriver|wudfusbcciddriver)\.inf'
$repo = Join-Path $Mount 'Windows\System32\DriverStore\FileRepository'
# The emptied folders stay (owner TrustedInstaller); only the ones that still have files count
$packages = @(Get-ChildItem $repo -Directory | Where-Object { $_.Name -match "${pattern}_" -and $_.GetFileSystemInfos().Count })
$infs = @($packages | ForEach-Object { ($_.Name -split '\.inf_')[0] + '.inf' } | Sort-Object -Unique)
Write-Host "$($packages.Count) packages: $($infs -join ', ')"
foreach ($p in $packages) { Clear-ImageFolder $p.FullName }
Remove-ImageFiles (Join-Path $Mount 'Windows\INF') (@($infs) + @($infs -replace '\.inf$', '.pnf'))
Get-ChildItem (Join-Path $Mount 'Windows\WinSxS') -Directory -Filter '*_dual_*' |
    Where-Object { ($_.Name -replace '^[a-z0-9]+_dual_') -match "${pattern}_" } |
    ForEach-Object { Clear-ImageFolder $_.FullName }
