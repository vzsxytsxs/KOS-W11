param([Parameter(Mandatory = $true)][string]$OutputPath)

$names = 'wuauserv', 'bits', 'UsoSvc', 'WaaSMedicSvc', 'dosvc'
$state = [ordered]@{
    Mode = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\TheKOS' -Name forceDisableWup -ErrorAction Stop).forceDisableWup
    Services = [ordered]@{}
}
foreach ($name in $names) {
    $state.Services[$name] = (Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$name" -Name Start -ErrorAction Stop).Start
}
$state | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
