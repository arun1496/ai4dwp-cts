# Hypothesis Analysis - Finance Shared Drives Unavailable

Date: 2026-08-06
Analyst: DWP Engineer
Scope basis only - no cause committed.

## Scope Facts Used

- Symptom: Finance team cannot access shared drives.
- Impact: All Finance users affected (45 users).
- Affected estate: `DESKTOP-FB*` devices, `OU=Finance`.
- Since: approximately 08:00:05.
- Declared change: 2024-03-14 23:30 - drive mapping moved from GPO logon script running as USER to Intune PowerShell script running as SYSTEM.
- Execution evidence provided in scope:
  - 08:00:01 - `Map-FinBridgeDrives.ps1` started.
  - 08:00:02 - script ran as SYSTEM.
  - 08:00:03 - `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time.
  - 08:00:03 - script failed with exit code 1 and `Network name cannot be found`.
  - 08:00:04 - no retry configured.
  - 08:00:05 - Workstation service entered running state.
  - 08:00:06 - Group Policy processed successfully.
  - 08:00:07 - NTFS warning that drive letter `S:` could not be mapped.

---

## Ranked Likely Causes (Most Probable First)

### 1) Script was migrated unchanged to SYSTEM context, but the drive mapping requires the user security context

Why this fits the scope facts:
- The change record explicitly says the script moved from USER context to SYSTEM context and was not updated for that change.
- The scope facts state the UNC path was not accessible from SYSTEM at execution time.
- The blast radius is all Finance users, which matches a centrally changed deployment method rather than a per-user fault.
- Group Policy succeeded, which isolates the issue away from generic logon processing and toward the new mapping method.

Single fastest check:
- Open the Intune-assigned `Map-FinBridgeDrives.ps1` and confirm it is still written as a user logon mapping script rather than a SYSTEM-safe deployment method.

### 2) The script ran before the Workstation service was available, so the SMB/UNC path was not ready when mapping was attempted

Why this fits the scope facts:
- The script failure is logged at 08:00:03.
- The Workstation service does not enter the running state until 08:00:05.
- A UNC mapping attempt before Workstation is running can produce a path-not-found or network-name failure even when the server itself is healthy.
- This timing explains why every affected device fails in the same short window.

Single fastest check:
- On one affected device, compare the Intune script execution timestamp to the Workstation service start event; if the script consistently runs first, this cause remains live.

### 3) The mapping depends on user credentials or a user Kerberos token that do not exist for SYSTEM at logon time

Why this fits the scope facts:
- The change note explicitly says mapped credentials are not available to SYSTEM at login time.
- Access to `\\finbridge-fs01\Finance` is a user-facing finance share, so authorization is likely tied to the signed-in user rather than the computer account.
- A device-context script can reach a different authentication path than a user logon script, which fits an all-users-in-one-OU impact after migration.

Single fastest check:
- Manually test access to `\\finbridge-fs01\Finance` as SYSTEM on one affected machine; if SYSTEM cannot browse the share while a Finance user can, this cause is confirmed or strongly supported.

### 4) The Intune deployment has no retry or deferred execution, so one early failure leaves the user session with no mapped drives

Why this fits the scope facts:
- The execution log explicitly says no retry is configured.
- Even if the path becomes reachable seconds later, there is no second attempt after Workstation starts or after user sign-in completes.
- This explains why the symptom persists for users even though the machine continues booting normally and Group Policy succeeds.

Single fastest check:
- Review the Intune assignment and script settings to confirm there is no rerun, retry, scheduled follow-up, or user-context fallback after the initial failure.

### 5) The script still uses a mapped-drive method that only creates the drive in the SYSTEM session, not in the interactive user session

Why this fits the scope facts:
- The old implementation was a GPO logon script, which naturally targeted the interactive user session.
- After migration, even a partially successful SYSTEM-side mapping would not necessarily surface as `S:` for the signed-in user.
- The NTFS warning that `S:` could not be assigned is consistent with the mapping logic not producing a usable per-user drive letter.

Single fastest check:
- Review the script for commands such as `net use` or `New-PSDrive` and verify whether they are creating a user-visible mapping or only operating inside the SYSTEM context.

---

## Working Position

- This is a hypothesis ranking only, using the provided scope facts.
- The facts point most strongly to a context-and-timing failure introduced by the migration from USER to SYSTEM execution.
- No single root cause is committed yet pending the fastest checks above.

---

## Evidence Assessment Against Provided Logs

### 1) Script was migrated unchanged to SYSTEM context, but the drive mapping requires the user security context

Judgement: SUPPORTS

Determining evidence:
- 08:00:02 - Intune Management Extension / ScriptRunner log: script context is `SYSTEM`.
- 08:00:03 - Intune Management Extension / ScriptRunner log: `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context at execution time.
- Event 1500 at 08:00:06 - Group Policy processed successfully, which pushes the failure away from GP and toward the new execution method.

Why this judgement:
- The provided evidence directly shows the script now runs as `SYSTEM` and directly fails because the share is not accessible from that context.
- Event 1500 at 08:00:06 removes Group Policy as the controlling fault path, which strengthens the migration-context hypothesis.

