@echo off
setlocal enabledelayedexpansion

:: close brave
taskkill /f /im brave.exe /t 
taskkill /f /IM BraveUpdate.exe /t
taskkill /f /IM brave_installer-x64.exe /t
taskkill /f /IM BraveCrashHandler.exe /t
taskkill /f /IM BraveCrashHandler64.exe /t
taskkill /f /IM BraveCrashHandlerArm64.exe /t
taskkill /f /IM BraveUpdateBroker.exe /t
taskkill /f /IM BraveUpdateCore.exe /t
taskkill /f /IM BraveUpdateOnDemand.exe /t
taskkill /f /IM BraveUpdateSetup.exe /t
taskkill /f /IM BraveUpdateComRegisterShell64 /t
taskkill /f /IM BraveUpdateComRegisterShellArm64 /t

:: del services
sc delete brave
sc delete bravem
sc delete BraveElevationService

:: debloater
echo deleting useless files
rmdir /s /q "C:\Program Files (x86)\BraveSoftware" >nul 2>&1
rmdir /s /q "%userprofile%\AppData\Local\BraveSoftware\Update" >nul 2>&1
rmdir /s /q "C:\Program Files\BraveSoftware\Brave-Browser\Application\SetupMetrics" >nul 2>&1
cd /d "C:\Program Files\BraveSoftware\Brave-Browser\Application\1*"
rmdir /s /q "Installer" >nul 2>&1
rmdir /s /q "BraveVpnWireguardService" >nul 2>&1
rmdir /s /q "Extensions" >nul 2>&1
rmdir /s /q "IwaKeyDistribution" >nul 2>&1
rmdir /s /q "PrivacySandboxAttestationsPreloaded" >nul 2>&1
rmdir /s /q "MEIPreload" >nul 2>&1
rmdir /s /q "C:\ProgramData\BraveSoftware" >nul 2>&1
cd /d "C:\Program Files\BraveSoftware\Brave-Browser\Application\1*"
del "notification_helper.exe" >nul 2>&1
del "eventlog_provider.dll" >nul 2>&1
del "chrome_pwa_launcher.exe" >nul 2>&1
del "brave_vpn_helper.exe" >nul 2>&1
del "elevation_service.exe" >nul 2>&1
del "vulkan-1.dll" >nul 2>&1
del "libEGL.dll" >nul 2>&1
del "libGLESv2.dll" >nul 2>&1
del "d3dcompiler_47.dll" >nul 2>&1
del "dxcompiler.dll" >nul 2>&1
del "dxil.dll" >nul 2>&1
cd /d "C:\Program Files\BraveSoftware\Brave-Browser\Application"
del "chrmstp.exe" /a /s >nul 2>&1

:: Locales
cd /d "C:\Program Files\BraveSoftware\Brave-Browser\Application\1*" >nul 2>&1
copy "Locales\en-US.pak" "C:\Program Files\BraveSoftware\Brave-Browser\Application" >nul 2>&1
rmdir /s /q "Locales" >nul 2>&1
mkdir "Locales" >nul 2>&1
move "C:\Program Files\BraveSoftware\Brave-Browser\Application\en-US.pak" "Locales" >nul 2>&1

