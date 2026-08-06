# Root Cause Analysis: User Login Failure - cthompson
**Incident Date:** 2024-03-15
**RCA Date:** 2026-08-06
**Author:** DWP Engineer
**Status:** Resolved

---

## 1. Executive Summary

A single-user login incident impacted FINBRIDGE\cthompson beginning at approximately 08:44. Security logs show repeated bad password attempts from DESKTOP-FB022, followed by automatic account lockout. Additional Kerberos pre-authentication failures from source IP 10.10.8.112 indicate continued use of stale or incorrect credentials from a secondary source during the same incident window. Remediation included containment of repeated attempts, credential reset and account unlock, and stale credential cleanup. Recovery was validated at 09:09 with a successful interactive logon and no further issues reported.

---

## 2. Scope and Impact

| Attribute | Detail |
|---|---|
| Affected user | FINBRIDGE\cthompson |
| User impact | Unable to log in during incident window |
| Start time | ~08:40 (reported), first captured failure at 08:44:01 |
| End time | 09:09 (successful login verified) |
| Broader impact | No evidence of multi-user or platform-wide failure |
| Incident type | Account lockout due to repeated bad password attempts |

---

## 3. Supporting Evidence

### 3.1 Security Log Evidence - Failure and Lockout Sequence

| Timestamp | Event ID | Outcome | Key Details |
|---|---|---|---|
| 08:44:01 | 4776 (Audit Failure) | Credential validation failed | Error 0xC000006A (wrong password), account FINBRIDGE\cthompson, source workstation DESKTOP-FB022 |
| 08:44:03 | 4625 (Audit Failure) | Interactive logon failed | Failure reason: unknown user name or bad password, logon type 2, source DESKTOP-FB022 |
| 08:44:28 | 4625 (Audit Failure) | Interactive logon failed | Failure reason: unknown user name or bad password, logon type 2, source DESKTOP-FB022 |
| 08:44:55 | 4625 (Audit Failure) | Interactive logon failed | Failure reason: unknown user name or bad password, logon type 2, source DESKTOP-FB022 |
| 08:44:56 | 4740 (Audit Failure) | Account lockout triggered | User account locked out, account FINBRIDGE\cthompson, caller computer DESKTOP-FB022 |
| 08:45:10 | 4625 (Audit Failure) | Unlock/sign-in blocked | Failure reason: account locked out, logon type 7, source DESKTOP-FB022 |

### 3.2 Security Log Evidence - Secondary Bad Credential Source

| Timestamp | Event ID | Outcome | Key Details |
|---|---|---|---|
| 08:45:44 | 4771 (Audit Failure) | Kerberos pre-auth failed | Failure code 0x18 (wrong password), source IP 10.10.8.112 |
| 08:46:01 | 4771 (Audit Failure) | Kerberos pre-auth failed | Failure code 0x18 (wrong password), source IP 10.10.8.112 |
| 08:46:33 | 4771 (Audit Failure) | Kerberos pre-auth failed | Failure code 0x18 (wrong password), source IP 10.10.8.112 |

### 3.3 Security Log Evidence - Recovery Confirmation

| Timestamp | Event ID | Outcome | Key Details |
|---|---|---|---|
| 09:08:14 | 4722 (Audit Success) | Account enabled | Account FINBRIDGE\cthompson enabled by FINBRIDGE\helpdesk-admin |
| 09:09:01 | 4624 (Audit Success) | Successful login | Interactive logon type 2, account FINBRIDGE\cthompson, source DESKTOP-FB022 |

### 3.4 Evidence-to-Hypothesis Judgement

| Hypothesis | Judgement | Determining Evidence |
|---|---|---|
| 1) User account lockout from repeated bad password attempts | Supported | 4776 at 08:44:01; 4625 at 08:44:03/08:44:28/08:44:55; 4740 at 08:44:56; 4625 locked-out at 08:45:10 |
| 2) Password expired or outdated password | Neutral | Wrong-password evidence exists (4776, 4771) but no explicit password-expired indicator in provided events |
| 3) Conditional Access or MFA challenge failure | Contradicted | Failures occur at credential validation and lockout stages (4776, 4740), before CA/MFA challenge path |
| 4) Account disabled/restricted by admin state | Neutral | Lockout state is evidenced (4740, 4625 locked out), but no explicit administrative disable/block event in the incident window |
| 5) Endpoint credential cache/profile issue on user device | Neutral | DESKTOP-FB022 failures exist, but parallel failures from 10.10.8.112 weaken a purely single-endpoint explanation |

---

## 4. Incident Timeline

