Symptom : FINBRIDGE\cthompson is unable to log in. During the incident window, interactive sign-in attempts failed and one unlock attempt was blocked because the account was locked out.

Cause : The verified root cause was account lockout (Event 4740 at 08:44:56) triggered by repeated bad password submissions from DESKTOP-FB022 (Events 4776 and 4625). Continued wrong-password Kerberos pre-authentication requests from 10.10.8.112 (Event 4771) increased relock risk until stale credentials were remediated.

Scope : Affected user was FINBRIDGE\cthompson only. No multi-user or platform-wide impact was evidenced in the RCA; observed sources were DESKTOP-FB022 and 10.10.8.112.

Workaround : Immediately stop repeated sign-in retries and contain active bad-credential sources, including DESKTOP-FB022 and 10.10.8.112. Perform account recovery (Event 4722) and then verify successful interactive sign-in (Event 4624).

Permanent fix: Implement the lockout containment runbook to identify all active sign-in sources, stop retries, then unlock/reset in a controlled sequence. Enforce a mandatory stale-credential sweep after any password reset or lockout across relevant credential stores.

How to spot it: Look for this sequence in Security logs for the same account: Event 4776 with error 0xC000006A, repeated Event 4625 bad-password interactive failures (Logon Type 2), then Event 4740 lockout, followed by Event 4625 showing account locked out (Logon Type 7). Corroborate with repeated Event 4771 failures from any secondary source using failure code 0x18, and confirm recovery with Event 4722 then Event 4624.
