# Floor 6 OPS Technical Knowledge Article (L2)

## Version Header
- Article ID: KA-F6-L2-2026-08-14
- Version: 1.0
- Date: 2026-08-14
- Source Runbook: RB-F6-OPS-2026-08-14 v1.0

## Purpose
Technical expression of the same RB-F6-OPS-2026-08-14 runbook for repeat execution by L2 engineers.

## Scope
- In scope: Floor 6 login slowness/failure and missing desktop shortcuts.
- Out of scope: Copilot security determination (separate SEC track).

## Procedure Summary (Re-expressed from source runbook)
1. Confirm OPS/SEC track separation and ownership.
2. Freeze rollout expansion.
3. Select pilot cohort: 2-3 affected devices plus 1 control.
4. Execute dry-run evidence script.
5. Execute evidence collection run.
6. Compare pilot evidence against control.
7. Move pilot devices from deploy ring to rollback ring and force sync.
8. Validate pilot metrics and user outcomes.
9. Expand rollback in controlled waves on pass.
10. Record before/after evidence and close OPS when stable.

## Core Commands
Dry-run:
```powershell
powershell -ExecutionPolicy Bypass -File ".\03-Differential-And-Evidence\floor6-evidence-hand-corrected.ps1" -DryRun
```

Collection:
```powershell
powershell -ExecutionPolicy Bypass -File ".\03-Differential-And-Evidence\floor6-evidence-hand-corrected.ps1" -IncidentStart "2026-08-14T06:00:00" -IncidentEnd "2026-08-14T14:00:00"
```

Ring rollback and sync:
- Use command block in immediate-fix-and-floor-message.md.

## Verification Criteria
- Login delay reduced vs baseline.
- Fewer sign-in failures.
- Desktop shortcut baseline restored.
- Evidence manifests complete.

## Rollback of Remediation
- Stop wave immediately if regression appears.
- Return pilot to previous assignment state.
- Re-sync devices and document outcomes.

## Escalation
- Endpoint Incident Lead -> Major Incident Manager -> Head of EUC.
- Security/Compliance lead governs Copilot-related SEC decisions.
