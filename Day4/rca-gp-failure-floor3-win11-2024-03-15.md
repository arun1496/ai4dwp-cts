# Root Cause Analysis — Group Policy Failure, Floor 3 Win11 Machines

**Incident ID:** INC-2024-0315-GP-FLOOR3  
**Date of Incident:** 2024-03-15  
**Date of RCA:** 2026-08-06  
**Analyst:** DWP Engineer  
**Status:** Resolved  

---

## Executive Summary

On 2024-03-15 at approximately 07:40, three Windows 11 machines on Floor 3 (DESKTOP-FB055, FB056, FB057) failed to apply Group Policy at logon. The root cause was the DHCP scope for the Floor 3 subnet (10.10.3.0/24) still assigning a decommissioned DNS server address (10.10.3.250 / 172.16.5.5) following an overnight DNS migration. Because the old DNS server was already offline, affected machines had no working resolver at boot time, preventing DC name resolution and causing the entire GP processing chain to fail. The fix — correcting DHCP Option 6, renewing leases, and running `gpupdate /force` — fully resolved the issue. All three machines were verified healthy at **09:09 on 2026-08-06**.

---

## Incident Details

| Field | Value |
|---|---|
| Affected machines | DESKTOP-FB055, DESKTOP-FB056, DESKTOP-FB057 (Floor 3, OU=Finance) |
| Unaffected control | DESKTOP-FB058 / DESKTOP-FB029 (same floor, same OU — manually pre-configured DNS) |
| Symptom | Group Policy not applied at logon |
| Incident start | 2024-03-15 ~07:40 (first boot after overnight DNS migration) |
| Incident end / verified resolved | 2026-08-06 09:09 |
| Triggering change | DNS migration overnight 2024-03-14 — decommission of local Floor 3 DNS servers |

---

## Timeline

| Time | Event |
|---|---|
| 2024-03-14 ~02:00 | DNS migration executed. Floor 3 local DNS servers (172.16.5.5 / 10.10.3.250) decommissioned and taken offline. Central DNS server 10.10.0.10 designated as replacement. |
| 2024-03-14 ~02:00 | DHCP scope for Floor 3 subnet (10.10.3.0/24) **not updated** — Option 6 still references 172.16.5.5 / 10.10.3.250. |
| 2024-03-15 07:40:05 | DESKTOP-FB029 (unaffected) obtains DHCP lease — DNS assigned 10.10.0.10 (pre-configured static; correct). |
| 2024-03-15 07:40:08 | **Event 5719 (Netlogon)** on FB031 — no secure channel to FINBRIDGE; DC unreachable; DNS query returned no response. |
| 2024-03-15 07:40:09 | **Event 1058 (GroupPolicy)** — SYSVOL path inaccessible, error 0x3. |
| 2024-03-15 07:40:10 | **Event 1030 (GroupPolicy)** — cannot query GPO list, error 0x546. |
| 2024-03-15 07:40:11 | **Event GP 1500 (FB029)** — Group Policy processed successfully on unaffected control machine. |
| 2024-03-15 07:40:12 | **Event 1129 (GroupPolicy)** — GP failed; no network connectivity to DC. |
| 2024-03-15 07:41:05 | **Event 1014 (DNS Client)** — name resolution for FINBRIDGE-DC01.finbridge.local timed out; no DNS server responded. |
| 2024-03-15 07:42:18 | **Event 50036 (DHCP Client)** — lease from 10.10.0.1; DNS assigned 10.10.3.250 (decommissioned at 02:00). |
| 2026-08-06 (morning) | Incident investigated. DHCP scope Option 6 confirmed still referencing 10.10.3.250 on Floor 3 scope. |
| 2026-08-06 (morning) | Resolution applied: DHCP Option 6 updated to 10.10.0.10; leases renewed on FB055/FB056/FB057; `gpupdate /force` executed. |
| 2026-08-06 09:09 | All three machines verified — users logging in successfully, no GP errors, incident closed. |

---

## Supporting Evidence

### Event Log — DESKTOP-FB031 (representative for affected machines), 2024-03-15 07:40–07:55

| Time | Source | Event ID | Detail |
|---|---|---|---|
| 07:40:08 | Netlogon | 5719 | No secure channel to FINBRIDGE — DC unreachable; DNS query for FINBRIDGE-DC01.finbridge.local returned no response |
| 07:40:09 | GroupPolicy | 1058 | SYSVOL path inaccessible, error 0x3 |
| 07:40:10 | GroupPolicy | 1030 | Cannot query GPO list, error 0x546 |
| 07:40:12 | GroupPolicy | 1129 | GP failed — no network connectivity to DC |
| 07:41:05 | DNS Client | 1014 | Name resolution for FINBRIDGE-DC01.finbridge.local timed out — no DNS server responded |
| 07:42:18 | DHCP Client | 50036 | Lease from 10.10.0.1; DNS assigned: 10.10.3.250 (decommissioned 02:00) |

### Control Machine Evidence — DESKTOP-FB029 (unaffected), same floor / same OU

| Time | Source | Event | Detail |
|---|---|---|---|
| 07:40:05 | DHCP Client | 50036 | DNS assigned: 10.10.0.10 (correct central DNS — machine was manually pre-configured) |
| 07:40:11 | GroupPolicy | 1500 | Group Policy processed successfully |

The control machine differs from affected machines in exactly one variable: DNS server assignment source. Its successful GP processing at 07:40:11 — 6 seconds after obtaining correct DNS — directly isolates DNS assignment as the sole causal factor.

