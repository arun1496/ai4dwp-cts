$ErrorActionPreference = "Continue"

"=== AVD related services ==="
Get-Service |
    Where-Object {
        $_.Name -match "RDAgent|wvdagent|TermService|RemoteDesktop" -or
        $_.DisplayName -match "Remote Desktop|AVD|WVD|Geneva"
    } |
    Select-Object Name, DisplayName, Status, StartType |
    Sort-Object Name |
    Format-Table -AutoSize

"`n=== Installed AVD components ==="
$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
Get-ItemProperty $paths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match "Remote Desktop|AVD|RDAgent|Geneva|Side-by-Side|WVD" } |
    Select-Object DisplayName, DisplayVersion, InstallDate |
    Sort-Object DisplayName |
    Format-Table -AutoSize

"`n=== Recent AVD/application events (last 2 hours) ==="
$start = (Get-Date).AddHours(-2)
Get-WinEvent -FilterHashtable @{ LogName = "Application"; StartTime = $start } -ErrorAction SilentlyContinue |
    Where-Object {
        $_.ProviderName -match "RDAgent|WVD|RemoteDesktop|DesktopVirtualization|Geneva" -or
        $_.Message -match "RDAgent|WVD|registration|host pool|token|broker|unavailable"
    } |
    Select-Object -First 40 TimeCreated, ProviderName, Id, LevelDisplayName, Message |
    Format-List

"`n=== WVD/AVD operational logs if present ==="
$logs = @(
    "Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational",
    "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational",
    "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"
)

foreach ($l in $logs) {
    if (Get-WinEvent -ListLog $l -ErrorAction SilentlyContinue) {
        "--- $l ---"
        Get-WinEvent -FilterHashtable @{ LogName = $l; StartTime = $start } -MaxEvents 30 -ErrorAction SilentlyContinue |
            Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message |
            Format-List
    }
}
