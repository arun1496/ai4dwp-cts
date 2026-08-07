# KB - L2/L3 Diagnosis and Fix: Finance Shared Drive Missing After Context Migration

**Version:** v 1.0  
**Date:** 07/08/2026  
**Status:** Draft

## Background

Finance users need automatic sign-in-time drive assignment to reach the shared path \\finbridge-fs01\Finance as drive S:. This matters because core Finance processes depend on that shared location at start of day. The design works only when mapping runs in the signed-in user context and after workstation/network services are ready.

## Symptom

What users report:
- Finance shared drive S: is missing after sign-in.
- Finance folder cannot be opened from the normal mapped-drive path.

What engineer observes:
- Affected endpoints are typically DESKTOP-FB* in Finance OU/scope.
- Repeated incidents cluster after a script deployment/change window.
- Drive S: is absent, or appears briefly then disappears on some sign-ins.

## Root Cause

Specific technical cause:
- Drive mapping script Map-FinBridgeDrives.ps1 was moved from GPO user logon execution to Intune device script execution in SYSTEM context.
- SYSTEM context attempted \\finbridge-fs01\Finance before full service readiness and without Finance user security context.
- Script failed (exit code 1, network name cannot be found), no retry occurred, and S: was not assigned.

Evidence that confirms root cause:
- Intune Management Extension log records script context as SYSTEM and failure on \\finbridge-fs01\Finance.
- Event ID 7036 (Service Control Manager) shows Workstation service started after script failure window.
- Event ID 1500 (GroupPolicy) shows policy processing success, excluding GP failure as primary cause.
- Event ID 98 (Ntfs) shows drive letter S: was not assigned.

## Detection

Run this as a 3-minute triage before changing assignments.

1. Open PowerShell as Administrator on the affected endpoint and run this command to pull the required events quickly.
   Command:
   ```powershell
   $since = (Get-Date).AddHours(-8)
   Get-WinEvent -FilterHashtable @{LogName='System'; Id=7036,98; StartTime=$since} |
     Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message |
     Sort-Object TimeCreated
   ```
   Exact log location: Event Viewer > Windows Logs > System.
   Exact Event IDs required: 7036 and 98.
   Exact fields to check: TimeCreated, Id, ProviderName, Message.
   Faulting module field to check for Event 7036: ProviderName must be Service Control Manager; Message must include Workstation service entered the running state.
   Confirm this issue when: Event 98 (ProviderName Ntfs, S: not assigned) occurs in the same sign-in window and Event 7036 Workstation startup is late relative to mapping failure.

2. Run this command to extract Event 1500 from the required log and capture module/provider details.
   Command:
   ```powershell
   $since = (Get-Date).AddHours(-8)
   Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-GroupPolicy/Operational'; Id=1500; StartTime=$since} |
     Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message |
     Sort-Object TimeCreated
   ```
   Exact log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational.
   Exact Event ID required: 1500.
   Exact fields to check: TimeCreated, Id, ProviderName, Message.
   Faulting module field to check for Event 1500: ProviderName must be GroupPolicy.
   Confirm this issue when: Event 1500 shows successful policy processing, which rules out GP processing failure as the primary cause.

3. Run this command to check the Application log explicitly and confirm there is no conflicting app-crash root cause in the same window.
   Command:
   ```powershell
   $since = (Get-Date).AddHours(-8)
   Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=$since} |
     Where-Object { $_.Id -in 1500,7036,98 -or $_.ProviderName -match 'Intune|GroupPolicy|Service Control Manager|Ntfs' } |
     Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message |
     Sort-Object TimeCreated
   ```
   Exact log location: Event Viewer > Windows Logs > Application.
   Exact Event IDs named for this triage set: 1500, 7036, 98.
   Exact fields to check: TimeCreated, Id, ProviderName, Message.
   Confirm this issue when: no dominant Application-log error explains drive loss better than the System/GroupPolicy timing signature.

4. Run baseline comparison against control endpoint DESKTOP-FB041.
   Command:
   ```powershell
   $since = (Get-Date).AddHours(-8)
   Get-WinEvent -ComputerName DESKTOP-FB041 -FilterHashtable @{LogName='Microsoft-Windows-GroupPolicy/Operational'; Id=1500; StartTime=$since} |
     Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message |
     Sort-Object TimeCreated
   ```
   Exact log location on control: Event Viewer > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational.
   Exact Event ID required for baseline: 1500.
   Exact fields to compare: TimeCreated, Id, ProviderName, Message.
   Healthy baseline requirement: Event 1500 must be present on DESKTOP-FB041 as the unaffected control and show normal successful policy processing in the same business window.

