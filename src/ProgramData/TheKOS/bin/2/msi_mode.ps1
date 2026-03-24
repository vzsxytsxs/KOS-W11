
$ErrorActionPreference = 'SilentlyContinue'

function Enable-MSI {
    param ($PNP)

    $msiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$PNP\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"

    if (-not (Test-Path $msiPath)) {
        New-Item -Path $msiPath -Force | Out-Null
    }

    New-ItemProperty -Path $msiPath `
                     -Name "MSISupported" `
                     -PropertyType DWord `
                     -Value 1 `
                     -Force | Out-Null
}

function Set-Affinity {
    param ($PNP)

    $affinityPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$PNP\Device Parameters\Interrupt Management\Affinity Policy"

    if (-not (Test-Path $affinityPath)) {
        New-Item -Path $affinityPath -Force | Out-Null
    }

    New-ItemProperty -Path $affinityPath `
                     -Name "DevicePriority" `
                     -PropertyType DWord `
                     -Value 2 `
                     -Force | Out-Null
}

function Remove-Affinity {
    param ($PNP)

    $affinityPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$PNP\Device Parameters\Interrupt Management\Affinity Policy"

    Remove-ItemProperty -Path $affinityPath `
                        -Name "DevicePriority" `
                        -Force
}

Get-CimInstance Win32_USBController |
Where-Object { $_.PNPDeviceID -like 'PCI\VEN_*' } |
ForEach-Object {
    Enable-MSI $_.PNPDeviceID
    Remove-Affinity $_.PNPDeviceID
}

Get-CimInstance Win32_VideoController |
Where-Object { $_.PNPDeviceID -like 'PCI\VEN_*' } |
ForEach-Object {
    Enable-MSI $_.PNPDeviceID
    Set-Affinity $_.PNPDeviceID
}

Get-CimInstance Win32_IDEController |
Where-Object { $_.PNPDeviceID -like 'PCI\VEN_*' } |
ForEach-Object {
    Enable-MSI $_.PNPDeviceID
    Set-Affinity $_.PNPDeviceID
}