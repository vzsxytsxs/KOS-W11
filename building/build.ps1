# Builds the KOS ISO from the ISO folder already processed by NTLite (C:\base). Does what used to be manual:
# mounts install.wim, runs the steps in steps\install, slims boot.wim with the steps in steps\boot,
# unmounts and creates the ISO with install.wim (to test and mount again) or install.esd (release).
#
# Steps: each .ps1/.cmd in steps\install and steps\boot runs in name order, receiving the mounted folder and the
# ISO folder (arguments 1 and 2). The .ps1 files run inside this script, can use Dism, Clear-ImageFolder,
# Remove-ImageFiles, Edit-ImageRegistry and $BuildExtras, and report errors with an exception; the .cmd files report
# errors with a non-zero exit code. To turn a step off, change its extension to .off.
# Extras: the .ps1 files in steps\extras only run when chosen in the build (T or R). The first line of each one is the
# menu text; the key is the name without the number (10-winre.ps1 = winre). The build records the chosen ones in
# HKLM\SOFTWARE\TheKOS\BuildExtras of the image, which tests\verify-iso.ps1 reads.
#
# Usage (administrator): build.cmd                                menu
#                        build.cmd -Run "R" -Extras "winre,esd"   no menu (same keys; without -Extras, the default for T or R)
param(
    [string]$IsoDir = 'C:\base',
    [string]$MountDir = (Join-Path $env:TEMP 'MOUNT_DIR'),
    [string]$OutIso = 'C:\Final.iso',
    [string]$Label = 'Final',
    [string]$Run = '',
    [string]$Extras
)

$ErrorActionPreference = 'Stop'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'DISM needs administrator: open it through build.cmd.' -ForegroundColor Red
    exit 1
}

$IsoDir = [IO.Path]::GetFullPath($IsoDir)
$MountDir = [IO.Path]::GetFullPath($MountDir)
$BootMount = "$MountDir-boot"
$Wim = Join-Path $IsoDir 'sources\install.wim'
$Esd = Join-Path $IsoDir 'sources\install.esd'
$BootWim = Join-Path $IsoDir 'sources\boot.wim'
$Steps = Join-Path $PSScriptRoot 'steps'
$Oscdimg = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe'
$ExtrasGiven = $PSBoundParameters.ContainsKey('Extras')
$BuildExtras = @()

# This process and the ones above it (the prompt that opened the build) mention the mount when it comes via -MountDir: do not wait for them
$Ancestors = @{}
$p = $PID
while ($p -and -not $Ancestors.ContainsKey([int]$p)) { $Ancestors[[int]$p] = $true; $p = (Get-CimInstance Win32_Process -Filter "ProcessId=$p").ParentProcessId }

function Dism {
    & dism.exe @args
    if ($LASTEXITCODE -notin 0, 3010) { throw "DISM exited with code $LASTEXITCODE." }
}