### 2) The script ran before the Workstation service was available, so the SMB/UNC path was not ready when mapping was attempted

Judgement: SUPPORTS

Determining evidence:
- 08:00:03 - Intune Management Extension / ScriptRunner log: script failed with `Network name cannot be found`.
- Event 7036 at 08:00:05 - Workstation service entered the running state.

Why this judgement:
- The failure occurs two seconds before the Workstation service is confirmed running.
- That timing directly supports a startup-order problem where UNC access was attempted before the SMB client path was ready.

### 3) The mapping depends on user credentials or a user Kerberos token that do not exist for SYSTEM at logon time

Judgement: SUPPORTS

Determining evidence:
- 08:00:03 - Intune Management Extension / ScriptRunner log: `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context at execution time.
- 08:00:03 - Intune Management Extension / ScriptRunner log: script failed with exit code 1.
- Event 1500 at 08:00:06 - Group Policy processed successfully.

Why this judgement:
- The failure is explicitly tied to `SYSTEM` context rather than to a generic machine logon failure.
- Because GP succeeds at 08:00:06, the remaining explanation space stays centered on how `SYSTEM` authenticates to the share versus how the interactive Finance user would authenticate.
- The evidence does not name Kerberos or credentials explicitly in an event ID, but it does support a context-specific access failure.

### 4) The Intune deployment has no retry or deferred execution, so one early failure leaves the user session with no mapped drives

Judgement: SUPPORTS

Determining evidence:
- 08:00:04 - Intune Management Extension / ScriptRunner log: no retry configured.
- Event 7036 at 08:00:05 - Workstation service entered the running state after the failed attempt.
- Event 98 at 08:00:07 - drive letter `S:` could not be mapped.

Why this judgement:
- The logs show a single failed attempt at 08:00:03, explicit confirmation that no retry exists at 08:00:04, and then the user-visible outcome at 08:00:07.
- The sequence supports the idea that the failure was not self-correcting once the machine became ready.

### 5) The script still uses a mapped-drive method that only creates the drive in the SYSTEM session, not in the interactive user session

Judgement: NEUTRAL

Determining evidence:
- 08:00:03 - Intune Management Extension / ScriptRunner log: script failed before completing the mapping.
- Event 98 at 08:00:07 - drive letter `S:` was not assigned.

Why this judgement:
- The evidence shows outright failure before a usable drive mapping is created.
- That means the scope does not prove a session-visibility problem, but it also does not eliminate the possibility that the script still uses a SYSTEM-only mapping method.
- A code review of `Map-FinBridgeDrives.ps1` would be required to move this from neutral to support or contradicts.

---

## Evidence Assessment Summary

| Hypothesis | Judgement | Determining evidence |
|------------|-----------|----------------------|
| H1 - Migrated unchanged to SYSTEM; requires user context | SUPPORTS | 08:00:02 ScriptRunner `SYSTEM`; 08:00:03 ScriptRunner share inaccessible from `SYSTEM`; Event 1500 at 08:00:06 |
| H2 - Ran before Workstation service was available | SUPPORTS | 08:00:03 ScriptRunner failure; Event 7036 at 08:00:05 |
| H3 - Depends on user credentials/token unavailable to SYSTEM | SUPPORTS | 08:00:03 ScriptRunner context-specific access failure; Event 1500 at 08:00:06 |
| H4 - No retry/deferred execution after early failure | SUPPORTS | 08:00:04 no retry configured; Event 7036 at 08:00:05; Event 98 at 08:00:07 |
| H5 - Mapping method only surfaces in SYSTEM session | NEUTRAL | 08:00:03 script failure before completion; Event 98 at 08:00:07 |

## Status

- All five hypotheses have now been assessed against the provided evidence.
- No winner is declared in this note.

---

## Most Suitable Winner

### Winner: 1) Script was migrated unchanged to SYSTEM context, but the drive mapping requires the user security context

Why this is the strongest fit:
- It is the only hypothesis directly named by both the change record and the execution evidence.
- The change note explicitly states the script was migrated from USER to SYSTEM and was not updated for that execution model.
- The ScriptRunner evidence at 08:00:02 and 08:00:03 shows the script ran as `SYSTEM` and failed because `\\finbridge-fs01\Finance` was not accessible from that context.
- Event 1500 at 08:00:06 shows Group Policy succeeded, which removes GP as the primary fault path and leaves the migrated script behavior as the most direct explanation.

Why the other supported hypotheses rank below it:
- Hypothesis 2 explains an important timing contributor, but it does not explain the explicit statement that the share was inaccessible from `SYSTEM` context.
- Hypothesis 3 is closely related, but it is a narrower mechanism inside the broader context mismatch described by Hypothesis 1.
- Hypothesis 4 explains persistence after the first failure, not the primary reason the first failure occurred.
- Hypothesis 5 remains unproven because the mapping never completed.

Determining evidence:
- 08:00:02 - Intune Management Extension / ScriptRunner log: script context is `SYSTEM`.
- 08:00:03 - Intune Management Extension / ScriptRunner log: `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context at execution time.
- 08:00:03 - Intune Management Extension / ScriptRunner log: script failed with exit code 1 and `Network name cannot be found`.
- Event 1500 at 08:00:06 - Group Policy processed successfully.

