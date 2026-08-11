# Analysis and RCA Report: Intune App Install Failure - Adobe Acrobat Pro v23.6

## 1. Incident Summary

- Incident date: 2024-03-15
- Platform: Microsoft Intune Win32 app deployment (.intunewin)
- Application: Adobe Acrobat Pro v23.6
- Install context: SYSTEM
- Installer command: `msiexec /i AcrobatPro.msi /quiet`
- Observed result: Install failed with return code 1603, followed by detection failure, then scheduled retries.

Business impact:
- Target device(s) did not receive Adobe Acrobat Pro as scheduled.
- Retry cycle increased endpoint non-compliance window and delayed user readiness.

## 2. Event Timeline (From Provided Logs)

- 10:01:00 - AgentExecutor started install: Adobe Acrobat Pro v23.6
- 10:01:01 - Install context confirmed: SYSTEM
- 10:01:02 - Package detected: AdobeAcrobatPro.intunewin
- 10:01:03 - Install command executed: `msiexec /i AcrobatPro.msi /quiet`
- 10:01:44 - Installer returned code 1603
- 10:01:44 - Install marked failed
- 10:01:45 - Detection rule executed (registry)
- 10:01:45 - Detection path queried: `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`
- 10:01:45 - Detection value not found
- 10:01:46 - Detection result: Not detected
- 10:01:47 - Overall app result: Failed
- 10:01:47 - Retry scheduled in 60 minutes
- 11:01:47 - Retry attempt 1 started
- 11:01:48 - Same install command executed
- 11:02:31 - Installer returned code 1603 again
- 11:02:32 - Retry attempt 1 failed; next retry scheduled

## 3. Technical Analysis

### 3.1 What the logs prove

- The installer was invoked correctly by Intune in SYSTEM context.
- The MSI execution terminated with return code 1603 on both initial attempt and retry.
- Detection rule did not find expected registry value after install attempt.
- Failure is reproducible across at least two runs under the same configuration.

### 3.2 Return code meaning

- MSI return code 1603 is a generic fatal error.
- In enterprise packaging, 1603 commonly indicates one of the following:
  - Existing/conflicting product state (version overlap or unsupported upgrade path)
  - Missing prerequisite/runtime requirement
  - Incorrect install command for package type or transform needs
  - Access/path issues for source files during SYSTEM-context execution
  - Device state conflict (pending reboot, locked files, service contention)

### 3.3 Detection design review

- Detection path used: `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`
- App being deployed: Adobe Acrobat Pro v23.6
- Likely mismatch risk:
  - `Acrobat Reader` key may be incorrect for `Acrobat Pro` SKU detection.
  - If installer succeeded partially or installed to a Pro-specific key, this rule would still mark Not detected.

Observation:
- In this incident, install is already failing with 1603, so detection mismatch is not the primary failure trigger.
- However, detection rule appears weak and could cause false negatives even after a future successful install.

## 4. Root Cause Analysis (RCA)

Primary root cause:
- Installation package/execution path for Adobe Acrobat Pro v23.6 is failing at MSI runtime with fatal error 1603 under SYSTEM context.

Most probable underlying cause category:
- Package readiness/configuration issue (command-line/package prerequisites/product-state conflict), not Intune assignment transport failure.

Supporting evidence:
- Repeated 1603 on retry with identical command.
- No evidence in provided logs of assignment ingestion failure or detection-only false failure.

Contributing factors:
- Detection rule references `Acrobat Reader` instead of clearly Pro-specific artifact, increasing risk of misreporting once install path is fixed.
- Retry loop without package-level remediation repeats same failing behavior.

## 5. Corrective Actions (Immediate)

1. Stop broad targeting for this app revision.
- Keep deployment scoped to pilot/troubleshooting group only until package validation completes.

2. Enable verbose MSI logging in install command for forensic detail.
- Update install command to:
  - `msiexec /i AcrobatPro.msi /qn /L*v C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AcrobatPro_v23.6_install.log`

3. Validate uninstall/upgrade preconditions.
- Check for existing Adobe Reader/Acrobat versions and remove or sequence upgrades according to vendor guidance.
- Confirm pending reboot state before install attempt.

4. Correct detection rule to Pro-specific marker.
- Prefer MSI product code detection or a Pro-specific registry path/value tied to v23.6.
- Avoid Reader-only key for Pro package compliance checks.

5. Re-test on clean pilot endpoints.
- Minimum: 10 devices across mixed hardware profiles before re-expanding assignments.

## 6. Preventive Actions (Longer-Term)

1. Packaging quality gate before production assignment.
- Require pre-release checklist: silent install, uninstall, reinstall, upgrade path, and detection validation.

2. Detection standardization.
- For MSI apps, default to product-code detection where possible.
- Require peer review for registry-path detections to avoid SKU mismatch.

3. Return-code response playbook.
- If 1603 repeats twice in same ring, automatically hold expansion and trigger packaging review.

4. Ring-based deployment safeguard.
- Keep required rollout ring progression blocked until:
  - >= 98% success in pilot
  - <= 2% failure
  - no repeated fatal MSI code pattern

## 7. Verification Plan After Fix

Success criteria to clear incident:
- At least 24 hours of pilot monitoring after remediated package deployment
- Install success >= 98% on pilot devices
- 1603 rate <= 1% on pilot
- Detection confirms installed state for >= 98% of successful installs

Operational checks:
- Confirm Intune device install status transitions to Installed.
- Sample endpoint validation:
  - Application launches successfully
  - Version reports as 23.6
  - Detection artifact exists at expected path/value (or product code present)

## 8. Executive Conclusion

The incident is a package execution failure, not an Intune transport issue. The decisive signal is repeated MSI fatal return code 1603 under SYSTEM context across initial and retry attempts. Detection currently also appears misaligned to product SKU and should be corrected to prevent future false compliance failures. Deployment should remain ring-limited until installer logging, prerequisite handling, and detection logic are remediated and pilot success criteria are met.
