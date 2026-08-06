<#
.SYNOPSIS
Archives and cleans stale Windows Event Logs with dry-run, logging, rollback metadata, and idempotent behavior.

.DESCRIPTION
- Finds enabled event logs whose newest write time is older than a cutoff date.
- In dry-run mode, reports how many records would be archived/cleared.
- Archives each target log to an .evtx file before clearing it.
- Skips processing when today's archive file already exists (idempotent behavior).
- Logs every action to a timestamped log file.
- Supports rollback mode to recover archived files from manifest data.

.NOTES
PowerShell 5.1 compatible.
Important platform limitation:
Windows does not provide a native way to re-insert archived records back into live built-in channels.
Rollback mode restores archive files for recovery/audit workflows.
#>

[CmdletBinding()]
param (
    # Log names to evaluate. Default '*' means all logs visible to the current account.
    [Parameter(Mandatory = $false)]
    [string[]]$LogNames = @('*'),

    # Only logs older than this many days (based on log LastWriteTime) are targeted.
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 36500)]
    [int]$OlderThanDays = 3,

    # Dry run mode: calculates and prints counts only; no archive/clear action.
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    # Rollback mode: uses a manifest to restore archived files into a restore folder.
    [Parameter(Mandatory = $false)]
    [switch]$Rollback,

    # Optional manifest path for rollback. If omitted, newest manifest in state folder is used.
    [Parameter(Mandatory = $false)]
    [string]$RollbackManifestPath,

    # Folder that stores archive files and manifests.
    [Parameter(Mandatory = $false)]
    [string]$StateFolder = (Join-Path -Path $PSScriptRoot -ChildPath 'eventlog-state'),

    # Folder where timestamped logs are written.
    [Parameter(Mandatory = $false)]
    [string]$LogFolder = (Join-Path -Path $PSScriptRoot -ChildPath 'logs')
)

# ---------------------------
# Section: Initialization
# Creates run metadata, required directories, and common output helpers.
# ---------------------------
$runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$todayStamp = Get-Date -Format 'yyyyMMdd'
$runId = [guid]::NewGuid().ToString()
$cutoffDate = (Get-Date).AddDays(-$OlderThanDays)

if (-not (Test-Path -LiteralPath $StateFolder)) {
    try {
        New-Item -Path $StateFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Failed to create state folder '$StateFolder'. $($_.Exception.Message)"
    }
}

if (-not (Test-Path -LiteralPath $LogFolder)) {
    try {
        New-Item -Path $LogFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Failed to create log folder '$LogFolder'. $($_.Exception.Message)"
    }
}

$archiveFolder = Join-Path -Path $StateFolder -ChildPath 'archives'
if (-not (Test-Path -LiteralPath $archiveFolder)) {
    try {
        New-Item -Path $archiveFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Failed to create archive folder '$archiveFolder'. $($_.Exception.Message)"
    }
}

$logPath = Join-Path -Path $LogFolder -ChildPath ("eventlog-archive-cleanup-{0}.log" -f $runTimestamp)

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Level, $Message

    try {
        Add-Content -LiteralPath $logPath -Value $line -ErrorAction Stop
    }
    catch {
        Write-Host "{0} [ERROR] Failed to write log file: {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $_.Exception.Message
    }

    Write-Host $line
}

function Convert-ToSafeFileName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    # Replace filename-invalid characters and separators used in event channel names.
    $safe = $Name -replace '[\\/:*?"<>|]', '_' -replace '\s+', '_'
    return $safe
}

function Get-LatestManifest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$BaseStateFolder
    )

    try {
        if (-not (Test-Path -LiteralPath $BaseStateFolder)) {
            return $null
        }

        $manifest = Get-ChildItem -LiteralPath $BaseStateFolder -Filter 'manifest-*.csv' -File -ErrorAction Stop |
            Sort-Object -Property LastWriteTime -Descending |
            Select-Object -First 1

        if ($manifest) {
            return $manifest.FullName
        }

        return $null
    }
    catch {
        return $null
    }
}

# ---------------------------
# Section: Summary Model
# Tracks all counters that are printed at the end of the run.
# ---------------------------
$summary = [ordered]@{
    LogsEvaluated        = 0
    CandidateLogs        = 0
    CandidateRecords     = 0
    ArchivedLogs         = 0
    ClearedLogs          = 0
    DryRunLogs           = 0
    DryRunRecords        = 0
    AlreadyArchivedToday = 0
    SkippedLogs          = 0
    RollbackRestored     = 0
    Errors               = 0
}

