@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ServiceBackup.ps1" -Mode Capture -Snapshot Custom.Backup.Services
if errorlevel 1 (echo Backup failed.) else (echo Backup complete.)
pause
