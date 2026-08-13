# Azure Virtual Desktop Build Runbook (Exact CLI Commands)

Date: 2026-08-13  
Subscription: 78353dee-d572-4944-bb85-98b8cbfce315  
Tenant: zippyops.in

Notes:
- Commands are listed in execution order.
- This is a literal command log (including retries and diagnostics).
- Some commands were interrupted in-session (`^C`) and are marked.

## 1) Identity and subscription validation

```powershell
az account show --output json
az ad signed-in-user show --output json
az group list --query "[].{name:name,location:location}" --output table
$sub='/subscriptions/78353dee-d572-4944-bb85-98b8cbfce315'; $obj='2e80de04-3590-4241-a20d-f68f701901c7'; az role assignment list --assignee-object-id $obj --scope $sub --include-inherited --query "[].{role:roleDefinitionName,scope:scope}" --output table
$obj='2e80de04-3590-4241-a20d-f68f701901c7'; az role assignment list --assignee-object-id $obj --all --query "[].{role:roleDefinitionName,scope:scope}" --output table
```

## 2) Initial RG attempt and corrected deployment scope

```powershell
$ErrorActionPreference='Stop'; $sub='78353dee-d572-4944-bb85-98b8cbfce315'; az account set --subscription $sub; $rg='Central US'; $loc='centralus'; az group create --name "$rg" --location $loc --output json
$ErrorActionPreference='Stop'
$sub='78353dee-d572-4944-bb85-98b8cbfce315'
$rg='Central-US'
$loc='centralus'
$hostPool='POOL-FIN-01'
$workspace='FinBridge-Workspace'
$appGroup='DAG-POOL-FIN-01'
az account set --subscription $sub
az extension add --name desktopvirtualization --upgrade --only-show-errors
az group create --name $rg --location $loc --output none
az network vnet create --resource-group $rg --name 'vnet-fin-01' --location $loc --address-prefixes '10.20.0.0/16' --subnet-name 'snet-avd' --subnet-prefixes '10.20.1.0/24' --output none
az desktopvirtualization hostpool create --resource-group $rg --name $hostPool --location $loc --host-pool-type Pooled --load-balancer-type BreadthFirst --max-session-limit 5 --preferred-app-group-type Desktop --custom-rdp-property 'targetisaadjoined:i:1;' --start-vm-on-connect true --output none
$hpId = az desktopvirtualization hostpool show --resource-group $rg --name $hostPool --query id --output tsv
az desktopvirtualization workspace create --resource-group $rg --name $workspace --location $loc --friendly-name $workspace --output none
az desktopvirtualization applicationgroup create --resource-group $rg --name $appGroup --location $loc --application-group-type Desktop --host-pool-arm-path $hpId --friendly-name $appGroup --output none
$appId = az desktopvirtualization applicationgroup show --resource-group $rg --name $appGroup --query id --output tsv
az desktopvirtualization workspace update --resource-group $rg --name $workspace --application-group-references $appId --output none
Write-Output "HostPoolId=$hpId"
Write-Output "AppGroupId=$appId"
az desktopvirtualization hostpool show --resource-group $rg --name $hostPool --query "{name:name,type:hostPoolType,lb:loadBalancerType,maxSessions:maxSessionLimit,customRdp:customRdpProperty,location:location}" --output json
az desktopvirtualization workspace show --resource-group $rg --name $workspace --query "{name:name,location:location,appGroupRefs:length(applicationGroupReferences)}" --output json
```

## 3) Verification and discovery

```powershell
az group show --name 'Central-US' --query "{name:name,location:location,provisioningState:properties.provisioningState}" --output json
az desktopvirtualization hostpool show --resource-group 'Central-US' --name 'POOL-FIN-01' --query "{name:name,type:hostPoolType,lb:loadBalancerType,max:maxSessionLimit,rdp:customRdpProperty,location:location}" --output json
az desktopvirtualization workspace show --resource-group 'Central-US' --name 'FinBridge-Workspace' --output json
az desktopvirtualization applicationgroup show --resource-group 'Central-US' --name 'DAG-POOL-FIN-01' --query "{name:name,type:applicationGroupType,hostPool:hostPoolArmPath}" --output json
az vm image list --location centralus --publisher MicrosoftWindowsDesktop --offer windows-11 --all --query "[?contains(sku, 'avd')].[sku,version]" --output table
az network vnet subnet show --resource-group Central-US --vnet-name vnet-fin-01 --name snet-avd --query id --output tsv
az desktopvirtualization hostpool update -h
```

