# Root Cause Analysis - Finance Shared Drives Unavailable

**Incident ID:** INC-2024-0315-FIN-DRIVES
**Date of Incident:** 2024-03-15
**Date of RCA:** 2026-08-06
**Analyst:** DWP Engineer
**Status:** Resolved

---

## Executive Summary

On 2024-03-15 at approximately 08:00, all Finance users were unable to access their shared drives. The incident affected 45 users on `DESKTOP-FB*` devices in `OU=Finance`. The root cause was a change made on 2024-03-14 at 23:30 that migrated the Finance drive mapping script from a Group Policy logon script running in USER context to an Intune PowerShell script running in SYSTEM context, without redesigning the script for that execution model. At logon, the script attempted to access `\\finbridge-fs01\Finance` from SYSTEM context before the Workstation service was fully available and without the Finance user's access context, causing the script to fail and preventing drive `S:` from being mapped. The applied resolution was to remove the broken SYSTEM-context deployment and restore a user-context mapping method. The issue was verified resolved at **10:00 on 2026-08-06**, with successful user logon to host and no further issues reported.

---

## Incident Details

| Field | Value |
|---|---|
| Affected users | All Finance users (45 users) |
| Affected estate | `DESKTOP-FB*` devices, `OU=Finance` |
| Symptom | Shared drives unavailable; Finance drive mapping failed at logon |
| Incident start | 2024-03-15 ~08:00 |
| Incident end / verified resolved | 2026-08-06 10:00 |
| Triggering change | 2024-03-14 23:30 - drive mapping moved from GPO USER logon script to Intune SYSTEM PowerShell script |
| Primary affected resource | `\\finbridge-fs01\Finance` / mapped drive `S:` |

---

## Timeline

| Time | Event |
|---|---|
| 2024-03-14 23:30 | Change implemented: `Map-FinBridgeDrives.ps1` migrated from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context). |
| 2024-03-15 08:00:01 | Intune Management Extension / ScriptRunner starts `Map-FinBridgeDrives.ps1`. |
| 2024-03-15 08:00:02 | ScriptRunner records script context as `SYSTEM`. |
| 2024-03-15 08:00:03 | ScriptRunner warns that `\\finbridge-fs01\Finance` is not accessible from `SYSTEM` context at execution time. |
| 2024-03-15 08:00:03 | ScriptRunner records script failure: exit code 1, `Network name cannot be found`. |
| 2024-03-15 08:00:04 | ScriptRunner records that no retry is configured. |
| 2024-03-15 08:00:05 | **Event 7036 (Service Control Manager)** - Workstation service entered running state. |
| 2024-03-15 08:00:06 | **Event 1500 (GroupPolicy)** - Group Policy settings processed successfully. |
| 2024-03-15 08:00:07 | **Event 98 (Ntfs)** - File system could not map drive letter `S:`; drive letter not assigned. |
| 2026-08-06 (morning) | Investigation confirms the new Intune deployment is running in SYSTEM context and matches the change note describing a context mismatch. |
| 2026-08-06 (morning) | Resolution applied: broken SYSTEM-context mapping deployment disabled; user-context mapping restored / redeployed. |
| 2026-08-06 10:00 | Resolution verified: user logged in to host successfully, shared drive access restored, and no further issues reported. |

---

## Supporting Evidence

### Event and Log Evidence

