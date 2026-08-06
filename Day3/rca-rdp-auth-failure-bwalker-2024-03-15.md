# RCA: RDP Authentication Failure Incident (2024-03-15)

## Incident Summary
- User: `FINBRIDGE\bwalker`
- Time window reviewed: 14:01:02 to 14:22:09
- Log sources: Windows System and Security logs
- Client IP: `10.10.5.44`
- Outcome: Multiple failed RDP logons led to account lockout; later connection succeeded.

## Reconstructed Event Sequence (Plain English)
1. At 14:01:02, the RDP stack recorded a failed connection attempt from `10.10.5.44` and reported that the supplied user name or password was not correct (System, `RemoteDesktopServices-RdpCoreTS`, Event ID `140`).
2. At 14:01:02, the RDP session was then disconnected because the Terminal Server security layer detected an error in the protocol stream from the same client IP (System, `TermDD`, Event ID `56`).
3. At 14:01:04, Windows Security logged a failed RemoteInteractive logon for `FINBRIDGE\bwalker` from `10.10.5.44` with failure reason `Unknown username or bad password` (Security, Event ID `4625`, Logon Type `10`).
4. At 14:03:18, a second failed RDP logon for the same account and source IP was recorded with the same bad-credentials reason (Security, Event ID `4625`, Logon Type `10`).
5. At 14:05:33, a third failed RDP logon for the same account and source IP was recorded, again with `Unknown username or bad password` (Security, Event ID `4625`, Logon Type `10`).
6. At 14:05:34, immediately after the third failure, the account `FINBRIDGE\bwalker` was locked out, with caller computer `10.10.5.44` (Security, Event ID `4740`).
7. At 14:22:07, the server accepted a new TCP connection from `10.10.5.44` (System, `RemoteDesktopServices-RdpCoreTS`, Event ID `131`).
8. At 14:22:09, `FINBRIDGE\bwalker` successfully completed an RDP logon from `10.10.5.44` (Security, Event ID `4624`, Logon Type `10`).

## System and Security Correlation
- The System log at 14:01:02 shows the RDP service rejecting the session because credentials were incorrect (Event ID `140`) and then tearing down the session (Event ID `56`).
- The Security log two seconds later confirms the authentication failure for the same source IP and the same RDP logon type (`4625`, Type `10`).
- Repeated Security `4625` failures at 14:01:04, 14:03:18, and 14:05:33 from `10.10.5.44` establish a repeated bad-credential pattern.
- Security `4740` at 14:05:34 ties the resulting account lockout directly to the same source IP.
- Later System `131` and Security `4624` events confirm that connectivity to the RDP service was still possible and that authentication eventually succeeded from the same client.

## Most Likely Root Cause
Most likely root cause: repeated submission of incorrect credentials during RDP logon caused authentication failures and triggered the domain account lockout threshold for `FINBRIDGE\bwalker`.

## Evidence
1. Incorrect-credential indication at the RDP layer:
- 2024-03-15 14:01:02, System, `RemoteDesktopServices-RdpCoreTS`, Event ID `140`
- Message: `A connection from the client computer with an IP address of 10.10.5.44 failed because the user name or password is not correct.`

2. Matching failed remote logons in Security:
- 2024-03-15 14:01:04, Security, Event ID `4625`, Logon Type `10`, account `FINBRIDGE\bwalker`, source IP `10.10.5.44`
- 2024-03-15 14:03:18, Security, Event ID `4625`, Logon Type `10`, account `FINBRIDGE\bwalker`, source IP `10.10.5.44`
- 2024-03-15 14:05:33, Security, Event ID `4625`, Logon Type `10`, account `FINBRIDGE\bwalker`, source IP `10.10.5.44`
- Failure reason on each: `Unknown username or bad password`

3. Lockout immediately follows repeated failures:
- 2024-03-15 14:05:34, Security, Event ID `4740`
- Message: `A user account was locked out`
- Account: `FINBRIDGE\bwalker`
- Caller computer: `10.10.5.44`

4. Successful recovery later from the same client:
- 2024-03-15 14:22:07, System, `RemoteDesktopServices-RdpCoreTS`, Event ID `131`
- Message: `Server accepted a new TCP connection from client 10.10.5.44:52341.`
- 2024-03-15 14:22:09, Security, Event ID `4624`, Logon Type `10`, account `FINBRIDGE\bwalker`, source IP `10.10.5.44`

## Confirmed Findings
- The failed access was an RDP logon path, confirmed by Security Logon Type `10` and RDP-related System sources.
- The same client IP, `10.10.5.44`, appears across the System and Security events tied to the failure sequence.
- The user account `FINBRIDGE\bwalker` had three failed remote logons before lockout.
- The account was locked out immediately after the third failed attempt.
- A later RDP logon from the same IP succeeded.

## Assumptions and Inferences
- The `TermDD` Event ID `56` protocol-stream error was a secondary effect of the failed authentication/session teardown, not a separate network transport outage. This is likely because it occurs at the same second as the bad-credential RDP event and is followed by repeated credential failures rather than connectivity errors.
- The successful 14:22:09 logon likely means the correct password was later used or the account was unlocked/reset in the interim. That remediation step is not shown directly in the provided events.
- There is no evidence in the supplied events of an RDP service outage, listener failure, or firewall block; the dataset supports an authentication problem rather than a platform availability problem.

## RCA Statement
The RDP failure was most likely caused by incorrect credentials entered for `FINBRIDGE\bwalker` from client `10.10.5.44`. Repeated Security `4625` failures and the immediate `4740` lockout show that authentication failures, not RDP service availability, were the controlling cause of the incident. The later successful `4624` RDP logon from the same IP further supports that the service remained reachable and the issue was resolved once the account/password state was corrected.

## Confidence and Limitations
- Confidence: High for the immediate cause being bad credentials leading to lockout.
- Limitation: The provided dataset does not include domain controller unlock/reset events or client-side credential source details, so the exact reason the wrong password was submitted cannot be proven.