## 4) Session host VM creation and agent bootstrap attempts

```powershell
$ErrorActionPreference='Stop'; $rg='Central-US'; $loc='centralus'; $vm='sh-fin-01'; $image='MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest'; $adminUser='avdlocaladmin'; $adminPass=[System.Web.Security.Membership]::GeneratePassword(20,4) + 'aA1!'; az vm create --resource-group $rg --name $vm --location $loc --image $image --size Standard_B2ms --vnet-name vnet-fin-01 --subnet snet-avd --admin-username $adminUser --admin-password $adminPass --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true --output json; az vm extension set --resource-group $rg --vm-name $vm --publisher Microsoft.Azure.ActiveDirectory --name AADLoginForWindows --output none; $expiry=(Get-Date).ToUniversalTime().AddHours(24).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'); az desktopvirtualization hostpool update --resource-group $rg --name 'POOL-FIN-01' --registration-info expiration-time=$expiry registration-token-operation=Update --output none; $token=az desktopvirtualization hostpool show --resource-group $rg --name 'POOL-FIN-01' --query registrationInfo.token --output tsv; if ([string]::IsNullOrWhiteSpace($token)) { throw 'Host pool registration token was not generated.' }; $scriptPath="$env:TEMP\install-avd-agent.ps1"; @"
$ErrorActionPreference='Stop'; $rg='Central-US'; $loc='centralus'; $vm='sh-fin-01'; $image='MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest'; $adminUser='avdlocaladmin'; $chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+'; $rand=-join ((1..24) | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] }); $adminPass=$rand + 'Aa1!'; az vm create --resource-group $rg --name $vm --location $loc --image $image --size Standard_B2ms --vnet-name vnet-fin-01 --subnet snet-avd --admin-username $adminUser --admin-password $adminPass --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true --output json; az vm extension set --resource-group $rg --vm-name $vm --publisher Microsoft.Azure.ActiveDirectory --name AADLoginForWindows --output none; $expiry=(Get-Date).ToUniversalTime().AddHours(24).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'); az desktopvirtualization hostpool update --resource-group $rg --name 'POOL-FIN-01' --registration-info expiration-time=$expiry registration-token-operation=Update --output none; $token=az desktopvirtualization hostpool show --resource-group $rg --name 'POOL-FIN-01' --query registrationInfo.token --output tsv; if ([string]::IsNullOrWhiteSpace($token)) { throw 'Host pool registration token was not generated.' }; $scriptPath="$env:TEMP\install-avd-agent.ps1"; @"
az vm list --resource-group Central-US --query "[].{name:name,provisioningState:provisioningState,powerState:powerState,location:location}" --output table
az desktopvirtualization session-host list --resource-group Central-US --host-pool-name POOL-FIN-01 --output table
az desktopvirtualization hostpool show --resource-group Central-US --name POOL-FIN-01 --query registrationInfo --output json
az vm extension list --resource-group Central-US --vm-name sh-fin-01 --query "[].{name:name,provisioningState:provisioningState,publisher:publisher}" --output table
az desktopvirtualization hostpool show -g Central-US -n POOL-FIN-01 --output json
az desktopvirtualization hostpool -h
az desktopvirtualization hostpool retrieve-registration-token -h
az desktopvirtualization hostpool retrieve-registration-token -g Central-US -n POOL-FIN-01 --output json
$ErrorActionPreference='Stop'; $rg='Central-US'; $vm='sh-fin-01'; $token = az desktopvirtualization hostpool retrieve-registration-token -g $rg -n POOL-FIN-01 --query token --output tsv; if ([string]::IsNullOrWhiteSpace($token)) { throw 'Registration token retrieval returned empty token.' }; $scriptPath = Join-Path $env:TEMP 'install-avd-agent.ps1'; $script = @'
```

## 5) AVD service and VM diagnostics

