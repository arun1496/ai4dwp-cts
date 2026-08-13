# AVD CLI Commands Explained in Simple Language

This file explains what each command in the runbook was used for, the common error seen, and how it was fixed.

## 1) Identity and access checks

Command: az account show --output json  
Purpose: Confirm which subscription and account are currently active.  
Common error: Wrong subscription is active.  
Remediation: Run az account set --subscription <subscription-id>.

Command: az ad signed-in-user show --output json  
Purpose: Get signed-in user object details (principal ID).  
Common error: Graph permission/auth failure.  
Remediation: Re-authenticate with az login and ensure proper tenant context.

Command: az group list --query "[].{name:name,location:location}" --output table  
Purpose: See existing resource groups and locations.  
Common error: None in this run.  
Remediation: N/A.

Command: az role assignment list --assignee-object-id ... --scope ... --include-inherited  
Purpose: Verify effective RBAC role at subscription scope.  
Common error: Empty output due wrong object ID or scope.  
Remediation: Re-check object ID and scope string.

## 2) Subscription and resource group setup

Command: az account set --subscription 78353dee-d572-4944-bb85-98b8cbfce315  
Purpose: Force all next operations to correct subscription.  
Common error: Subscription not found for current tenant.  
Remediation: Switch tenant or confirm subscription exists.

Command: az group create --name "Central US" --location centralus --output json  
Purpose: First attempt to create target resource group.  
Error seen: InvalidResourceGroup due space in resource group name.  
Remediation used: Changed name to Central-US.

Command: az group create --name Central-US --location centralus --output none  
Purpose: Create valid resource group.

## 3) Install AVD extension and network

Command: az extension add --name desktopvirtualization --upgrade --only-show-errors  
Purpose: Install/upgrade AVD CLI extension.

Command: az network vnet create --resource-group Central-US --name vnet-fin-01 --location centralus --address-prefixes 10.20.0.0/16 --subnet-name snet-avd --subnet-prefixes 10.20.1.0/24 --output none  
Purpose: Create VNet and subnet for session host VM.

Command: az network vnet subnet show --resource-group Central-US --vnet-name vnet-fin-01 --name snet-avd --query id --output tsv  
Purpose: Confirm subnet exists and get subnet ID.

## 4) Create AVD control plane components

Command: az desktopvirtualization hostpool create --resource-group Central-US --name POOL-FIN-01 --location centralus --host-pool-type Pooled --load-balancer-type BreadthFirst --max-session-limit 5 --preferred-app-group-type Desktop --custom-rdp-property targetisaadjoined:i:1; --start-vm-on-connect true --output none  
Purpose: Create pooled host pool with requested balancing and max sessions.

Command: az desktopvirtualization hostpool show --resource-group Central-US --name POOL-FIN-01 --query id --output tsv  
Purpose: Get host pool ARM ID for app group linking.

Command: az desktopvirtualization workspace create --resource-group Central-US --name FinBridge-Workspace --location centralus --friendly-name FinBridge-Workspace --output none  
Purpose: Create workspace.

Command: az desktopvirtualization applicationgroup create --resource-group Central-US --name DAG-POOL-FIN-01 --location centralus --application-group-type Desktop --host-pool-arm-path <hostpool-id> --friendly-name DAG-POOL-FIN-01 --output none  
Purpose: Create desktop app group attached to host pool.

Command: az desktopvirtualization workspace update --resource-group Central-US --name FinBridge-Workspace --application-group-references <appgroup-id> --output none  
Purpose: Register app group into workspace.

## 5) Verify AVD objects

Command: az group show ...  
Purpose: Verify RG provisioning state.

Command: az desktopvirtualization hostpool show ...  
Purpose: Verify pooled type, BreadthFirst, max session limit, custom RDP property.

Command: az desktopvirtualization workspace show ...  
Purpose: Verify workspace exists and app group reference is present.

Command: az desktopvirtualization applicationgroup show ...  
Purpose: Verify app group type and linked host pool.

Common issue seen in this stage: Query string quoting errors in PowerShell.  
Remediation used: Run command without complex query or adjust quoting.

## 6) Session host VM build

Command: az vm image list --location centralus --publisher MicrosoftWindowsDesktop --offer windows-11 --all --query "[?contains(sku, 'avd')].[sku,version]" --output table  
Purpose: Find valid Windows 11 AVD image in region.

