@echo off 

reg delete "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v "735209102" /f >NUL 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v "1853569164" /f >NUL 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v "156965516" /f >NUL 2>&1

echo restart your pc 
pause 
exit 