```powershell
az desktopvirtualization -h
az ad user show --id P04@zippyops.in --query "{id:id,userPrincipalName:userPrincipalName,displayName:displayName}" --output json
az vm show --resource-group Central-US --name sh-fin-01 --query "{name:name,size:hardwareProfile.vmSize,securityType:securityProfile.securityType,secureBoot:securityProfile.uefiSettings.secureBootEnabled,vtpm:securityProfile.uefiSettings.vTpmEnabled,imageOffer:storageProfile.imageReference.offer,imageSku:storageProfile.imageReference.sku}" --output json
$sub='78353dee-d572-4944-bb85-98b8cbfce315'; az rest --method get --uri "https://management.azure.com/subscriptions/$sub/resourceGroups/Central-US/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03" --output json
$scriptPath = Join-Path $env:TEMP 'diag-avd-agent.ps1'; @'
$ProgressPreference='SilentlyContinue'; $u1=(Invoke-WebRequest -Uri 'https://aka.ms/avdagent' -MaximumRedirection 10 -Method Head).BaseResponse.ResponseUri.AbsoluteUri; $u2=(Invoke-WebRequest -Uri 'https://aka.ms/avdbootloader' -MaximumRedirection 10 -Method Head).BaseResponse.ResponseUri.AbsoluteUri; Write-Output "Agent=$u1"; Write-Output "Bootloader=$u2"
az vm extension image list --location centralus --publisher Microsoft.Azure.VirtualDesktop --output table
$ErrorActionPreference='Stop'; $rg='Central-US'; $vm='sh-fin-01'; $token=az desktopvirtualization hostpool retrieve-registration-token -g $rg -n POOL-FIN-01 --query token --output tsv; if ([string]::IsNullOrWhiteSpace($token)) { throw 'Empty host pool token.' }; $settings = '{"modulesUrl":"https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip","configurationFunction":"Configuration.ps1\\AddSessionHost","properties":{"HostPoolName":"POOL-FIN-01","aadJoin":true}}'; $protected = '{"properties":{"registrationInfoToken":"' + $token + '"}}'; az vm extension set --resource-group $rg --vm-name $vm --publisher Microsoft.Powershell --name DSC --version 2.73 --settings $settings --protected-settings $protected --output json
Write-Output 'terminal-ok'; az vm extension list -g Central-US --vm-name sh-fin-01 --query "[].{name:name,state:provisioningState}" --output table
$ErrorActionPreference='Stop'; $rg='Central-US'; $vm='sh-fin-01'; $token=az desktopvirtualization hostpool retrieve-registration-token -g $rg -n POOL-FIN-01 --query token --output tsv; if ([string]::IsNullOrWhiteSpace($token)) { throw 'Empty host pool token.' }; $settingsPath=Join-Path $env:TEMP 'avd-dsc-settings.json'; $protectedPath=Join-Path $env:TEMP 'avd-dsc-protected.json'; '{"modulesUrl":"https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip","configurationFunction":"Configuration.ps1\\AddSessionHost","properties":{"HostPoolName":"POOL-FIN-01","aadJoin":true}}' | Set-Content -Path $settingsPath -Encoding ASCII; ('{"properties":{"registrationInfoToken":"' + $token + '"}}') | Set-Content -Path $protectedPath -Encoding ASCII; az vm extension set --resource-group $rg --vm-name $vm --publisher Microsoft.Powershell --name DSC --version 2.73 --settings @$settingsPath --protected-settings @$protectedPath --output json
```

## 6) Role assignments and final verification

