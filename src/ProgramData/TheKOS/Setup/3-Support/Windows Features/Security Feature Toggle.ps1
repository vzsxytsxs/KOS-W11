param(
    [Parameter(Mandatory)][ValidateSet('process', 'dma', 'firewall')][string]$Feature,
    [Parameter(Mandatory)][ValidateSet('on', 'off')][string]$Mode
)

$ErrorActionPreference = 'Stop'
$admin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 1 }

try {
    switch ($Feature) {
        'process' {
            # Advanced writes the same mask for each process; Basic removes only these two values.
            $root = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
            $names = 'fontdrvhost.exe', 'dwm.exe', 'lsass.exe', 'svchost.exe', 'WmiPrvSE.exe',
                'winlogon.exe', 'csrss.exe', 'audiodg.exe', 'ntoskrnl.exe', 'services.exe'
            $kernel = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\kernel')
            $source = $kernel.GetValue('MitigationAuditOptions')
            $length = if ($source -is [byte[]] -and $source.Length -gt 0) { $source.Length } else { 24 }
            $mask = [byte[]]::new($length)
            for ($i = 0; $i -lt $mask.Length; $i++) { $mask[$i] = 0x22 }
            foreach ($name in $names) {
                if ($Mode -eq 'on') {
                    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$root\$name", $true)
                    if ($null -eq $key) { continue }
                    $key.DeleteValue('MitigationOptions', $false)
                    $key.DeleteValue('MitigationAuditOptions', $false)
                } else {
                    $key = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("$root\$name", $true)
                    $key.SetValue('MitigationOptions', $mask, [Microsoft.Win32.RegistryValueKind]::Binary)
                    $key.SetValue('MitigationAuditOptions', $mask, [Microsoft.Win32.RegistryValueKind]::Binary)
                }
                $key.Close()
            }
        }
        'dma' {
            # Stores the original value by its full path, including when the service name has spaces.
            $backupPath = 'SOFTWARE\TheKOS\ProfileBackup\DmaRemapping'
            $backup = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($backupPath, $true)
            if ($Mode -eq 'on') {
                foreach ($name in @($backup.GetValueNames())) {
                    $relative = $name -replace '^(HKLM|HKEY_LOCAL_MACHINE)\\', ''
                    $service = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($relative, $true)
                    # Driver removed after Advanced: nothing to restore.
                    if ($null -eq $service) { $backup.DeleteValue($name, $false); continue }
                    $service.SetValue('DmaRemappingCompatible', [int]$backup.GetValue($name), [Microsoft.Win32.RegistryValueKind]::DWord)
                    $service.Close()
                    $backup.DeleteValue($name, $false)
                }
            } else {
                function Set-DmaOff([Microsoft.Win32.RegistryKey]$key, [string]$path) {
                    if ($key.GetValueNames() -contains 'DmaRemappingCompatible') {
                        $name = "HKLM\$path"
                        if ($null -eq $backup.GetValue($name)) {
                            $backup.SetValue($name, [int]$key.GetValue('DmaRemappingCompatible'), [Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                        $key.SetValue('DmaRemappingCompatible', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                    foreach ($sub in $key.GetSubKeyNames()) {
                        try {
                            $child = $key.OpenSubKey($sub, $true)
                            if ($null -ne $child) { Set-DmaOff $child "$path\$sub"; $child.Close() }
                        } catch [System.Security.SecurityException] { continue }
                          catch [System.UnauthorizedAccessException] { continue }
                    }
                }
                $path = 'SYSTEM\CurrentControlSet\Services'
                $services = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($path, $true)
                Set-DmaOff $services $path
                $services.Close()
            }
            $backup.Close()
        }
        'firewall' {
            $root = 'HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy'
            if ($Mode -eq 'on') {
                & netsh.exe advfirewall reset | Out-Null
                if ($LASTEXITCODE -ne 0) { throw 'netsh advfirewall reset failed' }
                foreach ($profile in 'StandardProfile', 'DomainProfile', 'PublicProfile') {
                    & reg.exe add "$root\$profile" /v DisableNotifications /t REG_DWORD /d 1 /f | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "Firewall profile update failed: $profile" }
                }
            } else {
                # No 2>$null: in PowerShell 5.1 with ErrorActionPreference Stop, redirected stderr becomes an exception.
                if (Test-Path -LiteralPath "Registry::$root\FirewallRules") { & reg.exe delete "$root\FirewallRules" /f | Out-Null }
                if (Test-Path -LiteralPath "Registry::$root\FirewallRules") { throw 'Could not delete firewall rules' }
                & reg.exe add "$root\FirewallRules" /f | Out-Null
                if ($LASTEXITCODE -ne 0) { throw 'Could not clear firewall rules' }
            }
        }
    }
    exit 0
} catch {
    Write-Error $_
    exit 1
}
