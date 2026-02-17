<#
.SYNOPSIS
    WindowsXXP - The Ultimate Windows Debloat, Privacy & Performance Script
.DESCRIPTION
    Combines aggressive debloating, telemetry blocking, privacy hardening,
    and raw performance tuning into a single one-shot script.
    Preserves Dolby and gaming-related apps/services by default.
.NOTES
    - Creates a system restore point before making changes
    - Logs all actions to your Desktop
    - Restart required after running
#>

# ═══════════════════════════════════════════════════════════════════════════
# SELF-ELEVATION
# ═══════════════════════════════════════════════════════════════════════════
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } catch {
        Write-Host "ERROR: This script requires Administrator privileges." -ForegroundColor Red
        Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
    }
    exit
}

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════
$LogFile = "$env:USERPROFILE\Desktop\WindowsXXP-Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
Start-Transcript -Path $LogFile -ErrorAction SilentlyContinue | Out-Null

# Counters
$Script:AppsRemoved = 0
$Script:AppsSkipped = 0
$Script:ServicesDisabled = 0
$Script:TasksDisabled = 0
$Script:HostsBlocked = 0

# ═══════════════════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════════════════
Clear-Host
Write-Host ""
Write-Host "  ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗███████╗" -ForegroundColor Cyan
Write-Host "  ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔════╝" -ForegroundColor Cyan
Write-Host "  ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║███████╗" -ForegroundColor Cyan
Write-Host "  ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║╚════██║" -ForegroundColor Cyan
Write-Host "  ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝███████║" -ForegroundColor Cyan
Write-Host "   ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚══════╝" -ForegroundColor Cyan
Write-Host "                  ██╗  ██╗██╗  ██╗██████╗                     " -ForegroundColor Magenta
Write-Host "                  ╚██╗██╔╝╚██╗██╔╝██╔══██╗                    " -ForegroundColor Magenta
Write-Host "                   ╚███╔╝  ╚███╔╝ ██████╔╝                    " -ForegroundColor Magenta
Write-Host "                   ██╔██╗  ██╔██╗ ██╔═══╝                     " -ForegroundColor Magenta
Write-Host "                  ██╔╝ ██╗██╔╝ ██╗██║                         " -ForegroundColor Magenta
Write-Host "                  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝                         " -ForegroundColor Magenta
Write-Host ""
Write-Host "  Debloat + Privacy + Performance - One Shot" -ForegroundColor White
Write-Host "  github.com/loponai/WindowsXXP" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════
# USER OPTIONS
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  OPTIONS" -ForegroundColor Yellow
Write-Host ""
$KeepXbox = Read-Host "   Keep Xbox apps & Game Bar? (Y/n)"
if ([string]::IsNullOrWhiteSpace($KeepXbox)) { $KeepXbox = "y" }
$KeepDolby = Read-Host "   Keep Dolby Audio/Access? (Y/n)"
if ([string]::IsNullOrWhiteSpace($KeepDolby)) { $KeepDolby = "y" }
$RemoveOneDrive = Read-Host "   Remove OneDrive completely? (y/N)"
if ([string]::IsNullOrWhiteSpace($RemoveOneDrive)) { $RemoveOneDrive = "n" }
$RemoveEdge = Read-Host "   Harden Microsoft Edge policies? (Y/n)"
if ([string]::IsNullOrWhiteSpace($RemoveEdge)) { $RemoveEdge = "y" }
Write-Host ""
Write-Host "  Press any key to start..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════
# 1. RESTORE POINT
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [1/20] Creating System Restore Point..." -ForegroundColor Cyan
Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
Checkpoint-Computer -Description "WindowsXXP - Pre-Debloat $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 2. REMOVE BLOATWARE APPS
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [2/20] Removing Bloatware Apps..." -ForegroundColor Cyan

