# Triage Summary — VDI Connection Failure (Remote User)

**Date raised:** 2026-08-03  
**Raised by:** End user (identity not provided)

---

## Summary
Remote user unable to connect to VDI session from home today; connection was working on Friday and is failing with a "cannot connect" error.

---

## Impact
- **Who affected:** 1 user (to confirm — no name or team provided)
- **How many:** 1 user reported; wider VDI service impact unknown (to confirm — may indicate a broader platform issue)
- **Business urgency:** High — user is fully locked out of their working environment and cannot perform their role while remote

---

## Known Facts
- User cannot connect to VDI today (2026-08-03, a Monday)
- VDI was working on Friday (2026-07-31 — to confirm this is the last known good date)
- Error message states "cannot connect" (exact wording to confirm — may contain more detail)
- User is working from home on a home Wi-Fi connection
- No changes to the setup reported by the user over the weekend (to confirm)

---

## Missing Information to Gather
1. User name and contact number for callback
2. Full and exact error message displayed — does it include an error code or reference number?
3. Which VDI client and version is being used (to confirm — e.g. Citrix Workspace, VMware Horizon)?
4. What device is the user connecting from — a corporate-issued device or personal machine?
5. Has the device been restarted since Friday?
6. Is the user able to reach any other internet resources (e.g. can they browse the web) — confirms whether the issue is Wi-Fi/internet or VDI-specific?
7. Has the user's corporate password expired or been changed since Friday?
8. Are there any VDI maintenance or outage notifications the user may have missed?
9. Has anything changed on the home network since Friday (new router, ISP issue, VPN conflict)?
10. Is multi-factor authentication (MFA) completing successfully, or is the failure occurring before or during authentication?

---

## Likely Category
**Remote access failure — VDI / virtual desktop connectivity**

Possible sub-categories (to confirm through investigation):
- VDI platform outage or scheduled maintenance affecting all or some users
- Expired credentials or MFA token issue
- VDI client software issue on the endpoint (stale cache, outdated client version)
- Home network or ISP blocking required ports/protocols
- Corporate device certificate or compliance check failure preventing session establishment

---

## Suggested First Diagnostic Step
Check whether there is an active VDI service outage or maintenance window affecting the platform before spending time on the individual device. If no known outage, ask the user to confirm whether MFA is completing successfully and what point in the connection process the error appears — this immediately separates an authentication failure from a network or client fault.
