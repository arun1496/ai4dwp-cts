<#
.SYNOPSIS
Safely cleans temporary files on Windows endpoints with logging, dry-run, and rollback support.

.DESCRIPTION
- Targets files in temp paths.
- Deletes only files older than the configured age in days.
- Supports dry run mode to list files that would be deleted.
- Skips locked files and logs the reason.
- Creates a per-run rollback manifest and backup copies before deletion.
- Reports a summary at the end.

.NOTES
PowerShell 5.1 compatible.
#>

[CmdletBinding()]
param (
	# Temp locations to scan.
	[Parameter(Mandatory = $false)]
	[string[]]$TargetPaths = @(
		$env:TEMP,
		(Join-Path -Path $env:WINDIR -ChildPath 'Temp')
	),

	# Only files older than this number of days are considered.
	[Parameter(Mandatory = $false)]
	[ValidateRange(0, 36500)]
	[int]$OlderThanDays = 0,

	# Dry run mode: do not delete, only print/log what would be deleted.
	[Parameter(Mandatory = $false)]
	[switch]$DryRun,

	# Roll back a prior cleanup operation using a manifest.
	[Parameter(Mandatory = $false)]
	[switch]$Rollback,

	# Path to a specific rollback manifest CSV file.
	[Parameter(Mandatory = $false)]
	[string]$RollbackManifestPath,

	# Folder that stores backup files and manifests.
	[Parameter(Mandatory = $false)]
	[string]$StateFolder = (Join-Path -Path $PSScriptRoot -ChildPath 'temp-cleanup-state'),

	# Folder for timestamped log files.
	[Parameter(Mandatory = $false)]
	[string]$LogFolder = (Join-Path -Path $PSScriptRoot -ChildPath 'logs')
)

# ---------------------------
# Section: Initialization
# Creates run identifiers, required folders, and logging helpers.
# ---------------------------
$runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runId = [guid]::NewGuid().ToString()

if (-not (Test-Path -LiteralPath $StateFolder)) {
	New-Item -Path $StateFolder -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $LogFolder)) {
	New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

$logPath = Join-Path -Path $LogFolder -ChildPath ("temp-cleanup-{0}.log" -f $runTimestamp)

function Write-Log {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message,

		[Parameter(Mandatory = $false)]
		[ValidateSet('INFO', 'WARN', 'ERROR')]
		[string]$Level = 'INFO'
	)

	$line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Level, $Message
	Add-Content -LiteralPath $logPath -Value $line
	Write-Host $line
}

# ---------------------------
# Section: Utility Functions
# Provides file lock checks and helper methods used by cleanup and rollback.
# ---------------------------
function Test-FileLocked {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	try {
		$stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
		$stream.Close()
		return $false
	}
	catch {
		return $true
	}
}

function Get-LatestManifest {
	param (
		[Parameter(Mandatory = $true)]
		[string]$BaseStateFolder
	)

	if (-not (Test-Path -LiteralPath $BaseStateFolder)) {
		return $null
	}

	$manifest = Get-ChildItem -LiteralPath $BaseStateFolder -Filter 'manifest-*.csv' -File -ErrorAction SilentlyContinue |
		Sort-Object -Property LastWriteTime -Descending |
		Select-Object -First 1

	if ($manifest) {
		return $manifest.FullName
	}

	return $null
}