$BloatwareApps = @(
    # ── Microsoft Bloat ──
    "Microsoft.3DBuilder"
    "Microsoft.3DViewer"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.549981C3F5F10"                    # Cortana
    "Microsoft.549981C3F5F10_8wekyb3d8bbwe"      # Cortana alt
    "Microsoft.Advertising.Xaml"
    "Microsoft.BingFinance"
    "Microsoft.BingFoodAndDrink"
    "Microsoft.BingHealthAndFitness"
    "Microsoft.BingNews"
    "Microsoft.BingSports"
    "Microsoft.BingTranslator"
    "Microsoft.BingTravel"
    "Microsoft.BingWeather"
    "Microsoft.BingSearch"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Messaging"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.MicrosoftPowerBIForWindows"
    "Microsoft.MixedReality.Portal"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.News"
    "Microsoft.Office.OneNote"
    "Microsoft.OneConnect"
    "Microsoft.OutlookForWindows"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.RemoteDesktop"
    "Microsoft.SkypeApp"
    "Microsoft.Todos"
    "Microsoft.Wallet"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsCommunicationsApps"         # Mail & Calendar
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsMeetNow"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.WindowsCamera"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.Windows.DevHome"
    "Microsoft.Windows.DevHomeGitHubExtension"
    "Microsoft.Windows.DevHomeAzureExtension"
    "MicrosoftCorporationII.MicrosoftFamily"
    "MicrosoftCorporationII.QuickAssist"
    "MicrosoftTeams"
    "MSTeams"

    # ── Third-Party Bloat ──
    "2FE3CB00.PicsArt-PhotoStudio"
    "46928bounde.EclipseManager"
    "46928boez.EclipseManager"
    "4DF9E0F8.Netflix"
    "613EBCEA.PolarrPhotoEditorAcademicEdition"
    "6Wunderkinder.Wunderlist"
    "7EE7776C.LinkedInforWindows"
    "89006A2E.AutodeskSketchBook"
    "9E2F88E3.Twitter"
    "A278AB0D.DisneyMagicKingdoms"
    "A278AB0D.MarchofEmpires"
    "ACGMediaPlayer"
    "ActiproSoftwareLLC"
    "ActiproSoftwareLLC.562882FEEB491"
    "AdobeSystemsIncorporated.AdobePhotoshopExpress"
    "Amazon.com.Amazon"
    "BytedancePte.Ltd.TikTok"
    "CAF9E577.Plex"
    "ClearChannelRadioDigital.iHeartRadio"
    "Clipchamp.Clipchamp"
    "D52A8D61.FarmVille2CountryEscape"
    "D5EA27B7.Duolingo-LearnLanguagesforFree"
    "DB6EA5DB.CyberLinkMediaSuiteEssentials"
    "Disney.37853FC22B2CE"
    "Drawboard.DrawboardPDF"
    "Duolingo-LearnLanguagesforFree"
    "Facebook.Facebook"
    "Fitbit.FitbitCoach"
    "Flipboard.Flipboard"
    "flaregamesGmbH.RoyalRevolt2"
    "GAMELOFTSA.Asphalt8Airborne"
    "KeeperSecurityInc.Keeper"
    "king.com.BubbleWitch3Saga"
    "king.com.CandyCrushFriends"
    "king.com.CandyCrushSaga"
    "king.com.CandyCrushSodaSaga"
    "king.com.FarmHeroesSaga"
    "LinkedInforWindows"
    "Nordcurrent.CookingFever"
    "PandoraMediaInc"
    "PandoraMediaInc.29680B314EFC2"
    "PricelinePartnerNetwork.Booking.comBi498tele498702702702"
    "SpotifyAB.SpotifyMusic"
    "ThumbmunkeysLtd.PhototasticCollage"
    "TheNewYorkTimes.NYTCrossword"
    "TuneIn.TuneInRadio"
    "Twitter.Twitter"
    "WinZipComputing.WinZipUniversal"
    "XINGAG.XING"
)

# Conditionally add Xbox apps
if ($KeepXbox -ne "y" -and $KeepXbox -ne "Y") {
    $BloatwareApps += @(
        "Microsoft.GamingApp"
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxApp"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
    )
}

# Conditionally add Dolby
if ($KeepDolby -ne "y" -and $KeepDolby -ne "Y") {
    $BloatwareApps += "DolbyLaboratories.DolbyAccess"
}

$AllProvisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
foreach ($App in $BloatwareApps) {
    $Package = Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue
    $Provisioned = $AllProvisioned | Where-Object DisplayName -Like $App
    if ($Package -or $Provisioned) {
        $Package | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        $Provisioned | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Write-Host "     Removed: $App" -ForegroundColor DarkGray
        $Script:AppsRemoved++
    } else {
        $Script:AppsSkipped++
    }
}
Write-Host "     $Script:AppsRemoved apps removed, $Script:AppsSkipped not found" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 3. DISABLE TELEMETRY & DATA COLLECTION
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [3/20] Disabling Telemetry & Data Collection..." -ForegroundColor Cyan

# Core telemetry
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1

# Application telemetry
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Type DWord -Value 0

# CEIP
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Type DWord -Value 0

# Diagnostic data
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" -Name "ShowedToastAtLevel" -Type DWord -Value 1

# Feedback frequency
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -Type DWord -Value 0

# Tailored experiences
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 1

# Error reporting
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 1

# DiagTrack + dmwappushservice
Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
Set-Service "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 4. PRIVACY HARDENING
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [4/20] Hardening Privacy Settings..." -ForegroundColor Cyan

# Advertising ID
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 1

# Activity history
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 0

# Location tracking
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocationScripting" -Type DWord -Value 1
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Deny"

# App launch tracking
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Type DWord -Value 0

# Website access to language list
New-Item -Path "HKCU:\Control Panel\International\User Profile" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Type DWord -Value 1

# Input personalization (typing/inking)
New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type DWord -Value 1
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type DWord -Value 1
New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Type DWord -Value 0
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Type DWord -Value 0

# Online speech recognition
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted" -Type DWord -Value 0

# App diagnostics
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2297E4E2-5DBE-466D-A12B-0F8286F0D9CA}" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2297E4E2-5DBE-466D-A12B-0F8286F0D9CA}" -Name "Value" -Type String -Value "Deny"

# Clipboard history & cross-device sync
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Type DWord -Value 0 -ErrorAction SilentlyContinue
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowCrossDeviceClipboard" -Type DWord -Value 0

# Lock screen camera
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreenCamera" -Type DWord -Value 1

# Find My Device
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name "AllowFindMyDevice" -Type DWord -Value 0

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 5. DISABLE CORTANA & BING SEARCH
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [5/20] Disabling Cortana & Bing Search..." -ForegroundColor Cyan

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWebOverMeteredConnections" -Type DWord -Value 0

New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaEnabled" -Type DWord -Value 0

New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type DWord -Value 1

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 6. DISABLE SUGGESTIONS, ADS & AUTO-INSTALL
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [6/20] Disabling Suggestions, Ads & Auto-Install..." -ForegroundColor Cyan

$cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

# Start Menu suggestions
Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0

# Suggested/silent-installed apps
Set-ItemProperty -Path $cdm -Name "ContentDeliveryAllowed" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "PreInstalledAppsEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "FeatureManagementEnabled" -Type DWord -Value 0

# Tips, tricks, suggestions
Set-ItemProperty -Path $cdm -Name "SoftLandingEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "SubscribedContent-310093Enabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "SubscribedContent-353694Enabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "SubscribedContent-353696Enabled" -Type DWord -Value 0

# Lock screen spotlight & tips
Set-ItemProperty -Path $cdm -Name "RotatingLockScreenEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "RotatingLockScreenOverlayEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0

# Settings app suggestions
Set-ItemProperty -Path $cdm -Name "SubscribedContent-338393Enabled" -Type DWord -Value 0
Set-ItemProperty -Path $cdm -Name "SubscribedContent-353698Enabled" -Type DWord -Value 0

# Welcome Experience
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Type DWord -Value 0 -ErrorAction SilentlyContinue

# Prevent bloatware reinstall after updates
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Type DWord -Value 1

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 7. DISABLE SCHEDULED TASKS
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [7/20] Disabling Telemetry Scheduled Tasks..." -ForegroundColor Cyan

