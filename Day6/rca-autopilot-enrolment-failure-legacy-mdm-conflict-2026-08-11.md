# Root Cause Analysis: Autopilot Enrolment Failure - Legacy MDM Conflict
**Incident Date:** 2026-08-11
**RCA Date:** 2026-08-11
**Author:** DWP Analyst
**Status:** Resolved

---

## 1. Executive Summary

Autopilot enrolment failed because the device already had an existing MDM enrolment from 2023-11-04 (legacy manual enrolment). The export explicitly records `EnrollmentState: Failed`, `ErrorCode: 0x80180014`, and `ErrorDescription: The device is already enrolled in MDM.` This existing enrolment blocked Autopilot MDM onboarding. Policy application did not proceed (`ProfilesApplied: 0 of 4`) and returned `LastError: 0x80070005 (Access denied)`.

Network and licensing were healthy (`All endpoints reachable`, `IntuneP1License: Yes`, `AutopilotLicense: Yes`), and the device was already Azure AD joined (`AzureADJoined: Yes`).

---

## 2. Confirmed Scope Facts

- Enrolment status: Failed
- Primary enrolment failure code: `0x80180014`
- Error description in export: Device already enrolled in MDM
- Existing enrolment: Yes, from 2023-11-04 (legacy manual source)
- Azure AD joined: Yes
- Profile application: Failed/incomplete (`0 of 4` applied)
- Policy/application error observed: `0x80070005 (Access denied)`
- Licensing: Correct (Intune P1 and Autopilot licenses present)
- Network: Healthy (all endpoints reachable, no proxy)

Code meaning confirmation:
- `0x80180014`: confirmed by export text as existing MDM enrolment conflict.
- `0x80070005`: known Windows access denied code.

---

## 3. Root Cause

A stale, pre-existing legacy MDM enrolment record and associated client state prevented Autopilot enrolment from taking ownership of device management. Autopilot cannot complete while a conflicting enrolment remains active for the device context.

---

## 4. Exact Remediation Steps

### 4.1 Intune Admin Center Actions (Admin Center only)

1. Open Microsoft Intune admin center -> Devices -> All devices.
Step type: **Admin center only**

2. Search by serial number, hardware hash identity, device name, and Azure AD device ID to locate duplicate or stale records for the same physical device.
Step type: **Admin center only**

3. Identify the legacy-managed record (typically older enrolment date, manual source/history alignment).
Step type: **Admin center only**

4. Retire the stale Intune device object if policy requires retire-before-delete.
Step type: **Admin center only**

5. Delete the stale Intune device object after retirement completes (or delete directly if your process allows direct deletion).
Step type: **Admin center only**

6. Open Entra admin center -> Devices -> All devices and confirm whether duplicate device objects exist for the same endpoint identity.
Step type: **Admin center only**

7. Remove stale/duplicate Entra device object only when you have confirmed it is not the active object required for current join state.
Step type: **Admin center only**

8. In Intune admin center -> Devices -> Windows -> Windows enrollment -> Devices (Autopilot), verify the Autopilot registration entry for the device still exists and is assigned to the intended deployment profile.
Step type: **Admin center only**

9. Confirm enrolment restrictions and assignment scope allow this user/device to enroll, and verify target profile assignment is still valid.
Step type: **Admin center only**

10. Record timestamp and object IDs removed in the incident ticket for audit and rollback traceability.
Step type: **Admin center only**

### 4.2 Device-Side Cleanup Actions (Device access required)

1. Sign in to the affected device with local admin or approved support admin context.
Step type: **Device access required (physical or remote)**

2. Open Settings -> Accounts -> Access work or school. Disconnect any legacy work account/MDM connection tied to the old enrolment.
Step type: **Device access required (physical or remote)**

3. Open an elevated command prompt/PowerShell and run `dsregcmd /status` to capture current join state before reset actions.
Step type: **Device access required (physical or remote)**

4. Remove stale MDM enrolment artifacts if they persist (enrolment account remnants, old MDM certificates, scheduled enrolment tasks) according to your approved endpoint cleanup SOP.
Step type: **Device access required (physical or remote)**

5. Reboot device to clear cached enrolment session state.
Step type: **Device access required (physical or remote)**

6. If stale state cannot be cleanly removed, perform Windows Reset/Autopilot Reset (org-approved method) to guarantee a clean provisioning state.
Step type: **Device access required (physical or remote)**

---

## 5. Correct Order of Operations

1. Freeze changes and capture evidence from export and portal (error codes, record IDs).
2. Remove stale device management records in Intune/Entra first.
3. Verify Autopilot registration/profile assignment still intact after cleanup.
4. Perform device-side unenrolment cleanup and reboot/reset.
5. Re-initiate Autopilot OOBE enrolment.
6. Validate profile delivery and compliance post-enrolment.

Reason for this order:
- Portal-side stale object removal must happen before device retry; otherwise the same conflict is likely to reoccur.
- Device cleanup must happen before OOBE retry so old enrolment context is not reused.

---

## 6. Verification After Remediation

Use all checks below to confirm successful completion:

1. Enrolment state in device diagnostics/Intune changes to successful (no `0x80180014`).
2. Device appears once in Intune with current check-in time and no duplicate legacy entry.
3. Autopilot deployment profile reports assigned and completed for the device/user context.
4. `ProfilesApplied` reaches expected count (not `0 of 4`).
5. `0x80070005` no longer appears during policy application stage.
6. Device receives baseline compliance/configuration policies and reports success in Intune.
7. Company Portal (if used) and MDM sync complete without enrolment conflict.

Success criteria:
- Single active management record, successful Autopilot enrolment, and policy application completion.

---

## 7. Preventive Action for Recurrence

Implement a pre-Autopilot legacy-enrolment gate in operations process:

1. Before assigning/redeploying Autopilot devices, run a mandatory stale-record check for duplicates/previous manual MDM enrolments in Intune and Entra.
2. If legacy enrolment is detected, perform retire/delete cleanup workflow before device enters OOBE.
3. Add this check as a formal checklist control in L2/L3 build and redeployment runbooks.
4. Add automation/reporting (scheduled query/export) to flag devices with older manual MDM enrolment history before Autopilot wave deployment.

Control objective:
- Prevent devices with historical manual enrolment state from reaching Autopilot without prior cleanup.

---

## 8. Operational Notes

- Do not remove active Entra device objects without confirming they are stale/duplicate; incorrect deletion can disrupt access.
- If multiple duplicates exist, preserve identifiers (serial, object IDs, timestamps) in ticket notes before deletion.
- If device ownership is uncertain, coordinate with endpoint engineering before object removal.

---

## 9. Closure Statement

Autopilot enrolment failure was caused by a confirmed legacy MDM enrolment conflict (`0x80180014`) with policy application blocked (`0x80070005`) as a downstream effect. Stale enrolment removal in admin center, followed by device-side cleanup/reset and controlled re-enrolment, is the required fix path and has been documented for repeatable execution.
