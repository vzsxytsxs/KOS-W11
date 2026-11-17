# One-time removal for the KOS Windows 11 26H2 post-setup.
# Never delete sync folders, account settings, or redirected known folders.
# Exit 0: verified; 1: incomplete removal; 2: prerequisite failure.
[CmdletBinding()]
param([string]$LogPath = '')

$ErrorActionPreference = 'Stop'
$script:Failures = 0
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error 'Run this script as an administrator.' -ErrorAction Continue
    exit 2
}
if (-not [Environment]::Is64BitProcess) {
    Write-Error 'Run this script with 64-bit Windows PowerShell.' -ErrorAction Continue
    exit 2
}
if (-not $LogPath) {
    $LogPath = Join-Path $env:ProgramData ('TheKOS\Logs\PostSetup\OneDrive-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
}
try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $LogPath) -Force | Out-Null
    Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value ('[{0:u}] START OneDrive removal' -f (Get-Date))
} catch {
    Write-Error "Cannot initialize the removal log: $($_.Exception.Message)" -ErrorAction Continue
    exit 2
}
function Write-Log([string]$Message) {
    $line = '[{0:u}] {1}' -f (Get-Date), $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    Write-Output $line
}
function Write-Failure([string]$Message) {
    $script:Failures++
    Write-Log "FAIL $Message"
}
function Invoke-Step([string]$Name, [scriptblock]$Action) {
    try { & $Action } catch { Write-Failure "${Name}: $($_.Exception.Message)" }
}
function Get-Setup([string]$InstallRoot) {
    $candidates = @()
    if (Test-Path -LiteralPath $InstallRoot) {
        $candidates += Join-Path $InstallRoot 'OneDriveSetup.exe'
        $candidates += @(Get-ChildItem -LiteralPath $InstallRoot -Directory |
            Where-Object { $_.Name -match '^\d+(\.\d+){3}$' } |
            Sort-Object { [version]$_.Name } -Descending |
            ForEach-Object { Join-Path $_.FullName 'OneDriveSetup.exe' })
    }
    $candidates += "$env:WINDIR\System32\OneDriveSetup.exe", "$env:WINDIR\SysWOW64\OneDriveSetup.exe"
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}
function Uninstall-Client([string]$InstallRoot, [switch]$AllUsers) {
    if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot 'OneDrive.exe'))) {
        Write-Log "ABSENT Client: $InstallRoot"
        return
    }
    $setup = Get-Setup $InstallRoot
    if (-not $setup) { throw "Client exists but no uninstaller is available: $InstallRoot" }
    $signature = Get-AuthenticodeSignature -LiteralPath $setup
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)') {
        throw "The uninstaller does not have a valid Microsoft signature: $setup"
    }
    $arguments = '/uninstall'
    if ($AllUsers) { $arguments += ' /allusers' }
    Write-Log "UNINSTALL $setup $arguments"
    $process = Start-Process -FilePath $setup -ArgumentList $arguments -PassThru
    if (-not $process.WaitForExit(120000)) {
        $process.Kill()
        throw 'The uninstaller exceeded the 120-second timeout.'
    }
    $process.WaitForExit()
    Write-Log "Uninstaller exit code: $($process.ExitCode)"
    if ($process.ExitCode -notin 0, 3010) { throw "Uninstaller failed with exit code $($process.ExitCode)." }
    # Some setup versions finish cleanup in a child process.
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot 'OneDrive.exe'))) { return }
        Start-Sleep -Milliseconds 500
    }
    throw "The client executable remains after uninstall: $InstallRoot"
}
function Remove-StartupValues([Microsoft.Win32.RegistryKey]$Hive, [string]$RelativePath) {
    $key = $Hive.OpenSubKey($RelativePath, $true)
    if (-not $key) { return }
    try {
        foreach ($name in $key.GetValueNames()) {
            if ($name -in 'OneDrive', 'OneDriveSetup') {
                $key.DeleteValue($name, $false)
                if ($null -ne $key.GetValue($name)) { throw "Startup value remains: $RelativePath\$name" }
                Write-Log "REMOVED Startup: $($Hive.Name)\$RelativePath\$name"
            }
        }
    } finally { $key.Dispose() }
}
function Remove-RegistryBranch([Microsoft.Win32.RegistryKey]$Hive, [string]$RelativePath) {
    $key = $Hive.OpenSubKey($RelativePath)
    if (-not $key) { return }
    $key.Dispose()
    $Hive.DeleteSubKeyTree($RelativePath, $false)
    Write-Log "REMOVED Registry: $($Hive.Name)\$RelativePath"
}
function Clear-Integrations([Microsoft.Win32.RegistryKey]$Hive) {
    foreach ($view in 'Software', 'Software\WOW6432Node') {
        foreach ($entry in 'Run', 'RunOnce') {
            Remove-StartupValues $Hive "$view\Microsoft\Windows\CurrentVersion\$entry"
        }
        $guid = '{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
        Remove-RegistryBranch $Hive "$view\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$guid"
    }
    foreach ($view in 'Software\Classes\CLSID', 'Software\Classes\WOW6432Node\CLSID') {
        $key = $Hive.OpenSubKey("$view\{018D5C66-4533-4307-9B53-224DE2ED1FE6}", $true)
        if ($key) {
            try { $key.SetValue('System.IsPinnedToNameSpaceTree', 0, [Microsoft.Win32.RegistryValueKind]::DWord) }
            finally { $key.Dispose() }
            Write-Log "UNPINNED Explorer integration: $($Hive.Name)\$view"
        }
    }
}
function Clear-Profile([string]$ProfilePath, [string]$Sid, [switch]$DefaultProfile) {
    $hiveFile = Join-Path $ProfilePath 'NTUSER.DAT'
    if (-not (Test-Path -LiteralPath $hiveFile)) { throw "Profile hive missing: $hiveFile" }
    $mount = $Sid
    $loadedByScript = $false
    $hive = if ($Sid) { [Microsoft.Win32.Registry]::Users.OpenSubKey($Sid, $true) } else { $null }
    if (-not $hive) {
        $mount = 'KOS_OneDrive_' + [guid]::NewGuid().ToString('N')
        $output = & "$env:WINDIR\System32\reg.exe" load "HKU\$mount" $hiveFile 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Cannot load profile hive: $ProfilePath ($output)" }
        $loadedByScript = $true
    }
    try {
        if (-not $hive) { $hive = [Microsoft.Win32.Registry]::Users.OpenSubKey($mount, $true) }
        if (-not $hive) { throw "Cannot open loaded profile hive: $ProfilePath" }
        Clear-Integrations $hive
        Write-Log "VERIFIED Profile integrations: $ProfilePath"
    } finally {
        if ($hive) { $hive.Dispose() }
        if ($loadedByScript) {
            $output = & "$env:WINDIR\System32\reg.exe" unload "HKU\$mount" 2>&1
            if ($LASTEXITCODE -ne 0) { Write-Failure "Cannot unload temporary hive HKU\$mount ($output)" }
        }
    }
    foreach ($relative in @(
        'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk',
        'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\OneDrive.lnk',
        'Desktop\OneDrive.lnk'
    )) {
        Remove-OneDriveShortcut (Join-Path $ProfilePath $relative)
    }
    if (-not $DefaultProfile -and $Sid -ne $identity.User.Value) {
        $client = Join-Path $ProfilePath 'AppData\Local\Microsoft\OneDrive\OneDrive.exe'
        if (Test-Path -LiteralPath $client) {
            Write-Failure "Another user's client remains: $client. Run removal from that account with elevation."
        }
    }
}
function Remove-OneDriveShortcut([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $shortcut = $script:Shell.CreateShortcut($Path)
    try { $target = $shortcut.TargetPath } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) }
    # A user-created shortcut with the same name may point to personal files.
    if ([IO.Path]::GetFileName($target) -notin 'OneDrive.exe', 'OneDriveSetup.exe') {
        Write-Log "PRESERVED Non-application shortcut: $Path"
        return
    }
    Remove-Item -LiteralPath $Path -Force
    Write-Log "REMOVED Shortcut: $Path"
}