$TasksToDisable = @(
    "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "Microsoft\Windows\Application Experience\StartupAppTask"
    "Microsoft\Windows\Autochk\Proxy"
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "Microsoft\Windows\Feedback\Siuf\DmClient"
    "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
    "Microsoft\Windows\Maps\MapsToastTask"
    "Microsoft\Windows\Maps\MapsUpdateTask"
    "Microsoft\Windows\Shell\FamilySafetyMonitor"
    "Microsoft\Windows\Shell\FamilySafetyRefreshTask"
    "Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "Microsoft\Windows\PI\Sqm-Tasks"
    "Microsoft\Windows\NetTrace\GatherNetworkInfo"
    "Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
)

foreach ($Task in $TasksToDisable) {
    $Result = Disable-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue
    if ($Result) { $Script:TasksDisabled++ }
}
Write-Host "     $Script:TasksDisabled tasks disabled" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 8. BLOCK TELEMETRY VIA HOSTS FILE
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [8/20] Blocking Telemetry Domains via Hosts File..." -ForegroundColor Cyan

$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$TelemetryDomains = @(
    "vortex.data.microsoft.com"
    "vortex-win.data.microsoft.com"
    "telecommand.telemetry.microsoft.com"
    "telecommand.telemetry.microsoft.com.nsatc.net"
    "oca.telemetry.microsoft.com"
    "oca.telemetry.microsoft.com.nsatc.net"
    "sqm.telemetry.microsoft.com"
    "sqm.telemetry.microsoft.com.nsatc.net"
    "watson.telemetry.microsoft.com"
    "watson.telemetry.microsoft.com.nsatc.net"
    "redir.metaservices.microsoft.com"
    "choice.microsoft.com"
    "choice.microsoft.com.nsatc.net"
    "df.telemetry.microsoft.com"
    "reports.wes.df.telemetry.microsoft.com"
    "wes.df.telemetry.microsoft.com"
    "services.wes.df.telemetry.microsoft.com"
    "sqm.df.telemetry.microsoft.com"
    "telemetry.microsoft.com"
    "watson.ppe.telemetry.microsoft.com"
    "telemetry.appex.bing.net"
    "telemetry.urs.microsoft.com"
    "settings-sandbox.data.microsoft.com"
    "vortex-sandbox.data.microsoft.com"
    "survey.watson.microsoft.com"
    "watson.live.com"
    "watson.microsoft.com"
    "statsfe2.ws.microsoft.com"
    "corpext.msitadfs.glbdns2.microsoft.com"
    "compatexchange.cloudapp.net"
    "cs1.wpc.v0cdn.net"
    "a-0001.a-msedge.net"
    "statsfe2.update.microsoft.com.akadns.net"
    "sls.update.microsoft.com.akadns.net"
    "fe2.update.microsoft.com.akadns.net"
    "diagnostics.support.microsoft.com"
    "corp.sts.microsoft.com"
    "statsfe1.ws.microsoft.com"
    "pre.footprintpredict.com"
    "i1.services.social.microsoft.com"
    "i1.services.social.microsoft.com.nsatc.net"
    "feedback.windows.com"
    "feedback.microsoft-hohm.com"
    "feedback.search.microsoft.com"
    "activity.windows.com"
    "self.events.data.microsoft.com"
    "v10.events.data.microsoft.com"
    "v20.events.data.microsoft.com"
    "v10.vortex-win.data.microsoft.com"
    "us-v10.events.data.microsoft.com"
    "eu-v10.events.data.microsoft.com"
    "events.data.microsoft.com"
    "umwatsonc.events.data.microsoft.com"
    "ceuswatcab01.blob.core.windows.net"
    "ceuswatcab02.blob.core.windows.net"
    "eaus2watcab01.blob.core.windows.net"
    "eaus2watcab02.blob.core.windows.net"
    "weus2watcab01.blob.core.windows.net"
    "weus2watcab02.blob.core.windows.net"
    "browser.events.data.msn.com"
)

