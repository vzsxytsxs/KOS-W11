param([string]$OutputPath = 'C:\Users\Public\KOS-OneDrive-Test\inventory.json')
$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$admin = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$profiles = @(Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } | Select-Object SID, LocalPath, Loaded)
$roots = @("$env:ProgramFiles\Microsoft OneDrive", "${env:ProgramFiles(x86)}\Microsoft OneDrive", "$env:LOCALAPPDATA\Microsoft\OneDrive")
$files = @(
    foreach ($root in $roots) {
        if (Test-Path -LiteralPath $root) { Get-ChildItem -LiteralPath $root -Filter '*.exe' -Recurse | Select-Object FullName, Length }
    }
    foreach ($folder in 'System32','SysWOW64') {
        Get-Item -LiteralPath "$env:WINDIR\$folder\OneDriveSetup.exe" -ErrorAction SilentlyContinue | Select-Object FullName, Length
    }
)
$uninstall = @(foreach ($root in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall') {
    Get-ItemProperty -Path "$root\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*OneDrive*' } | Select-Object PSPath, DisplayName, UninstallString, QuietUninstallString
})
$errorsFound = @()
$packages = try { @(Get-AppxPackage -AllUsers | Where-Object { $_.Name -match 'OneDrive|SkyDrive' } | Select-Object Name, PackageFullName, Publisher, PackageUserInformation) } catch { $errorsFound += $_.Exception.Message; @() }
$provisioned = try { @(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match 'OneDrive|SkyDrive' } | Select-Object DisplayName, PackageName) } catch { $errorsFound += $_.Exception.Message; @() }
$tasks = try { @(Get-ScheduledTask | Where-Object { $_.TaskName -like '*OneDrive*' } | Select-Object TaskName,TaskPath,State,Actions) } catch { $errorsFound += $_.Exception.Message; @() }
$run = @(foreach ($key in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce') {
    if (Test-Path $key) { Get-ItemProperty -LiteralPath $key }
})
$shortcuts = @(foreach ($root in @("$env:APPDATA\Microsoft\Windows\Start Menu", "$env:ProgramData\Microsoft\Windows\Start Menu", "$env:SystemDrive\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu")) {
    if (Test-Path $root) { Get-ChildItem -LiteralPath $root -Filter '*OneDrive*.lnk' -Recurse | Select-Object FullName }
})
[ordered]@{
    Time = (Get-Date).ToString('o'); Identity = $identity.Name; Administrator = $admin
    Build = [Environment]::OSVersion.Version.ToString(); Profiles = $profiles; Files = $files
    Uninstall = $uninstall; Packages = $packages; Provisioned = $provisioned; Tasks = $tasks
    Processes = @(Get-Process OneDrive,OneDriveSetup -ErrorAction SilentlyContinue | Select-Object Name,Id,Path)
    Startup = $run; Shortcuts = $shortcuts; Errors = $errorsFound
} | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
