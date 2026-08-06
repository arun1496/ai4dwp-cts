# Known Error Record — Group Policy Failure After DNS Server Decommission

**Record ID:** KE-2024-0315-GP-DNS  
**Date raised:** 2026-08-06  
**Source incident:** INC-2024-0315-GP-FLOOR3  
**Status:** Permanent fix identified  

---

**Symptom:** Users on affected machines cannot log in normally — Group Policy fails to apply at logon, resulting in missing drive mappings, printer policies, and security baseline settings. The machines boot and reach the login screen but desktop configuration is incomplete or absent.

**Cause:** The DHCP scope for the affected subnet retained stale DNS Option 6 entries referencing decommissioned DNS servers (10.10.3.250 / 172.16.5.5) after those servers were taken offline during a DNS migration. Machines receiving a DHCP lease have no working resolver, which prevents DC FQDN resolution, which breaks the Netlogon secure channel and causes the entire Group Policy processing chain to fail.

**Scope:** Any Windows 11 machine on a subnet whose DHCP scope Option 6 still references a decommissioned DNS server address following a DNS migration. In the source incident, DESKTOP-FB055, FB056, and FB057 on the Floor 3 subnet (10.10.3.0/24) were affected; machines with manually pre-configured DNS (e.g. DESKTOP-FB058 with 10.10.0.10) were unaffected.

**Workaround:** On the DHCP server, update Option 6 on the affected scope to a working DNS server address (10.10.0.10). On each affected machine run `ipconfig /release`, `ipconfig /renew`, `ipconfig /flushdns`, then `gpupdate /force`. Verify GP success with Event 1500 in the Application log and confirm the Netlogon secure channel with `nltest /sc_query:<domain>`.

**Permanent fix:** Update the DNS migration runbook to require a mandatory pre-decommission DHCP scope audit — all DHCP scopes across all DHCP servers must be confirmed free of any IP address on the decommission list before any DNS server is taken offline. Build a validation script to automate this check and attach its output to the change record as a required sign-off step.

**How to spot it:** Look for the combination of Event **5719** (Netlogon — "DNS query returned no response"), Event **1014** (DNS Client — "none of the configured DNS servers responded"), and Events **1058 / 1030 / 1129** (GroupPolicy) occurring together within seconds at machine startup. Confirm by checking `ipconfig /all` on the affected machine — if the DNS server address is not a currently live server, check DHCP scope Option 6 immediately. The 5719 text will say "DNS query returned no response" rather than an RPC or trust error, which distinguishes this from a computer account or secure channel failure.
