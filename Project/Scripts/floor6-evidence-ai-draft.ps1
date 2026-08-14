[CmdletBinding()]
param(
    [string]$OutputRoot = "C:\ProgramData\Floor6Evidence",
    [string]$IncidentDate = "2026-08-14",
    [string]$TargetAppNamePattern = "document|management",
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runFolder = Join-Path $OutputRoot "run-$timestamp"

if (-not $DryRun) {
    New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
}

$result = [ordered]@{
    scriptVersion = "ai-draft-1"
    runTimestamp = (Get-Date).ToString("o")
    incidentDate = $IncidentDate
    dryRun = [bool]$DryRun
    topRankedCause = "Friday floor-targeted app or policy regression affecting sign-in and shell readiness"
    device = @{}
    checks = @{}
    files = @{}
}

# Device context
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$result.device = [ordered]@{
    computerName = $env:COMPUTERNAME
    userName = $env:USERNAME
    model = $cs.Model
    manufacturer = $cs.Manufacturer
    osCaption = $os.Caption
    osVersion = $os.Version
    lastBoot = $os.LastBootUpTime
}

# Installed app snapshot
$apps = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

$suspectApps = $apps | Where-Object { $_.DisplayName -match $TargetAppNamePattern }
$result.checks.installedAppsTotal = ($apps | Measure-Object).Count
$result.checks.suspectApps = $suspectApps

if (-not $DryRun) {
    $apps | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $runFolder "apps.json") -Encoding UTF8
    $result.files.apps = (Join-Path $runFolder "apps.json")
}

# Boot and logon performance signals
$startTime = (Get-Date $IncidentDate).AddDays(-1)
$bootEvents = Get-WinEvent -FilterHashtable @{
    LogName = "Microsoft-Windows-Diagnostics-Performance/Operational"
    Id      = 100,101,102,103,200,201
    StartTime = $startTime
} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, Message

$profileEvents = Get-WinEvent -FilterHashtable @{
    LogName = "Application"
    ProviderName = "Microsoft-Windows-User Profiles Service"
    StartTime = $startTime
} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, Message

$result.checks.bootPerfEvents = ($bootEvents | Measure-Object).Count
$result.checks.profileEvents = ($profileEvents | Measure-Object).Count

if (-not $DryRun) {
    $bootEvents | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $runFolder "boot-events.json") -Encoding UTF8
    $profileEvents | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $runFolder "profile-events.json") -Encoding UTF8
    $result.files.bootEvents = (Join-Path $runFolder "boot-events.json")
    $result.files.profileEvents = (Join-Path $runFolder "profile-events.json")
}

# Startup and scheduled tasks introduced recently
$recentServices = Get-CimInstance Win32_Service |
    Sort-Object Name |
    Select-Object Name, DisplayName, StartMode, State, PathName

$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
    Select-Object TaskName, TaskPath, State, Author

$result.checks.servicesTotal = ($recentServices | Measure-Object).Count
$result.checks.scheduledTasksTotal = ($tasks | Measure-Object).Count

if (-not $DryRun) {
    $recentServices | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $runFolder "services.json") -Encoding UTF8
    $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $runFolder "scheduled-tasks.json") -Encoding UTF8
    $result.files.services = (Join-Path $runFolder "services.json")
    $result.files.tasks = (Join-Path $runFolder "scheduled-tasks.json")
}

# Desktop shortcut state
$desktopPaths = @(
    "$env:PUBLIC\Desktop",
    "$env:USERPROFILE\Desktop"
)

$shortcutRows = foreach ($path in $desktopPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Filter *.lnk -ErrorAction SilentlyContinue |
            Select-Object @{n='DesktopPath';e={$path}}, Name, FullName, LastWriteTime
    }
}

$result.checks.desktopShortcutCount = ($shortcutRows | Measure-Object).Count

if (-not $DryRun) {
    $shortcutRows | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $runFolder "desktop-shortcuts.json") -Encoding UTF8
    $result.files.desktopShortcuts = (Join-Path $runFolder "desktop-shortcuts.json")
}

# DSREG status capture for identity context
if (-not $DryRun) {
    cmd /c "dsregcmd /status" | Set-Content -Path (Join-Path $runFolder "dsreg-status.txt") -Encoding UTF8
    gpresult /R /SCOPE COMPUTER > (Join-Path $runFolder "gpresult-computer.txt")
    gpresult /R /SCOPE USER > (Join-Path $runFolder "gpresult-user.txt")
    $result.files.dsreg = (Join-Path $runFolder "dsreg-status.txt")
    $result.files.gpComputer = (Join-Path $runFolder "gpresult-computer.txt")
    $result.files.gpUser = (Join-Path $runFolder "gpresult-user.txt")
}

$result.actions = @(
    "Compare suspect app install dates against first incident reports",
    "Correlate boot/profile event spikes with Monday sign-in times",
    "Compare gpresult and dsreg output to unaffected floor control device"
)

if (-not $DryRun) {
    $summaryPath = Join-Path $runFolder "summary.json"
    $result | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryPath -Encoding UTF8
    Write-Host "Evidence package created: $runFolder"
    Write-Host "Summary: $summaryPath"
} else {
    Write-Host "DRY RUN ONLY - planned evidence package location: $runFolder"
    $result | ConvertTo-Json -Depth 8
}
