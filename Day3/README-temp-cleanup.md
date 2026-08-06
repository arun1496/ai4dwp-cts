# Temp Cleanup Script (PowerShell 5.1)

This folder includes `temp-cleanup.ps1`, a safe temp-file cleanup script for DWP endpoint engineers.

The script supports:
- Dry run mode (shows files that would be deleted)
- Age-based filtering (`OlderThanDays`, default `0`)
- Locked-file skip behavior (logs and continues)
- Per-file `try/catch` error handling
- Timestamped logging for every action
- End-of-run summary
- Rollback using a generated manifest and backup copies
- Idempotent behavior across repeated runs

## Script File

- `temp-cleanup.ps1`

## Parameters

- `-TargetPaths <string[]>`
Default temp paths to scan:
- `$env:TEMP`
- `$env:WINDIR\Temp`

- `-OlderThanDays <int>`
Only files with `LastWriteTime` older than this many days are considered.
Default: `0`

- `-DryRun`
Lists candidate files to console and log only. No files are deleted.

- `-Rollback`
Runs rollback mode and restores files from an existing rollback manifest.

- `-RollbackManifestPath <string>`
Optional manifest CSV path for rollback. If omitted with `-Rollback`, the script uses the newest manifest in the state folder.

- `-StateFolder <string>`
Folder where backup files and rollback manifests are stored.
Default: `<script folder>\temp-cleanup-state`

- `-LogFolder <string>`
Folder where timestamped log files are created.
Default: `<script folder>\logs`

## Usage Examples

### 1) Dry run with defaults

```powershell
.\temp-cleanup.ps1 -DryRun
```

### 2) Delete only files older than 7 days

```powershell
.\temp-cleanup.ps1 -OlderThanDays 7
```

### 3) Dry run for custom paths older than 3 days

```powershell
.\temp-cleanup.ps1 -TargetPaths "C:\Windows\Temp","C:\Temp" -OlderThanDays 3 -DryRun
```

### 4) Run cleanup and create a rollback manifest file

```powershell
.\temp-cleanup.ps1 -TargetPaths "C:\Windows\Temp","C:\Temp" -OlderThanDays 3
```

Note: A rollback manifest is created only when at least one file is deleted (not in `-DryRun` mode).

### 5) Roll back using the latest available manifest

```powershell
.\temp-cleanup.ps1 -Rollback
```

### 6) Roll back using a specific manifest

```powershell
.\temp-cleanup.ps1 -Rollback -RollbackManifestPath ".\temp-cleanup-state\manifest-20260805-093000-<guid>.csv"
```

## Output and Logs

- A new log file is created for each run in the log folder:
`temp-cleanup-YYYYMMDD-HHMMSS.log`

- If files are deleted, a rollback manifest CSV is created in the state folder.

- Summary output is printed at the end with counts for:
- Paths checked
- Files scanned
- Candidate files
- Deleted files
- Dry-run listed files
- Locked skipped files
- Other skipped files
- Errors

## Safety and Idempotency Notes

- The script is file-only cleanup (no directory deletion).
- Locked files are skipped and logged; processing continues.
- Per-file errors are caught so one failure does not stop the run.
- Running the script repeatedly is idempotent:
- Already deleted files are not processed again.
- Rollback skips files that already exist at the original path.

## Recommended Operational Pattern

1. Run `-DryRun` first.
2. Validate file list and scope.
3. Run actual cleanup with desired `-OlderThanDays`.
4. Keep state folder contents until you confirm no rollback is required.
