param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "78353dee-d572-4944-bb85-98b8cbfce315",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "Central-US",

    [Parameter(Mandatory = $false)]
    [string]$Location = "centralus",

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceName = "FinBridge-Workspace",

    [Parameter(Mandatory = $false)]
    [string]$HostPoolName = "POOL-FIN-01",

    [Parameter(Mandatory = $false)]
    [string]$RemoteAppGroupName = "RAG-POOL-FIN-01",

    [Parameter(Mandatory = $false)]
    [string]$DesktopAppGroupName = "DAG-POOL-FIN-01",

    [Parameter(Mandatory = $false)]
    [string]$SessionHostVmName = "sh-fin-01",

    [Parameter(Mandatory = $false)]
    [string]$AppName = "Google-Chrome",

    [Parameter(Mandatory = $false)]
    [string]$AppFriendlyName = "Google Chrome",

    [Parameter(Mandatory = $false)]
    [string]$AppFilePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",

    [Parameter(Mandatory = $false)]
    [string]$AssigneeUpn = "P04@zippyops.in"
)

$ErrorActionPreference = "Stop"

# Description:
# This script publishes Chrome as a RemoteApp on an existing AVD host pool.
# It installs Chrome on the session host (if missing), creates a RemoteApp app group,
# publishes the app object, registers app groups to the workspace, and grants user access.

Write-Output "Setting Azure subscription context..."
az account set --subscription $SubscriptionId --output none

Write-Output "Installing Chrome on session host if needed..."
$installScript = Join-Path $env:TEMP "install-chrome-remoteapp.ps1"
@'
$ProgressPreference='SilentlyContinue'
$path='C:\Program Files\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path $path)) {
  New-Item -ItemType Directory -Path 'C:\Temp' -Force | Out-Null
  $msi='C:\Temp\googlechromestandaloneenterprise64.msi'
  Invoke-WebRequest -Uri 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' -OutFile $msi
  Start-Process msiexec.exe -ArgumentList "/i $msi /qn /norestart" -Wait
}
if (-not (Test-Path $path)) { throw 'Chrome was not found after installation attempt.' }
Write-Output 'ChromePresent=True'
'@ | Set-Content -Path $installScript -Encoding ASCII

az vm run-command invoke \
  -g $ResourceGroup \
  -n $SessionHostVmName \
  --command-id RunPowerShellScript \
  --scripts @$installScript \
  --query "value[0].message" \
  --output tsv

Write-Output "Ensuring RemoteApp application group exists..."
$hostPoolId = az desktopvirtualization hostpool show -g $ResourceGroup -n $HostPoolName --query id --output tsv
az desktopvirtualization applicationgroup create \
  -g $ResourceGroup \
  -n $RemoteAppGroupName \
  --location $Location \
  --application-group-type RemoteApp \
  --host-pool-arm-path $hostPoolId \
  --friendly-name $RemoteAppGroupName \
  --output none

$remoteAppGroupId = az desktopvirtualization applicationgroup show -g $ResourceGroup -n $RemoteAppGroupName --query id --output tsv
$desktopAppGroupId = az desktopvirtualization applicationgroup show -g $ResourceGroup -n $DesktopAppGroupName --query id --output tsv

Write-Output "Publishing RemoteApp object via ARM API..."
$appUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/applicationGroups/$RemoteAppGroupName/applications/$AppName?api-version=2024-04-03"
$payloadPath = Join-Path $env:TEMP "remoteapp-payload.json"
@{
    location = $Location
    properties = @{
        friendlyName = $AppFriendlyName
        description = "$AppFriendlyName RemoteApp"
        filePath = $AppFilePath
        commandLineSetting = "DoNotAllow"
        showInPortal = $true
        iconPath = $AppFilePath
        iconIndex = 0
    }
} | ConvertTo-Json -Depth 8 | Set-Content -Path $payloadPath -Encoding ASCII

az rest --method put --uri $appUri --headers "Content-Type=application/json" --body @${payloadPath} --output none

Write-Output "Registering both app groups in workspace..."
az desktopvirtualization workspace update \
  -g $ResourceGroup \
  -n $WorkspaceName \
  --application-group-references $desktopAppGroupId $remoteAppGroupId \
  --output none

Write-Output "Assigning user access to RemoteApp group..."
az role assignment create \
  --assignee $AssigneeUpn \
  --role "Desktop Virtualization User" \
  --scope $remoteAppGroupId \
  --output none

Write-Output "Verifying RemoteApp publication..."
az rest --method get --uri "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/applicationGroups/$RemoteAppGroupName/applications?api-version=2024-04-03" --query "value[].{name:name,friendly:properties.friendlyName,path:properties.filePath,showInPortal:properties.showInPortal}" --output table

Write-Output "Done. RemoteApp has been published and assigned."
