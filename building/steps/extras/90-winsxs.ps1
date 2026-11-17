# Removes WinSxS: much smaller ISO, but after install there is no Windows Update, sfc, DISM /RestoreHealth or new optional feature.
# What stays is what Windows uses at run time or on the first boot: the public
# assemblies (common-controls, gdiplus, VC80/VC90), the servicing stack with its manifests and catalogs, Narrator and the
# loose files. The system files outside WinSxS are hardlinks and stay in place.
# A pending operation (pending.xml, e.g. .NET 3.5 enabled offline) is finished on the first boot from the packages in
# WinSxS; without them Setup fails in the specialize pass, so the step refuses.
param([string]$Mount, [string]$Iso)
if (Test-Path (Join-Path $Mount 'Windows\WinSxS\pending.xml')) {
    throw 'The image has pending operations (WinSxS\pending.xml, usually .NET 3.5 enabled by NTLite or offline); removing WinSxS would break Setup at first boot.'
}
Clear-ImageFolder (Join-Path $Mount 'Windows\WinSxS') -Keep '*_6595b64144ccf1df_*', '*_1fc8b3b9a1e18e3b_*', '*servicingstack*', '*-s..*stack*',
    '*narrator*', 'Manifests', 'SettingsManifests', 'Catalogs', 'FileMaps', 'InstallTemp', 'Temp'
