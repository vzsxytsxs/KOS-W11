# Deletes the superseded versions of the boot.wim components (65 MB in ISO 4.0.0).
param([string]$Mount, [string]$Iso)
Dism /Image:$Mount /Cleanup-Image /StartComponentCleanup /ResetBase
