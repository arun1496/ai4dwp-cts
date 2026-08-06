# End-User Communications - Finance Shared Drives Unavailable

**Incident:** INC-2024-0315-FIN-DRIVES
**Date:** 2026-08-06
**Resolved:** 10:00

---

## Audience 1 - Non-technical executive

Your access is restored and your data is safe. Around 08:00, a planned overnight change moved the automatic Finance shared-drive connection from the normal sign-in step to the computer start-up step, so the connection did not complete and shared drives were unavailable. We removed that broken setup, restored the correct sign-in method, and verified recovery at 10:00 with successful sign-in and drive access. No action is needed.

---

## Audience 2 - Affected end-user team (10 people)

Your access is restored and your data is safe. Around 08:00, a planned overnight change moved the automatic Finance shared-drive connection from the normal sign-in step to the computer start-up step, so the connection failed and shared drives were unavailable. We removed that broken setup, restored the correct sign-in method, and verified recovery at 10:00 with successful sign-in and drive access, with no further issues reported. If you see the same issue, sign out and sign back in once, then contact the IT Service Desk.

---

## Audience 3 - Engineer-to-engineer internal note

Access restored; data safe.

Root cause:
Planned overnight change at 2024-03-14 23:30 moved the Finance drive mapping from GPO logon script in USER context to Intune PowerShell in SYSTEM context. `Map-FinBridgeDrives.ps1` attempted to map `\\finbridge-fs01\Finance` as `S:` from SYSTEM during logon-start timing, failed before user-session access was available, and Finance shared drives were unavailable.

Exact action taken:
Broken SYSTEM-context deployment was removed / disabled, and the correct user sign-in mapping method was restored.

Config detail:
Old path: GPO USER-context logon mapping.
Broken path: Intune SYSTEM-context PowerShell deployment.
Affected resource: `\\finbridge-fs01\Finance` mapped as `S:`.

Verification step:
Recovery was verified at 10:00 with successful user logon to host and successful shared-drive access; no further issues were reported.

Preventive action needed:
Do not move user-resource drive mappings from USER context to SYSTEM context without redesign and validation of execution context, startup timing, retry behavior, and user-session visibility.

Same incident facts for handoff:
Around 08:00, a planned overnight change moved the automatic Finance shared-drive connection from the normal user sign-in path to the computer-level path, the connection failed, shared drives became unavailable, the broken setup was removed, the correct sign-in method was restored, and recovery was verified at 10:00.