# Triage Summary — AVD Session Disconnects After ~10 Minutes Then Reconnects

**Ticket:** T-1003  
**Date raised:** to-verify  
**Raised by:** to-verify

---

## Summary
AVD user session disconnects after approximately 10 minutes and then reconnects.

## Impact
- **Who affected:** Reported user to-verify; potentially additional AVD users on the same host pool to-verify
- **How many:** 1 user reported; wider impact unknown to-verify
- **Business urgency:** Medium-High to-verify, because repeated disconnects interrupt work and may impact service continuity/productivity

## Known Facts
- Ticket reference is T-1003
- Reported behavior: AVD session disconnects after around 10 minutes
- Session appears to reconnect after the disconnect
- Exact disconnect message, timestamp pattern, and client type are not yet confirmed to-verify
- Scope (single user vs multiple users/host pool wide) is not yet confirmed to-verify

## Missing Information to Gather
1. Affected user identity, location/network context, and contact details to-verify
2. AVD client type and version (Remote Desktop client, web client, or other) to-verify
3. Whether issue occurs on all endpoints/networks or only one device/network to-verify
4. Exact user-visible message at disconnect/reconnect and approximate timestamps to-verify
5. Whether disconnect interval is consistently ~10 minutes or variable to-verify
6. Whether other users in the same host pool report similar behavior to-verify
7. Whether reconnect lands on the same session host and whether apps remain open to-verify
8. Any recent platform/network/policy/client changes before issue onset to-verify
9. Correlated session host and broker diagnostics around the same timestamps to-verify

## Likely Category
**AVD / session stability / connectivity**

## First Diagnostic Step
Confirm the pattern and scope first by capturing exact disconnect timestamps and client type from the affected user, then check whether other users on the same host pool are experiencing matching disconnect intervals at the same time windows.