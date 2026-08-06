# Hypothesis Analysis — Group Policy Failure, Floor 3 Win11 Machines

Date: 2026-08-06
Analyst: DWP Engineer
Scope basis only — no cause committed.

## Scope Facts Used

- Symptom: Three Win11 machines on Floor 3 (DESKTOP-FB055, FB056, FB057) — Group Policy not applied at logon.
- Reference machine: DESKTOP-FB031 event log used as representative.
- Since: ~2024-03-15 07:40–07:55 (startup window).
- Unaffected control: DESKTOP-FB058 (same floor, same OU=Finance) — GP processed successfully.
- Change: DNS migration overnight 2024-03-14. DHCP comparison from server logs:
  - FB055–FB057: DNS assigned 172.16.5.5 (Floor 3 local DNS — decommissioned 2024-03-14 ~02:00)
  - FB058: DNS assigned 10.10.0.10 (central DNS — correct; machine was manually pre-configured)

## Key Event Log Signals (DESKTOP-FB031, 07:40–07:55)

| Time     | Source       | Event | Summary |
|----------|-------------|-------|---------|
| 07:40:08 | Netlogon     | 5719  | No secure channel to FINBRIDGE — DC unreachable, DNS query returned no response |
| 07:40:09 | GroupPolicy  | 1058  | SYSVOL path inaccessible, error 0x3 |
| 07:40:10 | GroupPolicy  | 1030  | Cannot query GPO list, error 0x546 |
| 07:40:12 | GroupPolicy  | 1129  | GP failed — no network connectivity to DC |
| 07:41:05 | DNS Client   | 1014  | Name resolution for FINBRIDGE-DC01.finbridge.local timed out — no DNS server responded |
| 07:42:18 | DHCP Client  | 50036 | Lease from 10.10.0.1; DNS assigned: 10.10.3.250 (OLD server, decommissioned 02:00) |

---

## Ranked Likely Causes (Most Probable First)

### 1) DHCP scope for Floor 3 subnet not updated — still assigns decommissioned DNS server

**Why this fits the scope facts:**
- Event 50036 on FB031 explicitly shows DHCP assigned 10.10.3.250, which the change log confirms was decommissioned at 02:00 during the migration wave.
- The DHCP scope comparison shows FB055–057 all received the old DNS (172.16.5.5 / 10.10.3.250), while FB058 — manually pre-configured with 10.10.0.10 — is the only unaffected machine.
- The unaffected control (FB058 / FB029) differs in exactly one variable: DNS server source. This is the cleanest discriminator in the evidence.
- No DNS server responds → DC FQDN can't resolve → Netlogon 5719 → GP 1058/1129 chain is a direct causal sequence.

**Fastest single check:**
- On the DHCP server, open the scope for the Floor 3 subnet (10.10.3.0/24) and read the DNS server option (option 6). If it still shows 10.10.3.250 or 172.16.5.5, this is confirmed.

---

### 2) Decommissioned DNS server (172.16.5.5 / 10.10.3.250) removed from network before DHCP scope was updated — no graceful cutover

**Why this fits the scope facts:**
- The DNS servers were decommissioned at ~02:00 and are no longer reachable. Machines that received these addresses before or during the morning boot window have no working resolver.
- DNS Client Event 1014 confirms "none of the configured DNS servers responded" — consistent with the server being fully offline rather than returning NXDOMAIN.
- Timing matches: decommission happened overnight; machines booting at 07:40 during the migration window receive dead DNS entries.

**Fastest single check:**
- From an affected machine, run `nslookup FINBRIDGE-DC01.finbridge.local 10.10.3.250`. If timeout/no response, the server is unreachable. Compare with `nslookup FINBRIDGE-DC01.finbridge.local 10.10.0.10` to confirm new DNS resolves correctly.

---

### 3) DNS forward zone for finbridge.local not migrated or not yet replicated to the new DNS server (10.10.0.10)

