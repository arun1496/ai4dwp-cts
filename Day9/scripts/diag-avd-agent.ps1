$ErrorActionPreference = "Continue"

"=== Services matching *RDAgent* ==="
Get-Service |
    Where-Object { $_.Name -like "*RDAgent*" -or $_.DisplayName -like "*Remote Desktop*Agent*" } |
    Select-Object Name, DisplayName, Status, StartType |
    Format-Table -AutoSize

"`n=== C:\Temp MSI files ==="
Get-ChildItem "C:\Temp" -ErrorAction SilentlyContinue |
    Select-Object Name, Length, LastWriteTime |
    Format-Table -AutoSize

"`n=== Installed products (RDAgent/AVD) from registry ==="
$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
Get-ItemProperty $paths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match "Remote Desktop|AVD|RDAgent|WVD" } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Format-Table -AutoSize

"`n=== Recent Application log entries containing RDAgent/WVD ==="
Get-WinEvent -LogName "Application" -MaxEvents 200 -ErrorAction SilentlyContinue |
    Where-Object {
        $_.ProviderName -match "RDAgent|WVD|RemoteDesktop" -or
        $_.Message -match "RDAgent|WVD|registration|host pool"
    } |
    Select-Object -First 30 TimeCreated, ProviderName, Id, LevelDisplayName, Message |
    Format-List