5. Run mapped-drive vs direct-path comparison in the affected user session.
   Exact console location: File Explorer > This PC and File Explorer address bar.
   Exact fields/state to check: S: presence in This PC, direct path result for \\finbridge-fs01\Finance.
   Confirm this issue when: S: is missing but direct \\finbridge-fs01\Finance opens, matching mapping workflow/context failure.
   Do not use this fix alone when: both S: and direct \\finbridge-fs01\Finance fail, indicating possible wider file-server or network outage.

## Resolution

Use this fast path in order. Keep one pilot device first, then expand.

1. Open Intune path `https://intune.microsoft.com` > `Devices` > `Scripts and remediations` > `Platform scripts` > `Map-FinBridgeDrives.ps1` > `Assignments`. [ELEVATED]
   Expected result: You are on the SYSTEM script assignment page.

2. In `Included groups`, remove `Finance Desktops` (or tenant-equivalent Finance production desktop group), then select `Review + save` > `Save`. [ELEVATED]
   Expected result: SYSTEM script no longer targets Finance desktops.

3. Open Intune path `Devices` > `Scripts and remediations` > `Platform scripts` > approved USER-context mapping object > `Assignments`. [ELEVATED]
   Expected result: USER-context mapping assignment page opens.

4. In `Included groups`, add `Finance Pilot Users` (or tenant-equivalent pilot group), then select `Review + save` > `Save`. [ELEVATED]
   Expected result: Only pilot users are targeted by USER-context mapping.

5. Open Intune path `Devices` > `Windows` > `Windows devices` > `DESKTOP-FB041` (pilot endpoint) > `Sync`. [ELEVATED]
   Expected result: Sync is accepted and `Last check-in` updates.

6. On `DESKTOP-FB041`, sign out and sign back in as pilot Finance user.
   Expected result: New user session starts.

7. On `DESKTOP-FB041`, open File Explorer > `This PC` and confirm `S:` is present.
   Expected result: `S:` appears as a mapped drive.

8. On `DESKTOP-FB041`, open `\\finbridge-fs01\\Finance`.
   Expected result: Share opens without error.

9. Return to Intune USER-context mapping object > `Assignments`, replace pilot group with `Finance Desktops` (or tenant-equivalent full production group), then `Review + save` > `Save`. [ELEVATED]
   Expected result: USER-context mapping now targets Finance production desktops/users.

10. Open Intune path `Devices` > `Windows` > `Windows devices`, select at least two additional Finance desktops, and select `Sync`. [ELEVATED]
   Expected result: Sync accepted for all selected devices.

Azure CLI quick path (Graph API) for the same change:

```bash
az login
az account set --subscription "<subscription-id-or-name>"

# 1) Find script IDs
az rest --method GET \
  --uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts?$select=id,displayName" \
  --query "value[?contains(displayName,'Map-FinBridgeDrives') || contains(displayName,'Finance')].[displayName,id]" -o table

# 2) Remove Finance Desktops from SYSTEM script by assigning only NON-Finance keep-group(s)
az rest --method POST \
  --uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<SYSTEM_SCRIPT_ID>/assign" \
  --headers "Content-Type=application/json" \
  --body '{"deviceManagementScriptGroupAssignments":[{"@odata.type":"#microsoft.graph.deviceManagementScriptGroupAssignment","targetGroupId":"<KEEP_GROUP_ID_1>"}]}'

# 3) Assign USER-context script to pilot group first
az rest --method POST \
  --uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<USER_SCRIPT_ID>/assign" \
  --headers "Content-Type=application/json" \
  --body '{"deviceManagementScriptGroupAssignments":[{"@odata.type":"#microsoft.graph.deviceManagementScriptGroupAssignment","targetGroupId":"<FINANCE_PILOT_GROUP_ID>"}]}'

# 4) Expand USER-context script to Finance Desktops production group
az rest --method POST \
  --uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<USER_SCRIPT_ID>/assign" \
  --headers "Content-Type=application/json" \
  --body '{"deviceManagementScriptGroupAssignments":[{"@odata.type":"#microsoft.graph.deviceManagementScriptGroupAssignment","targetGroupId":"<FINANCE_DESKTOPS_GROUP_ID>"}]}'
```

GPO Domain fallback path (only if approved method is GPO):

11. Open `Group Policy Management` > `Forest: <your-forest>` > `Domains` > `<your-domain>` > `Group Policy Objects` > approved Finance drive-map GPO > `Scope`.
   Expected result: Security Filtering and linked scope are visible.

12. In `Security Filtering`, include Finance user target group and remove incorrect targets, then apply changes.
   Expected result: GPO scope matches last known-good Finance targeting.

