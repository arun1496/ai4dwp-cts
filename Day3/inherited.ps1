<#
.SYNOPSIS
Read-only endpoint snapshot for basic system visibility.

.DESCRIPTION
Collects and displays the computer name, total physical memory, free space on drive C,
the top five processes by memory usage, recent System event log errors, and the count
of stale user profiles older than 90 days.

.NOTES
Author: GitHub Copilot
Compatibility: PowerShell 5.1+
Behavior: Read-only. This script does not modify system settings or files.

.HOW TO RUN
Open PowerShell and run:
.
\inherited.ps1

Or from another location run:
& 'c:\Users\labuser\Documents\Training\Day3\inherited.ps1'
#>

# Retrieve general computer system information such as the machine name and total RAM.
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem

# Retrieve the number of free bytes currently available on the C drive.
$freeSpaceBytes = Get-PSDrive -Name C | Select-Object -ExpandProperty Free

# Retrieve all running processes, sort them by memory usage from highest to lowest,
# and keep only the top five entries.
$topProcessesByMemory = Get-Process |
	# Sort processes so the largest working set appears first.
	Sort-Object -Property WorkingSet64 -Descending |
	# Keep only the first five processes from the sorted list.
	Select-Object -First 5

# Retrieve the latest ten events from the System log and keep only error-level entries.
$recentSystemErrorEvents = Get-WinEvent -LogName System -MaxEvents 10 |
	# Keep only events where the level is 2, which represents Error.
	Where-Object { $_.Level -eq 2 }

# Retrieve local user profiles and keep only non-special profiles that have not been
# used within the last 90 days.
$staleUserProfiles = Get-CimInstance -ClassName Win32_UserProfile |
	# Filter profiles to exclude special system profiles and include only stale profiles.
	Where-Object {
		# Exclude special built-in or system-managed profiles from the results.
		-not $_.Special -and
		# Keep profiles whose last use time is older than 90 days.
		$_.LastUseTime -lt (Get-Date).AddDays(-90)
	}

# Display the computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Convert free space on drive C from bytes to gigabytes, round it, and display it.
Write-Host ([math]::Round($freeSpaceBytes / 1GB, 2)) 'GB free'

# Loop through the top memory-consuming processes and display each process name and memory usage.
$topProcessesByMemory | ForEach-Object {
	# Print the process name and working set size in bytes for the current process.
	Write-Host $_.ProcessName $_.WorkingSet64
}

# Loop through the recent System error events and display the timestamp and message for each one.
$recentSystemErrorEvents | ForEach-Object {
	# Print when the event occurred and the event message text.
	Write-Host $_.TimeCreated $_.Message
}

# Check whether any stale user profiles were found.
if ($staleUserProfiles.Count -gt 0) {
	# Display the number of stale user profiles.
	Write-Host 'Stale profiles:' $staleUserProfiles.Count
}