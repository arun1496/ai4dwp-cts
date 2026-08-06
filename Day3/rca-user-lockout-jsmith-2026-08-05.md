# RCA: User Lockout Incident (jsmith)

## Incident Summary
- User: `jsmith`
- Time window reviewed: 08:02:14 to 08:23:44 (about 22 minutes)
- System: Windows Security Event Log
- Source host in failed attempts: `DESKTOP-FB001`
- Outcome: Account locked, then re-enabled by helpdesk, then successful interactive logon.

## Event ID Meaning (What Each Event Records)

### Event ID 4625 (Audit Failure) - Failed logon attempt
This records a failed authentication attempt. Important fields in this case:
- Failure reason: `Unknown username or bad password` (wrong credentials submitted)
- Logon type `2`: Interactive logon at local console/keyboard sign-in
- Logon type `7`: Unlock attempt against existing session

In this incident, `4625` appears three times:
- Two failed interactive sign-ins before lockout
- One failed unlock after lockout because the account was already locked

### Event ID 4740 (Audit Failure) - Account lockout
This records that the account lockout threshold was reached and Windows locked the account.
- Account locked: `jsmith`
- Caller/source machine: `DESKTOP-FB001`

This is the key control-plane event proving lockout occurred and where the triggering attempts came from.

### Event ID 4722 (Audit Success) - Account enabled
This records that an account was enabled (or re-enabled) by an administrator.
- Target account: `jsmith`
- Performed by: `FINBRIDGE\helpdesk-admin`

In context, this indicates helpdesk intervention to restore account usability after lockout.

### Event ID 4624 (Audit Success) - Successful logon
This records successful authentication.
- Logon type `2`: Interactive local sign-in

This confirms user access was restored after admin action.

## Reconstructed Sequence of Events (Plain English)
1. At 08:02:14, `jsmith` entered bad credentials at the machine console (`4625`, type 2).
2. At 08:04:22, another bad interactive sign-in occurred (`4625`, type 2).
3. At 08:06:01, account lockout was triggered (`4740`) from `DESKTOP-FB001`.
4. At 08:07:45, someone attempted to unlock/sign in again, but it failed because the account was already locked (`4625`, type 7, reason account locked out).
5. At 08:22:10, helpdesk admin `FINBRIDGE\helpdesk-admin` enabled/re-enabled the account (`4722`).
6. At 08:23:44, `jsmith` successfully logged on interactively (`4624`, type 2).

## Most Likely Cause of Lockout
Most likely cause: repeated incorrect password entry at the local workstation, causing lockout threshold to be met.

### Evidence supporting this conclusion
- Two pre-lockout failed interactive logons (`4625`, logon type 2) with `Unknown username or bad password`.
- Lockout event (`4740`) immediately follows those failures and identifies the same endpoint (`DESKTOP-FB001`) as source.
- Post-lockout failed unlock (`4625`, type 7) confirms the account state changed to locked, not an ongoing username typo only.
- Successful logon after admin re-enable (`4722` then `4624`) indicates no persistent endpoint auth stack failure.

## Alternate Possibilities Considered
- Stale cached credentials in another service/process: less likely because all visible failures point to local interactive/unlock behavior on the same desktop, not network/service logon types.
- AD replication or domain controller issue: not supported by events shown; lockout and recovery sequence is internally consistent on one endpoint.

## 5 Whys Analysis
1. Why was `jsmith` locked out?
Because the account exceeded configured bad-password threshold and triggered lockout (`4740`).

2. Why was the threshold exceeded?
Because there were repeated failed sign-ins with bad credentials (`4625` at 08:02:14 and 08:04:22).

3. Why were bad credentials repeatedly entered?
Most likely user entered an incorrect password multiple times during interactive logon at `DESKTOP-FB001`.

4. Why did the user continue attempts until lockout instead of recovery earlier?
No immediate guided recovery occurred before threshold (for example, password reset/self-service prompt/helpdesk escalation before final attempts).

5. Why did recovery require manual helpdesk action?
Account remained locked until admin intervention (`4722` by `FINBRIDGE\helpdesk-admin`), indicating operational dependency on support flow once lockout occurs.

## RCA Statement
The lockout was caused by repeated incorrect interactive password attempts on `DESKTOP-FB001`, which reached lockout policy threshold and generated `4740`. The account remained unusable until helpdesk re-enabled it, after which `jsmith` logged on successfully.

## Corrective and Preventive Actions
1. User coaching: reinforce password-check steps and lockout threshold awareness at sign-in.
2. Validate SSPR/help instructions visibility on lock screen to reduce repeated bad attempts.
3. Review lockout policy communication (threshold and lockout duration) with end users.
4. For repeat incidents, correlate with workstation keyboard layout/time-sync and credential manager artifacts.
5. Add service desk runbook step: capture bad-logon count and source host before unlock to detect brute force vs user error.

## Confidence and Limitations
- Confidence: High for immediate cause (bad password attempts leading to lockout).
- Limitation: This RCA uses only the provided event subset for a 30-minute window; no domain controller-side full security log correlation included.
