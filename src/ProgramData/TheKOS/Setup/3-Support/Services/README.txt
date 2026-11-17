TheKOS service snapshots
========================

Snapshots (.json, .reg, .full.reg, .previous, diff CSV) are stored in the Backups
subfolder; ServiceBackup.ps1 moves files left in this folder by older versions.

RunOnce captures Windows.Default.Services and TheKOS.services, then writes
TheKOS.Services.Diff.csv. Custom.Services.Backup.cmd captures a manual snapshot.
The original .reg names are kept for compatibility; those files contain Start
values only. The matching .json files additionally contain DelayedAutoStart,
StartOverride, date, machine name, and service count. A .previous copy is kept
when an existing snapshot is replaced.

The .reg file is a reference, not a full service restore. Importing all of it
would overwrite later changes and could recreate incomplete keys for services
that TheKOS deliberately deleted. TheKOS does not import it automatically.

ServiceBackupUI.cmd opens a window (asks for administrator rights) to create
snapshots, compare any snapshot with the current state, and restore the services
you tick. Windows.Default.Services is taken once and never replaced by a rerun
(use -Force). RunOnce also saves Windows.Default.Services.full.reg, a full export
of the Services key, to recover deleted services by hand. Every restore first
saves the current state as PreRestore.<date>.

To restore startup settings for selected, existing services only, open an
elevated PowerShell window and run, for example:

  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\TheKOS\Setup\3-Support\Services\ServiceBackup.ps1" -Mode Restore -Snapshot Windows.Default.Services -Services "W32Time,BITS"

Only the named services are touched. Start, DelayedAutoStart, and DWORD
StartOverride entries are restored. Deleted services are never recreated.
Services managed on each startup, such as Windows Update, also need their
corresponding TheKOS toggle changed or startup will apply that policy again.

These snapshots cover startup-related values, not every service setting,
dependency, binary, trigger, or security descriptor. They are not a full
Windows system-state backup.