:: cleaning reg
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\BraveSoftwareUpdateTaskMachineCore" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\BraveSoftwareUpdateTaskMachineCore{FE515A4B-9531-42A3-9ABB-4CEC234762CD}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\BraveSoftwareUpdateTaskMachineUA" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\BraveSoftwareUpdateTaskMachineUA{981B6403-1813-4DE8-9D2D-F73F2DA25E50}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{781AE031-F26B-47E5-9257-00B9378E2439}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{5B7D273A-5382-4BC9-9F25-49D34A368FAA}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{5B7D273A-5382-4BC9-9F25-49D34A368FAA}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{781AE031-F26B-47E5-9257-00B9378E2439}" /f
reg delete "HKLM\Software\Microsoft\Active Setup\Installed Components\{AFE6A462-C574-4B8A-AF43-4CC60DF4563B}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{56CA197F-543C-40DC-953C-B9C6196C92A5}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{0948A341-8E1E-479F-A667-6169E4D5CB2A}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0948A341-8E1E-479F-A667-6169E4D5CB2A}" /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{56CA197F-543C-40DC-953C-B9C6196C92A5}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "BraveVpnWireguardService" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "BraveVpnWireguardService" /f
schtasks /delete /tn "BraveSoftwareUpdateTaskMachineCore{2320C90E-9617-4C25-88E0-CC10B8F3B6BB}" /f
schtasks /delete /tn "BraveSoftwareUpdateTaskMachineUA{FD1FD78D-BD51-4A16-9F47-EE6518C2D038}" /f
schtasks /delete /tn "BraveSoftwareUpdateTaskMachineCore{1B4ECC99-A065-4BA8-B4B5-6828D11834AC}" /f
schtasks /delete /tn "BraveSoftwareUpdateTaskMachineUA{C2741D3F-2DB1-4D3D-9679-8AF7E44826F3}" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v UiAutomationProviderEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ScreenCaptureAllowed /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DataUrlInSvgUseEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultGeolocationSetting /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultWindowManagementSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultWebUsbGuardSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultWebHidGuardSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultWebBluetoothGuardSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSerialGuardSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSensorsSetting /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultNotificationsSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultLocalFontsSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultJavaScriptJitSetting /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultInsecureContentSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSearchProviderEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSearchProviderImageURLPostParams /t REG_SZ /d "content={google:imageThumbnail},url={google:imageURL},sbisrc={google:imageSearchSource}" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSearchProviderKeyword /t REG_SZ /d "googl" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSearchProviderName /t REG_SZ /d "Google" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSearchProviderSuggestURL /t REG_SZ /d "{google:baseURL}complete/search?output=chrome&q={searchTerms}" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSearchProviderSearchURLPostParams /t REG_SZ /d "q={searchTerms},ie=utf-8,oe=utf-8" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSearchProviderSearchURL /t REG_SZ /d "{google:baseURL}search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}ie={inputEncoding}" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultSearchProviderSuggestURLPostParams /t REG_SZ /d "q={searchTerms},ie=utf-8,oe=utf-8" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SafeBrowsingEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v RendererCodeIntegrityEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ProxyServerMode /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v InsecureFormsWarningsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultWindowPlacementSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultMediaStreamSetting /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ExtensionManifestV2Availability /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ExtensionUnpublishedAvailability /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CreateThemesSettings /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DevToolsGenAiSettings /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v GenAILocalFoundationalModelSettings /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HelpMeWriteSettings /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HistorySearchSettings /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v TabOrganizerSettings /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v EnableMediaRouter /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v MediaRouterCastAllowAllIPs /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ShowCastIconInToolbar /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ShowCastSessionsStartedByOtherDevices /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AccessCodeCastEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CloudAPAuthEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CompressionDictionaryTransportEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AccessControlAllowMethodsInCORSPreflightSpecConformant /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v IPv6ReachabilityOverrideEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ZstdContentEncodingEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DeletingUndecryptablePasswordsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PasswordLeakDetectionEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrintHeaderFooter /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrintingEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrintingLPACSandboxEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrivacySandboxAdMeasurementEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrivacySandboxAdTopicsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrivacySandboxPromptEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrivacySandboxSiteEnabledAdsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrivateNetworkAccessRestrictionsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AdvancedProtectionDeepScanningEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultPluginsSetting /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DisableSSLRecordSplitting /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DnsPrefetchingEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v OptimizationGuideFetchingEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SafeBrowsingSurveysEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SafeBrowsingProxiedRealTimeChecksAllowed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SafeBrowsingExtendedReportingEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SafeBrowsingProtectionLevel /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DisableSafeBrowsingProceedAnyway /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PasswordProtectionWarningTrigger /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SafeBrowsingDeepScanningEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HomepageIsNewTabPage /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HomepageLocation /t REG_SZ /d "google.com" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v NewTabPageLocation /t REG_SZ /d "google.com" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v RestoreOnStartup /t REG_DWORD /d 4 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ShowHomeButton /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AbusiveExperienceInterventionEnforce /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AccessibilityImageLabelsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AdditionalDnsQueryTypesEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AdsSettingForIntrusiveAdsSites /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AdvancedProtectionAllowed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AllowBackForwardCacheForCacheControlNoStorePageEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AllowDinosaurEasterEgg /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AllowFileSelectionDialogs /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AlternateErrorPagesEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ApplicationBoundEncryptionEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AudioCaptureAllowed /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AudioProcessHighPriorityEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AudioSandboxEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v AutoplayAllowed /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BatterySaverModeAvailability /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BrowserGuestModeEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BrowserGuestModeEnforced /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BrowserLabsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BrowserNetworkTimeQueriesEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BrowserSignin /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BuiltInDnsClientEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CSSCustomStateDeprecatedSyntaxEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CORSNonWildcardRequestHeadersSupport /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ChromeForTestingAllowed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ChromeVariations /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ClickToCallEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CloudManagementEnrollmentMandatory /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CloudPolicyOverridesPlatformPolicy /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CloudUserPolicyMerge /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CloudUserPolicyOverridesCloudMachinePolicy /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v CommandLineFlagSecurityWarningsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ComponentUpdatesEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DNSInterceptionChecksEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DefaultBrowserSettingEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DesktopSharingHubEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DomainReliabilityAllowed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DownloadRestrictions /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v DynamicCodeSettings /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v FeedbackSurveysEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ForceGoogleSafeSearch /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ForcePermissionPolicyUnloadDefaultEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ForceYouTubeRestrict /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v FullscreenAllowed /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v GloballyScopeHTTPAuthCacheEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v GoogleSearchSidePanelEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HeadlessMode /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HideWebStoreIcon /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HighEfficiencyModeEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HistoryClustersVisible /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v HttpsUpgradesEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v IntensiveWakeUpThrottlingEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v IntranetRedirectBehavior /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v KeyboardFocusableScrollersEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v LensDesktopNTPSearchEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v LensRegionSearchEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v MediaRecommendationsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v MetricsReportingEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v NTPCardsVisible /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v NetworkPredictionOptions /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v NetworkServiceSandboxEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PaymentMethodQueryEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PrefixedVideoFullscreenApiAvailability /t REG_SZ /d "enabled" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PromotionalTabsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v PromotionsEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v QRCodeGeneratorEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v QuicAllowed /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v RendererAppContainerEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v RequireOnlineRevocationChecksForLocalAnchors /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v RoamingProfileSupportEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SafeBrowsingForTrustedSourcesEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SandboxExternalProtocolBlocked /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SafeSitesFilterBehavior /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ScrollToTextFragmentEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SharedClipboardEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ShoppingListEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ShowFullUrlsInAddressBar /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SideSearchEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SpellCheckServiceEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SpellcheckEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v StandardizedBrowserZoomEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v SuppressUnsupportedOSWarning /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v TaskManagerEndProcessEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v ToolbarAvatarLabelSettings /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v TranslateEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v UrlKeyedAnonymizedDataCollectionEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v UserAgentReduction /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v VideoCaptureAllowed /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v WPADQuickCheckEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v WebRtcEventLogCollectionAllowed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v WebRtcIPHandling /t REG_SZ /d "default" /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v WebRtcTextLogCollectionAllowed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v WindowOcclusionEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v IPFSEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BraveWalletDisabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BraveVPNDisabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave" /v BraveAIChatEnabled /t REG_DWORD /d 0 /f
cls

echo done
pause
exit /b