# End-User Communications — Group Policy Failure, Floor 3 Win11 Machines

**Incident:** INC-2024-0315-GP-FLOOR3  
**Date:** 2026-08-06  
**Resolved:** 09:09  

---

## Audience 1 — Non-Technical Executive

Your systems, access, and data were not at risk at any point. This morning, three computers on Floor 3 were briefly unable to load their standard settings at login due to an incomplete configuration step carried over from a planned infrastructure update last night. The issue was identified and fixed; all machines were confirmed working by 09:09. No action is required from you.

---

## Audience 2 — Affected End-User Team

Good news — the issue affecting Floor 3 computers this morning has been fully resolved as of 09:09. What happened: a setting left over from planned overnight maintenance meant three computers could not connect to the network properly at login, which prevented your desktop settings from loading. Your computers are now working normally. If you experience any login or settings problems, please restart your machine first. If the issue persists after restarting, contact the IT Service Desk and reference **INC-2024-0315-GP-FLOOR3**.

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Incident:** INC-2024-0315-GP-FLOOR3  
**Resolved:** 2026-08-06 09:09  

### Root Cause

DNS migration on 2024-03-14 ~02:00 decommissioned Floor 3 local DNS servers (172.16.5.5 / 10.10.3.250) but the DHCP scope for the Floor 3 subnet (10.10.3.0/24) was not updated — Option 6 still referenced the dead addresses. Machines booting at 07:40 on 2024-03-15 received a non-functional resolver via DHCP lease, causing silent DNS timeout → Netlogon 5719 (DC unreachable, DNS returned no response) → GP 1058 / 1030 / 1129 chain. Unaffected machine DESKTOP-FB058 had DNS manually pre-configured to 10.10.0.10 and was the control discriminator.

**Key events (DESKTOP-FB031, representative):**

| Time | Event | Detail |
|---|---|---|
| 07:40:08 | Netlogon 5719 | DC unreachable — DNS query returned no response |
| 07:40:09 | GroupPolicy 1058 | SYSVOL inaccessible, error 0x3 |
| 07:40:10 | GroupPolicy 1030 | Cannot query GPO list, error 0x546 |
| 07:40:12 | GroupPolicy 1129 | GP failed — no DC connectivity |
| 07:41:05 | DNS Client 1014 | FINBRIDGE-DC01.finbridge.local timed out — none responded |
| 07:42:18 | DHCP Client 50036 | DNS assigned 10.10.3.250 (decommissioned 02:00) |

Control confirmation: FB029 received DNS 10.10.0.10 via DHCP at 07:40:05 → GP 1500 success at 07:40:11.

### Action Taken

1. DHCP server — Floor 3 scope (10.10.3.0/24) Option 6: removed 10.10.3.250 / 172.16.5.5, set 10.10.0.10.
2. All remaining DHCP scopes audited — no other stale entries found.
3. On FB055, FB056, FB057: `ipconfig /release && ipconfig /renew && ipconfig /flushdns`.
4. Confirmed `ipconfig /all` shows DNS = 10.10.0.10 on all three.
5. `gpupdate /force` — GP 1500 observed in Application log on all three.
6. `nltest /sc_query:FINBRIDGE` — healthy secure channel confirmed on all three.
7. Interactive logon verified by users — no errors.

### Verification Step if This Recurs

From affected machine, check `ipconfig /all` for DNS server address. If it shows any address other than 10.10.0.10 (or current authoritative DNS), check DHCP scope Option 6 on the server immediately — do not waste time on GP or Netlogon until DNS assignment is confirmed correct. DNS Client 1014 + Netlogon 5719 with "no response" wording = resolver is offline, not misconfigured.

### Preventive Action Required

The DNS migration runbook must be updated to include a mandatory pre-decommission gate: query all DHCP scopes across all DHCP servers and confirm zero scopes reference any IP on the decommission list before any DNS server is taken offline. A validation script should be built to automate this check and its output must be attached to the change record as sign-off evidence. Assign to Infrastructure team — priority high.

**Reference:** [Day4/rca-gp-failure-floor3-win11-2024-03-15.md](rca-gp-failure-floor3-win11-2024-03-15.md)
