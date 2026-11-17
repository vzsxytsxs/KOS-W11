# Removes Recall from the image along with its content (on 26H2 it ships disabled, but with the files inside). Runs before
# ResetBase, which cleans up what is left; in the 26H2 test this left no pending operation. The AllowRecallEnablement policy
# from RunOnce keeps it from coming back. Uses dism.exe directly: Get-WindowsOptionalFeature failed here inside the build.
param([string]$Mount, [string]$Iso)
& dism.exe /Image:$Mount /Disable-Feature /FeatureName:Recall /Remove
if ($LASTEXITCODE -eq -2146498548) { Write-Host 'Recall does not exist in this image.'; return }   # 0x800f080c: unknown feature
if ($LASTEXITCODE -notin 0, 3010) { throw "DISM exited with code $LASTEXITCODE." }