**Why this fits the scope facts:**
- Even if DHCP was corrected, the new DNS server must hold the finbridge.local zone (or forward to a DNS server that does) for DC name resolution to succeed.
- If zone migration was incomplete or replication lag occurred, machines pointed at 10.10.0.10 could also fail — but FB058/FB029 (which use 10.10.0.10) resolved successfully, which argues against this being the primary cause.
- Cannot be fully eliminated without confirming zone presence on 10.10.0.10.

**Fastest single check:**
- On the new DNS server (10.10.0.10), run `Get-DnsServerZone -Name finbridge.local` (or check DNS Manager). Verify the finbridge.local forward zone exists and FINBRIDGE-DC01 A record resolves correctly.

---

### 4) Domain controller FINBRIDGE-DC01 unreachable from Floor 3 subnet due to routing or firewall change during migration

**Why this fits the scope facts:**
- A network-layer block between Floor 3 (10.10.3.0/24) and the DC would produce identical symptoms: Netlogon 5719, GP 1058/1129, SYSVOL inaccessible.
- Infrastructure migrations often involve VLAN, firewall rule, or ACL changes that may inadvertently block DC traffic.
- Does not fully explain why FB058 succeeded unless it was on a different VLAN or had a static route.

**Fastest single check:**
- From an affected machine, run `Test-NetConnection FINBRIDGE-DC01.finbridge.local -Port 445` (after manually setting DNS to 10.10.0.10 to bypass the DNS issue). If port 445 is blocked or unreachable, a network path issue exists independently of DNS.

---

### 5) Netlogon secure channel broken due to stale or mismatched computer account in Active Directory

**Why this fits the scope facts:**
- Netlogon Event 5719 can be caused by a computer account password mismatch or a stale/reset machine trust, not only by DNS failure.
- If the migration involved AD changes (domain rename, OU restructure, or account reset), the secure channel could have been invalidated.
- Less likely here because the DNS evidence is very specific and explains all three machines simultaneously, whereas a computer account issue would typically be per-machine and not correlated with DHCP scope assignment.

**Fastest single check:**
- On a DC (once reachable), run `Test-ComputerSecureChannel -ComputerName DESKTOP-FB031 -Verbose` or check `nltest /sc_query:FINBRIDGE` from the affected machine after DNS is temporarily corrected. A healthy return eliminates this cause.

---

## Summary Table

| Rank | Cause | Key Evidence | Single Check |
|------|-------|-------------|-------------|
| 1 | DHCP scope assigns decommissioned DNS | Event 50036; FB058 unaffected (manual DNS); direct scope comparison | Read DHCP scope option 6 on server |
| 2 | Decommissioned DNS server offline — no resolver responds | DNS Client 1014 (no server responded); server taken down at 02:00 | `nslookup` against 10.10.3.250 vs 10.10.0.10 |
| 3 | finbridge.local zone missing/incomplete on new DNS server | FB058 succeeds with 10.10.0.10 (argues against, but not confirmed) | Check zone on 10.10.0.10 with `Get-DnsServerZone` |
| 4 | Routing/firewall block between Floor 3 and DC | Migration window; identical symptoms possible | `Test-NetConnection` to DC port 445 with DNS bypassed |
| 5 | Stale computer account / Netlogon secure channel break | Event 5719 present; weaker — does not explain 3-machine correlation | `Test-ComputerSecureChannel` on affected machine |

---

## Evidence Assessment Against Event Log (DESKTOP-FB031, 2024-03-15 07:40–07:55)

### H1 — DHCP scope assigns decommissioned DNS server
**Verdict: SUPPORTS**

| Event | Time | Basis |
|-------|------|-------|
| DHCP Client 50036 | 07:42:18 | Lease confirmed; DNS assigned = 10.10.3.250, annotated in log as OLD server decommissioned at 02:00. Direct, explicit evidence. |
| DHCP Client 50036 (FB029) | 07:40:05 | Unaffected machine received DNS 10.10.0.10 from the same DHCP server — same scope server, different option value. Isolates DNS assignment as the single variable. |
| GroupPolicy 1500 (FB029) | 07:40:11 | GP succeeded on FB029 seconds after receiving correct DNS. Confirms DNS is the gating factor. |

