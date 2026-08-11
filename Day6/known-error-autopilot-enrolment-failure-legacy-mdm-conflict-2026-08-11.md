Symptom : Windows Autopilot setup fails and device provisioning does not complete. Reported errors include 0x80180014 during enrolment and downstream 0x80070005 during policy stage.

Cause : A stale legacy manual MDM enrolment from 2023-11-04 remained associated with the device. This pre-existing enrolment blocked Autopilot from taking management ownership.

Scope : Affected devices with historical manual/legacy MDM records and duplicate or stale Intune/Entra objects. Incident validation confirmed network, licensing, and Azure AD join were healthy.

Workaround : Remove stale management records in Intune/Entra, disconnect old work/school account on device, clear residual enrolment artifacts per SOP, reboot, and retry Autopilot enrolment.

Permanent fix: Add a mandatory pre-Autopilot stale-enrolment gate in redeployment workflow: check for legacy MDM history, retire/delete stale objects first, then allow OOBE enrolment.

How to spot it: Export or diagnostics show EnrollmentState Failed with ErrorCode 0x80180014 and message that device is already enrolled in MDM; ProfilesApplied remains 0 of 4; policy stage may show 0x80070005.