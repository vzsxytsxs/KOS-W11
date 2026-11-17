@echo off
setlocal EnableExtensions
if /i not "%~1"=="on" if /i not "%~1"=="off" exit /b 2
fltmc >nul 2>&1 && goto admin
set "KOS_SCRIPT=%~f0"
set "KOS_SCRIPT_ARGS=%~1"
powershell.exe -NoProfile -Command "try { $p=Start-Process -Verb RunAs -Wait -PassThru -FilePath $env:KOS_SCRIPT -ArgumentList $env:KOS_SCRIPT_ARGS; exit $p.ExitCode } catch { exit 1 }"
exit /b %errorlevel%

:admin
set "TARGET=%windir%\System32\Utilman.exe"
set "CMD=%windir%\System32\cmd.exe"
set "BACKUP=%ProgramData%\TheKOS\Backup\Utilman.exe"
set "POWERRUN=%windir%\PowerRun.exe"
if not exist "%TARGET%" exit /b 1
if not exist "%CMD%" exit /b 1
if not exist "%POWERRUN%" exit /b 1
call :prepareBackup || exit /b 1
call :isCmd
if /i "%~1"=="on" (
    if not errorlevel 1 exit /b 0
    if not exist "%BACKUP%" (
        call :verifyOriginal "%TARGET%" || exit /b 1
        copy /y "%TARGET%" "%BACKUP%" >nul || exit /b 1
    )
    call :verifyOriginal "%BACKUP%" || exit /b 1
    "%POWERRUN%" /SW:0 cmd.exe /d /c copy /y "%CMD%" "%TARGET%" >nul || exit /b 1
    call :isCmd
    if errorlevel 1 exit /b 1
    exit /b 0
)
if errorlevel 1 exit /b 0
if exist "%BACKUP%" (
    call :verifyOriginal "%BACKUP%" || exit /b 1
    "%POWERRUN%" /SW:0 cmd.exe /d /c copy /y "%BACKUP%" "%TARGET%" >nul || exit /b 1
) else (
    sfc /scanfile="%TARGET%" >nul
)
call :verifyOriginal "%TARGET%"
exit /b %errorlevel%

:isCmd
powershell.exe -NoProfile -Command "if ((Get-FileHash -LiteralPath $env:TARGET).Hash -eq (Get-FileHash -LiteralPath $env:CMD).Hash -or [Diagnostics.FileVersionInfo]::GetVersionInfo($env:TARGET).OriginalFilename -match '^cmd\.exe(\.mui)?$') { exit 0 } else { exit 1 }"
exit /b %errorlevel%

:verifyOriginal
set "KOS_CHECK_FILE=%~1"
powershell.exe -NoProfile -Command "$f=$env:KOS_CHECK_FILE; $name=[Diagnostics.FileVersionInfo]::GetVersionInfo($f).OriginalFilename; if ($name -notmatch '^utilman2?\.exe(\.mui)?$' -or (Get-AuthenticodeSignature -LiteralPath $f).Status -ne 'Valid') { exit 1 }"
exit /b %errorlevel%

:: Standard users can create folders in %ProgramData%\TheKOS. A Backup folder (or a backup) owned by someone else, or a
:: link, is refused: the file could be swapped between the check and the copy as TrustedInstaller.
:prepareBackup
set "KOS_BACKUP_DIR=%ProgramData%\TheKOS\Backup"
powershell.exe -NoProfile -Command "$d=$env:KOS_BACKUP_DIR; $ok='S-1-5-32-544','S-1-5-18'; try { if (Test-Path -LiteralPath $d) { $i=Get-Item -LiteralPath $d -Force; if (-not $i.PSIsContainer -or ($i.Attributes -band [IO.FileAttributes]::ReparsePoint)) { exit 1 } } else { New-Item -ItemType Directory -Path $d -ErrorAction Stop | Out-Null }; if ($ok -notcontains (Get-Acl -LiteralPath $d).GetOwner([Security.Principal.SecurityIdentifier]).Value) { exit 1 }; & icacls.exe $d /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' | Out-Null; if ($LASTEXITCODE -ne 0) { exit 1 }; $f=Join-Path $d 'Utilman.exe'; if ((Test-Path -LiteralPath $f) -and $ok -notcontains (Get-Acl -LiteralPath $f).GetOwner([Security.Principal.SecurityIdentifier]).Value) { exit 1 } } catch { exit 1 }"
exit /b %errorlevel%