$HostsContent = Get-Content $HostsPath -ErrorAction SilentlyContinue
$NewEntries = @()
foreach ($Domain in $TelemetryDomains) {
    if ($HostsContent -notcontains "0.0.0.0 $Domain") {
        $NewEntries += "0.0.0.0 $Domain"
        $Script:HostsBlocked++
    }
}
if ($NewEntries.Count -gt 0) {
    if ($HostsContent -notcontains "# WindowsXXP Telemetry Block") {
        Add-Content -Path $HostsPath -Value "`n# WindowsXXP Telemetry Block"
    }
    Add-Content -Path $HostsPath -Value $NewEntries
}
Write-Host "     $Script:HostsBlocked domains blocked" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 9. FIREWALL RULES FOR TELEMETRY
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [9/20] Adding Firewall Rules to Block Telemetry..." -ForegroundColor Cyan

$TelemetryIPs = @(
    "134.170.30.202"
    "137.116.81.24"
    "157.56.106.189"
    "184.86.53.99"
    "2.22.61.43"
    "2.22.61.66"
    "204.79.197.200"
    "23.218.212.69"
    "65.39.117.230"
    "65.55.108.23"
)

Remove-NetFirewallRule -DisplayName "WindowsXXP - Block Telemetry" -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "WindowsXXP - Block Telemetry" -Direction Outbound -Action Block -RemoteAddress $TelemetryIPs -ErrorAction SilentlyContinue | Out-Null
Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 10. PERFORMANCE TWEAKS (REGISTRY)
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [10/20] Applying Performance Tweaks..." -ForegroundColor Cyan

# ── Visual effects: best performance ──
$vfx = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
New-Item -Path $vfx -Force | Out-Null
Set-ItemProperty -Path $vfx -Name "VisualFXSetting" -Type DWord -Value 2

# Keep ClearType (looks terrible without it)
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Type String -Value "2"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothingType" -Type DWord -Value 2

# Disable animations
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value "0"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 0

# ── Faster shutdown ──
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Type String -Value "2000"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Type String -Value "1000"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type String -Value "2000"

# ── Disable startup delay ──
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Type DWord -Value 0

# ── Mouse: disable acceleration ──
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type String -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type String -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type String -Value "0"

# ── Disable background apps ──
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type DWord -Value 1
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Type DWord -Value 2

# ── Disable Fast Startup (causes issues, not actually faster) ──
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Type DWord -Value 0

# ── Verbose boot status ──
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Type DWord -Value 1

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 11. POWER PLAN: HIGH / ULTIMATE PERFORMANCE
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [11/20] Setting High Performance Power Plan..." -ForegroundColor Cyan

# Try Ultimate Performance first
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
$ultimate = powercfg /list | Select-String "Ultimate Performance"
if ($ultimate) {
    $guid = ($ultimate -replace '.*GUID:\s*','') -replace '\s*\(.*',''
    powercfg /setactive $guid.Trim()
    Write-Host "     Ultimate Performance plan activated" -ForegroundColor Green
} else {
    $highPerf = powercfg /list | Select-String "High performance"
    if ($highPerf) {
        $guid = ($highPerf -replace '.*GUID:\s*','') -replace '\s*\(.*',''
        powercfg /setactive $guid.Trim()
        Write-Host "     High Performance plan activated" -ForegroundColor Green
    } else {
        Write-Host "     Could not set power plan - set manually" -ForegroundColor Yellow
    }
}

# Disable hibernation
powercfg /hibernate off 2>$null
Write-Host "     Hibernation disabled" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 12. NETWORK OPTIMIZATIONS
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [12/20] Optimizing Network..." -ForegroundColor Cyan

# ── Low-latency: disable Nagle's algorithm ──
$netInterfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
foreach ($iface in $netInterfaces) {
    Set-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -Type DWord -Value 1 2>$null
    Set-ItemProperty -Path $iface.PSPath -Name "TCPNoDelay" -Type DWord -Value 1 2>$null
}

# TCP stack tuning
netsh int tcp set global autotuninglevel=normal 2>$null
netsh int tcp set global chimney=enabled 2>$null
netsh int tcp set global dca=enabled 2>$null
netsh int tcp set global netdma=enabled 2>$null

# ── Privacy: disable NetBIOS ──
$RegKey = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
Get-ChildItem $RegKey -ErrorAction SilentlyContinue | ForEach-Object {
    Set-ItemProperty -Path "$RegKey\$($_.PSChildName)" -Name "NetbiosOptions" -Type DWord -Value 2 -ErrorAction SilentlyContinue
}

