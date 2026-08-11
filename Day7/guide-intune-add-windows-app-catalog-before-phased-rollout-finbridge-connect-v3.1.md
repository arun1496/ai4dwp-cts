# Step-by-Step Guide: Add a Windows App to Intune Before Phased Rollout

**Audience:** DWP engineers with no prior Intune app-deployment experience  
**Use case example:** FinBridge Connect v3.1 (.intunewin package)  
**Goal:** Add app correctly to Intune catalog, assign to pilot first, and verify install outcomes before phased rollout

## 1. Confirm prerequisites before you start

1. Confirm you have:
   - Intune admin access with app management permissions.
   - The packaged app file: `FinBridgeConnect_v3.1.intunewin`.
   - Install command: `FinBridgeConnect_Setup.exe /silent`.
   - Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`.
   - Detection target: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`.
2. Confirm a pilot device group exists (small, controlled set), for example 10-50 test devices.
3. Do not begin large-scale deployment yet. This document is the pre-rollout setup and validation phase.

## 2. Navigate to where apps are added in Intune

1. Open Microsoft Intune admin center.
2. Go to:
   - `Apps -> All apps -> Add`
3. If your tenant UI differs, find the equivalent app onboarding entry point.

UI label variation note:
- Menu labels and blade layout can vary by tenant version and portal updates.
- Verify live labels in your own tenant before proceeding; do not rely only on screenshots or historical wording.

## 3. Choose the correct app type

1. In the app type picker, choose based on package/source:
   - **Windows LOB app (.intunewin package):** choose the Win32 app option used for `.intunewin` onboarding.
   - **Microsoft Store app:** choose the Microsoft Store app type when app source is Store-managed.
   - **Web link:** choose Web link when you only need a URL shortcut/app link published to users.
2. For this worked example, select the Win32/LOB path for `.intunewin` and upload `FinBridgeConnect_v3.1.intunewin`.

UI label variation note:
- Some tenants show wording like "Windows app (Win32)" while others show "Line-of-business" variants.
- Validate that your selected type explicitly supports `.intunewin` upload.

## 4. Create the app record and complete required fields

### 4.1 App information

1. Enter app metadata:
   - **Name:** `FinBridge Connect`
   - **Description:** `FinBridge Connect desktop client v3.1 for managed Windows endpoints.`
   - **Publisher:** `FinBridge`
   - **Version:** `3.1`
2. Review for naming consistency (this name will be used in reporting and user-facing views).

### 4.2 Program settings

1. Configure program commands:
   - **Install command:** `FinBridgeConnect_Setup.exe /silent`
   - **Uninstall command:** `FinBridgeConnect_Setup.exe /uninstall /silent`
2. Set install behavior/context:
   - **Install behavior:** `System` (recommended default for managed enterprise app deployment unless vendor requires user context).
3. Save and continue.

System vs user context guidance:
- **System context** installs with device-level rights and is best for machine-wide installs.
- **User context** installs in current user context and can fail for apps requiring elevation.
- For FinBridge Connect baseline rollout, use **System** unless packaging test proves user-context requirement.

UI label variation note:
- "Install behavior" can appear as "Install context" in some portals.
- Verify that selected context matches your packaging and detection design.

### 4.3 Requirements

1. Set device requirements:
   - **Operating system architecture:** select supported architecture (for example `64-bit`).
   - **Minimum OS version:** set the minimum supported Windows version per engineering baseline.
2. For Windows 11 managed fleet, align minimum OS with your approved baseline policy.

UI label variation note:
- OS requirement fields may be grouped differently by tenant build.
- Confirm architecture and minimum OS are both explicitly set before continuing.

### 4.4 Detection rules

1. Choose rule type: **Registry**.
2. Configure detection rule for this app:
   - **Hive:** `HKEY_LOCAL_MACHINE`
   - **Key path:** `SOFTWARE\FinBridge\Connect`
   - **Value name:** `Version`
   - **Detection method/operator:** `Equals`
   - **Expected value:** `3.1`
3. Save the detection rule.

Why detection matters:
- Intune marks installation outcome based on this rule.
- Wrong detection design causes false "Failed" or reinstall loops even when app files exist.

