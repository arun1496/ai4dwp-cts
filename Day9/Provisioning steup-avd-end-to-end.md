# Provisioning Steup - AVD End-to-End Build Record

Date: 2026-08-13  
Subscription: 78353dee-d572-4944-bb85-98b8cbfce315  
Tenant: zippyops.in  
Region: centralus  
Resource Group used: Central-US

## 1) Objective

Provision Azure Virtual Desktop end-to-end for a Windows 11 workplace migration with:
- Pooled host pool
- Desktop app group
- Workspace registration
- One Windows 11 multi-session session host
- Entra-based sign-in path
- Role assignments for direct VM sign-in and AVD client access

## 2) Resources Created

- Host pool: POOL-FIN-01
- Host pool type: Pooled
- Load balancing: BreadthFirst
- Max session limit: 5
- Workspace: FinBridge-Workspace
- Desktop app group: DAG-POOL-FIN-01
- VNet: vnet-fin-01
- Subnet: snet-avd
- Session host VM: sh-fin-01
- VM image: MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest
- VM size: Standard_B2ms
- Security profile: TrustedLaunch + Secure Boot + vTPM

## 3) Pre-checks Performed

1. Verified active Azure account and tenant.
2. Verified active subscription context.
3. Verified RBAC role of signed-in identity.
4. Confirmed ability to create role assignments before access steps.

## 4) Provisioning Steps Followed

### Step A: Baseline configuration

- Set subscription context.
- Installed/updated desktopvirtualization Azure CLI extension.
- Created valid resource group name (Central-US) after initial invalid-name attempt.

### Step B: Network provisioning

- Created VNet and subnet for session hosts.
- Confirmed subnet exists and is usable.

### Step C: AVD control-plane provisioning

- Created pooled host pool with required settings.
- Created workspace.
- Created desktop application group.
- Registered app group to workspace.
- Verified host pool/workspace/app group properties.

### Step D: Session host provisioning

- Enumerated available AVD Windows 11 image SKUs in centralus.
- Created session host VM with requested image/size/security profile.
- Installed AADLoginForWindows extension.

### Step E: Session host registration

- Retrieved host pool registration token.
- Applied AVD registration path using DSC AddSessionHost extension.
- Validated extension states and host registration behavior.

### Step F: Access assignment

- Assigned Virtual Machine User Login role on VM scope to P04@zippyops.in.
- Assigned Desktop Virtualization User role on app-group scope to P04@zippyops.in.
- Verified both assignments.

### Step G: Health verification and diagnostics

- Queried session host status via ARM REST endpoint.
- Queried session host health checks.
- Ran VM-side diagnostics and join-state checks using run-command scripts.
- Revalidated extension status and health checks after remediation attempts.

## 5) Scripts Created During Provisioning

These were created as temporary run-command scripts during troubleshooting/provisioning:

1. install-avd-agent.ps1  
Purpose:
- Download and install AVD agent components
- Use host pool registration token during install
- Validate related services

2. diag-avd-agent.ps1  
Purpose:
- Check AVD/RDAgent services
- Check installed AVD-related products
- Review application event logs for AVD/registration hints

3. diag-avd-unavailable.ps1  
Purpose:
- Deep-diagnose why a session host is Unavailable
- Inspect service state, install artifacts, and relevant event channels

4. check-dsreg.ps1  
Purpose:
- Run dsregcmd /status on session host
- Confirm Entra join/device registration posture

Note:
- These scripts were generated under the temporary path used by VM run-command (`$env:TEMP`) and executed remotely.
- They are now saved in Day9/scripts for reuse.

Saved paths:
- Day9/scripts/install-avd-agent.ps1
- Day9/scripts/diag-avd-agent.ps1
- Day9/scripts/diag-avd-unavailable.ps1
- Day9/scripts/check-dsreg.ps1

## 6) Issues Seen and Fixes Applied

1. Invalid resource group name (space in name).  
Fix: Use Central-US.

2. PowerShell JSON/JMESPath quoting issues in some commands.  
Fix: Simplified query or moved JSON payload into temp files.

3. Password helper type not available in shell.  
Fix: Switched to native random password generation logic.

4. Session-host list command not available in current CLI extension build.  
Fix: Used az rest calls against Microsoft.DesktopVirtualization sessionHosts endpoint.

5. Registration/host health ambiguity during provisioning.  
Fix: Used VM-side run-command diagnostics and host health-check API output instead of blind reruns.

## 7) Final Validation Checklist Used

- Host pool exists with requested pooled settings.
- Workspace and desktop app group exist and are linked.
- Session host VM exists with requested image/size/security profile.
- AADLoginForWindows and DSC extensions reach successful states.
- Required RBAC assignments exist for target user.
- Session host status and heartbeat verified through ARM API.

## 8) Related Day9 Files

- avd-cli-command-runbook-2026-08-13.md
- avd-command-purpose-errors-remediation.md
- avd-step-by-step-from-scratch.md
- avd-components-requirements.md
- avd-fslogix-integration.md
- README-avd-guides.md

## 9) File Movement Check

- Checked for step-related markdown files outside Day9.
- Result: no step files were found outside Day9, so no moves were required.
