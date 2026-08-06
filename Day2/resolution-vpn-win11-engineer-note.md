Engineer note:
Root cause:
- Win11 upgrade removed the legacy VPN client.
- Intune did not re-deploy the new VPN client because of a detection-rule gap.

Exact action taken:
- Manually removed stale VPN registry entries under HKLM\SOFTWARE<vendor>.
- Force-triggered Intune sync.
- New VPN client deployed.
- Split-tunnel config applied.

Config detail:
- Registry cleanup path: HKLM\SOFTWARE<vendor> (stale VPN entries).
- VPN profile mode: split-tunnel.

Verification:
- Connectivity confirmed to all internal subnets.
- No data loss.

Preventive action needed:
- Close detection-rule gap so Intune re-deployment of the new VPN client triggers reliably after Win11 upgrade/removal of legacy client.