Command: az vm create --resource-group Central-US --name sh-fin-01 --location centralus --image MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest --size Standard_B2ms --vnet-name vnet-fin-01 --subnet snet-avd --admin-username avdlocaladmin --admin-password <generated> --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true --output json  
Purpose: Create session host VM with trusted launch, secure boot, and vTPM.

Error seen in first attempt: Unable to find type [System.Web.Security.Membership] during password generation helper call.  
Remediation used: Switched to PowerShell-native random password generation.

Command: az vm extension set --resource-group Central-US --vm-name sh-fin-01 --publisher Microsoft.Azure.ActiveDirectory --name AADLoginForWindows --output none  
Purpose: Enable Entra sign-in support on VM.

## 7) Host pool registration and AVD agent setup

Command: az desktopvirtualization hostpool retrieve-registration-token -g Central-US -n POOL-FIN-01 --output json  
Purpose: Retrieve host registration token.

Command: az vm run-command invoke ... install-avd-agent.ps1  
Purpose: Install AVD agent stack on VM.

Error seen: Token not found in one attempt after update syntax.  
Remediation used: Use retrieve-registration-token command directly.

Command: az vm extension set --resource-group Central-US --vm-name sh-fin-01 --publisher Microsoft.Powershell --name DSC --version 2.73 --settings ... --protected-settings ...  
Purpose: Register session host using DSC AddSessionHost flow.

Error seen: JSON parse errors from PowerShell quoting.  
Remediation used: Put settings/protected-settings in JSON files and reference with @file.

## 8) Troubleshooting host status

Command: az rest --method get --uri https://management.azure.com/.../sessionHosts?api-version=2024-04-03  
Purpose: Get actual session host status when CLI subgroup did not exist in current extension build.

Command: az rest --method get --uri https://management.azure.com/.../sessionHosts/sh-fin-01?api-version=2024-04-03  
Purpose: Fetch health checks (DomainJoinedCheck, DomainTrustCheck, AADJoinedHealthCheck, etc.).

Command: az vm run-command invoke ... check-dsreg.ps1  
Purpose: Check VM Entra join state via dsregcmd /status.

Observed issue: Host showed Unavailable with domain health checks failing and AzureAdJoined initially NO.  
Remediation used: Ensure VM identity and extension/state remediation attempts, then re-validate status.

## 9) Assign user access roles

Command: az ad user show --id P04@zippyops.in --query "{id:id,userPrincipalName:userPrincipalName,displayName:displayName}" --output json  
Purpose: Resolve user principal for RBAC assignment.

Command: az role assignment create --assignee P04@zippyops.in --role "Virtual Machine User Login" --scope <vm-id> --output none  
Purpose: Allow direct VM sign-in.

Command: az role assignment create --assignee P04@zippyops.in --role "Desktop Virtualization User" --scope <app-group-id> --output json  
Purpose: Allow AVD client access to published desktop.

Command: az role assignment list --assignee ... --scope ...  
Purpose: Verify assignments exist.

## 10) Final health verification

Command: az vm extension list -g Central-US --vm-name sh-fin-01 --query "[].{name:name,state:provisioningState,publisher:publisher}" --output table  
Purpose: Verify AADLoginForWindows and DSC extension states.

Command: az rest --method get --uri https://management.azure.com/.../sessionHosts/sh-fin-01?api-version=2024-04-03 --query "{status:...,lastHeartBeat:...,domainJoinedCheck:...,domainTrustCheck:...,aadJoinedCheck:...}" --output json  
Purpose: Verify final AVD session host status and key health checks.

---

## Quick list of errors seen and fix applied

1. Invalid resource group name with space (Central US).  
Fix: Use Central-US.

2. PowerShell parsing errors for JMESPath and JSON strings.  
Fix: Simplify query or move JSON into files.

3. Password helper type not available ([System.Web.Security.Membership]).  
Fix: Use native random string logic.

4. Session-host CLI subgroup not available in installed extension build.  
Fix: Use az rest calls to DesktopVirtualization sessionHosts endpoint.

5. Token retrieval inconsistency during hostpool update attempts.  
Fix: Use az desktopvirtualization hostpool retrieve-registration-token.

6. VM/host status Unavailable during registration phase.  
Fix: Diagnose with az rest + VM run-command logs and dsregcmd; remediate identity/extension path and re-check health.
