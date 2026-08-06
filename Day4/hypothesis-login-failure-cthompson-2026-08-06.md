# Hypothesis Analysis - User Login Failure (cthompson)

Date: 2026-08-06  
Analyst: DWP Engineer  
Scope basis only: single affected user (`cthompson`), symptom started ~08:40 today, no declared change.

## Scope Facts Used
- Symptom: `cthompson` unable to log in.
- Impact: one user only.
- Start time: approximately 08:40 this morning.
- Declared change: none.

## Ranked Likely Causes (Most Probable First)

### 1) User account lockout from repeated bad password attempts
Why this fits the scope facts:
- A one-user-only incident strongly aligns with an account-specific condition rather than a platform-wide fault.
- A sudden start time (~08:40) is consistent with lockout threshold being reached at a specific moment.
- "No change" does not conflict; lockouts often occur without formal change.

Fastest single check:
- In AD/Azure sign-in/account status, check whether `cthompson` is currently locked out and review latest failed sign-in reason around 08:40.

### 2) Password expired or user entering an outdated password
Why this fits the scope facts:
- Single-user impact is consistent with credential lifecycle/user memory issue.
- The abrupt onset suggests a time boundary event (expiry window reached) or recent password mismatch.
- No service change required for this to occur.

Fastest single check:
- Check account password status/expiry and attempt a controlled sign-in test with known-correct credentials (or trigger password reset and retest).

### 3) Conditional Access / MFA challenge failure specific to this user
Why this fits the scope facts:
- Conditional Access and MFA issues can affect only one user if challenge method, device registration, or user policy assignment differs.
- Sudden failure at a known time can map to token expiry or failed second-factor prompt.
- No declared infrastructure change is needed.

Fastest single check:
- Review the latest Entra ID sign-in log entry for `cthompson` and inspect failure reason (CA block, MFA failure, unmet grant control).

### 4) Account disabled/restricted or sign-in blocked by identity admin state
Why this fits the scope facts:
- A user-only incident maps directly to user object state problems.
- Start time can reflect an administrative action or automated identity governance event.
- "No change" from reporter perspective does not rule out backend admin/security actions.

Fastest single check:
- Inspect account properties for `cthompson` (enabled/disabled, sign-in allowed, risk state) in identity admin portal.

### 5) Endpoint-specific credential cache/profile issue on user’s device
Why this fits the scope facts:
- A single affected person may indicate local workstation/profile corruption rather than account or service fault.
- Sudden onset with no known change is common for token/cache corruption.
- Does not imply broader user impact.

Fastest single check:
- Perform a login attempt for `cthompson` from a known-good alternate device/session; if successful there, local endpoint/profile issue is highly likely.

## Notes
- This is a hypothesis ranking only, based strictly on provided scope facts.
- No single root cause is committed at this stage.
- Next action should be to run the five checks in order until one is confirmed or eliminated.

---

## Addendum - Event Evidence Review and Resolution Update

Date added: 2026-08-06  
Analyst: DWP Engineer

### Event Evidence Used (Security Log, DESKTOP-FB022, Window 08:44-09:12)
- 08:44:01 - Event 4776 Audit Failure - 0xC000006A (wrong password) - Account `FINBRIDGE\cthompson`.
- 08:44:03 - Event 4625 Audit Failure - unknown user name or bad password - Logon type 2 - Source `DESKTOP-FB022`.
- 08:44:28 - Event 4625 Audit Failure - unknown user name or bad password - Logon type 2 - Source `DESKTOP-FB022`.
- 08:44:55 - Event 4625 Audit Failure - unknown user name or bad password - Logon type 2 - Source `DESKTOP-FB022`.
- 08:44:56 - Event 4740 Audit Failure - user account locked out - Caller computer `DESKTOP-FB022`.
- 08:45:10 - Event 4625 Audit Failure - account locked out - Logon type 7 (unlock attempt) - Source `DESKTOP-FB022`.
- 08:45:44 - Event 4771 Audit Failure - Kerberos pre-auth failed - 0x18 (wrong password) - Source IP `10.10.8.112`.
- 08:46:01 - Event 4771 Audit Failure - Kerberos pre-auth failed - 0x18 (wrong password) - Source IP `10.10.8.112`.
- 08:46:33 - Event 4771 Audit Failure - Kerberos pre-auth failed - 0x18 (wrong password) - Source IP `10.10.8.112`.

### Hypothesis-by-Hypothesis Elimination Outcome

1. User account lockout from repeated bad password attempts
- Judgement: Supports.
- Determining events: 4776 at 08:44:01, 4625 at 08:44:03/08:44:28/08:44:55, 4740 at 08:44:56, and 4625 (locked out) at 08:45:10.

2. Password expired or user entering an outdated password
- Judgement: Neutral.
- Determining events: 4776 at 08:44:01 and 4771 at 08:45:44/08:46:01/08:46:33 show wrong password, but no explicit expiry indicator.

3. Conditional Access / MFA challenge failure specific to this user
- Judgement: Contradicts.
- Determining events: 4776 at 08:44:01 (primary credential failure) and 4740 at 08:44:56 (lockout) indicate failure before CA/MFA challenge stage.

4. Account disabled/restricted or sign-in blocked by identity admin state
- Judgement: Neutral.
- Determining events: 4740 at 08:44:56 and 4625 at 08:45:10 confirm lockout state, but do not show an administrative disable/block action.

5. Endpoint-specific credential cache/profile issue on user's device
- Judgement: Neutral.
- Determining events: 4625 failures from `DESKTOP-FB022` and 4771 failures from a different source (`10.10.8.112`) do not support a purely single-endpoint explanation.

### Surviving Hypothesis
- User account lockout from repeated bad password attempts.

### Detailed Resolution Steps

1. Confirm and document lockout sequence
- Validate and record the event chain: 4776 wrong password, repeated 4625 bad password, 4740 lockout, then 4625 locked out.
- Record continuing wrong-password attempts from `10.10.8.112` after lockout.

2. Contain immediate relock risk before unlock/reset
- Identify host/device for `10.10.8.112` via DHCP/DNS/CMDB/EDR.
- Stop active authentication attempts from that source (sign out sessions, disable task/service using cached credentials, or isolate briefly if needed).
- Instruct user to stop repeated login attempts on `DESKTOP-FB022` until reset is complete.

3. Reset and recover account access
- Reset password for `cthompson`.
- Unlock account.
- Confirm account is enabled and sign-in allowed.

4. Clear stale credentials across all likely endpoints
- On `DESKTOP-FB022`: clear Credential Manager entries, reauthenticate Office/Teams/OneDrive, retest interactive sign-in.
- On source `10.10.8.112`: clear cached credentials and update any saved credentials in scheduled tasks/services/apps.
- Re-enter updated credentials on mobile clients or additional devices if used.

5. Validate stabilization
- Verify successful user sign-in events after reset/unlock.
- Confirm no new 4740 lockout events.
- Monitor 30-60 minutes for recurring 4625/4771 failures for `cthompson`.

6. Close and prevent recurrence
- Document root cause as repeated bad password attempts causing lockout, with a secondary bad credential source from `10.10.8.112`.
- Add a post-reset hygiene checklist for multi-device/app credential updates.