### DHCP Server Log Comparison

| Machine | DNS Assigned | Source |
|---|---|---|
| DESKTOP-FB055 | 172.16.5.5 / 10.10.3.250 | DHCP scope Option 6 (stale) |
| DESKTOP-FB056 | 172.16.5.5 / 10.10.3.250 | DHCP scope Option 6 (stale) |
| DESKTOP-FB057 | 172.16.5.5 / 10.10.3.250 | DHCP scope Option 6 (stale) |
| DESKTOP-FB058 | 10.10.0.10 | Manual static pre-configuration |

---

## Root Cause

The DHCP scope for the Floor 3 subnet (10.10.3.0/24) was not updated as part of the DNS migration on 2024-03-14. Option 6 (DNS Servers) continued to reference the decommissioned servers (172.16.5.5 / 10.10.3.250). Because those servers were taken offline at ~02:00 before the DHCP scope was corrected, machines that obtained a DHCP lease during and after the migration received a non-functional DNS address. At first boot on 2024-03-15, affected machines could not resolve the DC FQDN, which caused Netlogon to fail to establish a secure channel, which in turn caused the entire Group Policy processing chain to fail.

---

## 5 Whys Analysis

| Why | Answer |
|---|---|
| **Why** did Group Policy fail on FB055, FB056, FB057? | The machines could not contact the domain controller — Netlogon event 5719 states DC was unreachable due to DNS resolution failure. |
| **Why** did DNS resolution fail? | The DNS servers configured on the affected machines (10.10.3.250 / 172.16.5.5) were offline and returned no response — DNS Client event 1014. |
| **Why** were the machines configured with offline DNS servers? | The DHCP scope for the Floor 3 subnet (10.10.3.0/24) still had the decommissioned DNS addresses in Option 6 — the scope was not updated during the DNS migration. |
| **Why** was the DHCP scope not updated during the migration? | The DNS migration runbook did not include a step to audit and update all DHCP scopes before decommissioning the old DNS servers. The scope update was missed for the Floor 3 subnet. |
| **Why** was there no DHCP scope audit step in the runbook? | The migration was planned with DNS server decommission as the final step, but no pre-decommission validation gate was defined to confirm all DHCP scopes referencing the old DNS addresses had been updated. |

**Root cause statement:** The DNS migration runbook lacked a pre-decommission DHCP scope audit gate, allowing the Floor 3 DHCP scope to retain stale DNS Option 6 entries after the old DNS servers were taken offline.

---

## Resolution Applied

1. DHCP server — Floor 3 scope (10.10.3.0/24) Option 6 updated: removed 10.10.3.250 / 172.16.5.5, added 10.10.0.10.
2. All other DHCP scopes audited and confirmed clean.
3. On DESKTOP-FB055, FB056, FB057: `ipconfig /release`, `ipconfig /renew`, `ipconfig /flushdns` executed.
4. `ipconfig /all` confirmed DNS servers = 10.10.0.10 on all three machines.
5. `gpupdate /force` executed on all three machines — GP 1500 (success) observed in Application log.
6. `nltest /sc_query:FINBRIDGE` confirmed healthy Netlogon secure channel on all three machines.
7. Interactive logon verified for affected users — no errors reported.

**Verified resolved: 2026-08-06 09:09.** Users logging in successfully, no GP errors, no repeat of events 5719 / 1058 / 1030 / 1129 / 1014.

---

## Preventive Actions

| # | Action | Owner | Priority |
|---|---|---|---|
| 1 | Update the DNS migration runbook to require a full DHCP scope audit (checking Option 6 on all scopes) as a mandatory pre-decommission gate check before any DNS server is taken offline. | Change / Infrastructure team | High |
| 2 | Create a pre-migration validation script that queries all DHCP scopes across all servers and reports any scope still referencing IP addresses on the decommission list. Run this as a required sign-off step in the change record. | Infrastructure / Automation team | High |
| 3 | After any DNS migration, run a post-change verification: resolve the DC FQDN from at least one machine per subnet before declaring the change complete. | Change manager / engineer on duty | Medium |
| 4 | Identify all machines that rely on DHCP-assigned DNS (vs. static / pre-configured) and include them explicitly in the migration test scope. Machines with manual DNS pre-configuration (like FB058) should be documented as exceptions, not used as the sole validation sample. | Infrastructure team | Medium |
| 5 | Add a Known Error record to the ITSM tool capturing this failure pattern (stale DHCP DNS option after server decommission) so that future incidents with the same symptom chain (5719 + 1014 + DHCP 50036 showing old DNS) can be triaged immediately. | Service Desk / Problem management | Low |

---

## Lessons Learned

- A single unaffected control machine (FB058) was the key discriminator. It differed from affected machines in exactly one variable (DNS assignment source), which allowed rapid hypothesis elimination.
- DNS Client Event 1014 ("none responded") is a critical distinguisher: it indicates a fully offline resolver, not a misconfigured-but-reachable one. This immediately directed investigation toward server decommission rather than zone or firewall issues.
- Netlogon 5719 has two distinct failure modes — DNS-caused (DC never contacted) and trust-caused (DC reachable but rejects channel). The event text must be read carefully to distinguish them.
- Decommissioning infrastructure before validating all consumers of that infrastructure is a repeating risk pattern. The fix must be enforced at the process level (runbook gate), not relied upon as an engineer's checklist item.
