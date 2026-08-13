$ProgressPreference = "SilentlyContinue"

# Creates working directory used for agent package downloads.
New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null

# IMPORTANT:
# Set the host pool registration token before running this script.
# Example: $token = "<paste-registration-token>"
if (-not $token -or [string]::IsNullOrWhiteSpace($token)) {
    throw "Registration token variable `$token is empty. Set it before running this script."
}

# These URLs were used in the provisioning session.
$agentUrl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
$bootUrl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"

Invoke-WebRequest -Uri $agentUrl -OutFile "C:\Temp\AVDAgent.msi"
Invoke-WebRequest -Uri $bootUrl -OutFile "C:\Temp\AVDBootloader.msi"

Start-Process msiexec.exe -ArgumentList "/i C:\Temp\AVDAgent.msi /quiet /qn REGISTRATIONTOKEN=$token" -Wait
Start-Process msiexec.exe -ArgumentList "/i C:\Temp\AVDBootloader.msi /quiet /qn" -Wait

Get-Service -Name "RDAgentBootLoader", "RDAgent" -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType |
    Format-Table -AutoSize |
    Out-String
