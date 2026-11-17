# Removes sources\sxs from the ISO (68 MB): it is only used to install .NET 3.5, which the preset already leaves enabled.
# If .NET 3.5 is not enabled in the image, enables it from the sxs itself before deleting. Not with the winsxs extra:
# enabled offline, .NET 3.5 stays pending until the first boot, which needs its packages in WinSxS (without them Setup
# stops with "The computer restarted unexpectedly or encountered an unexpected error").
param([string]$Mount, [string]$Iso)
$sxs = Join-Path $Iso 'sources\sxs'
if (-not (Test-Path $sxs)) { Write-Host 'sources\sxs no longer exists.'; return }
$state = (Get-WindowsOptionalFeature -Path $Mount -FeatureName NetFx3).State
Write-Host ".NET 3.5 in the image: $state"
if ($BuildExtras -contains 'winsxs') { Write-Host '.NET 3.5 not enabled: the winsxs extra removes the packages it needs at first boot.' -ForegroundColor Yellow }
elseif ($state -notin 'Enabled', 'EnablePending') { Dism /Image:$Mount /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:$sxs }
Remove-Item $sxs -Recurse -Force
