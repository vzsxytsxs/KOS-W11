# One-shot RunOnce association setup; bin\2 is removed after RunOnce completes.
$ErrorActionPreference = 'Stop'

$logPath = Join-Path $env:LOCALAPPDATA 'TheKOS\NotepadPP-Defaults.log'
New-Item -ItemType Directory -Path (Split-Path -Parent $logPath) -Force | Out-Null
function Write-Log([string]$message) {
    Add-Content -LiteralPath $logPath -Value ('{0:u} {1}' -f (Get-Date), $message) -Encoding UTF8
}

Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class KOSNotepadPPAssoc {
    [DllImport("Shlwapi.dll", CharSet = CharSet.Unicode)]
    public static extern int AssocQueryString(int flags, int str, string assoc, string extra, StringBuilder output, ref int length);
}
'@

function Get-EffectiveProgId([string]$extension) {
    $buffer = New-Object System.Text.StringBuilder 1024
    $length = $buffer.Capacity
    $result = [KOSNotepadPPAssoc]::AssocQueryString(0, 20, $extension, $null, $buffer, [ref]$length)
    if ($result -ne 0) { throw ('AssocQueryString failed for {0}: 0x{1:X8}' -f $extension, $result) }
    return $buffer.ToString()
}

try {
    $exe = Join-Path $env:ProgramFiles 'Notepad++\notepad++.exe'
    if (-not (Test-Path -LiteralPath $exe)) { throw "Notepad++ missing: $exe" }

    # Own registration of the ProgID: the silent installer doesn't set any association.
    $progId = 'Notepad++_file'
    $key = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\$progId"
    New-Item -Path "$key\shell\open\command" -Force | Out-Null
    New-Item -Path "$key\DefaultIcon" -Force | Out-Null
    Set-Item -LiteralPath $key -Value 'Notepad++ Document'
    Set-Item -LiteralPath "$key\shell\open\command" -Value "`"$exe`" `"%1`""
    Set-Item -LiteralPath "$key\DefaultIcon" -Value "$exe,0"

    . (Join-Path $PSScriptRoot 'PhotoViewer-FTA.ps1')
    $extensions = '.txt', '.log', '.ini', '.inf', '.scp', '.wtx', '.cfg', '.conf', '.md', '.json', '.xml', '.yml', '.yaml'

    # Returns the effective ProgID after up to 3 writes. The UserChoice hash includes the current minute: a write that
    # crosses into the next minute doesn't count, so try again.
    function Set-Association([string]$extension) {
        for ($try = 1; $try -le 3; $try++) {
            try {
                $null = Set-FTA -ProgId $progId -Extension $extension
                $effective = Get-EffectiveProgId $extension
            } catch { $effective = $_.Exception.Message }
            if ($effective -eq $progId) { break }
            Start-Sleep -Seconds 2
        }
        return $effective
    }

    # An extension that doesn't take doesn't stop the others: it gets another round at the end.
    $failed = @()
    foreach ($extension in $extensions) {
        $effective = Set-Association $extension
        if ($effective -eq $progId) {
            Write-Log "$extension set to $progId"
        } else {
            Write-Log "$extension is still $effective, trying again at the end"
            $failed += $extension
        }
    }
    $left = @()
    foreach ($extension in $failed) {
        $effective = Set-Association $extension
        if ($effective -eq $progId) { Write-Log "$extension set to $progId" } else { $left += "$extension is $effective" }
    }
    if ($left) { throw "effective ProgID not $progId`: $($left -join ', ')" }
    Write-Log 'Notepad++ associations verified'
} catch {
    Write-Log "FAILED: $($_.Exception.Message)"
    Write-Error $_
    exit 1
}
