param([string]$OutputPath)

# Read-only probe for the effective image-file association.
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class KOSAssocQuery {
    [DllImport("Shlwapi.dll", CharSet = CharSet.Unicode)]
    public static extern int AssocQueryString(int flags, int str, string assoc, string extra, StringBuilder output, ref int length);
}
'@

$lines = foreach ($ext in '.jpg', '.png', '.gif', '.bmp', '.tif') {
    $buffer = New-Object System.Text.StringBuilder 1024
    $length = $buffer.Capacity
    $result = [KOSAssocQuery]::AssocQueryString(0, 20, $ext, $null, $buffer, [ref]$length)
    $choice = Get-ItemProperty -LiteralPath "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\UserChoice" -ErrorAction SilentlyContinue
    $userClass = Get-Item -LiteralPath "Registry::HKEY_CURRENT_USER\Software\Classes\$ext" -ErrorAction SilentlyContinue
    $classDefault = if ($userClass) { $userClass.GetValue('') } else { $null }
    '{0}: effective={1}; query=0x{2:X8}; userChoice={3}; userClass={4}' -f $ext, $buffer.ToString(), $result, $choice.ProgId, $classDefault
}

$lines
if ($OutputPath) { $lines | Set-Content -LiteralPath $OutputPath -Encoding UTF8 }

