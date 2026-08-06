# User Login Incident Communications - cthompson

## Audience 1 - Non-technical executive

Your access is restored and your data is safe. cthompson's login issue began around 08:40 when repeated incorrect password attempts from DESKTOP-FB022 locked the account; additional incorrect attempts also came from 10.10.8.112. We re-enabled the account and verified successful interactive sign-in on DESKTOP-FB022 at 09:09, with no further issues reported. Preventive control now requires stale-credential cleanup before and after lockout recovery. No action is needed unless it happens again; contact Service Desk.

## Audience 2 - Affected end-user team (10 people)

Your access is restored and your data is safe. Around 08:40, cthompson could not sign in because repeated incorrect password attempts from DESKTOP-FB022 locked the account, and more incorrect attempts also came from 10.10.8.112. We re-enabled the account and confirmed successful interactive sign-in on DESKTOP-FB022 at 09:09, with no further issues reported. We are now requiring stale-credential cleanup before and after lockout recovery to prevent repeat incidents. If you see this issue, stop retrying and contact Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Access restored; data safe.

Root cause:
Repeated incorrect credential submissions from DESKTOP-FB022 drove account lockout for cthompson (incident onset ~08:40), with additional incorrect credential attempts from secondary source 10.10.8.112 contributing relock risk.

Exact action taken:
Account was re-enabled, interactive sign-in was retested on DESKTOP-FB022, and stale-credential cleanup control was set as a required step before and after lockout recovery.

Config detail:
Primary source host: DESKTOP-FB022. Secondary source: 10.10.8.112. Affected account: cthompson.

Verification step:
Successful interactive sign-in on DESKTOP-FB022 at 09:09; no further issues reported.

Preventive action needed:
Enforce mandatory stale-credential cleanup before and after lockout recovery to prevent repeated bad-credential retries from multiple sources.

Recurrence handling:
If repeated lockout signs return, stop user retry attempts, identify and suppress all active credential sources (including DESKTOP-FB022 and any secondary source such as 10.10.8.112), then re-run recovery verification.
