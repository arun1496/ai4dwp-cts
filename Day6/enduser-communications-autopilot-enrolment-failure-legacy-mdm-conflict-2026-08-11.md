# Autopilot Setup Incident Communications

## Audience 1 - Non-technical executive

Your access and data are safe. A previous setup record on the device blocked the new setup process, so setup stopped before completion. We removed the old record and restarted setup controls. This issue is resolved and safeguards are in place to prevent repeat cases during future device rollouts. No action is needed unless setup fails again; if it does, contact Service Desk.

## Audience 2 - Affected end-user team (10 people)

Your access and files are safe, and we have fixed the setup issue. This happened because an old device setup record was still attached, so the new setup could not finish. If you see this again, stop retrying, restart the device once, and contact Service Desk with your device name and the time it failed. For help, contact Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Root cause:
Legacy manual MDM enrolment state (timestamp 2023-11-04) remained active for device context, causing Autopilot enrolment conflict. Primary failure code: 0x80180014 (already enrolled in MDM). Downstream policy stage showed 0x80070005 with ProfilesApplied 0 of 4.

Exact action taken:
1. Intune: located stale/duplicate device objects via serial, device name, and Azure AD device ID.
2. Retired and deleted stale Intune device record.
3. Entra: validated duplicate object set and removed stale duplicate only after active-object confirmation.
4. Confirmed Autopilot registration entry and deployment profile assignment remained intact.
5. Device-side: disconnected legacy Access work or school connection, removed residual enrolment artifacts per endpoint cleanup SOP, rebooted, and re-initiated Autopilot OOBE flow.

Config detail:
- EnrollmentState prior to fix: Failed
- ErrorCode: 0x80180014
- ErrorDescription: Device already enrolled in MDM
- LastError during policy stage: 0x80070005
- ProfilesApplied before fix: 0 of 4
- Licensing: Intune P1 = Yes, Autopilot license = Yes
- Connectivity: all required endpoints reachable, no proxy blocker
- Join state: AzureADJoined = Yes

Verification step:
1. Re-run enrolment diagnostics and confirm no 0x80180014.
2. Validate single active Intune record with current check-in; no stale duplicate remains.
3. Confirm Autopilot profile assignment/completion and policy application proceeds beyond previous failure point.
4. Confirm baseline compliance/config profiles now apply successfully.

Preventive action needed:
Implement mandatory pre-Autopilot legacy-enrolment gate in L2/L3 redeploy runbook. Block OOBE release until duplicate/stale Intune/Entra object check passes and any legacy manual enrolment is retired/deleted. Add scheduled reporting to flag devices with historical manual enrolment before Autopilot waves.