@echo off
:: Removals from prepareiso.cmd on the mounted image (%1)
call "%~dp0..\..\prepareiso.cmd" "%~1"
exit /b %errorlevel%