# ── Disable LLMNR ──
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Type DWord -Value 0

# ── Disable SMBv1 ──
Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart -ErrorAction SilentlyContinue | Out-Null
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue

# ── Disable WiFi Sense ──
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Type DWord -Value 0

# ── DNS over HTTPS ──
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoh" -Type DWord -Value 2 -ErrorAction SilentlyContinue

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 13. DISABLE UNNECESSARY SERVICES
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [13/20] Disabling Unnecessary Services..." -ForegroundColor Cyan

$ServicesToDisable = @(
    @{ Name="DiagTrack";            Desc="Connected User Experiences and Telemetry" }
    @{ Name="dmwappushservice";     Desc="WAP Push Message Routing" }
    @{ Name="SysMain";              Desc="Superfetch" }
    @{ Name="WSearch";              Desc="Windows Search Indexer" }
    @{ Name="MapsBroker";           Desc="Downloaded Maps Manager" }
    @{ Name="lfsvc";                Desc="Geolocation Service" }
    @{ Name="SharedAccess";         Desc="Internet Connection Sharing" }
    @{ Name="RemoteRegistry";       Desc="Remote Registry" }
    @{ Name="RetailDemo";           Desc="Retail Demo Service" }
    @{ Name="wisvc";                Desc="Windows Insider Service" }
    @{ Name="WMPNetworkSvc";        Desc="Windows Media Player Sharing" }
    @{ Name="WerSvc";               Desc="Windows Error Reporting" }
    @{ Name="Fax";                  Desc="Fax Service" }
    @{ Name="fhsvc";                Desc="File History Service" }
    @{ Name="PhoneSvc";             Desc="Phone Service" }
    @{ Name="TabletInputService";   Desc="Touch Keyboard" }
    @{ Name="HomeGroupListener";    Desc="HomeGroup Listener" }
    @{ Name="HomeGroupProvider";    Desc="HomeGroup Provider" }
    @{ Name="TrkWks";               Desc="Distributed Link Tracking" }
    @{ Name="PcaSvc";               Desc="Program Compatibility Assistant" }
    @{ Name="WpcMonSvc";            Desc="Parental Controls" }
)

# Conditionally add Xbox services
if ($KeepXbox -ne "y" -and $KeepXbox -ne "Y") {
    $ServicesToDisable += @(
        @{ Name="XblAuthManager";   Desc="Xbox Live Auth Manager" }
        @{ Name="XblGameSave";      Desc="Xbox Live Game Save" }
        @{ Name="XboxNetApiSvc";    Desc="Xbox Live Networking" }
        @{ Name="XboxGipSvc";       Desc="Xbox Accessory Management" }
    )
}

foreach ($svc in $ServicesToDisable) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        $Script:ServicesDisabled++
    }
}
Write-Host "     $Script:ServicesDisabled services disabled" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 14. EXPLORER & UI TWEAKS
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [14/20] Applying Explorer & UI Tweaks..." -ForegroundColor Cyan

# Show file extensions
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0

# Show hidden files
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type DWord -Value 1

# Disable recent files in Quick Access
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Type DWord -Value 0

# Disable frequent folders in Quick Access
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Type DWord -Value 0

# Default to This PC
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1

# Disable Edge desktop shortcut on update
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "DisableEdgeDesktopShortcutCreation" -Type DWord -Value 1

# Disable "Look for app in Store" for unknown extensions
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoUseStoreOpenWith" -Type DWord -Value 1

# Disable Windows Ink Workspace
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -Name "AllowWindowsInkWorkspace" -Type DWord -Value 0

# Hide Task View button
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0

# Minimize search bar (icon only)
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 1

# Disable News and Interests / Widgets
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 0
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Type DWord -Value 0

# Disable Chat icon (Teams)
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Type DWord -Value 0

# Disable Game DVR (conditionally)
if ($KeepXbox -ne "y" -and $KeepXbox -ne "Y") {
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 0
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0 -ErrorAction SilentlyContinue
}

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 15. WINDOWS 11 SPECIFIC
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [15/20] Applying Windows 11 Tweaks..." -ForegroundColor Cyan