try {
    $machineRoots = @("$env:ProgramFiles\Microsoft OneDrive", "${env:ProgramFiles(x86)}\Microsoft OneDrive") | Select-Object -Unique
    $userRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive'
    # Enumerate real profiles from the registry; never guess C:\Users\<name>.
    $profiles = @(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' |
        Where-Object { $_.PSChildName -match '^S-1-(5-21|12-1)-' -and $_.PSChildName -notlike '*.bak' } |
        ForEach-Object {
            $path = [Environment]::ExpandEnvironmentVariables($_.GetValue('ProfileImagePath'))
            [pscustomobject]@{ Sid = $_.PSChildName; Path = $path }
        })
    $defaultPath = [Environment]::ExpandEnvironmentVariables((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').Default)
    Write-Log "Account: $($identity.Name); profiles: $($profiles.Count)"
    Invoke-Step 'Stop sync client' {
        Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force
    }
    foreach ($root in $machineRoots) {
        Invoke-Step "Machine uninstall ($root)" { Uninstall-Client $root -AllUsers }
    }
    Invoke-Step 'Current-user uninstall' { Uninstall-Client $userRoot }

    # Only known Microsoft package identities; do not match arbitrary *Drive* apps.
    $packageNames = @('Microsoft.OneDriveSync', 'microsoft.microsoftskydrive')
    Invoke-Step 'Remove provisioned packages' {
        foreach ($package in @(Get-AppxProvisionedPackage -Online | Where-Object {
            $_.DisplayName -in $packageNames -and $_.PackageName -like '*_8wekyb3d8bbwe'
        })) {
            Remove-AppxProvisionedPackage -Online -AllUsers -PackageName $package.PackageName | Out-Null
            Write-Log "REMOVED Provisioned package: $($package.PackageName)"
        }
    }
    Invoke-Step 'Remove registered packages' {
        foreach ($package in @(Get-AppxPackage -AllUsers | Where-Object {
            $_.Name -in $packageNames -and $_.PublisherId -eq '8wekyb3d8bbwe'
        })) {
            Remove-AppxPackage -AllUsers -Package $package.PackageFullName
            Write-Log "REMOVED Registered package: $($package.PackageFullName)"
        }
    }
    Invoke-Step 'Remove OneDrive tasks' {
        foreach ($task in @(Get-ScheduledTask | Where-Object { $_.TaskName -like 'OneDrive*' })) {
            $actions = @($task.Actions)
            if ($actions.Count -gt 0 -and @($actions | Where-Object {
                [IO.Path]::GetFileName(([string]$_.Execute).Trim('"')) -notin 'OneDrive.exe', 'OneDriveSetup.exe', 'OneDriveStandaloneUpdater.exe'
            }).Count -eq 0) {
                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false
                Write-Log "REMOVED Task: $($task.TaskPath)$($task.TaskName)"
            } else {
                Write-Failure "Unrecognized OneDrive task was preserved: $($task.TaskPath)$($task.TaskName)"
            }
        }
    }
    Invoke-Step 'Machine integrations' { Clear-Integrations ([Microsoft.Win32.Registry]::LocalMachine) }
    Invoke-Step 'OneDrive Active Setup' {
        foreach ($view in 'SOFTWARE', 'SOFTWARE\WOW6432Node') {
            $parent = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$view\Microsoft\Active Setup\Installed Components", $true)
            if (-not $parent) { continue }
            try {
                foreach ($name in $parent.GetSubKeyNames()) {
                    $key = $parent.OpenSubKey($name)
                    try { $stub = [string]$key.GetValue('StubPath') } finally { $key.Dispose() }
                    if ($stub -match '(?i)(?:^|[\\"])OneDriveSetup\.exe(?:"|\s|$)') {
                        $parent.DeleteSubKeyTree($name)
                        Write-Log "REMOVED OneDrive Active Setup: $name"
                    }
                }
            } finally { $parent.Dispose() }
        }
    }
    $script:Shell = New-Object -ComObject WScript.Shell
    try {
        foreach ($profile in $profiles) {
            Invoke-Step "Profile ($($profile.Path))" { Clear-Profile $profile.Path $profile.Sid }
        }
        Invoke-Step 'Default profile' { Clear-Profile $defaultPath '' -DefaultProfile }
        foreach ($shortcut in @(
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk",
            "$env:PUBLIC\Desktop\OneDrive.lnk"
        )) { Invoke-Step 'Common shortcut' { Remove-OneDriveShortcut $shortcut } }
    } finally { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($script:Shell) }

    # The NTLite preset owns DisableFileSyncNGSC; prepareiso.cmd removes the inbox setup.
    # Preserve all data folders, junctions, account settings and User Shell Folders.
    Invoke-Step 'Final verification' {
        foreach ($root in @($machineRoots) + @($userRoot)) {
            if (Test-Path -LiteralPath (Join-Path $root 'OneDrive.exe')) { Write-Failure "Client remains: $root" }
        }
        if (@(Get-Process OneDrive -ErrorAction SilentlyContinue).Count) { Write-Failure 'The sync client is still running.' }
        if (@(Get-AppxPackage -AllUsers | Where-Object { $_.Name -in $packageNames -and $_.PublisherId -eq '8wekyb3d8bbwe' }).Count) {
            Write-Failure 'A registered OneDrive package remains.'
        }
        if (@(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -in $packageNames -and $_.PackageName -like '*_8wekyb3d8bbwe' }).Count) {
            Write-Failure 'A provisioned OneDrive package remains.'
        }
    }
} catch { Write-Failure $_.Exception.Message }
if ($script:Failures) {
    Write-Log "INCOMPLETE Removal finished with $script:Failures failure(s)."
    exit 1
}
Write-Log 'VERIFIED Client and packages absent; profile startup entries and application shortcuts cleaned. Sync data preserved.'
exit 0
