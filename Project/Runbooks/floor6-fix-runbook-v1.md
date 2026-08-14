# Floor 6 Fix Runbook

## Version Header
- Runbook ID: RB-FLOOR6-OPS-2026-08-14
- Version: 1.0
- Date: 2026-08-14
- Status: Approved for controlled execution
- Change Type: Incident remediation and evidence collection

## Purpose
Provide one standard procedure to stabilize Floor 6 login and desktop issues, collect evidence for root-cause validation, and communicate clearly to users while the Copilot/client matter concern is handled on a separate security track.

## Scope
- In scope: Floor 6 endpoints with login slowness, login failures, and missing desktop shortcuts.
- In scope: Evidence collection for suspected app or policy regression and controlled remediation actions.
- Out of scope: Security determination of the Copilot/client matter concern. That remains a separate security incident workflow.

## Prerequisites
- Incident bridge active with assigned incident owner.
- Affected user and device list for Floor 6.
- At least one unaffected control device for comparison.
- Local admin rights on target endpoints.
- Access to run PowerShell scripts with execution policy bypass for approved scripts.

## Required Access
- Endpoint local administrator on target devices.
- Read access to Windows Event Logs.
- Read access to local registry uninstall keys.
- Ability to run gpresult and dsregcmd locally.
- Intune and policy assignment visibility for comparison and rollback approval.
- Service desk update channel for user communication.

## Impacted Systems
- Floor 6 Windows endpoints.
- Desktop shell and user profile components.
- Startup services and scheduled tasks.
- Identity and policy processing surfaces (device join, user/computer policy results).
- Document management app deployment and targeting assignments.

## Assumptions
- Top operational cause is a change-induced app or policy regression in the Floor 6 cohort.
- Security concern for Copilot/client matter is being reviewed separately by security and compliance.
- Controlled rollback can be executed on a small pilot set before broad rollout.

## Numbered Procedure
1. Confirm incident segmentation and ownership.
Expected result after step 1: OPS incident owner is confirmed, security track owner is confirmed, and communication responsibilities are assigned.

2. Announce user advisory to Floor 6 using approved plain-language communication.
Expected result after step 2: Users are reassured, informed what to do and not do, and told that Copilot/client matter is under separate security review.

3. Select pilot devices.
Expected result after step 3: 2 to 3 affected Floor 6 devices and 1 unaffected control device are documented for comparison.

4. Run evidence script in dry-run mode on one pilot device.
Command: powershell -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Project\floor6-evidence-hand-corrected.ps1" -DryRun
Expected result after step 4: Structured dry-run manifest is produced with command plan and zero script errors.

5. Run evidence script in collection mode on pilot devices.
Command: powershell -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Project\floor6-evidence-hand-corrected.ps1" -IncidentStart "2026-08-14T06:00:00" -IncidentEnd "2026-08-14T14:00:00"
Expected result after step 5: Evidence package folder is created with manifest and artifact files for each pilot device.

6. Correlate evidence.
Expected result after step 6: Team can compare suspect app install timing, sign-in related events, policy output, desktop shortcut state, and startup surface against control device.

7. Execute controlled remediation on pilot devices if evidence supports app or policy regression.
Expected result after step 7: Pilot users show measurable login improvement and desktop behavior improvement without introducing new critical issues.

8. Expand remediation in waves after pilot success and approval.
Expected result after step 8: Additional affected devices are remediated with tracked outcomes and no uncontrolled blast radius.

9. Re-run targeted verification checks post-remediation.
Expected result after step 9: Login times and desktop readiness improve to acceptable levels for remediated users.

10. Update incident record and close operational actions when stable.
Expected result after step 10: Incident timeline, actions, evidence, outcomes, and remaining security-track dependencies are fully documented.

## Verification
- Compare before and after login timing for pilot users.
- Confirm desktop shortcut presence and usability.
- Confirm no increase in authentication failures.
- Confirm user reports indicate restored productivity.
- Confirm evidence manifest contains required artifacts and no capture errors.

## Rollback
- If pilot remediation causes regression, stop wave expansion immediately.
- Reapply previous app or policy state on pilot devices.
- Restore prior shortcut state if changed by remediation actions.
- Reboot affected pilot devices only when required by remediation path.
- Document rollback start time, completion time, and user impact.

## Communication Steps
1. Send initial acknowledgment to Floor 6 users.
2. Send update after dry-run and pilot evidence collection.
3. Send update before pilot remediation starts.
4. Send update after pilot results are validated.
5. Send closure update for OPS track when stable.
6. Include statement in each update that Copilot/client matter is under separate security review.

## Evidence to Attach to the Incident
- Dry-run output JSON from evidence script.
- Evidence manifest JSON from each pilot device.
- apps-all.json and apps-suspect.json.
- events-diagnostics-performance.json.
- events-user-profile-service.json.
- services.json and scheduled-tasks.json.
- desktop-shortcuts.json.
- dsreg-status.txt, gpresult-computer.txt, gpresult-user.txt.
- Affected versus control comparison notes.
- User communication copies and timestamps.

## Owner and Escalation Path
- Primary owner: Endpoint Engineering Incident Lead.
- Secondary owner: Service Desk Major Incident Manager.
- Security owner for Copilot/client matter concern: Security and Compliance Incident Lead.
- Escalation path:
  1. Endpoint Engineering Incident Lead
  2. Major Incident Manager
  3. Head of End User Computing
  4. Security and Compliance Incident Lead for security-track decisions