13. Open `Group Policy Management` > `Forest: <your-forest>` > `Domains` > `<your-domain>` > `Organizational Units` > `OU=Finance` > `Linked Group Policy Objects` and confirm the approved drive-map GPO is linked and enabled.
   Expected result: Finance OU has the correct drive-map GPO link enabled.

14. On pilot endpoint, run `gpupdate /target:user /force` and sign out/sign in.
   Expected result: Policy reapplies and pilot user receives `S:`.

## Verification

1. Verify Intune SYSTEM script scope at `https://intune.microsoft.com` > `Devices` > `Scripts and remediations` > `Platform scripts` > `Map-FinBridgeDrives.ps1` > `Assignments`.
   Success: `Finance Desktops` is not listed in `Included groups`.

2. Verify Intune USER-context script scope at `Devices` > `Scripts and remediations` > `Platform scripts` > USER-context mapping object > `Assignments`.
   Success: `Finance Desktops` is listed in `Included groups`.

3. Verify pilot endpoint at `Devices` > `Windows` > `Windows devices` > `DESKTOP-FB041`.
   Success: `Last check-in` is newer than change time and remote user confirms `S:` plus `\\finbridge-fs01\\Finance` access.

4. Verify additional endpoints at `Devices` > `Windows` > `Windows devices` for at least two Finance desktops.
   Success: both endpoints complete sync and users confirm `S:` plus direct path access.

5. Verify log stability on pilot endpoint with command below.
   ```powershell
   $since = (Get-Date).AddHours(-2)
   Get-WinEvent -FilterHashtable @{LogName='System'; Id=98; StartTime=$since} |
     Select-Object TimeCreated, Id, ProviderName, Message
   ```
   Success: no new Event ID 98 entries for `S:` in post-fix window.

Azure CLI verification commands:

```bash
# Check SYSTEM script assignments
az rest --method GET \
  --uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<SYSTEM_SCRIPT_ID>/assignments" -o json

# Check USER-context script assignments
az rest --method GET \
  --uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<USER_SCRIPT_ID>/assignments" -o json
```

## Rollback

Use immediately if user impact increases.

1. Open Intune path `https://intune.microsoft.com` > `Devices` > `Scripts and remediations` > `Platform scripts` > USER-context mapping object > `Assignments` and remove `Finance Desktops`, then `Review + save` > `Save`. [ELEVATED]
   Expected result: New USER-context rollout is stopped.

2. Open Intune path `Devices` > `Scripts and remediations` > `Platform scripts` > `Map-FinBridgeDrives.ps1` > `Assignments` and restore the exact pre-change group list from the incident snapshot, then `Review + save` > `Save`. [ELEVATED]
   Expected result: SYSTEM script assignment returns to pre-change state.

3. Open Intune path `Devices` > `Windows` > `Windows devices` > `DESKTOP-FB041` > `Sync`. [ELEVATED]
   Expected result: Rollback state is pushed to pilot endpoint.

4. On `DESKTOP-FB041`, sign out/sign in and test `S:` and `\\finbridge-fs01\\Finance`.
   Expected result: Pilot returns to last known behavior.

5. If still failing, execute GPO Domain fallback at `Group Policy Management` > `Forest: <your-forest>` > `Domains` > `<your-domain>` > `OU=Finance` and re-enable last known-good drive-map GPO link.
   Expected result: OU link state matches pre-incident known-good configuration.

6. If failure remains after Step 5, open Major Incident with assignment screenshots, Event 7036/Event 1500/Event 98 extracts, and pilot timestamps.
   Expected result: Escalation is active with complete evidence.

Azure CLI rollback commands:

```bash
# Remove Finance Desktops from USER-context script
az rest --method POST \
  --uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<USER_SCRIPT_ID>/assign" \
  --headers "Content-Type=application/json" \
  --body '{"deviceManagementScriptGroupAssignments":[{"@odata.type":"#microsoft.graph.deviceManagementScriptGroupAssignment","targetGroupId":"<FINANCE_PILOT_GROUP_ID>"}]}'

# Restore SYSTEM script pre-change assignments (example with two groups)
az rest --method POST \
  --uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/<SYSTEM_SCRIPT_ID>/assign" \
  --headers "Content-Type=application/json" \
  --body '{"deviceManagementScriptGroupAssignments":[{"@odata.type":"#microsoft.graph.deviceManagementScriptGroupAssignment","targetGroupId":"<PRECHANGE_GROUP_ID_1>"},{"@odata.type":"#microsoft.graph.deviceManagementScriptGroupAssignment","targetGroupId":"<PRECHANGE_GROUP_ID_2>"}]}'
```