UI label variation note:
- Detection pages often differ by wording (for example "Rule format" vs "Detection type").
- Verify you are matching **value data** at the exact registry path above.

### 4.5 Return codes

1. Review/define return codes used by the installer:
   - Map expected success codes (commonly `0`, and if applicable `3010` for soft reboot required) as success.
   - Ensure non-success installer exits are marked failure/retry according to org standard.
2. If vendor documentation defines additional valid success codes, add them before assignment.

Return code guidance:
- `0` usually means success.
- `3010` typically means success with reboot required.
- Unknown non-zero codes should not be treated as success unless explicitly documented.

UI label variation note:
- Return code tables may be pre-populated differently by app type and tenant revision.
- Verify each mapped code action before finalizing app creation.

## 5. Finish creation and confirm app is in catalog

1. Review summary page and create the app.
2. Return to:
   - `Apps -> All apps`
3. Confirm `FinBridge Connect` appears in catalog.
4. Open the app record and verify key tabs/sections show expected values:
   - App info (name/publisher/version)
   - Program (install/uninstall commands, install context)
   - Requirements
   - Detection rules
   - Return codes

UI label variation note:
- Tab names can differ (for example "Properties" vs separate category blades).
- Validate field values themselves, not just label names.

## 6. Assignment basics and pilot-first approach

1. Open app assignments section.
2. Understand assignment types:
   - **Required:** Intune pushes install automatically to targeted devices/users.
   - **Available:** App is optional; user can install from Company Portal.
   - **Uninstall:** Intune removes app from targeted devices/users.
3. For a new app, assign to a **small pilot group first** (never directly to 10,000-device fleet).

Why pilot first:
- Validates packaging, detection, and return-code behavior in real environment.
- Limits blast radius if install command, detection rule, or dependencies are wrong.
- Produces operational evidence before CAB/change expansion.

Recommended first assignment for this example:
1. Add **Required** assignment to pilot devices only.
2. Optionally add **Available** to limited pilot users if self-service validation is needed.
3. Do not assign broad production group until verification criteria in Step 7 are met.

## 7. Verify deployment on test devices before phased rollout

### 7.1 Confirm assignment ingestion

1. In app record, open device/user install status view.
2. Confirm pilot group targets are present.
3. Allow initial policy sync window, then refresh status.

### 7.2 Check install status on an assigned test device

1. Open the target device in Intune:
   - `Devices -> All devices -> <test device> -> Managed apps` (or equivalent app status section)
2. Locate `FinBridge Connect` and review state.
3. If needed, trigger manual device sync and re-check after next check-in.

UI label variation note:
- Device-side app status blade names vary by tenant UX.
- Verify by finding the per-device managed app status view, even if naming differs.

### 7.3 Interpret status values

1. **Installed**
   - Meaning: app installed and detection rule matched (`HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`).
   - Action: count as success for pilot metrics.
2. **Failed**
   - Meaning: installer failed, timed out, or detection did not match after install attempt.
   - Action: check command syntax, installer logs, detection rule path/value, and return-code mapping.
3. **Not applicable**
   - Meaning: device does not meet requirement filters (OS/architecture/scope) or assignment context mismatch.
   - Action: verify requirements and assignment targeting logic.

## 8. Exit criteria before phased rollout starts

1. App visible in catalog with correct metadata.
2. Program commands validated on pilot devices.
3. Detection rule consistently reports installed version 3.1.
4. Return codes correctly map success/failure outcomes.
5. Pilot Required assignment shows stable success rate with no unexplained failures.
6. Any "Failed" or "Not applicable" statuses are triaged and resolved.

Only after all exit criteria pass should phased rollout expand beyond pilot.

## 9. Common mistakes to avoid

1. Assigning Required directly to full production fleet.
2. Using wrong app type (for example Store app flow for `.intunewin`).
3. Detection path typo or wrong value comparison operator.
4. Choosing user-context install for an app that needs machine-level rights.
5. Treating unknown non-zero return codes as success without vendor confirmation.

## 10. Quick reference for this worked example

- Package: `FinBridgeConnect_v3.1.intunewin`
- Install command: `FinBridgeConnect_Setup.exe /silent`
- Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
- Detection rule: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`
- Initial assignment: `Required` to pilot device group only