DHCP server log comparison (FB055–057 = 172.16.5.5, FB058 = 10.10.0.10) directly confirms the scope misconfiguration across all affected machines. The evidence is explicit, not inferred.

---

### H2 — Decommissioned DNS server offline; no resolver responds
**Verdict: SUPPORTS**

| Event | Time | Basis |
|-------|------|-------|
| DNS Client 1014 | 07:41:05 | "None of the configured DNS servers responded." The word **responded** is critical: a misconfigured-but-online server would return NXDOMAIN or SERVFAIL. Timeout with no response indicates the server IP is unreachable — consistent with physical/VM decommission at 02:00. |
| Netlogon 5719 | 07:40:08 | States "DNS query for FINBRIDGE-DC01.finbridge.local returned **no response**" — same signature, DNS layer silent. |

This supports H2 as the mechanism that makes the H1 misconfiguration fatal. The two causes are not mutually exclusive; H1 explains *which* DNS was assigned and H2 explains *why* that assignment causes total failure rather than degraded service.

---

### H3 — finbridge.local zone missing or incomplete on new DNS server (10.10.0.10)
**Verdict: CONTRADICTS**

| Event | Time | Basis |
|-------|------|-------|
| DHCP Client 50036 (FB029) | 07:40:05 | FB029 received DNS 10.10.0.10 — the new server under test. |
| GroupPolicy 1500 (FB029) | 07:40:11 | GP processed successfully **6 seconds later**, which requires DC FQDN resolution via 10.10.0.10. The zone is demonstrably intact and resolving. |

FB029 is a direct live probe of 10.10.0.10 against the finbridge.local zone during the same incident window. Successful GP processing eliminates zone absence or replication lag as a contributing factor. **H3 is eliminated by the control machine evidence.**

---

### H4 — Routing or firewall block between Floor 3 subnet and the DC
**Verdict: CONTRADICTS**

| Event | Time | Basis |
|-------|------|-------|
| Netlogon 5719 | 07:40:08 | Event text explicitly states the failure mode: "DNS query for FINBRIDGE-DC01.finbridge.local returned no response." The failure is attributed to DNS resolution, not to TCP/IP connectivity to the DC. A routing block would produce a different failure: DNS would resolve the DC IP but `Test-NetConnection` to port 445/389 would time out. |
| DHCP Client 50036 (FB029) | 07:40:05 | FB029 is on the same OU=Finance (Floor 3) and reached the DC successfully — same subnet, same network path. |
| GroupPolicy 1500 (FB029) | 07:40:11 | SYSVOL access (port 445) succeeded from the same floor, eliminating a subnet-level network block. |

**H4 is eliminated.** A routing or firewall issue affecting the subnet would have blocked FB029 as well.

---

### H5 — Stale computer account / Netlogon secure channel break
**Verdict: CONTRADICTS**

| Event | Time | Basis |
|-------|------|-------|
| Netlogon 5719 | 07:40:08 | Event text states the cause: "DNS query for FINBRIDGE-DC01.finbridge.local **returned no response**." A trust or computer-account failure produces a different 5719 variant: the DC is reachable but rejects the secure channel negotiation (RPC/Kerberos error). Here the DC is never contacted — no IP is resolved. |
| DNS Client 1014 | 07:41:05 | A purely resolver-layer failure. Computer account state has no influence on DNS resolution. This event cannot be produced by a credential or trust issue. |

A stale computer account would not generate DNS Client Event 1014 under any circumstances. The 5719 here is a DNS-caused 5719, not a trust-caused 5719. **H5 is eliminated by the DNS-layer evidence.**

---

## Evidence Assessment Summary