# ---------------------------
# Section: Rollback Execution
# Restores deleted files from backup copies listed in a manifest.
# ---------------------------
function Invoke-Rollback {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ManifestPath
	)

	Write-Log -Message ("Rollback requested. Manifest: {0}" -f $ManifestPath)

	if (-not (Test-Path -LiteralPath $ManifestPath)) {
		throw "Rollback manifest not found: $ManifestPath"
	}

	$entries = Import-Csv -LiteralPath $ManifestPath
	if (-not $entries -or $entries.Count -eq 0) {
		Write-Log -Level 'WARN' -Message 'Manifest is empty. Nothing to roll back.'
		return
	}

	$restored = 0
	$skipped = 0
	$errors = 0

	foreach ($entry in $entries) {
		$originalPath = $entry.OriginalPath
		$backupPath = $entry.BackupPath

		try {
			if (Test-Path -LiteralPath $originalPath) {
				$skipped++
				Write-Log -Level 'WARN' -Message ("Skip restore (already exists): {0}" -f $originalPath)
				continue
			}

			if (-not (Test-Path -LiteralPath $backupPath)) {
				$skipped++
				Write-Log -Level 'WARN' -Message ("Skip restore (backup missing): {0}" -f $backupPath)
				continue
			}

			$parent = Split-Path -Path $originalPath -Parent
			if (-not (Test-Path -LiteralPath $parent)) {
				New-Item -Path $parent -ItemType Directory -Force | Out-Null
				Write-Log -Message ("Created restore folder: {0}" -f $parent)
			}

			Copy-Item -LiteralPath $backupPath -Destination $originalPath -Force -ErrorAction Stop
			$restored++
			Write-Log -Message ("Restored: {0}" -f $originalPath)
		}
		catch {
			$errors++
			Write-Log -Level 'ERROR' -Message ("Rollback error for {0}. {1}" -f $originalPath, $_.Exception.Message)
		}
	}

	Write-Log -Message ('Rollback summary: Restored={0}, Skipped={1}, Errors={2}' -f $restored, $skipped, $errors)
}

# ---------------------------
# Section: Rollback Mode Router
# Determines manifest file and executes rollback when requested.
# ---------------------------
if ($Rollback) {
	try {
		$manifestToUse = $RollbackManifestPath
		if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
			$manifestToUse = Get-LatestManifest -BaseStateFolder $StateFolder
		}

		if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
			throw 'No rollback manifest available. Provide -RollbackManifestPath or run a cleanup first.'
		}

		Invoke-Rollback -ManifestPath $manifestToUse
		exit 0
	}
	catch {
		Write-Log -Level 'ERROR' -Message ("Rollback failed. {0}" -f $_.Exception.Message)
		exit 1
	}
}

# ---------------------------
# Section: Cleanup Setup
# Prepares cutoff date, backup folders, manifest path, and counters.
# ---------------------------
$cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
$backupRoot = Join-Path -Path $StateFolder -ChildPath ("backup-{0}-{1}" -f $runTimestamp, $runId)
$manifestPath = Join-Path -Path $StateFolder -ChildPath ("manifest-{0}-{1}.csv" -f $runTimestamp, $runId)

New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null

$summary = [ordered]@{
	PathsChecked    = 0
	FilesScanned    = 0
	CandidateFiles  = 0
	DeletedFiles    = 0
	DryRunFiles     = 0
	LockedFiles     = 0
	SkippedFiles    = 0
	Errors          = 0
}

$manifestRows = New-Object System.Collections.Generic.List[object]

Write-Log -Message ("Cleanup started. DryRun={0}; OlderThanDays={1}; CutoffDate={2}" -f [bool]$DryRun, $OlderThanDays, $cutoffDate)

