# Triage Summary — Company App Fails to Install from Company Portal

**Ticket:** T-1004  
**Date raised:** to-verify  
**Raised by:** to-verify

---

## Summary
Company app fails to install from Company Portal with error 0x87D1041C.

## Impact
- **Who affected:** Reported user to-verify; potentially other users targeted for the same app deployment to-verify
- **How many:** 1 user reported; broader impact unknown to-verify
- **Business urgency:** Medium-High to-verify, because inability to install required business app may block user productivity

## Known Facts
- Ticket reference is T-1004
- App install is attempted via Company Portal
- Installation fails with reported error 0x87D1041C
- App name, assignment type, and affected device details are not yet confirmed to-verify
- Scope (single user vs wider deployment issue) is not yet confirmed to-verify

## Missing Information to Gather
1. Affected user identity and device name/ID to-verify
2. Exact app name, version, and whether it is required or available deployment to-verify
3. Whether failure occurs on one device only or across multiple users/devices to-verify
4. Screenshot/time of failure and whether retry behavior changes outcome to-verify
5. Device compliance and management status in Intune to-verify
6. Network context at install time (corporate network, VPN, home internet) to-verify
7. Available disk space and pending reboot state on affected device to-verify
8. Whether Company Portal sync and policy refresh were completed before install attempt to-verify
9. Relevant deployment and install status details from management console to-verify

## Likely Category
**Endpoint management / Intune Company Portal / app deployment**

## First Diagnostic Step
Confirm the exact app package and assignment status for the affected user/device in management tooling, then force a Company Portal sync and retry while capturing timestamped failure evidence for correlation.