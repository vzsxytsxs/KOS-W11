# Logon task that runs the every-boot scripts (bin\3\startup.vbs: cleanup.cmd and startuptweaks.cmd) as
# administrator, with no prompt. Replaces the "KOS Cleanup" value of HKLM\...\Run: with UAC on (Basic profile), what
# comes out of the Run key runs without privileges, and the startup scripts touch services, HKLM and Program Files.
# Users group (S-1-5-32-545) + RunLevel Highest: runs in the session of whoever logs on (cleanup.cmd cleans that user's
# %TEMP% and %LOCALAPPDATA%), elevated for administrators.
# Exit: 0 = task registered and verified; 1 = failed.
$ErrorActionPreference = 'Stop'
try {
    $script = Join-Path $env:ProgramData 'TheKOS\bin\3\startup.vbs'
    $action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "`"$script`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $trigger.Delay = 'PT10S' # like the Run key: after the desktop starts loading
    $principal = New-ScheduledTaskPrincipal -GroupId 'S-1-5-32-545' -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskPath '\TheKOS\' -TaskName 'Startup' -Action $action -Trigger $trigger -Principal $principal `
        -Settings $settings -Description 'KOS: startup.vbs (cleanup.cmd and startuptweaks.cmd) at every logon, elevated.' -Force | Out-Null
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name 'KOS Cleanup' -ErrorAction SilentlyContinue

    $task = Get-ScheduledTask -TaskPath '\TheKOS\' -TaskName 'Startup'
    if ($task.Principal.RunLevel -ne 'Highest' -or $task.Principal.GroupId -notmatch 'S-1-5-32-545|Users|Usu' -or $task.Actions[0].Arguments -notlike '*startup.vbs*') {
        throw "Task registered with unexpected settings (RunLevel=$($task.Principal.RunLevel), Group=$($task.Principal.GroupId))."
    }
    exit 0
} catch {
    Write-Error $_.Exception.Message -ErrorAction Continue
    exit 1
}