Working conclusion:
- The most suitable winner is the USER-to-SYSTEM migration context mismatch.
- Timing and retry behavior are supporting contributors, but not the primary winner.

---

## Surviving Hypothesis

- The surviving hypothesis is: the drive mapping script was migrated unchanged from a USER logon script to an Intune PowerShell script running as SYSTEM, and the mapping requires user context to access `\\finbridge-fs01\Finance` and create the Finance users' drive mapping successfully.

## Detailed Resolution Steps

1. Stop the broken deployment path
- In Intune, disable or unassign the current device-context deployment for `Map-FinBridgeDrives.ps1` so additional logons do not continue failing in the same way.

2. Restore service quickly for users
- Revert to the last known-good user-context method for Finance drive mapping, or deploy an equivalent user-context mapping as the immediate workaround.
- Confirm the mapping targets the Finance user session rather than SYSTEM.

3. Correct the execution model
- Rewrite or redeploy the mapping so it runs in user context after sign-in, not as a SYSTEM startup-time script.
- If Intune must remain the delivery method, use a user-scoped approach rather than a device-scoped SYSTEM script.

4. Remove startup-order dependency
- Ensure the mapping runs only after the user session is established and normal network services are available.
- Avoid execution at the pre-user logon timing that produced the 08:00:03 failure before Workstation was running at Event 7036, 08:00:05.

5. Add resilience for transient early failures
- Add retry or deferred execution logic so a single early miss does not leave the whole session without `S:`.
- Minimum control: one or more delayed retries after network stack and Workstation service availability.

6. Validate access using the intended security principal
- Test the corrected mapping while signed in as a Finance user.
- Confirm the user can open `\\finbridge-fs01\Finance` and that drive `S:` is assigned in the interactive session.

7. Verify at scale on affected estate
- Test on representative `DESKTOP-FB*` Finance devices.
- Confirm the previous failure pattern no longer appears:
  - no ScriptRunner share-access failure at 08:00:03-equivalent runtime
  - no Event 98 warning for drive `S:` not assigned
  - successful user-visible drive mapping after sign-in

8. Close the change gap
- Update the script or deployment documentation to state that user drive mappings must run in user context unless explicitly redesigned for another method.
- Record the migration lesson: do not move user-resource mappings from GPO logon script to SYSTEM-context Intune script without redesigning authentication, timing, and session visibility.

---

## Addendum - Event Details, Surviving Hypothesis, and Resolution

Date added: 2026-08-06
Analyst: DWP Engineer

### Event Details Used

- 08:00:01 - Intune Management Extension / ScriptRunner Info: `Map-FinBridgeDrives.ps1` started.
- 08:00:02 - Intune Management Extension / ScriptRunner Info: script context is `SYSTEM`.
- 08:00:03 - Intune Management Extension / ScriptRunner Warning: `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context at execution time.
- 08:00:03 - Intune Management Extension / ScriptRunner Error: script failed, exit code 1, `Network name cannot be found`.
- 08:00:04 - Intune Management Extension / ScriptRunner Info: no retry configured.
- 08:00:05 - Service Control Manager Event 7036: Workstation service entered running state.
- 08:00:06 - GroupPolicy Event 1500: Group Policy settings processed successfully.
- 08:00:07 - Ntfs Event 98 Warning: file system could not map drive letter `S:`; drive letter not assigned.

### Surviving Hypothesis

- The surviving hypothesis is that the Finance drive mapping failed because the script was moved from a USER-context GPO logon script to a SYSTEM-context Intune script without being redesigned for that execution model.
- The decisive evidence is the direct sequence showing `SYSTEM` execution at 08:00:02, access failure to `\\finbridge-fs01\Finance` from `SYSTEM` at 08:00:03, then script failure before the Workstation service is fully running at Event 7036, 08:00:05.
- Event 1500 at 08:00:06 confirms Group Policy is not the failing control path.

### Resolution

1. Disable the current Intune device-context deployment of `Map-FinBridgeDrives.ps1` to stop repeated failed execution at user logon.
2. Restore the last known-good user-context mapping method, or deploy an equivalent user-context workaround so Finance users regain access to shared drives immediately.
3. Redesign the permanent mapping method so it runs in the signed-in user context and not under SYSTEM.
4. Ensure the mapping runs only after the user session and required network services are available.
5. Add retry or delayed execution logic so a transient early failure does not leave the session without `S:`.
6. Validate the fix with a Finance user by confirming access to `\\finbridge-fs01\Finance` and successful assignment of drive `S:` in the interactive session.
7. Verify on representative `DESKTOP-FB*` devices that the prior failure sequence no longer occurs and that Event 98 is no longer generated for the mapping attempt.
8. Update the migration/change documentation so future drive-mapping moves do not shift user-resource access into SYSTEM context without redesigning authentication, timing, and session visibility.
