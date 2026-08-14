[CmdletBinding()]
param(
    [string]$OutputRoot = "C:\ProgramData\Floor6Evidence",
    [datetime]$IncidentStart = [datetime]"2026-08-14T06:00:00",
    [datetime]$IncidentEnd = [datetime]"2026-08-14T14:00:00",
    [string]$SuspectAppPattern = "document|management",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-RunState {
    param(
        [string]$Root,
        [switch]$IsDryRun
    )

    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $runId = "floor6-evidence-$ts"
    $runPath = Join-Path $Root $runId

    [pscustomobject]@{
        RunId = $runId
        RunPath = $runPath
        IsDryRun = [bool]$IsDryRun
        PlannedCommands = New-Object System.Collections.Generic.List[string]
        ExecutedCommands = New-Object System.Collections.Generic.List[string]
        Errors = New-Object System.Collections.Generic.List[object]
        Files = [ordered]@{}
    }
}

function Register-Plan {
    param(
        [Parameter(Mandatory)] [object]$State,
        [Parameter(Mandatory)] [string]$CommandText
    )
    $State.PlannedCommands.Add($CommandText) | Out-Null
}

function Register-Execution {
    param(
        [Parameter(Mandatory)] [object]$State,
        [Parameter(Mandatory)] [string]$CommandText
    )
    $State.ExecutedCommands.Add($CommandText) | Out-Null
}

function Register-ErrorRecord {
    param(
        [Parameter(Mandatory)] [object]$State,
        [Parameter(Mandatory)] [string]$Step,
        [Parameter(Mandatory)] [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $State.Errors.Add([pscustomobject]@{
        step = $Step
        exceptionType = $ErrorRecord.Exception.GetType().FullName
        message = $ErrorRecord.Exception.Message
        category = $ErrorRecord.CategoryInfo.Category
    }) | Out-Null
}

function Export-JsonArtifact {
    param(
        [Parameter(Mandatory)] [object]$State,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [AllowNull()] [object]$Data
    )

    Register-Plan -State $State -CommandText "Export $Name as JSON"

    if ($State.IsDryRun) {
        return
    }

    $target = Join-Path $State.RunPath ("$Name.json")
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $target -Encoding UTF8
    $State.Files[$Name] = $target
    Register-Execution -State $State -CommandText "Wrote $target"
}

function Invoke-TextCommand {
    param(
        [Parameter(Mandatory)] [object]$State,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [scriptblock]$Command
    )

    Register-Plan -State $State -CommandText "$Name (text capture)"

    if ($State.IsDryRun) {
        return
    }

    $target = Join-Path $State.RunPath ("$Name.txt")
    $output = & $Command
    $output | Out-String | Set-Content -Path $target -Encoding UTF8
    $State.Files[$Name] = $target
    Register-Execution -State $State -CommandText "$Name captured to $target"
}

function Get-InstalledApps {
    $paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($_.PSObject.Properties.Name -contains "DisplayName" -and -not [string]::IsNullOrWhiteSpace($_.DisplayName)) {
                [pscustomobject]@{
                    DisplayName = $_.DisplayName
                    DisplayVersion = if ($_.PSObject.Properties.Name -contains "DisplayVersion") { $_.DisplayVersion } else { $null }
                    Publisher = if ($_.PSObject.Properties.Name -contains "Publisher") { $_.Publisher } else { $null }
                    InstallDate = if ($_.PSObject.Properties.Name -contains "InstallDate") { $_.InstallDate } else { $null }
                }
            }
        }
}

function Get-ProfileEvents {
    param(
        [datetime]$Start,
        [datetime]$End
    )

    try {
        Get-WinEvent -FilterHashtable @{
            LogName = "Application"
            ProviderName = "Microsoft-Windows-User Profiles Service"
            StartTime = $Start
            EndTime = $End
        } -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, Message
    }
    catch {
        @()
    }
}

function Get-DiagnosticsPerfEvents {
    param(
        [datetime]$Start,
        [datetime]$End
    )

    $ids = 100,101,102,103,200,201
    try {
        Get-WinEvent -FilterHashtable @{
            LogName = "Microsoft-Windows-Diagnostics-Performance/Operational"
            Id = $ids
            StartTime = $Start
            EndTime = $End
        } -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, Message
    }
    catch {
        @()
    }
}

function Get-DesktopShortcutState {
    $locations = @(
        "$env:PUBLIC\Desktop",
        "$env:USERPROFILE\Desktop"
    )

    foreach ($location in $locations) {
        if (-not (Test-Path -Path $location)) {
            [pscustomobject]@{
                desktopPath = $location
                status = "PathMissing"
                shortcutName = $null
                fullName = $null
                lastWriteTime = $null
            }
            continue
        }

        $lnks = Get-ChildItem -Path $location -Filter *.lnk -ErrorAction SilentlyContinue
        if (-not $lnks) {
            [pscustomobject]@{
                desktopPath = $location
                status = "NoShortcuts"
                shortcutName = $null
                fullName = $null
                lastWriteTime = $null
            }
            continue
        }

        foreach ($lnk in $lnks) {
            [pscustomobject]@{
                desktopPath = $location
                status = "ShortcutPresent"
                shortcutName = $lnk.Name
                fullName = $lnk.FullName
                lastWriteTime = $lnk.LastWriteTime
            }
        }
    }
}

$state = New-RunState -Root $OutputRoot -IsDryRun:$DryRun

$manifest = [ordered]@{
    scriptVersion = "hand-corrected-1"
    generatedFrom = "AI draft, then manually corrected"
    topRankedCause = "Change-induced Floor 6 app or policy regression causing sign-in and shell readiness degradation"
    runTimestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    incidentWindow = [ordered]@{
        start = $IncidentStart.ToString("o")
        end = $IncidentEnd.ToString("o")
    }
    dryRun = [bool]$DryRun
    device = $null
    findings = [ordered]@{}
    actions = @(
        "Correlate suspect app install dates with first affected login timestamps",
        "Compare policy evidence and sign-in events with one unaffected control device",
        "If matched, proceed with controlled rollback on 2-3 affected devices"
    )
    commandPlan = $state.PlannedCommands
    commandExecution = $state.ExecutedCommands
    files = $state.Files
    errors = $state.Errors
}

try {
    Register-Plan -State $state -CommandText "Create output folder $($state.RunPath)"
    if (-not $state.IsDryRun) {
        New-Item -Path $state.RunPath -ItemType Directory -Force | Out-Null
        Register-Execution -State $state -CommandText "Created $($state.RunPath)"
    }

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $manifest.device = [ordered]@{
        computerName = $env:COMPUTERNAME
        userName = "$($env:USERDOMAIN)\$($env:USERNAME)"
        manufacturer = $cs.Manufacturer
        model = $cs.Model
        osCaption = $os.Caption
        osVersion = $os.Version
        lastBoot = $os.LastBootUpTime
    }

    $apps = Get-InstalledApps
    $suspectApps = $apps | Where-Object { $_.DisplayName -match $SuspectAppPattern }
    $manifest.findings.appInventory = [ordered]@{
        totalApps = ($apps | Measure-Object).Count
        suspectAppPattern = $SuspectAppPattern
        suspectAppCount = ($suspectApps | Measure-Object).Count
    }
    Export-JsonArtifact -State $state -Name "apps-all" -Data $apps
    Export-JsonArtifact -State $state -Name "apps-suspect" -Data $suspectApps

    $diagEvents = Get-DiagnosticsPerfEvents -Start $IncidentStart -End $IncidentEnd
    $profileEvents = Get-ProfileEvents -Start $IncidentStart -End $IncidentEnd
    $manifest.findings.signInEvidence = [ordered]@{
        diagnosticsPerfEventCount = ($diagEvents | Measure-Object).Count
        profileServiceEventCount = ($profileEvents | Measure-Object).Count
    }
    Export-JsonArtifact -State $state -Name "events-diagnostics-performance" -Data $diagEvents
    Export-JsonArtifact -State $state -Name "events-user-profile-service" -Data $profileEvents

    $services = Get-CimInstance -ClassName Win32_Service |
        Select-Object Name, DisplayName, StartMode, State, PathName
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
        Select-Object TaskName, TaskPath, State, Author
    $manifest.findings.startupSurface = [ordered]@{
        servicesCount = ($services | Measure-Object).Count
        scheduledTasksCount = ($tasks | Measure-Object).Count
    }
    Export-JsonArtifact -State $state -Name "services" -Data $services
    Export-JsonArtifact -State $state -Name "scheduled-tasks" -Data $tasks

    $shortcutState = Get-DesktopShortcutState
    $manifest.findings.desktopShortcutState = [ordered]@{
        rowCount = ($shortcutState | Measure-Object).Count
        missingPathCount = ($shortcutState | Where-Object { $_.status -eq "PathMissing" } | Measure-Object).Count
        noShortcutPathCount = ($shortcutState | Where-Object { $_.status -eq "NoShortcuts" } | Measure-Object).Count
    }
    Export-JsonArtifact -State $state -Name "desktop-shortcuts" -Data $shortcutState

    Invoke-TextCommand -State $state -Name "dsreg-status" -Command { cmd /c "dsregcmd /status" }
    Invoke-TextCommand -State $state -Name "gpresult-computer" -Command { gpresult /R /SCOPE COMPUTER }
    Invoke-TextCommand -State $state -Name "gpresult-user" -Command { gpresult /R /SCOPE USER }
}
catch {
    Register-ErrorRecord -State $state -Step "collection" -ErrorRecord $_
}
finally {
    $manifest.commandPlan = $state.PlannedCommands
    $manifest.commandExecution = $state.ExecutedCommands
    $manifest.files = $state.Files
    $manifest.errors = $state.Errors

    if ($state.IsDryRun) {
        $manifest | ConvertTo-Json -Depth 12
    } else {
        $manifestPath = Join-Path $state.RunPath "evidence-manifest.json"
        $manifest | ConvertTo-Json -Depth 12 | Set-Content -Path $manifestPath -Encoding UTF8
        Write-Output "Evidence package path: $($state.RunPath)"
        Write-Output "Manifest path: $manifestPath"
    }
}