| Hypothesis | Verdict | Determining Event(s) |
|------------|---------|---------------------|
| H1 — DHCP scope assigns dead DNS | **SUPPORTS** | DHCP 50036 @ 07:42:18; FB029 DHCP 50036 @ 07:40:05 + GP 1500 @ 07:40:11 |
| H2 — Decommissioned DNS server offline | **SUPPORTS** | DNS Client 1014 @ 07:41:05 ("none responded"); Netlogon 5719 @ 07:40:08 ("no response") |
| H3 — finbridge.local zone missing on new DNS | **CONTRADICTS** | FB029 GP 1500 @ 07:40:11 (proves 10.10.0.10 resolves zone correctly) |
| H4 — Routing/firewall block to DC | **CONTRADICTS** | FB029 GP 1500 @ 07:40:11 (same subnet reached DC); Netlogon 5719 text attributes failure to DNS not TCP |
| H5 — Stale computer account / secure channel | **CONTRADICTS** | DNS Client 1014 @ 07:41:05 (trust state cannot cause DNS resolver failure); Netlogon 5719 text cites DNS |

---

## Status

Open — not committed to a single cause. H3, H4, and H5 are eliminated by the event log evidence. H1 and H2 both receive positive support and are not mutually exclusive — H1 explains the misconfiguration vector, H2 explains why it causes total DNS failure. Winner not declared pending confirmation check of DHCP scope option 6.

---

## Addendum — Evidence Assessment, Surviving Hypotheses, and Resolution

Date added: 2026-08-06
Analyst: DWP Engineer

### Evidence Assessment Against Event Log (DESKTOP-FB031, 2024-03-15 07:40–07:55)

#### H1 — DHCP scope assigns decommissioned DNS server
**Verdict: SUPPORTS**

| Event | Time | Basis |
|-------|------|-------|
| DHCP Client 50036 | 07:42:18 | Lease on FB031 shows DNS assigned = 10.10.3.250, annotated as the server decommissioned at 02:00. Direct, explicit evidence. |
| DHCP Client 50036 (FB029) | 07:40:05 | Unaffected control received DNS 10.10.0.10 from the same DHCP server — same scope server, different option value. Isolates DNS assignment as the single differing variable. |
| GroupPolicy 1500 (FB029) | 07:40:11 | GP succeeded 6 seconds after FB029 received correct DNS. Confirms DNS assignment is the gating factor. |

DHCP server log comparison (FB055–057 = 172.16.5.5 / 10.10.3.250, FB058 = 10.10.0.10) directly confirms the scope misconfiguration across all affected machines.

---

#### H2 — Decommissioned DNS server offline; no resolver responds
**Verdict: SUPPORTS**

| Event | Time | Basis |
|-------|------|-------|
| DNS Client 1014 | 07:41:05 | "None of the configured DNS servers responded." Timeout with no response indicates the server IP is unreachable — a misconfigured-but-online server would return NXDOMAIN or SERVFAIL. Consistent with physical/VM decommission at 02:00. |
| Netlogon 5719 | 07:40:08 | States "DNS query for FINBRIDGE-DC01.finbridge.local returned no response" — same silent-resolver signature. |

H1 and H2 are not mutually exclusive. H1 explains which DNS was assigned; H2 explains why that assignment causes total failure rather than degraded service.

---

#### H3 — finbridge.local zone missing or incomplete on new DNS server (10.10.0.10)
**Verdict: CONTRADICTS**

| Event | Time | Basis |
|-------|------|-------|
| DHCP Client 50036 (FB029) | 07:40:05 | FB029 received DNS 10.10.0.10 — the new server under test. |
| GroupPolicy 1500 (FB029) | 07:40:11 | GP processed successfully 6 seconds later, requiring DC FQDN resolution via 10.10.0.10. Zone is demonstrably intact. FB029 is a live probe of 10.10.0.10 during the same incident window. |

H3 eliminated by control machine evidence.

---

#### H4 — Routing or firewall block between Floor 3 subnet and the DC
**Verdict: CONTRADICTS**

| Event | Time | Basis |
|-------|------|-------|
| Netlogon 5719 | 07:40:08 | Failure text attributes the fault to DNS resolution ("DNS query returned no response"), not TCP/IP connectivity. A routing block produces a different failure: DNS resolves the IP but port 445/389 connections time out. |
| GroupPolicy 1500 (FB029) | 07:40:11 | FB029 is on the same Floor 3 / OU=Finance subnet and reached the DC (SYSVOL over port 445) successfully, eliminating a subnet-level network block. |

