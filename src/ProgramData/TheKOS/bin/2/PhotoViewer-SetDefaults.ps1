# One-shot RunOnce association setup; bin\2 is removed after RunOnce completes.
$ErrorActionPreference = 'Stop'

$logPath = Join-Path $env:LOCALAPPDATA 'TheKOS\PhotoViewer-Defaults.log'
New-Item -ItemType Directory -Path (Split-Path -Parent $logPath) -Force | Out-Null
function Write-Log([string]$message) {
    Add-Content -LiteralPath $logPath -Value ('{0:u} {1}' -f (Get-Date), $message) -Encoding UTF8
}

Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class KOSPhotoViewerAssoc {
    [DllImport("Shlwapi.dll", CharSet = CharSet.Unicode)]
    public static extern int AssocQueryString(int flags, int str, string assoc, string extra, StringBuilder output, ref int length);
}
'@

function Get-EffectiveProgId([string]$extension) {
    $buffer = New-Object System.Text.StringBuilder 1024
    $length = $buffer.Capacity
    $result = [KOSPhotoViewerAssoc]::AssocQueryString(0, 20, $extension, $null, $buffer, [ref]$length)
    if ($result -ne 0) { throw ('AssocQueryString failed for {0}: 0x{1:X8}' -f $extension, $result) }
    return $buffer.ToString()
}

try {
    $viewer = Join-Path $env:ProgramFiles 'Windows Photo Viewer\PhotoViewer.dll'
    if (-not (Test-Path -LiteralPath $viewer)) { throw "PhotoViewer.dll missing: $viewer" }
    if (-not (Test-Path -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff\shell\open\command')) {
        throw 'PhotoViewer.FileAssoc.Tiff open command is missing'
    }

    . (Join-Path $PSScriptRoot 'PhotoViewer-FTA.ps1')
    $progId = 'PhotoViewer.FileAssoc.Tiff'
    $extensions = '.bmp', '.dib', '.gif', '.jfif', '.jpe', '.jpeg', '.jpg', '.jxr', '.png', '.tif', '.tiff'

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
        if ((Get-EffectiveProgId $extension) -eq $progId) {
            Write-Log "$extension already $progId"
            continue
        }
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
    Write-Log 'Photo Viewer associations verified'
} catch {
    Write-Log "FAILED: $($_.Exception.Message)"
    Write-Error $_
    exit 1
}
