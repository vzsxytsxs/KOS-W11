@echo off
del "C:\Program Files\Mozilla Firefox\crashreporter.exe" /f /q >nul 2>&1
del "C:\Program Files\Mozilla Firefox\crashreporter.ini" /f /q >nul 2>&1
del "C:\Program Files\Mozilla Firefox\maintenanceservice.exe" /f /q >nul 2>&1
del "C:\Program Files\Mozilla Firefox\maintenanceservice_installer.exe" /f /q >nul 2>&1
del "C:\Program Files\Mozilla Firefox\minidump-analyzer.exe" /f /q >nul 2>&1
del "C:\Program Files\Mozilla Firefox\pingsender.exe" /f /q >nul 2>&1
del "C:\Program Files\Mozilla Firefox\updater.exe" /f /q >nul 2>&1
cd /d "C:\Program Files\Mozilla Firefox">nul 2>&1
del /f crash*.* >nul 2>&1
del /f maintenance*.* >nul 2>&1
del /f install.log >nul 2>&1
del /f minidump*.* >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v ShowHomeButton /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v AllowFileSelectionDialogs /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v AppAutoUpdate /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v BackgroundAppUpdate /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v BlockAboutSupport /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableAppUpdate /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableBuiltinPDFViewer /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableFeedbackCommands /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableFirefoxAccounts /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableFirefoxScreenshots /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableFirefoxStudies /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableForgetButton /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableMasterPasswordCreation /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisablePocket /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableProfileImport /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableProfileRefresh /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableSafeMode /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableSetDesktopBackground /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableTelemetry /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisableThirdPartyModuleBlocking /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DontCheckDefaultBrowser /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v HardwareAcceleration /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v LegacyProfiles /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v ManualAppUpdateOnly /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v NetworkPrediction /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v NewTabPage /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v NoDefaultBookmarks /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v OfferToSaveLogins /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v UseSystemPrintDialog /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Cookies" /v Default /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\DisableSecurityBypass" /v SafeBrowsing /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\DisableSecurityBypass" /v InvalidCertificate /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\EnableTrackingProtection" /v Value /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\EnableTrackingProtection" /v Cryptomining /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\EnableTrackingProtection" /v Fingerprinting /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\EnableTrackingProtection" /v Locked /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\EnableTrackingProtection" /v EmailTracking /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxHome" /v Search /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxHome" /v TopSites /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxHome" /v SponsoredTopSites /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxHome" /v Highlights /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxHome" /v Pocket /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxHome" /v SponsoredPocket /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxHome" /v Snippets /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxHome" /v Locked /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxSuggest" /v ImproveSuggest /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxSuggest" /v Locked /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxSuggest" /v SponsoredSuggestions /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FirefoxSuggest" /v WebSuggestions /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FlashPlugin" /v Default /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\FlashPlugin" /v Locked /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Homepage" /v StartPage /t REG_SZ /d "homepage" /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Homepage" /v URL /t REG_SZ /d "https://google.com" /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Homepage" /v Locked /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\InstallAddonsPermission" /v Default /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\PDFjs" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\PDFjs" /v EnablePermissions /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Permissions\Camera" /v BlockNewRequests /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Permissions\Location" /v BlockNewRequests /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Permissions\Microphone" /v BlockNewRequests /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\PictureInPicture" /v Enabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v browser.cache.disk.enable /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v browser.fixup.dns_first_for_single_words /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v browser.safebrowsing.malware.enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v browser.safebrowsing.phishing.enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v browser.search.update /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v app.update.auto /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v browser.tabs.warnOnClose /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v browser.taskbar.previews.enable /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v datareporting.policy.dataSubmissionPolicyBypassNotification /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v dom.disable_window_flip /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v extensions.htmlaboutaddons.recommendations.enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v geo.enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Preferences" /v security.ssl.errorReporting.enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\SanitizeOnShutdown" /v Cache /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\SanitizeOnShutdown" /v OfflineApps /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\UserMessaging" /v ExtensionRecommendations /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\UserMessaging" /v FeatureRecommendations /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\UserMessaging" /v Locked /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\UserMessaging" /v MoreFromMozilla /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\UserMessaging" /v SkipOnboarding /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\UserMessaging" /v UrlbarInterventions /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\UserMessaging" /v WhatsNew /t REG_DWORD /d 0 /f
echo done
pause
exit /b