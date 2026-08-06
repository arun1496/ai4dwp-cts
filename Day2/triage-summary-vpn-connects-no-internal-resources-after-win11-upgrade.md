# Triage Summary — VPN Connects but Internal Resources Not Reachable After Win11 Upgrade

**Ticket:** T-1008  
**Date raised:** to-verify  
**Raised by:** to-verify

---

## Summary
VPN connection succeeds, but internal resources are not reachable after Windows 11 upgrade.

## Impact
- **Who affected:** Reported remote user to-verify; potentially other recently upgraded remote users to-verify
- **How many:** 1 user reported; wider impact unknown to-verify
- **Business urgency:** High to-verify, because user cannot access internal business services despite VPN connection

## Known Facts
- Ticket reference is T-1008
- VPN is reported as connected
- Internal resources are not reachable
- Issue started after Windows 11 upgrade
- Specific resources affected (file shares, intranet, apps) are not yet confirmed to-verify

## Missing Information to Gather
1. Affected user/device identity and VPN client/profile in use to-verify
2. Which internal resources fail and whether any internal resource is reachable to-verify
3. Whether internet access remains normal while VPN is connected to-verify
4. Whether issue occurs on multiple networks (home/hotspot/corporate) to-verify
5. Whether DNS resolution for internal names works while connected to VPN to-verify
6. Whether route behavior changed after Win11 upgrade to-verify
7. Whether similar symptoms exist for other upgraded VPN users to-verify
8. Any recent VPN client update or policy/profile change to-verify
9. Exact user-visible error messages when attempting internal access to-verify

## Likely Category
**Remote access / VPN connectivity / post-Windows 11 upgrade**

## First Diagnostic Step
Verify symptom boundaries by testing both internal name-based access and direct internal endpoint reachability immediately after VPN connects, then compare with a known-good user/profile to identify DNS or routing mismatch post-upgrade.