```powershell
$ErrorActionPreference='Stop'; $assignee='P04@zippyops.in'; $vmId=az vm show -g Central-US -n sh-fin-01 --query id --output tsv; az role assignment create --assignee $assignee --role 'Virtual Machine User Login' --scope $vmId --output none; az role assignment list --assignee $assignee --scope $vmId --query "[].{role:roleDefinitionName,scope:scope,principalName:principalName}" --output table
$ErrorActionPreference='Stop'; $assignee='P04@zippyops.in'; $appId=az desktopvirtualization applicationgroup show -g Central-US -n DAG-POOL-FIN-01 --query id --output tsv; az role assignment create --assignee $assignee --role 'Desktop Virtualization User' --scope $appId --output none; az role assignment list --assignee $assignee --scope $appId --query "[].{role:roleDefinitionName,scope:scope,principalName:principalName}" --output table
$assignee='P04@zippyops.in'; $vmId=az vm show -g Central-US -n sh-fin-01 --query id --output tsv; $appId=az desktopvirtualization applicationgroup show -g Central-US -n DAG-POOL-FIN-01 --query id --output tsv; az role assignment list --assignee $assignee --scope $vmId --query "[].roleDefinitionName" --output table; az role assignment list --assignee $assignee --scope $appId --query "[].roleDefinitionName" --output table; az vm extension list -g Central-US --vm-name sh-fin-01 --query "[].{name:name,state:provisioningState}" --output table
az role assignment create --assignee P04@zippyops.in --role "Desktop Virtualization User" --scope $(az desktopvirtualization applicationgroup show -g Central-US -n DAG-POOL-FIN-01 --query id --output tsv) --output json
az vm extension list -g Central-US --vm-name sh-fin-01 --query "[].{name:name,state:provisioningState}" --output table
$sub='78353dee-d572-4944-bb85-98b8cbfce315'; az rest --method get --uri "https://management.azure.com/subscriptions/$sub/resourceGroups/Central-US/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03" --query "value[].{name:name,status:properties.status,lastHeartBeat:properties.lastHeartBeat,allowNewSession:properties.allowNewSession,sessions:properties.sessions}" --output table
$sub='78353dee-d572-4944-bb85-98b8cbfce315'; az rest --method get --uri "https://management.azure.com/subscriptions/$sub/resourceGroups/Central-US/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts/sh-fin-01?api-version=2024-04-03" --output json
$scriptPath = Join-Path $env:TEMP 'check-dsreg.ps1'; @'
$ErrorActionPreference='Stop'; az vm identity assign -g Central-US -n sh-fin-01 --output none; az vm extension delete -g Central-US --vm-name sh-fin-01 --name AADLoginForWindows; az vm extension set -g Central-US --vm-name sh-fin-01 --publisher Microsoft.Azure.ActiveDirectory --name AADLoginForWindows --output none; az vm restart -g Central-US -n sh-fin-01 --output none; az vm extension list -g Central-US --vm-name sh-fin-01 --query "[].{name:name,state:provisioningState}" --output table
az vm show -g Central-US -n sh-fin-01 --query "{identityType:identity.type}" --output json
az role assignment list --assignee P04@zippyops.in --scope $(az desktopvirtualization applicationgroup show -g Central-US -n DAG-POOL-FIN-01 --query id --output tsv) --query "[].roleDefinitionName" --output table
```

## 7) Consolidated final-state command (latest successful check)

```powershell
$appScope=$(az desktopvirtualization applicationgroup show -g Central-US -n DAG-POOL-FIN-01 --query id --output tsv); Write-Output 'Identity:'; az vm show -g Central-US -n sh-fin-01 --query "{identityType:identity.type}" --output json; Write-Output 'Extensions:'; az vm extension list -g Central-US --vm-name sh-fin-01 --query "[].{name:name,state:provisioningState,publisher:publisher}" --output table; Write-Output 'RoleAssignments VM:'; az role assignment list --assignee P04@zippyops.in --scope $(az vm show -g Central-US -n sh-fin-01 --query id --output tsv) --query "[].roleDefinitionName" --output table; Write-Output 'RoleAssignments AppGroup:'; az role assignment list --assignee P04@zippyops.in --scope $appScope --query "[].roleDefinitionName" --output table; Write-Output 'SessionHost:'; $sub='78353dee-d572-4944-bb85-98b8cbfce315'; az rest --method get --uri "https://management.azure.com/subscriptions/$sub/resourceGroups/Central-US/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts/sh-fin-01?api-version=2024-04-03" --query "{status:properties.status,lastHeartBeat:properties.lastHeartBeat,domainJoinedCheck:properties.sessionHostHealthCheckResults[?healthCheckName=='DomainJoinedCheck'].healthCheckResult | [0],domainTrustCheck:properties.sessionHostHealthCheckResults[?healthCheckName=='DomainTrustCheck'].healthCheckResult | [0],aadJoinedCheck:properties.sessionHostHealthCheckResults[?healthCheckName=='AADJoinedHealthCheck'].healthCheckResult | [0]}" --output json
```
