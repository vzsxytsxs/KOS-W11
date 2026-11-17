# Removes the lock screen (LockApp, 12 MB): Windows goes straight to the password, also on Win+L.
# Writes the NoLockScreen policy, so Windows does not try to open the screen that no longer exists.
param([string]$Mount, [string]$Iso)
Clear-ImageFolderWithSxs $Mount (Join-Path $Mount 'Windows\SystemApps\Microsoft.LockApp_cw5n1h2txyewy') '*_microsoft-windows-l*'
Edit-ImageRegistry $Mount 'SOFTWARE' {
    param($root)
    $key = "$root\Policies\Microsoft\Windows\Personalization"
    New-Item $key -Force | Out-Null
    Set-ItemProperty $key 'NoLockScreen' 1 -Type DWord
}
