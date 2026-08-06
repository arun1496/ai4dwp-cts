# Event Log Archive and Cleanup Script (PowerShell 5.1)

This folder includes `eventlog-archive-cleanup.ps1`, a safe Windows endpoint script for DWP engineers to archive and clean stale Windows event logs.

The script supports:
- Dry run mode that reports the number of records that would be deleted
- Age-based targeting of logs (`OlderThanDays`, default `3`)
- Per-operation `try/catch` error handling
- Timestamped run logging for every action
- End-of-run summary output
- Rollback mode based on generated manifest data
- Idempotent behavior (skips a log when today's archive already exists)

## Script File

- `eventlog-archive-cleanup.ps1`

## Parameters

- `-LogNames <string[]>`
Log channels/patterns to evaluate.
Default: `'*'`

- `-OlderThanDays <int>`
Only logs with `LastWriteTime` older than this many days are candidates.
Default: `3`

- `-DryRun`
Prints how many records would be deleted and logs candidate details.
No archive or clear operation is performed.

- `-Rollback`
Runs rollback mode using a manifest.
Rollback restores archive files to a restore folder for recovery/audit workflows.

- `-RollbackManifestPath <string>`
Optional path to a specific manifest CSV.
If omitted with `-Rollback`, the newest manifest in the state folder is used.

- `-StateFolder <string>`
Stores archives and manifests.
Default: `<script folder>\eventlog-state`

- `-LogFolder <string>`
Stores timestamped script log files.
Default: `<script folder>\logs`

## Usage Examples

### 1) Dry run with defaults

```powershell
.\eventlog-archive-cleanup.ps1 -DryRun
```

### 2) Cleanup logs older than 7 days

```powershell
.\eventlog-archive-cleanup.ps1 -OlderThanDays 7
```

### 3) Dry run for selected logs only

```powershell
.\eventlog-archive-cleanup.ps1 -LogNames "Application","System" -OlderThanDays 5 -DryRun
```

Note: If `Application` or `System` has recent writes, dry run may return `0` candidates. This is expected because the filter uses log `LastWriteTime` (log-level activity), not age of individual records.

### 4) Cleanup selected logs and create manifest

```powershell
.\eventlog-archive-cleanup.ps1 -LogNames "Application","System" -OlderThanDays 5
```

### 5) Rollback using latest manifest

```powershell
.\eventlog-archive-cleanup.ps1 -Rollback
```

### 6) Rollback using a specific manifest

```powershell
.\eventlog-archive-cleanup.ps1 -Rollback -RollbackManifestPath ".\eventlog-state\manifest-20260805-090000-<guid>.csv"
```

## Output and Logs

- A new run log is created in the log folder:
`eventlog-archive-cleanup-YYYYMMDD-HHMMSS.log`

- Archive files are created per log in:
`<script folder>\eventlog-state\archives`

- If at least one log is archived and cleared, a manifest CSV is created in:
`<script folder>\eventlog-state`

- Summary includes counts for:
- Logs evaluated
- Candidate logs
- Candidate records
- Archived logs
- Cleared logs
- Dry-run logs
- Dry-run records
- Already archived today
- Skipped logs
- Rollback restored
- Errors

## Safety and Idempotency Notes

- The script archives each candidate log before clearing.
- A log is skipped when today's archive file already exists.
- Re-running the script on the same day is idempotent for already archived logs.
- `-DryRun` should be executed first for validation.

## Rollback Limitation

- Windows does not natively support re-inserting `.evtx` backup records directly into built-in live event channels.
- Rollback mode restores archive files to a restore folder so engineers can recover exported evidence and audit data.

## Recommended Operational Pattern

1. Run `-DryRun` first.
2. Validate candidate counts and target scope.
3. Run actual cleanup with desired `-OlderThanDays`.
4. Keep `eventlog-state` contents until rollback is no longer needed.

## Quick Troubleshooting

- Dry run shows `0` candidates for active channels:
Use a wider scope (`-LogNames "*"`) or increase `-OlderThanDays` and rerun dry run.
- Verify behavior in summary counters:
`SkippedLogs` increases when logs are recent, and `Errors` should remain `0` for a healthy run.