| Time | Event |
|---|---|
| ~08:40 | User-reported onset: cthompson unable to log in. |
| 08:44:01 | Event 4776 wrong-password failure from DESKTOP-FB022. |
| 08:44:03 | Event 4625 interactive logon failure (bad password) from DESKTOP-FB022. |
| 08:44:28 | Event 4625 interactive logon failure (bad password) from DESKTOP-FB022. |
| 08:44:55 | Event 4625 interactive logon failure (bad password) from DESKTOP-FB022. |
| 08:44:56 | Event 4740 account lockout generated for FINBRIDGE\cthompson. |
| 08:45:10 | Event 4625 unlock attempt fails due to account locked out. |
| 08:45:44 | Event 4771 wrong-password Kerberos pre-auth failure from 10.10.8.112. |
| 08:46:01 | Event 4771 wrong-password Kerberos pre-auth failure from 10.10.8.112. |
| 08:46:33 | Event 4771 wrong-password Kerberos pre-auth failure from 10.10.8.112. |
| 09:08:14 | Event 4722 account enabled by helpdesk-admin as part of remediation. |
| 09:09:01 | Event 4624 interactive logon success for FINBRIDGE\cthompson on DESKTOP-FB022. |
| 09:09 | User verified logged in and no further issue reported. |

---

## 5. Root Cause Statement

The immediate technical cause was account lockout (Event 4740 at 08:44:56) triggered by repeated bad password submissions from DESKTOP-FB022 (Events 4776 and 4625 sequence). Contributing evidence shows continued wrong-password Kerberos requests from a second source (10.10.8.112, Event 4771), which increased relock risk until stale credentials were remediated.

---

## 6. Five Whys Analysis

| Why | Question | Answer |
|---|---|---|
| Why 1 | Why could the user not log in? | The account became locked out after repeated failed sign-in attempts. |
| Why 2 | Why did repeated sign-in attempts fail? | Authentication attempts used incorrect credentials (wrong password errors 0xC000006A and 0x18). |
| Why 3 | Why were incorrect credentials repeatedly submitted? | At least one endpoint/session continued attempting authentication with stale or incorrect saved credentials. |
| Why 4 | Why was stale credential use not stopped before lockout? | Credential retries occurred from more than one source (DESKTOP-FB022 and 10.10.8.112), indicating credential hygiene was not synchronized across devices/services at the time of failure. |
| Why 5 | Why did multi-source stale credential retries persist operationally? | The operational process lacked a strict, immediate post-failure containment checklist to identify and suppress all active bad-credential sources before unlocking/reset validation. |

**5-Why conclusion:** The incident was caused by repeated incorrect credential attempts leading to lockout, with persistence driven by unsuppressed stale credential sources across multiple endpoints.

---

## 7. Resolution Actions Applied

1. Confirmed lockout and error sequence in security events (4776, repeated 4625, 4740, post-lockout 4625).
2. Identified and addressed continued bad-credential activity from secondary source IP 10.10.8.112.
3. Performed account recovery actions including account enable (Event 4722 at 09:08:14).
4. Validated successful interactive user sign-in after recovery (Event 4624 at 09:09:01 on DESKTOP-FB022).
5. Confirmed user-reported service restoration at 09:09 with no ongoing symptoms.

---

## 8. Preventive Actions

| # | Action | Owner | Priority | Target |
|---|---|---|---|---|
| 1 | Implement lockout containment runbook: identify all active sign-in sources, stop retries, then unlock/reset. | Service Desk / Identity Ops | High | Immediate |
| 2 | Add mandatory stale-credential sweep after any password reset or lockout (desktop, mobile, mail clients, scheduled tasks, services). | Service Desk | High | Immediate |
| 3 | Add alerting for repeated 4771/4625 bursts by account across multiple sources within 5 minutes. | SOC / Monitoring | Medium | 2 sprints |
| 4 | Add account-lockout rapid triage checklist with required evidence capture (4776, 4625, 4740, 4771, 4624, source host/IP). | Identity Ops | Medium | 1 sprint |
| 5 | Improve user guidance for password-change hygiene across all devices and apps to prevent legacy retries. | IT Operations / End User Support | Medium | 1 sprint |
| 6 | Track repeat lockout users and perform targeted remediation on recurring unmanaged credential stores. | Identity Ops | Medium | Ongoing |

---

## 9. Validation and Closure Criteria

Closure criteria met:
- Successful account recovery action logged: Event 4722 at 09:08:14.
- Successful interactive login logged: Event 4624 at 09:09:01.
- User verified access restored at 09:09.
- No additional issue reported after successful login.

Incident closure status: Resolved.

---

## 10. References

- Hypothesis analysis: Day4/hypothesis-login-failure-cthompson-2026-08-06.md
- Related prior example RCA: Day3/rca-user-lockout-jsmith-2026-08-05.md
- Primary evidence source: Security event logs from DESKTOP-FB022 during 08:44-09:12 window and recovery events at 09:08-09:09.
