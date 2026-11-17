$GLOBAL_INTERVAL = 0x0

$INDIVIDUAL_INTERVALS = @{}

# specify the path to Rw.exe
$RWE_PATH = "C:\ProgramData\TheKOS\bin\3\rw\Rw.exe"

function GetValueFromAddress($address) {
    # convert the hex value to string for RWE
    $address = "0x$(([uint64]$address).ToString("X2"))"

    $stdout = & $RWE_PATH /Min /NoLogo /Stdout /Command="R32 $address" | Out-String
    $split_string = $stdout -split " "
    return [uint64]$split_string[-1]
}

# Rw.exe loads RwDrv.sys, which is on Microsoft's vulnerable driver blocklist. Windows refuses it while the blocklist is on (value
# absent = on) or while VBS or memory integrity (HVCI) runs: then RW isn't started. The KOS Toolbox option "USB interrupt
# moderation off" writes XhciImod = 0 to turn the tweak off. Device Guard unreadable counts as blocked.
function RwBlocked() {
    if ((Get-ItemProperty "HKLM:\SOFTWARE\TheKOS" -ErrorAction SilentlyContinue).XhciImod -eq 0) { return "turned off in the KOS Toolbox" }
    # Off only as a DWORD 0, like the toolbox reads it; Smart App Control (and S mode) force the blocklist on whatever this value says.
    $blocklist = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config" -ErrorAction SilentlyContinue).VulnerableDriverBlocklistEnable
    if (-not ($blocklist -is [int] -and $blocklist -eq 0)) { return "vulnerable driver blocklist on" }
    $sac = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
    if ($null -ne $sac -and $sac -ne 0) { return "Smart App Control on" }
    $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue
    if (-not $dg -or $null -eq $dg.VirtualizationBasedSecurityStatus) { return "Device Guard state unreadable" }
    if (@($dg.SecurityServicesRunning) -contains 2) { return "memory integrity (HVCI) running" }
    if ($dg.VirtualizationBasedSecurityStatus -eq 2) { return "VBS running" }
    return $null
}

function Is-Admin() {
    $current_principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $current_principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function main() {
    if (-not (Is-Admin)) {
        Write-Host "error: administrator privileges required"
        return 1
    }

    $blocked = RwBlocked
    if ($blocked) {
        Write-Host "skipped: $blocked"
        return 0
    }

    if (-not (Test-Path $RWE_PATH -PathType Leaf)) {
        Write-Host "error: $($RWE_PATH) not exists, edit the script to change the path to Rw.exe"
        return 1
    }

    # CLI will not work if Rw is already open
    Stop-Process -Name "Rw" -ErrorAction SilentlyContinue

    # get physical address of each device present in the system
    $device_map = @{}

    $resources = Get-WmiObject -Class Win32_PNPAllocatedResource -ComputerName LocalHost -Namespace root\CIMV2

    foreach ($resource in $resources) {
        $device_ID = $resource.Dependent.Split("=")[1].Replace('"', '').Replace("\\", "\")
        $physical_address = $resource.Antecedent.Split("=")[1].Replace('"', '')

        if (-not $device_map.ContainsKey($device_ID) -and $device_ID -and $physical_address) {
            $device_map[$device_ID] = [uint64]$physical_address
        }
    }

    foreach ($xhci_controller in Get-WmiObject Win32_USBController) {
        $is_disabled = $xhci_controller.ConfigManagerErrorCode -eq 22

        if ($is_disabled) {
            continue
        }

        $device_ID = $xhci_controller.DeviceID

        Write-Host "$($xhci_controller.Caption) - ${device_ID}"

        # skip if entry is null
        if (-not $device_map.Contains($device_ID)) {
            Write-Host "error: could not obtain base address`n"
            continue
        }

        $capability_address = $device_map[$device_ID]
        $HCSPARAMS_value = GetValueFromAddress($capability_address + 0x4)
        $HCSPARAMS_bitmask = [Convert]::ToString($HCSPARAMS_value, 2)
        $max_intrs = [Convert]::ToInt32($HCSPARAMS_bitmask.Substring($HCSPARAMS_bitmask.Length - 16, 8), 2)
        $RTSOFF_value = GetValueFromAddress($capability_address + 0x18)
        $runtime_address = $capability_address + $RTSOFF_value

        $desired_interval = $GLOBAL_INTERVAL

        foreach ($hwid in $INDIVIDUAL_INTERVALS.Keys) {
            if ($device_ID -match $hwid) {
                $desired_interval = $INDIVIDUAL_INTERVALS[$hwid]
            }
        }

        for ($i = 0; $i -lt $max_intrs; $i++) {
            # calculate address and convert address to hex string
            $interrupter_address = "0x$(([uint64]($runtime_address + 0x24 + (0x20 * $i))).ToString("X2"))"
            & $RWE_PATH /Min /NoLogo /Stdout /Command="W32 $interrupter_address $desired_interval" | Write-Host
        }

        # new line
        Write-Host
    }

    return 0
}

exit main