# Disable Copilot
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Type DWord -Value 1
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Type DWord -Value 1

# Disable Recall (AI screenshot feature - 24H2+)
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Type DWord -Value 1
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Type DWord -Value 1

# Disable Search Highlights
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsDynamicSearchBoxEnabled" -Type DWord -Value 0 -ErrorAction SilentlyContinue

# Restore classic right-click context menu
New-Item -Path "HKCU:\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Type String -Value ""

# Disable Suggested Actions (clipboard)
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard" -Name "Disabled" -Type DWord -Value 1

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 16. MICROSOFT EDGE HARDENING
# ═══════════════════════════════════════════════════════════════════════════
if ($RemoveEdge -eq "y" -or $RemoveEdge -eq "Y") {
    Write-Host "  [16/20] Hardening Microsoft Edge..." -ForegroundColor Cyan

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force | Out-Null

    # Disable startup boost & background mode
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Type DWord -Value 0

    # Disable first run experience
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Type DWord -Value 1

    # Disable Edge telemetry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DiagnosticData" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PersonalizationReportingEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SendSiteInfoToImproveServices" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Type DWord -Value 0

    # Disable shopping, collections, sidebar, mini menu
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeShoppingAssistantEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeCollectionsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MiniMenuEnabled" -Type DWord -Value 0

    # Disable Edge Copilot sidebar
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "CopilotCDPPageContext" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DiscoverPageContextEnabled" -Type DWord -Value 0

    # Prevent auto-import & desktop search bar
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "AutoImportAtFirstRun" -Type DWord -Value 4
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "WebWidgetAllowed" -Type DWord -Value 0

    Write-Host "     OK" -ForegroundColor Green
} else {
    Write-Host "  [16/20] Skipping Edge Hardening" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════════════════
# 17. WINDOWS DEFENDER (KEEP PROTECTION, REDUCE TELEMETRY)
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [17/20] Configuring Windows Defender..." -ForegroundColor Cyan

# Disable sample submission (keep protection active)
Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue

# Disable SpyNet reporting
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Type DWord -Value 2

# Keep Defender enabled
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Type DWord -Value 0 -ErrorAction SilentlyContinue

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 18. WINDOWS UPDATE TUNING
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [18/20] Tuning Windows Update..." -ForegroundColor Cyan

# Disable auto-restart with logged-on users
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1

# Disable driver updates via Windows Update
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1 -ErrorAction SilentlyContinue

# Disable P2P update downloads outside local network
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 1

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 19. REMOTE ACCESS HARDENING
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "  [19/20] Hardening Remote Access..." -ForegroundColor Cyan

# Disable Remote Assistance
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowFullControl" -Type DWord -Value 0

# Disable Device Portal
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WebManagement\Service" -Name "EnableWebManagement" -Type DWord -Value 0 -ErrorAction SilentlyContinue

Write-Host "     OK" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# 20. ONEDRIVE REMOVAL (OPTIONAL)
# ═══════════════════════════════════════════════════════════════════════════
if ($RemoveOneDrive -eq "y" -or $RemoveOneDrive -eq "Y") {
    Write-Host "  [20/20] Removing OneDrive..." -ForegroundColor Cyan

    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue

    if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
        Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
    }
    if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
    }

    Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1

    # Remove from Explorer sidebar
    New-PSDrive -Name "HKCR" -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "     OK" -ForegroundColor Green
} else {
    Write-Host "  [20/20] Skipping OneDrive Removal" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════════════════
# CLEANUP: STARTUP PROGRAMS, TEMP FILES, DISK
# ═══════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  ── Cleanup ──" -ForegroundColor White

# Remove common startup bloat
Write-Host "  Cleaning startup programs..." -ForegroundColor DarkGray
$startupDisable = @("OneDrive", "Spotify", "com.squirrel.Teams.Teams", "MicrosoftEdgeAutoLaunch*")
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
foreach ($item in $startupDisable) {
    $entries = Get-ItemProperty -Path $runKey 2>$null | Get-Member -MemberType NoteProperty |
        Where-Object { $_.Name -like $item }
    foreach ($entry in $entries) {
        Remove-ItemProperty -Path $runKey -Name $entry.Name -ErrorAction SilentlyContinue
    }
}

# Clear temp files
Write-Host "  Clearing temp files..." -ForegroundColor DarkGray
$tempPaths = @("$env:TEMP", "$env:WINDIR\Temp", "$env:WINDIR\Prefetch", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache")
$totalFreed = 0
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $size = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        $totalFreed += $size
    }
}
$freedMB = [math]::Round($totalFreed / 1MB, 1)

