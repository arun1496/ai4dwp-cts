# Floor 6 Remediation Technical Knowledge Article

## Version Header
- Article ID: KA-FLOOR6-L2-2026-08-14
- Version: 1.0
- Date: 2026-08-14
- Audience: Service Desk and Endpoint Engineering
- Source Runbook: RB-FLOOR6-OPS-2026-08-14 v1.0
- Relationship: Technical expression of the same remediation logic and sequence

## Purpose
Provide the operational procedure to stabilize Floor 6 login and desktop issues while collecting evidence for root-cause validation. Security determination for Copilot/client matter remains a separate security track.

## Scope
- In scope: Floor 6 endpoints with login slowness, login failures, missing desktop shortcuts.
- Out of scope: Security adjudication of Copilot/client matter.

## Preconditions and Access
- Incident bridge active; OPS owner and security-track owner assigned.
- Affected user/device list and at least one unaffected control device.
- Local admin on target endpoints.
- Access to event logs, registry uninstall keys, gpresult, dsregcmd.
- Intune/policy assignment visibility for comparison and rollback approvals.

## Procedure (same logic as source runbook)
1. Confirm segmentation and ownership.
- Output: OPS owner, security owner, and comms owner documented.

2. Send Floor 6 advisory in plain language.
- Output: users know what to do/not do; security concern called out as separate track.

3. Select pilot set.
- Output: 2-3 affected pilot devices plus 1 unaffected control device documented.

4. Run evidence script dry-run on one pilot.
- Command:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Project\floor6-evidence-hand-corrected.ps1" -DryRun
```
- Output: dry-run manifest generated; zero script errors.

5. Run evidence collection on pilot devices.
- Command:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\labuser\Documents\Training\Project\floor6-evidence-hand-corrected.ps1" -IncidentStart "2026-08-14T06:00:00" -IncidentEnd "2026-08-14T14:00:00"
```
- Output: evidence package folder with manifest and artifacts per device.

6. Correlate affected vs control evidence.
- Check app install timing, sign-in events, policy outputs, shortcut state, startup surfaces.
- Output: likely regression signal isolated to app or policy path.

7. Execute controlled remediation on pilots when evidence supports regression.
- Output: measurable login and desktop improvement with no new critical issues.

8. Expand remediation in waves after pilot success and approval.
- Output: controlled rollout, tracked outcomes, no uncontrolled blast radius.

9. Re-run targeted verification checks.
- Output: improved login time and desktop readiness at acceptable threshold.

10. Update record and close OPS actions when stable.
- Output: timeline, actions, evidence, outcomes, and open security dependencies documented.

## Verification Checks
- Before/after login timing comparison for pilot users.
- Desktop shortcut presence and usability.
- No increase in auth failure rate.
- User productivity feedback restored.
- Manifest completeness and zero capture errors.

## Evidence Requirements
Attach:
- Dry-run output JSON.
- Evidence manifest JSON (each pilot).
- apps-all.json, apps-suspect.json.
- events-diagnostics-performance.json.
- events-user-profile-service.json.
- services.json, scheduled-tasks.json.
- desktop-shortcuts.json.
- dsreg-status.txt, gpresult-computer.txt, gpresult-user.txt.
- Affected vs control comparison notes.
- User communication copies with timestamps.

## Escalation Path
1. Endpoint Engineering Incident Lead.
2. Major Incident Manager.
3. Head of End User Computing.
4. Security and Compliance Incident Lead (security-track decisions).

## Rollback Reference
Rollback is the same as the source runbook rollback section:
- Stop wave expansion immediately if pilot regresses.
- Reapply previous app/policy state on pilot devices.
- Restore prior shortcut state where changed.
- Reboot only when remediation path requires.
- Document rollback start, completion, and user impact.

## Communication Checkpoints
- Initial acknowledgment.
- Post dry-run/evidence update.
- Pre-pilot remediation update.
- Post-pilot validation update.
- OPS closure update.
- Every update includes the separate security review statement.