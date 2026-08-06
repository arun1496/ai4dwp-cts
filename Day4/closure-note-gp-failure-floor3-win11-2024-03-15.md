# Closure Note — Group Policy Failure, Floor 3 Win11 Machines

**Incident:** INC-2024-0315-GP-FLOOR3  
**Resolved:** 2026-08-06 09:09  

Resolved. Cause: DHCP scope for Floor 3 subnet (10.10.3.0/24) retained stale DNS Option 6 entries (10.10.3.250 / 172.16.5.5) after the overnight DNS migration on 2024-03-14 decommissioned those servers at ~02:00; affected machines (DESKTOP-FB055, FB056, FB057) received a non-functional resolver at boot, preventing DC name resolution and causing Group Policy processing to fail (Netlogon 5719, GP 1058/1030/1129, DNS Client 1014). Action: Updated DHCP scope Option 6 on the Floor 3 scope to 10.10.0.10; renewed leases on all three machines (`ipconfig /release /renew /flushdns`); ran `gpupdate /force`; confirmed GP 1500 success events and healthy Netlogon secure channel via `nltest /sc_query:FINBRIDGE` on all three machines. Preventive: DNS migration runbook to be updated with a mandatory pre-decommission DHCP scope audit gate — all scopes must be confirmed free of decommission-list IPs before any DNS server is taken offline; a validation script to be built and its output attached to the change record as sign-off evidence. User confirmed working.