# ---------------------------
# Section: File Discovery and Processing
# Enumerates candidate files and processes each one with per-file try/catch.
# ---------------------------
foreach ($targetPath in $TargetPaths) {
	$summary.PathsChecked++

	if ([string]::IsNullOrWhiteSpace($targetPath)) {
		Write-Log -Level 'WARN' -Message 'Skipping empty target path entry.'
		continue
	}

	if (-not (Test-Path -LiteralPath $targetPath)) {
		Write-Log -Level 'WARN' -Message ("Target path not found: {0}" -f $targetPath)
		continue
	}

	Write-Log -Message ("Scanning target path: {0}" -f $targetPath)

	$files = Get-ChildItem -LiteralPath $targetPath -Recurse -File -Force -ErrorAction SilentlyContinue |
		Where-Object { $_.LastWriteTime -lt $cutoffDate }

	foreach ($file in $files) {
		$summary.FilesScanned++
		$summary.CandidateFiles++

		if ($DryRun) {
			$summary.DryRunFiles++
			Write-Output $file.FullName
			Write-Log -Message ("DRY-RUN would delete: {0}" -f $file.FullName)
			continue
		}

		# Per-file processing to ensure one failure does not stop the run.
		try {
			if (Test-FileLocked -Path $file.FullName) {
				$summary.LockedFiles++
				Write-Log -Level 'WARN' -Message ("Locked file skipped: {0}" -f $file.FullName)
				continue
			}

			$safeName = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($file.FullName)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
			$backupPath = Join-Path -Path $backupRoot -ChildPath ($safeName + '.bak')

			Copy-Item -LiteralPath $file.FullName -Destination $backupPath -Force -ErrorAction Stop
			Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop

			$manifestRows.Add([pscustomobject]@{
				OriginalPath      = $file.FullName
				BackupPath        = $backupPath
				DeletedUtc        = (Get-Date).ToUniversalTime().ToString('o')
				OriginalLength    = $file.Length
				OriginalWriteTime = $file.LastWriteTimeUtc.ToString('o')
			}) | Out-Null

			$summary.DeletedFiles++
			Write-Log -Message ("Deleted (backup retained): {0}" -f $file.FullName)
		}
		catch {
			$errorMessage = $_.Exception.Message
			if ($errorMessage -match 'being used by another process|used by another process|The process cannot access the file') {
				$summary.LockedFiles++
				Write-Log -Level 'WARN' -Message ("Locked file skipped during delete attempt: {0}. {1}" -f $file.FullName, $errorMessage)
				continue
			}

			$summary.Errors++
			Write-Log -Level 'ERROR' -Message ("Error processing file: {0}. {1}" -f $file.FullName, $errorMessage)
		}
	}
}

# ---------------------------
# Section: Manifest Persistence
# Saves rollback metadata for files that were successfully deleted.
# ---------------------------
if ($manifestRows.Count -gt 0) {
	$manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
	Write-Log -Message ("Rollback manifest created: {0}" -f $manifestPath)
}
else {
	$summary.SkippedFiles++
	Write-Log -Level 'WARN' -Message 'No files were deleted. Manifest not created.'
}

# ---------------------------
# Section: Final Summary
# Prints a concise summary of work completed and where logs/manifests are stored.
# ---------------------------
Write-Host ''
Write-Host '=== Temp Cleanup Summary ===' -ForegroundColor Cyan
Write-Host ('Paths checked      : {0}' -f $summary.PathsChecked)
Write-Host ('Files scanned      : {0}' -f $summary.FilesScanned)
Write-Host ('Candidate files    : {0}' -f $summary.CandidateFiles)
Write-Host ('Deleted files      : {0}' -f $summary.DeletedFiles)
Write-Host ('Dry-run listed     : {0}' -f $summary.DryRunFiles)
Write-Host ('Locked skipped     : {0}' -f $summary.LockedFiles)
Write-Host ('Other skipped      : {0}' -f $summary.SkippedFiles)
Write-Host ('Errors             : {0}' -f $summary.Errors)
Write-Host ('Log file           : {0}' -f $logPath)
if ($manifestRows.Count -gt 0) {
	Write-Host ('Rollback manifest  : {0}' -f $manifestPath)
}
Write-Host '============================'

Write-Log -Message ('Cleanup summary: PathsChecked={0}, FilesScanned={1}, Candidates={2}, Deleted={3}, DryRun={4}, Locked={5}, Skipped={6}, Errors={7}' -f $summary.PathsChecked, $summary.FilesScanned, $summary.CandidateFiles, $summary.DeletedFiles, $summary.DryRunFiles, $summary.LockedFiles, $summary.SkippedFiles, $summary.Errors)
