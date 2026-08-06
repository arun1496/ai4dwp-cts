# endpoint-health-report.ps1
# Purpose: Read-only endpoint health report for DWP engineers (PowerShell 5.1 compatible).
# Safety: This script only reads system information and writes output to the console.

# ---------------------------
# Section: Report Header
# This section prints a simple header and timestamp for when the report was generated.
# ---------------------------
Write-Host "=== DWP Endpoint Health Report ===" -ForegroundColor Cyan
Write-Host ("Generated: {0}" -f (Get-Date))
Write-Host ""

# ---------------------------
# Section: System Uptime
# This section reads the OS last boot time and calculates current uptime.
# ---------------------------
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = $os.LastBootUpTime
$uptime = (Get-Date) - $lastBoot

Write-Host "[System Uptime]" -ForegroundColor Yellow
Write-Host ("Last Boot Time : {0}" -f $lastBoot)
Write-Host ("Uptime         : {0} days {1} hours {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
Write-Host ""

# ---------------------------
# Section: Free Disk Space
# This section reads local fixed disks and shows total and free space.
# ---------------------------
# VERIFY: Confirm you only want fixed local disks (DriveType = 3).
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
                  @{Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) }},
                  @{Name = 'FreeGB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) }},
                  @{Name = 'FreePercent'; Expression = { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) }}

Write-Host "[Free Disk Space]" -ForegroundColor Yellow
$disks | Format-Table -AutoSize
Write-Host ""

# ---------------------------
# Section: Pending Reboot Check (Registry)
# This section checks common registry indicators that Windows uses for pending reboot states.
# ---------------------------
# VERIFY: Confirm these registry keys/values match your organization's reboot criteria.
$rebootChecks = [ordered]@{
    'CBS RebootPending'                = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    'WindowsUpdate RebootRequired'     = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    'SessionManager PendingFileRename' = $null
}

# VERIFY: PendingFileRenameOperations can be absent; absence usually means no pending file rename reboot trigger.
$sessionManager = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction SilentlyContinue
$rebootChecks['SessionManager PendingFileRename'] = [bool]($sessionManager.PendingFileRenameOperations)

$pendingReboot = $rebootChecks.Values -contains $true

Write-Host "[Pending Reboot (Registry)]" -ForegroundColor Yellow
$rebootChecks.GetEnumerator() | ForEach-Object {
    Write-Host ("{0}: {1}" -f $_.Key, $_.Value)
}
Write-Host ("Overall Pending Reboot: {0}" -f $pendingReboot)
Write-Host ""

# ---------------------------
# Section: Top 5 Processes by Memory (Working Set)
# This section reads running processes and lists the highest working set memory consumers.
# ---------------------------
# VERIFY: ExecutablePath may be unavailable for some protected/system processes.
$topMemory = Get-Process |
    Sort-Object -Property WorkingSet -Descending |
    Select-Object -First 5 ProcessName,
                         Id,
                         @{Name = 'ExecutablePath'; Expression = {
                             $process = Get-CimInstance -ClassName Win32_Process -Filter ("ProcessId = {0}" -f $_.Id) -ErrorAction SilentlyContinue
                             $process.ExecutablePath
                         }},
                         @{Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) }}

Write-Host "[Top 5 Processes by Memory (Working Set)]" -ForegroundColor Yellow
$topMemory | Format-Table -AutoSize
Write-Host ""

# ---------------------------
# Section: Top 5 Processes by CPU
# This section reads process CPU time (seconds since process start) and lists the top 5.
# ---------------------------
# VERIFY: CPU is cumulative process time, not instantaneous utilization percent.
$topCpu = Get-Process |
    Where-Object { $_.CPU -ne $null } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 ProcessName,
                         Id,
                         @{Name = 'ExecutablePath'; Expression = {
                             $process = Get-CimInstance -ClassName Win32_Process -Filter ("ProcessId = {0}" -f $_.Id) -ErrorAction SilentlyContinue
                             $process.ExecutablePath
                         }},
                         @{Name = 'CPUSeconds'; Expression = { [math]::Round($_.CPU, 2) }}

Write-Host "[Top 5 Processes by CPU]" -ForegroundColor Yellow
$topCpu | Format-Table -AutoSize
Write-Host ""

# ---------------------------
# Section: Last 5 System Log Errors
# This section reads the Windows System event log and shows the five most recent error events.
# ---------------------------
# VERIFY: Confirm 'System' log and Level=2 (Error) align with your support/reporting expectations.
$lastSystemErrors = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, ProviderName, Message

Write-Host "[Last 5 System Log Errors]" -ForegroundColor Yellow
if ($lastSystemErrors) {
    $lastSystemErrors | Format-List
}
else {
    Write-Host "No system error events found or access was denied."
}

Write-Host ""
Write-Host "=== End of Report ===" -ForegroundColor Cyan