# Clear Windows Update cache
Write-Host "  Clearing update cache..." -ForegroundColor DarkGray
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

# Disk cleanup (all categories)
Write-Host "  Running disk cleanup..." -ForegroundColor DarkGray
$cleanupKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
Get-ChildItem $cleanupKey -ErrorAction SilentlyContinue | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "StateFlags0064" -Type DWord -Value 2 -ErrorAction SilentlyContinue
}
Start-Process cleanmgr -ArgumentList "/sagerun:64" -NoNewWindow -Wait -ErrorAction SilentlyContinue

Write-Host "     ~${freedMB} MB freed from temp files" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════════════════════════════════
Stop-Transcript -ErrorAction SilentlyContinue | Out-Null

Write-Host ""
Write-Host "  ════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  WindowsXXP Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  SUMMARY" -ForegroundColor White
Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "    Apps removed:          $Script:AppsRemoved" -ForegroundColor Cyan
Write-Host "    Services disabled:     $Script:ServicesDisabled" -ForegroundColor Cyan
Write-Host "    Tasks disabled:        $Script:TasksDisabled" -ForegroundColor Cyan
Write-Host "    Telemetry domains:     $Script:HostsBlocked blocked via hosts" -ForegroundColor Cyan
Write-Host "    Temp files freed:      ~${freedMB} MB" -ForegroundColor Cyan
Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  WHAT WAS DONE" -ForegroundColor White
Write-Host "    - Removed bloatware apps" -ForegroundColor DarkGray
Write-Host "    - Disabled telemetry, Cortana, Bing search" -ForegroundColor DarkGray
Write-Host "    - Hardened privacy (ads, tracking, location, clipboard)" -ForegroundColor DarkGray
Write-Host "    - Blocked telemetry via hosts file + firewall" -ForegroundColor DarkGray
Write-Host "    - Performance: animations off, fast shutdown, no startup delay" -ForegroundColor DarkGray
Write-Host "    - Ultimate/High Performance power plan" -ForegroundColor DarkGray
Write-Host "    - Network: Nagle off, TCP tuned, SMBv1/NetBIOS/LLMNR disabled" -ForegroundColor DarkGray
Write-Host "    - Disabled bloat services & scheduled tasks" -ForegroundColor DarkGray
Write-Host "    - Explorer: file extensions, hidden files, This PC default" -ForegroundColor DarkGray
Write-Host "    - Win11: Copilot off, Recall off, classic context menu" -ForegroundColor DarkGray
Write-Host "    - Edge hardened, Defender telemetry reduced" -ForegroundColor DarkGray
Write-Host "    - Windows Update: no auto-restart, no driver updates" -ForegroundColor DarkGray
Write-Host "    - Remote access hardened" -ForegroundColor DarkGray
Write-Host "    - Cleaned temp files, prefetch, update cache" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  PRESERVED" -ForegroundColor Yellow
if ($KeepXbox -eq "y" -or $KeepXbox -eq "Y") {
    Write-Host "    - Xbox, Game Bar, Gaming services" -ForegroundColor Yellow
}
if ($KeepDolby -eq "y" -or $KeepDolby -eq "Y") {
    Write-Host "    - Dolby Audio/Access" -ForegroundColor Yellow
}
Write-Host "    - Windows Store, Calculator, Photos, Terminal" -ForegroundColor Yellow
Write-Host "    - Windows Defender (protection active)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Log: $LogFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  >> RESTART YOUR PC TO APPLY ALL CHANGES <<" -ForegroundColor Red
Write-Host ""

$Restart = Read-Host "  Restart now? (y/n)"
if ($Restart -eq "y" -or $Restart -eq "Y") {
    Restart-Computer -Force
} else {
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