# ---------------------------
# Section: Rollback Execution
# Restores archive files listed in a manifest to a timestamped restore folder.
# ---------------------------
function Invoke-Rollback {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    Write-Log -Message ("Rollback requested. Manifest: {0}" -f $ManifestPath)

    try {
        if (-not (Test-Path -LiteralPath $ManifestPath)) {
            throw "Rollback manifest not found: $ManifestPath"
        }
    }
    catch {
        Write-Log -Level 'ERROR' -Message $_.Exception.Message
        $summary.Errors++
        return
    }

    $restoreFolder = Join-Path -Path $StateFolder -ChildPath ("rollback-restored-{0}-{1}" -f $runTimestamp, $runId)
    try {
        New-Item -Path $restoreFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Log -Message ("Created rollback restore folder: {0}" -f $restoreFolder)
    }
    catch {
        Write-Log -Level 'ERROR' -Message ("Failed to create rollback restore folder. {0}" -f $_.Exception.Message)
        $summary.Errors++
        return
    }

    $entries = @()
    try {
        $entries = Import-Csv -LiteralPath $ManifestPath -ErrorAction Stop
    }
    catch {
        Write-Log -Level 'ERROR' -Message ("Failed to read manifest CSV. {0}" -f $_.Exception.Message)
        $summary.Errors++
        return
    }

    if (-not $entries -or $entries.Count -eq 0) {
        Write-Log -Level 'WARN' -Message 'Manifest has no rows. Nothing to restore.'
        return
    }

    foreach ($entry in $entries) {
        $archivePath = $entry.ArchivePath
        $logName = $entry.LogName

        try {
            if (-not (Test-Path -LiteralPath $archivePath)) {
                $summary.SkippedLogs++
                Write-Log -Level 'WARN' -Message ("Archive missing for rollback; skipped log '{0}'. File: {1}" -f $logName, $archivePath)
                continue
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Error checking archive path '{0}'. {1}" -f $archivePath, $_.Exception.Message)
            continue
        }

        $destName = [System.IO.Path]::GetFileName($archivePath)
        $destPath = Join-Path -Path $restoreFolder -ChildPath $destName

        try {
            Copy-Item -LiteralPath $archivePath -Destination $destPath -Force -ErrorAction Stop
            $summary.RollbackRestored++
            Write-Log -Message ("Rollback restored archive copy for log '{0}' to '{1}'" -f $logName, $destPath)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Rollback copy failed for log '{0}'. {1}" -f $logName, $_.Exception.Message)
        }
    }

    Write-Log -Level 'WARN' -Message 'Rollback restored archive files for audit/recovery. Native Windows event channels cannot be repopulated from .evtx backups automatically.'
}

# ---------------------------
# Section: Rollback Router
# Selects a manifest and executes rollback mode when requested.
# ---------------------------
if ($Rollback) {
    try {
        $manifestToUse = $RollbackManifestPath
        if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
            $manifestToUse = Get-LatestManifest -BaseStateFolder $StateFolder
        }

        if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
            throw 'No rollback manifest available. Provide -RollbackManifestPath or run cleanup first.'
        }

        Invoke-Rollback -ManifestPath $manifestToUse
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Rollback execution failed. {0}" -f $_.Exception.Message)
    }

    Write-Log -Message 'Run summary (rollback mode):'
    foreach ($k in $summary.Keys) {
        Write-Log -Message ("  {0}: {1}" -f $k, $summary[$k])
    }

    if ($summary.Errors -gt 0) {
        exit 1
    }

    exit 0
}

# ---------------------------
# Section: Log Enumeration
# Lists logs and keeps only enabled logs older than cutoff with at least one record.
# ---------------------------
$logInfos = New-Object System.Collections.Generic.List[object]

foreach ($pattern in $LogNames) {
    try {
        $list = Get-WinEvent -ListLog $pattern -ErrorAction Stop
        foreach ($log in $list) {
            $logInfos.Add($log)
        }
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed to enumerate logs for pattern '{0}'. {1}" -f $pattern, $_.Exception.Message)
    }
}

if ($logInfos.Count -eq 0) {
    Write-Log -Level 'WARN' -Message 'No logs found to evaluate.'
}

$uniqueLogs = $logInfos |
    Group-Object -Property LogName |
    ForEach-Object { $_.Group | Select-Object -First 1 }

$candidates = New-Object System.Collections.Generic.List[object]

foreach ($log in $uniqueLogs) {
    $summary.LogsEvaluated++

    try {
        if (-not $log.IsEnabled) {
            $summary.SkippedLogs++
            Write-Log -Level 'WARN' -Message ("Skipping disabled log: {0}" -f $log.LogName)
            continue
        }
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed to read IsEnabled for log object. {0}" -f $_.Exception.Message)
        continue
    }

    try {
        $recordCount = [long]$log.RecordCount
        if ($recordCount -le 0) {
            $summary.SkippedLogs++
            Write-Log -Message ("Skipping empty log: {0}" -f $log.LogName)
            continue
        }
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed to read RecordCount for '{0}'. {1}" -f $log.LogName, $_.Exception.Message)
        continue
    }

    try {
        if (-not $log.LastWriteTime) {
            $summary.SkippedLogs++
            Write-Log -Level 'WARN' -Message ("Skipping log with no LastWriteTime: {0}" -f $log.LogName)
            continue
        }

        if ($log.LastWriteTime -ge $cutoffDate) {
            $summary.SkippedLogs++
            Write-Log -Message ("Skipping recent log: {0} (LastWriteTime={1})" -f $log.LogName, $log.LastWriteTime)
            continue
        }
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed to evaluate age for '{0}'. {1}" -f $log.LogName, $_.Exception.Message)
        continue
    }

    $summary.CandidateLogs++
    $summary.CandidateRecords += $recordCount
    $candidates.Add($log)
}

