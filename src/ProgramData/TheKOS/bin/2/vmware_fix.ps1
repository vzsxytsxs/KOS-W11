try {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop

    if ($cs.Manufacturer -match 'VMware') {

        $adapters = Get-CimInstance Win32_NetworkAdapter -ErrorAction Stop |
                    Where-Object { $_.PNPDeviceID -like 'PCI\VEN_*' }

        foreach ($adapter in $adapters) {

            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($adapter.PNPDeviceID)\Device Parameters\Interrupt Management\Affinity Policy"

            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
            }

            New-ItemProperty -Path $regPath `
                             -Name "DevicePriority" `
                             -PropertyType DWord `
                             -Value 2 `
                             -Force `
                             -ErrorAction SilentlyContinue | Out-Null
        }
    }

} catch {
    # idk
}