function Get-Mount([string]$Dir) { Get-WindowsImage -Mounted | Where-Object { $_.Path.TrimEnd('\') -eq $Dir } }

function Assert-Mounted { if ((Get-Mount $MountDir).MountStatus -ne 'Ok') { throw 'Mount install.wim first (1).' } }

# Deletes inside a mounted-image folder (owner: TrustedInstaller) with robocopy in backup mode, without changing owner or ACL
function Invoke-Purge([string]$Path, [string[]]$Options) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $empty = Join-Path $env:TEMP ('kos-build-' + [guid]::NewGuid())
    New-Item -ItemType Directory $empty | Out-Null
    try { robocopy $empty $Path @Options /B /XJ /NODCOPY /R:0 /W:0 /NFL /NDL /NJH /NJS /NP | Out-Null }
    finally { Remove-Item $empty -Force }
    if ($LASTEXITCODE -ge 8) { throw "robocopy could not delete in $Path (code $LASTEXITCODE)." }
}

# Empties the folder; the folder itself stays, empty. With -Keep, those subfolders (accepts * and ?) and the loose files in the root stay.
function Clear-ImageFolder([string]$Path, [string[]]$Keep) {
    $options = @('/MIR')
    if ($Keep) { $options += @('/XF', '*', '/XD') + $Keep }
    Invoke-Purge $Path $options
}

# Deletes these files from an image folder, only at its own level
function Remove-ImageFiles([string]$Dir, [string[]]$Names) { if ($Names) { Invoke-Purge $Dir (@($Names) + '/PURGE') } }

# Empties image folders and deletes their copies (hardlinks: same name and size) in the WinSxS folders that match
# $SxsFilter; while WinSxS exists, without this the ISO does not shrink.
function Clear-ImageFolderWithSxs([string]$Mount, [string[]]$Paths, [string]$SxsFilter) {
    $Paths = @($Paths | Where-Object { Test-Path -LiteralPath $_ })
    $copies = @{}
    foreach ($f in $Paths | ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Force }) { $copies["$($f.Name)|$($f.Length)"] = $true }
    foreach ($p in $Paths) { Clear-ImageFolder $p }
    if (-not $copies.Count) { return }
    foreach ($dir in Get-ChildItem (Join-Path $Mount 'Windows\WinSxS') -Directory -Filter $SxsFilter) {
        $names = @(Get-ChildItem -LiteralPath $dir.FullName -File -Force | Where-Object { $copies["$($_.Name)|$($_.Length)"] } | ForEach-Object Name)
        if ($names) { Remove-ImageFiles $dir.FullName $names }
    }
}

# Loads a hive of the mounted image (SOFTWARE, SYSTEM...) into HKLM\KOS_<hive>, runs $Edit with the path
# (HKLM:\KOS_<hive>) and unloads it; the commit fails if an image hive is left loaded.
function Edit-ImageRegistry([string]$Mount, [string]$Hive, [scriptblock]$Edit) {
    $key = "HKLM\KOS_$Hive"
    & reg.exe load $key (Join-Path $Mount "Windows\System32\config\$Hive") | Out-Null
    if ($LASTEXITCODE) { throw "reg load of the image's $Hive hive failed." }
    try { & $Edit "HKLM:\KOS_$Hive" }
    finally {
        [GC]::Collect(); [GC]::WaitForPendingFinalizers()
        for ($i = 0; $i -lt 5; $i++) { & reg.exe unload $key | Out-Null; if (-not $LASTEXITCODE) { break }; Start-Sleep -Seconds 1 }
        if ($LASTEXITCODE) { throw "Could not unload ${key}: close regedit and run 'reg unload $key' before unmounting." }
    }
}

# PowerRun (used by prepareiso) returns before the command finishes: waits for the processes that still mention the mount
function Wait-MountFree([string]$Dir) {
    $limit = (Get-Date).AddMinutes(10)
    while ($busy = @(Get-CimInstance Win32_Process | Where-Object { -not $Ancestors.ContainsKey([int]$_.ProcessId) -and $_.CommandLine -and $_.CommandLine.IndexOf($Dir, [StringComparison]::OrdinalIgnoreCase) -ge 0 })) {
        if ((Get-Date) -gt $limit) { throw "Processes are still using $Dir after 10 minutes:$(($busy.Name | Sort-Object -Unique) -join ', ')." }
        Start-Sleep -Milliseconds 500
    }
}

# Clean mount folder: discards the mount of a build that crashed and deletes the leftovers, as the old command did
function Reset-MountDir([string]$Dir) {
    if (Get-Mount $Dir) { Dism /Unmount-Wim /MountDir:$Dir /Discard }
    if (Test-Path $Dir) {
        & dism.exe /Cleanup-Mountpoints | Out-Null
        Remove-Item $Dir -Recurse -Force
    }
    New-Item -ItemType Directory $Dir | Out-Null
}

function Mount-Install {
    $m = Get-Mount $MountDir
    if ($m -and $m.ImagePath -ne $Wim) { throw "Another image is mounted at $MountDir ($($m.ImagePath)). Unmount it first (4 or 5)." }
    if ($m.MountStatus -eq 'Ok') { Write-Host "install.wim is already mounted at $MountDir."; return }
    if ($m.MountStatus -eq 'NeedsRemount') { Dism /Remount-Wim /MountDir:$MountDir; return }
    if (-not (Test-Path $Wim)) {
        if (Test-Path $Esd) { throw 'Only install.esd exists, and DISM cannot mount it for editing. Option 7 goes back to install.wim.' }
        throw "Could not find $Wim."
    }
    Reset-MountDir $MountDir
    # KOS is Pro only: the other editions are removed before mounting. /Delete-Image is fast; the export at the end recompresses.
    $images = @(Get-WindowsImage -ImagePath $Wim | ForEach-Object { Get-WindowsImage -ImagePath $Wim -Index $_.ImageIndex })
    if (-not ($images | Where-Object EditionId -eq 'Professional')) { throw 'install.wim has no Pro (Professional) edition.' }
    foreach ($img in $images | Where-Object EditionId -ne 'Professional' | Sort-Object ImageIndex -Descending) {
        Write-Host "Removing edition $($img.ImageName) (index $($img.ImageIndex))..."
        Dism /Delete-Image /ImageFile:$Wim /Index:$($img.ImageIndex)
    }
    Dism /Get-WimInfo /WimFile:$Wim
    Dism /Mount-Wim /WimFile:$Wim /Index:1 /MountDir:$MountDir
}

function Dismount-Install([switch]$Discard) {
    $m = Get-Mount $MountDir
    if (-not $m) { Write-Host 'install.wim is not mounted.'; return }
    if ($m.MountStatus -eq 'NeedsRemount' -and -not $Discard) { Dism /Remount-Wim /MountDir:$MountDir }
    Wait-MountFree $MountDir
    $mode = if ($Discard) { '/Discard' } else { '/Commit' }
    try { Dism /Unmount-Wim /MountDir:$MountDir $mode }
    catch { Write-Host 'If the error is about a folder in use, close Explorer and any prompts open on the mount and try again.' -ForegroundColor Yellow; throw }
    Remove-Item $MountDir -Recurse -Force -ErrorAction SilentlyContinue
}

function Get-Steps([string]$Kind) { @(Get-ChildItem (Join-Path $Steps $Kind) -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.ps1', '.cmd' } | Sort-Object Name) }

function Invoke-Step([IO.FileInfo]$Step, [string]$Mount) {
    Write-Host "`n--- $($Step.Name)" -ForegroundColor Cyan
    if ($Step.Extension -eq '.ps1') { & $Step.FullName $Mount $IsoDir }
    else {
        $proc = Start-Process cmd.exe -ArgumentList "/c `"`"$($Step.FullName)`" `"$Mount`" `"$IsoDir`"`"" -NoNewWindow -Wait -PassThru
        if ($proc.ExitCode) { throw "$($Step.Name) exited with code $($proc.ExitCode)." }
    }
    Wait-MountFree $Mount
}

# Rewrites the image into a new file with only what the indexes use: /Commit leaves the old versions inside the .wim
function Export-ImageFile([string]$From, [string]$To, [string]$Compress, [switch]$BootableLast) {
    $tmp = [IO.Path]::ChangeExtension($To, '.tmp' + [IO.Path]::GetExtension($To))
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
    $images = @(Get-WindowsImage -ImagePath $From)
    foreach ($img in $images) {
        $a = @('/Export-Image', "/SourceImageFile:$From", "/SourceIndex:$($img.ImageIndex)", "/DestinationImageFile:$tmp", '/CheckIntegrity')
        if ($img.ImageIndex -eq $images[0].ImageIndex) { $a += "/Compress:$Compress" }
        if ($BootableLast -and $img.ImageIndex -eq $images[-1].ImageIndex) { $a += '/Bootable' }
        Dism @a
    }
    Remove-Item $From -Force
    Move-Item $tmp $To -Force
    Write-Host ('{0}: {1:N2} GB' -f (Split-Path $To -Leaf), ((Get-Item $To).Length / 1GB)) -ForegroundColor Green
}

function Convert-Install([string]$Format) {
    if ((Test-Path $Wim) -and (Test-Path $Esd)) { throw 'Both install.wim and install.esd exist; delete the leftover from a previous build.' }
    $from = if (Test-Path $Wim) { $Wim } elseif (Test-Path $Esd) { $Esd } else { throw 'Found neither install.wim nor install.esd.' }
    if ($Format -eq 'wim') { Export-ImageFile $from $Wim 'max' }
    elseif ($from -eq $Esd) { Write-Host 'Already install.esd.' }
    else { Export-ImageFile $from $Esd 'recovery' }
}

function Invoke-BootSteps {
    if (-not (Test-Path $BootWim)) { throw "Could not find $BootWim." }
    $index = @(Get-WindowsImage -ImagePath $BootWim)[-1].ImageIndex   # Setup is always the last index
    Reset-MountDir $BootMount
    Dism /Mount-Wim /WimFile:$BootWim /Index:$index /MountDir:$BootMount
    try { foreach ($s in Get-Steps 'boot') { Invoke-Step $s $BootMount } }
    catch { Dism /Unmount-Wim /MountDir:$BootMount /Discard; throw }
    Dism /Unmount-Wim /MountDir:$BootMount /Commit
    Remove-Item $BootMount -Recurse -Force -ErrorAction SilentlyContinue
    Export-ImageFile $BootWim $BootWim 'max' -BootableLast
}

function New-Iso {
    if (-not (Test-Path $Oscdimg)) { throw "Could not find oscdimg (Windows ADK, Deployment Tools): $Oscdimg" }
    $etfs = Join-Path $IsoDir 'boot\etfsboot.com'
    # efisys_ex.bin = boot via the 2023 certificate, put there by the steps\boot\40-boot-2023 step
    $efi = Join-Path $IsoDir 'efi\microsoft\boot\efisys_ex.bin'
    if (-not (Test-Path $efi)) { $efi = Join-Path $IsoDir 'efi\microsoft\boot\efisys.bin' }
    & $Oscdimg -m -o -u2 -udfver102 "-l$Label" "-bootdata:2#p0,e,b$etfs#pEF,e,b$efi" $IsoDir $OutIso
    if ($LASTEXITCODE) { throw "oscdimg exited with code $LASTEXITCODE." }
    Write-Host ('{0}: {1:N2} GB' -f $OutIso, ((Get-Item $OutIso).Length / 1GB)) -ForegroundColor Green
}

function Get-ExtraKey([IO.FileInfo]$Step) { $Step.BaseName -replace '^\d+-' }

# Build extras: the ones in steps\extras and ESD compression, checked or unchecked by number
function Select-Extras([string[]]$Default) {
    $list = @(Get-Steps 'extras' | ForEach-Object { [pscustomobject]@{ Key = Get-ExtraKey $_; Text = (Get-Content $_.FullName -TotalCount 1 -Encoding UTF8) -replace '^#\s*' } })
    $list += [pscustomobject]@{ Key = 'esd'; Text = 'ESD compression: much smaller ISO; takes about 1 hour and DISM cannot mount install.esd for editing.' }
    $on = @{}
    foreach ($k in $Default) { $on[$k] = $true }
    while ($true) {
        Write-Host "`nExtras (numbers to check or uncheck; Enter to start):" -ForegroundColor Cyan
        for ($i = 0; $i -lt $list.Count; $i++) { Write-Host ('  {0} [{1}] {2}: {3}' -f ($i + 1), $(if ($on[$list[$i].Key]) { 'x' } else { ' ' }), $list[$i].Key, $list[$i].Text) }
        $line = Read-Host '>'
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        foreach ($n in $line -split '[\s,]+' | Where-Object { $_ -match '^\d+$' }) {
            if ([int]$n -ge 1 -and [int]$n -le $list.Count) { $k = $list[[int]$n - 1].Key; $on[$k] = -not $on[$k] }
        }
    }
    @($list.Key | Where-Object { $on[$_] })
}

# T (test, default without extras) or R (release, default with ESD): mount, steps, extras, unmount, boot.wim, ISO
function Invoke-Build([string]$Kind) {
    $default = if ($Kind -eq 'r') { @('esd') } else { @() }
    $script:BuildExtras = if ($ExtrasGiven) { @($Extras -split '[\s,]+' | Where-Object { $_ }) } elseif ($Run) { $default } else { Select-Extras $default }
    $known = @(Get-Steps 'extras' | ForEach-Object { Get-ExtraKey $_ }) + 'esd'
    $unknown = @($BuildExtras | Where-Object { $_ -notin $known })
    if ($unknown) { throw "Unknown extra: $($unknown -join ', '). Available: $($known -join ', ')." }
    Write-Host "Extras: $(if ($BuildExtras) { $BuildExtras -join ', ' } else { 'none' })" -ForegroundColor Cyan
    Mount-Install
    foreach ($s in Get-Steps 'install') { Invoke-Step $s $MountDir }
    foreach ($s in Get-Steps 'extras') { if ($BuildExtras -contains (Get-ExtraKey $s)) { Invoke-Step $s $MountDir } }
    $mark = ($BuildExtras | Where-Object { $_ -ne 'esd' }) -join ','
    Edit-ImageRegistry $MountDir 'SOFTWARE' { param($root) New-Item "$root\TheKOS" -Force | Out-Null; Set-ItemProperty "$root\TheKOS" 'BuildExtras' $mark }
    Dismount-Install
    Invoke-BootSteps
    Convert-Install $(if ($BuildExtras -contains 'esd') { 'esd' } else { 'wim' })
    New-Iso
}

function Show-Menu {
    $m = Get-Mount $MountDir
    $img = if (Test-Path $Wim) { 'install.wim, {0:N2} GB' -f ((Get-Item $Wim).Length / 1GB) }
           elseif (Test-Path $Esd) { 'install.esd, {0:N2} GB' -f ((Get-Item $Esd).Length / 1GB) }
           else { 'no install.wim/esd' }
    Write-Host "`n=== KOS: ISO build ===" -ForegroundColor Cyan
    Write-Host "ISO:    $IsoDir ($img)"
    Write-Host "Mount:  $MountDir ($(if ($m) { "mounted, $($m.MountStatus)" } else { 'not mounted' }))"
    Write-Host "Output: $OutIso`n"
    Write-Host '  T  Test build: choose the extras (default: none) and do everything'
    Write-Host '  R  Release build: choose the extras (default: ESD) and do everything'
    Write-Host ''
    Write-Host '  1  Mount install.wim'
    Write-Host '  2  Run all the steps in steps\install (or just one, by letter)'
    $i = 0
    foreach ($s in Get-Steps 'install') { Write-Host ('       {0}  {1}' -f [char](97 + $i++), $s.Name) }
    Write-Host '  3  Open the mount in Explorer (close it before unmounting)'
    Write-Host '  4  Unmount and save'
    Write-Host '  5  Unmount and discard'
    Write-Host ('  6  Slim boot.wim: {0}' -f ((Get-Steps 'boot').Name -join ', '))
    Write-Host '  7  Create the ISO with install.wim (can be mounted again)'
    Write-Host '  8  Create the ISO with install.esd'
    Write-Host '  0  Exit'
}

function Invoke-Key([string]$Key) {
    $install = Get-Steps 'install'
    switch -Regex ($Key) {
        '^[tr]$' { Invoke-Build $Key; break }
        '^1$' { Mount-Install }
        '^2$' { Assert-Mounted; foreach ($s in $install) { Invoke-Step $s $MountDir } }
        '^3$' { Assert-Mounted; Start-Process explorer.exe $MountDir }
        '^4$' { Dismount-Install }
        '^5$' { Dismount-Install -Discard }
        '^6$' { Invoke-BootSteps }
        '^7$' { Dismount-Install; Convert-Install 'wim'; New-Iso }
        '^8$' { Dismount-Install; Convert-Install 'esd'; New-Iso }
        '^[a-z]$' {
            $n = [int][char]$Key - 97
            if ($n -ge $install.Count) { throw "There is no step $Key." }
            Assert-Mounted
            Invoke-Step $install[$n] $MountDir
        }
        default { throw "Unknown option: $Key" }
    }
}

function Invoke-Keys([string]$Line) {
    foreach ($k in $Line -split '[\s,]+' | Where-Object { $_ }) {
        $k = $k.ToLowerInvariant()
        $watch = [Diagnostics.Stopwatch]::StartNew()
        Invoke-Key $k
        Write-Host ('[{0}] finished in {1:hh\:mm\:ss}' -f $k, $watch.Elapsed) -ForegroundColor DarkGray
    }
}

if ($Run) {
    try { Invoke-Keys $Run; exit 0 }
    catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
}
while ($true) {
    Show-Menu
    $line = Read-Host 'Choose (you can combine several, e.g.: 1 c 4)'
    if ($null -eq $line -or $line -match '^\s*0\s*$') { break }
    try { Invoke-Keys $line }
    catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red }
}