# ---------------------------
# Section: Dry-Run Report
# Prints counts of records that would be deleted and exits safely.
# ---------------------------
if ($DryRun) {
    $summary.DryRunLogs = $summary.CandidateLogs
    $summary.DryRunRecords = $summary.CandidateRecords

    if ($summary.DryRunLogs -eq 0) {
        Write-Log -Message ("No candidate logs matched the age filter (OlderThanDays={0}, CutoffDate={1}). This is expected when selected logs have recent activity." -f $OlderThanDays, $cutoffDate)
    }

    Write-Log -Message ("Dry run: {0} log(s) would be cleared, deleting {1} total record(s)." -f $summary.DryRunLogs, $summary.DryRunRecords)

    foreach ($log in $candidates) {
        try {
            Write-Log -Message ("Dry run candidate: Log='{0}', RecordCount={1}, LastWriteTime={2}" -f $log.LogName, [long]$log.RecordCount, $log.LastWriteTime)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Dry run reporting error. {0}" -f $_.Exception.Message)
        }
    }

    Write-Log -Message 'Run summary (dry run mode):'
    foreach ($k in $summary.Keys) {
        Write-Log -Message ("  {0}: {1}" -f $k, $summary[$k])
    }

    if ($summary.Errors -gt 0) {
        exit 1
    }

    exit 0
}

# ---------------------------
# Section: Archive and Clear
# Archives each candidate log and clears it only after a successful archive.
# ---------------------------
$manifestRows = New-Object System.Collections.Generic.List[object]

foreach ($log in $candidates) {
    $logName = $log.LogName
    $recordCount = [long]$log.RecordCount

    $safeName = $null
    try {
        $safeName = Convert-ToSafeFileName -Name $logName
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed to create safe filename for '{0}'. {1}" -f $logName, $_.Exception.Message)
        continue
    }

    $archivePath = Join-Path -Path $archiveFolder -ChildPath ("{0}-{1}.evtx" -f $safeName, $todayStamp)

    try {
        if (Test-Path -LiteralPath $archivePath) {
            $summary.AlreadyArchivedToday++
            Write-Log -Message ("Skipping log '{0}' because today's archive already exists: {1}" -f $logName, $archivePath)
            continue
        }
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Archive path check failed for '{0}'. {1}" -f $logName, $_.Exception.Message)
        continue
    }

    try {
        Write-Log -Message ("Archiving log '{0}' to '{1}'" -f $logName, $archivePath)
        & wevtutil epl "$logName" "$archivePath" 2>$null

        if ($LASTEXITCODE -ne 0) {
            throw "wevtutil epl returned exit code $LASTEXITCODE"
        }

        if (-not (Test-Path -LiteralPath $archivePath)) {
            throw 'Archive file was not created.'
        }

        $summary.ArchivedLogs++
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Archive failed for '{0}'. {1}" -f $logName, $_.Exception.Message)
        continue
    }

    try {
        Write-Log -Message ("Clearing log '{0}'" -f $logName)
        & wevtutil cl "$logName" 2>$null

        if ($LASTEXITCODE -ne 0) {
            throw "wevtutil cl returned exit code $LASTEXITCODE"
        }

        $summary.ClearedLogs++

        $row = [pscustomobject]@{
            RunTimestamp = $runTimestamp
            RunId        = $runId
            LogName      = $logName
            RecordCount  = $recordCount
            LastWriteTime= $log.LastWriteTime
            ArchivePath  = $archivePath
            ClearedAt    = (Get-Date)
        }
        $manifestRows.Add($row)
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Clear failed for '{0}'. {1}" -f $logName, $_.Exception.Message)
    }
}

# ---------------------------
# Section: Manifest Output
# Writes manifest rows for successful archive/clear operations.
# ---------------------------
if ($manifestRows.Count -gt 0) {
    $manifestPath = Join-Path -Path $StateFolder -ChildPath ("manifest-{0}-{1}.csv" -f $runTimestamp, $runId)

    try {
        $manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-Log -Message ("Manifest written: {0}" -f $manifestPath)
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed to write manifest. {0}" -f $_.Exception.Message)
    }
}
else {
    Write-Log -Level 'WARN' -Message 'No successful archive/clear operations; manifest not created.'
}

# ---------------------------
# Section: Final Summary
# Prints end-of-run metrics for operator review and auditing.
# ---------------------------
Write-Log -Message 'Run summary:'
foreach ($k in $summary.Keys) {
    Write-Log -Message ("  {0}: {1}" -f $k, $summary[$k])
}

if ($summary.Errors -gt 0) {
    exit 1
}

exit 0