## Preventive

Strengthened process/tooling controls:

1. Mandatory execution-context change gate.
   - Owner/Timing/Mode: change manager, before deployment, manual [REQUIRES: change workflow with required fields].
   - Action: require `RunAs context`, `User session dependency`, `Startup timing dependency`, and architecture sign-off on every USER-to-SYSTEM change.
   - Pass/Fail signal: pass only if all fields + sign-off are present; fail on any missing field/sign-off.
   - If fail: reject change and block release window entry.

2. Pre-deployment smoke-test gate (pilot endpoint).
   - Owner/Timing/Mode: release engineer, before deployment, automated [REQUIRES: pilot smoke-test job on DESKTOP-FB041].
   - Action: run pilot checks after assignment: `S:` present, direct `\\finbridge-fs01\\Finance` open, Event 98=0 (30 min), Event 1500 present.
   - Pass/Fail signal: pass when all checks pass; fail if any check fails or Event 98 >= 1.
   - If fail: block production assignment and open failed gate task.

3. Startup timing resilience standard in drive scripts.
   - Owner/Timing/Mode: DWP engineer, before deployment, manual + automated [REQUIRES: CI lint rule for retry/log pattern].
   - Action: enforce template with 3 retries at 20-second intervals and per-attempt structured logs.
   - Pass/Fail signal: pass when retry block + timestamped attempt logs exist; fail if either is missing.
   - If fail: reject pull request from release.

4. In-flight monitoring during rollout window.
   - Owner/Timing/Mode: DWP engineer, during deployment, automated [REQUIRES: 5-minute rollout monitor for Finance desktops].
   - Action: track Event ID 98 in `System` and assignment/context drift for the first 60 minutes.
   - Pass/Fail signal: pass if Event 98 <= 2 per 15 minutes and no unauthorized drift; fail at Event 98 >= 3 or drift detected.
   - If fail: stop rollout immediately and execute rollback.

5. Assignment drift alerting.
   - Owner/Timing/Mode: image owner, after deployment (daily), automated [REQUIRES: assignment/context baseline diff job].
   - Action: compare current Intune script groups/context to approved baseline daily.
   - Pass/Fail signal: pass if no unauthorized diff; fail if drift exists without active approved change.
   - If fail: raise Sev-2 ops alert and auto-open DWP investigation task.

6. Post-deployment validation gate before change closure.
   - Owner/Timing/Mode: change manager, after deployment, manual + automated [REQUIRES: closure evidence report from endpoint/ticket data].
   - Action: validate DESKTOP-FB041 plus 2 Finance desktops and review ticket/event outputs.
   - Pass/Fail signal: pass if 3/3 pass access checks, pilot Event 98=0 (60 min), and Finance tickets <= 2/hour; otherwise fail.
   - If fail: keep change open and execute rollback trigger.

7. Explicit rollback trigger threshold.
   - Owner/Timing/Mode: release engineer, during deployment and first 2 hours after, automated trigger + manual approval [REQUIRES: threshold alert pipeline].
   - Action: monitor trigger set: Event 98 >= 3/15 min, direct-path failures on >=2 devices, or >=5 Finance outage tickets/30 min.
   - Pass/Fail signal: pass if all below thresholds; fail when any one threshold is crossed.
   - If fail: execute rollback immediately and notify change manager + service desk lead.

8. Service desk known-error signature and triage macro.
   - Owner/Timing/Mode: service desk lead, before deployment and after updates, manual + automated [REQUIRES: mandatory ticket template fields].
   - Action: enforce triage macro capture of Event 7036/1500/98 and mapped-drive vs direct-path result.
   - Pass/Fail signal: pass if 100% of Finance tickets contain all fields; fail if any ticket is missing required evidence.
   - If fail: return ticket for completion and schedule shift retraining.

9. Knowledge update from incident learnings.
   - Owner/Timing/Mode: DWP engineer, after deployment (within 2 business days), manual [REQUIRES: closure workflow document-link check].
   - Action: update runbook, L2 KB, and checklist with new detection signature and rollback thresholds.
   - Pass/Fail signal: pass if versioned updates are published and linked in change record; fail if links are missing after 2 business days.
   - If fail: change manager reopens closure until documentation is complete.

## Related

- Runbook: Day5/runbook-finance-shared-drives-unavailable-context-mismatch-2024-03-15.md
- RCA: Day4/rca-finance-shared-drives-2024-03-15.md
- Hypothesis: Day4/hypothesis-finance-shared-drives-2024-03-15.md
- Known Error: Day4/known-error-finance-shared-drives-2024-03-15.md
