# L2/L3 Knowledge Base: Windows Autopilot Enrolment Failure - Legacy MDM Conflict (0x80180014)

**Version:** v1.0  
**Date:** 11/08/2026  
**Status:** Draft  
**Audience:** L2/L3 Endpoint Engineering, Intune Operations  
**Related RCA:** rca-autopilot-enrolment-failure-legacy-mdm-conflict-2026-08-11

---

## Background

Autopilot requires clean management ownership during OOBE enrolment. If a device context still has an active or stale manual/legacy MDM enrolment, the MDM channel ownership check fails and Autopilot onboarding cannot complete.

In this incident, network and licensing were healthy, and device join state was valid. Failure path was ownership conflict, not connectivity or licensing.

---

## Symptom

Typical indicators:
- Autopilot enrolment fails during setup.
- Export/diagnostics show `EnrollmentState: Failed`.
- Primary error: `0x80180014` with description device already enrolled in MDM.
- Policy/application stage can show `0x80070005`.
- `ProfilesApplied` remains `0 of 4`.

---

## Root Cause

Stale legacy manual MDM enrolment (record timestamp 2023-11-04) remained linked to device identity and blocked Autopilot from taking management ownership.

---

## Preconditions and Checks

Before remediation, confirm:
- Intune P1 and Autopilot licensing assigned.
- Device is Azure AD joined (or intended join path is valid).
- Required endpoints reachable.
- You have approval to retire/delete stale records.

Data points to capture in ticket before changes:
- Serial number
- Device name
- Intune device ID
- Entra device object ID(s)
- Autopilot registration identity
- Error codes and timestamp

---

## Resolution Runbook

### Phase 1: Portal-side cleanup (must happen first)

1. Intune admin center -> Devices -> All devices.
2. Search by serial, device name, and Azure AD device ID.
3. Identify duplicate/stale legacy-managed object.
4. Retire stale Intune record if required by process, then delete.
5. Entra admin center -> Devices -> All devices: identify duplicates.
6. Remove stale Entra duplicate only after confirming active object.
7. Intune -> Devices -> Windows -> Windows enrollment -> Devices (Autopilot): verify registration still present and deployment profile assignment intact.
8. Validate enrolment restrictions and assignment scope still permit this user/device.
9. Log all removed object IDs and timestamps in incident ticket.

### Phase 2: Device-side cleanup

1. Sign in with local admin/support admin.
2. Settings -> Accounts -> Access work or school: disconnect legacy work account/MDM link.
3. Capture join state:

```powershell
dsregcmd /status
```

4. Remove residual enrolment artifacts per endpoint cleanup SOP (old enrolment account remnants, stale MDM certs, scheduled enrolment tasks).
5. Reboot endpoint.
6. If remnants persist, perform approved Windows Reset/Autopilot Reset to guarantee clean state.

### Phase 3: Re-enrol and validate

1. Re-initiate Autopilot OOBE enrolment.
2. Monitor enrolment and profile application progression.

---

## Verification Steps

Successful remediation requires all checks below:

1. No recurrence of `0x80180014` in fresh diagnostics.
2. Single active Intune device object with current check-in.
3. No stale duplicate Entra object tied to same endpoint identity.
4. Autopilot profile assigned and completion flow succeeds.
5. `ProfilesApplied` progresses beyond previous `0 of 4` state.
6. `0x80070005` no longer observed at policy stage.
7. Baseline compliance/configuration policies apply successfully.

Success criteria:
Single active management record plus successful Autopilot enrolment and policy application completion.

---

## Preventive Action

Implement mandatory pre-Autopilot legacy-enrolment gate:

1. Before redeploy/wave assignment, run duplicate/stale record check in Intune + Entra.
2. If legacy manual enrolment exists, complete retire/delete workflow before OOBE release.
3. Add gate to formal L2/L3 redeployment checklist as required control.
4. Add scheduled reporting/query to flag historical manual enrolment candidates before Autopilot waves.

Control objective:
Prevent ownership-conflict devices from entering Autopilot flow.

---

## Escalation Conditions

Escalate to endpoint engineering when:
- Duplicate identity cannot be confidently distinguished.
- Object deletion risk to active join state is unclear.
- Device-side cleanup cannot remove enrolment remnants without reset.
- Error signature changes from known pattern (for example no 0x80180014 but enrolment still fails).

---

## Quick Triage Signature

Use this as a fast match pattern:
- `EnrollmentState Failed`
- `ErrorCode 0x80180014`
- Message indicates already enrolled in MDM
- `ProfilesApplied 0 of 4`
- Secondary `0x80070005`
- Licensing/network/join checks healthy

If all match, use this runbook.