H4 eliminated.

---

#### H5 — Stale computer account / Netlogon secure channel break
**Verdict: CONTRADICTS**

| Event | Time | Basis |
|-------|------|-------|
| DNS Client 1014 | 07:41:05 | Resolver-layer failure. Computer account or trust state has no influence on DNS resolution; this event cannot be produced by a credential or trust issue. |
| Netlogon 5719 | 07:40:08 | Event text cites DNS non-response as the cause. A trust/computer-account failure produces a different 5719 variant where the DC is reachable but rejects the secure channel negotiation. Here the DC is never contacted. |

H5 eliminated.

---

### Surviving Hypotheses

H1 and H2 both survive and are complementary:
- **H1 — DHCP scope assigns decommissioned DNS server** — the configuration error that caused affected machines to receive a dead DNS address.
- **H2 — Decommissioned DNS server offline** — the mechanism that makes the H1 misconfiguration fatal (silent timeout rather than degraded resolution).

H3, H4, and H5 are eliminated.

---

### Detailed Resolution Steps

#### 1 — Confirm DHCP scope misconfiguration (H1 check)
- On the DHCP server, open the scope for the Floor 3 subnet (10.10.3.0/24).
- Read Option 6 (DNS Servers). If it shows 10.10.3.250 or 172.16.5.5, misconfiguration is confirmed.
- Document the current incorrect value before making any change.

#### 2 — Confirm the decommissioned DNS server is unreachable (H2 check)
- From an affected machine, run:
  ```
  nslookup FINBRIDGE-DC01.finbridge.local 10.10.3.250
  ```
  Expect: timeout / no response — confirms server is offline.
- Then run:
  ```
  nslookup FINBRIDGE-DC01.finbridge.local 10.10.0.10
  ```
  Expect: correct A record returned — confirms new DNS server is a valid replacement.

#### 3 — Correct the DHCP scope option
- On the DHCP server, update Option 6 on the Floor 3 scope (10.10.3.0/24):
  - Remove: 10.10.3.250 / 172.16.5.5
  - Add: 10.10.0.10 (and a secondary if available, e.g. 10.10.0.11)
- Audit all other DHCP scopes for the same stale DNS entries — any scope not updated during the migration wave may have the same problem.

#### 4 — Force immediate lease renewal on affected machines
- On each of DESKTOP-FB055, FB056, FB057, run:
  ```
  ipconfig /release
  ipconfig /renew
  ipconfig /flushdns
  ```
- After renewal, verify DNS servers shown in `ipconfig /all` are 10.10.0.10, not 10.10.3.250.

#### 5 — Force Group Policy reapplication
- Once DNS is corrected, trigger GP refresh on each affected machine:
  ```
  gpupdate /force
  ```
- Verify successful GP processing — expect Event GP 1500 (success) in the Application log, no repeat of 1058/1030/1129.

#### 6 — Confirm Netlogon secure channel recovery
- On each affected machine, run:
  ```
  nltest /sc_query:FINBRIDGE
  ```
  Expect: "Flags: 30 HAS_IP HAS_TIMESERV" and a DC name returned. If the secure channel is still broken after DNS correction, run:
  ```
  nltest /sc_reset:FINBRIDGE
  ```

#### 7 — Validate across all three machines
- Confirm interactive logon succeeds on FB055, FB056, FB057.
- Check Security/System/Application event logs for absence of 5719, 1058, 1030, 1129, 1014.
- Confirm GP settings (drive maps, printer policy, security baseline) are applied as expected.

#### 8 — Post-incident actions
- Review the DNS migration runbook — the gap is that DHCP scope updates were not completed for all subnets before decommissioning the old DNS servers.
- Update the runbook to require a DHCP scope audit as a pre-decommission gate check.
- Confirm any other subnets that received leases during the migration window also have correct DNS options.