| Time | Source | Event ID | Detail |
|---|---|---|---|
| 08:00:01 | Intune Management Extension / ScriptRunner | n/a | Executing `Map-FinBridgeDrives.ps1` |
| 08:00:02 | Intune Management Extension / ScriptRunner | n/a | Script context: `SYSTEM` |
| 08:00:03 | Intune Management Extension / ScriptRunner | n/a | Network path `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context at execution time |
| 08:00:03 | Intune Management Extension / ScriptRunner | n/a | Script failed. Exit code: 1. Error: `Network name cannot be found` |
| 08:00:04 | Intune Management Extension / ScriptRunner | n/a | No retry configured |
| 08:00:05 | Service Control Manager | 7036 | Workstation service entered running state |
| 08:00:06 | GroupPolicy | 1500 | Group Policy settings processed successfully |
| 08:00:07 | Ntfs | 98 | File system could not map drive letter `S:`. Drive letter has not been assigned |

### Evidence Interpretation

- The script was confirmed to run as `SYSTEM`, not as the signed-in Finance user.
- The failure is explicitly tied to `SYSTEM` access to `\\finbridge-fs01\Finance`, not to a Group Policy failure.
- Event 7036 shows the Workstation service started only after the failed share access attempt.
- Event 1500 confirms Group Policy completed successfully, eliminating GP as the root cause path.
- Event 98 captures the user-visible outcome: drive `S:` was never assigned.

### Resolution Verification Evidence

- Resolution was applied on 2026-08-06 by removing the broken SYSTEM-context deployment path and restoring a user-context mapping method.
- At 10:00, user logon to host was verified successfully.
- No further issues were reported after restoration of the correct execution model.

---

## Root Cause

The Finance shared drive outage was caused by an implementation error in the 2024-03-14 23:30 change. The drive mapping script `Map-FinBridgeDrives.ps1` was migrated from a GPO logon script that ran in USER context to an Intune PowerShell script that ran in SYSTEM context. The script was not redesigned for SYSTEM execution, even though the Finance share mapping depended on user session context, user authorization, and timing that occurs after the interactive user logon is established. As a result, the script attempted to reach `\\finbridge-fs01\Finance` too early and under the wrong security principal, failed with `Network name cannot be found`, did not retry, and left Finance users without drive `S:`.

---

## 5 Whys Analysis

| Why | Answer |
|---|---|
| **Why** were Finance users unable to access their shared drives? | Because drive `S:` was not mapped during logon, as shown by Event 98 at 08:00:07. |
| **Why** was drive `S:` not mapped? | Because `Map-FinBridgeDrives.ps1` failed at 08:00:03 with `Network name cannot be found` while trying to access `\\finbridge-fs01\Finance`. |
| **Why** did the script fail to access the Finance share? | Because it was running in `SYSTEM` context instead of the signed-in user's context, and the share was explicitly recorded as not accessible from `SYSTEM` at execution time. |
| **Why** was the script running in `SYSTEM` context? | Because the change migrated the mapping from a GPO USER logon script to an Intune PowerShell deployment that executes as SYSTEM. |
| **Why** was a user-dependent drive mapping moved to SYSTEM context without redesign? | Because the change process did not require an execution-context review for user-resource mappings, and the migration was implemented without validating authentication context, startup timing, retry behavior, or user-session visibility. |

**Root cause statement:** The change control and implementation process allowed a user-dependent drive mapping script to be migrated into SYSTEM context without redesign or validation of context, timing, and session behavior.

---

## Resolution Applied

1. The broken Intune device-context deployment of `Map-FinBridgeDrives.ps1` was disabled / removed.
2. A working user-context mapping method for Finance shared drives was restored or redeployed.
3. The drive mapping was aligned back to the signed-in Finance user session rather than SYSTEM.
4. The corrected mapping path was validated after user sign-in rather than at pre-user startup timing.
5. User access was retested against `\\finbridge-fs01\Finance` and drive `S:`.
6. At 10:00, user logon to host was verified and no further issues were reported.

**Verified resolved: 2026-08-06 10:00.**

---

## Preventive Actions

| # | Action | Owner | Priority |
|---|---|---|---|
| 1 | Update the change runbook for script migrations to require an execution-context review before moving any user-resource access script from GPO to Intune. | Endpoint Engineering / Change Management | High |
| 2 | Require explicit validation that any drive mapping or user-share access script runs in the correct user security context before production deployment. | Endpoint Engineering | High |
| 3 | Add a pre-release test case for user-session visibility, confirming that mapped drives appear in the interactive session and not only in SYSTEM context. | EUC / Endpoint Engineering | High |
| 4 | Add delayed execution or retry logic for logon-dependent mappings so transient early-start timing does not result in persistent loss of mapped drives. | Endpoint Engineering | Medium |
| 5 | Create a standard design pattern for Intune-delivered drive mappings so teams do not repurpose USER logon scripts as SYSTEM scripts without redesign. | Endpoint Architecture | Medium |
| 6 | Add a post-change validation step for one representative Finance endpoint and one real Finance user before broad deployment to all users. | Change Implementer | Medium |
| 7 | Record a Known Error pattern for: ScriptRunner in `SYSTEM` context + share inaccessible + Event 98 drive mapping failure after GPO-to-Intune migration. | Problem Management / Service Desk | Low |

---

## Lessons Learned

- USER-context logon scripts cannot be assumed to work unchanged when moved to Intune SYSTEM context.
- Event 1500 was a key discriminator because it proved Group Policy succeeded, preventing mis-triage into a GP incident.
- The timestamp gap between the script failure at 08:00:03 and Workstation service readiness at Event 7036, 08:00:05 highlighted an important startup-order risk.
- No-retry behavior turned a single early failure into a broad user-visible outage.
- Changes affecting all users in a business unit require a live representative user validation before full deployment.

---

## Document References

- Hypothesis analysis: `Day4/hypothesis-finance-shared-drives-2024-03-15.md`
- Evidence sources: Intune Management Extension log, System log, change note dated 2024-03-14 23:30
- Event IDs referenced: 7036, 1500, 98