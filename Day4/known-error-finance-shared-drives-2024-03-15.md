# Known Error Record - Finance Shared Drives Unavailable

**Symptom:** Finance users cannot access shared drives because drive `S:` is not mapped at logon. In the source incident, users on `DESKTOP-FB*` devices in `OU=Finance` were unable to reach `\\finbridge-fs01\Finance`.

**Cause:** The verified root cause was a 2024-03-14 23:30 change that moved `Map-FinBridgeDrives.ps1` from a GPO logon script running in USER context to an Intune PowerShell script running in SYSTEM context without redesign for that execution model. The script then attempted to access `\\finbridge-fs01\Finance` from SYSTEM context, failed with `Network name cannot be found`, and did not map drive `S:`.

**Scope:** The source incident affected all Finance users, 45 users total, on `DESKTOP-FB*` devices in `OU=Finance`. The primary affected resource was `\\finbridge-fs01\Finance` mapped as drive `S:`.

**Workaround:** Disable or remove the broken Intune device-context deployment of `Map-FinBridgeDrives.ps1` and restore the working user-context mapping method for Finance shared drives. Retest user access after sign-in and confirm that drive `S:` is assigned.

**Permanent fix:** Require an execution-context review before moving any user-resource access script from GPO to Intune, and validate that the mapping runs in the correct user security context before production deployment. Add delayed execution or retry logic for logon-dependent mappings, and confirm mapped drives appear in the interactive session rather than SYSTEM context.

**How to spot it:** Look for this sequence: ScriptRunner starts `Map-FinBridgeDrives.ps1` at 08:00:01, records `SYSTEM` context at 08:00:02, then logs `\\finbridge-fs01\Finance` as not accessible from SYSTEM and `Network name cannot be found` at 08:00:03. Corroborate with Event **7036** at 08:00:05 for Workstation service start, Event **1500** at 08:00:06 showing Group Policy succeeded, and Event **98** at 08:00:07 showing drive `S:` was not assigned.