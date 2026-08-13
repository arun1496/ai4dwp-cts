# macOS Security Baseline to Jamf Configuration Profile Mapping

**Audience:** DWP engineer translating a macOS baseline for a 25-device Design team fleet  
**Target platform:** macOS managed through Jamf Pro  
**Scope:** Configuration profile payloads plus one item that must be enforced by Smart Group / policy rather than a direct payload  
**Important:** Jamf Pro payload labels and field names can shift between versions. Verify the exact label in your own Jamf instance before deploying, especially for Security & Privacy, Passcode, Restrictions, and Software Update.

## Policy Scope

This document translates the baseline into Jamf Pro controls that are practical for a small design fleet.

Recommended control split:
- Configuration Profiles for FileVault, Firewall, Gatekeeper, password-after-sleep, and Software Update
- Smart Groups and an OS-version remediation policy for the minimum macOS version requirement

Recommended implementation model:
- Create a pilot smart group first
- Scope the profile to a test subset of design devices
- Verify actual on-device behavior before broadening to the full 25-device fleet

## Global Jamf Approach

Jamf Pro is not a one-to-one match for every compliance style used in Intune. For this baseline, the cleanest pattern is:
- Use configuration profiles when the setting is natively enforceable on macOS
- Use a Smart Group or Extension Attribute when the setting is better expressed as an OS version rule
- Use a remediation policy if the device must be corrected rather than merely reported

That approach keeps the policy readable and avoids overloading a single profile with controls that do not belong to the same payload.

---

## Requirement Mapping

### 1) FileVault disk encryption must be enabled

- Payload type: **FileVault**
- Value: **Enable FileVault for managed Macs** and escrow the recovery key to Jamf if your process requires key recovery.
- Effect: Forces full-disk encryption so data at rest remains protected if the Mac is lost, stolen, or removed from the office.
- False-positive risk:
	- New enrollments may not be fully encrypted yet when the compliance check runs.
	- Recovery key escrow can lag behind encryption state.
	- Devices that were manually encrypted before Jamf enrollment may look pending until inventory refresh completes.
- Setup notes:
	- Turn on FileVault at enrollment or as early in the user journey as possible.
	- Confirm the recovery key escrow workflow is tested before rollout.
	- Keep the enrollment process simple so the user completes the encryption prompt promptly.
- UI path (likely current):
	- Computers -> Configuration Profiles -> New -> **Disk Encryption** or **FileVault**
- UI path drift risk: **Medium**. The payload exists consistently, but Jamf console grouping and label wording can shift.

### 2) Gatekeeper must be enabled, identified developers only

- Payload type: **Security & Privacy**
- Value: **App Store and identified developers** or the closest Jamf equivalent that restricts execution to identified developers only.
- Effect: Blocks apps that are not signed, notarized, or otherwise allowed by Apple’s identified developer trust model.
- False-positive risk:
	- Legitimate internal tools may fail until they are signed and notarized correctly.
	- Older app packages can be blocked even though they are business-approved.
	- Users may report the setting as “broken” when the app is simply unsigned.
- Setup notes:
	- Align this control with your app distribution workflow before enforcing it.
	- Validate all design-team creative tools, plug-ins, and helper utilities before rollout.
	- If your organisation has unsigned internal tools, allowlist them through a controlled exception process rather than weakening the global baseline.
- UI path (likely current):
	- Computers -> Configuration Profiles -> New -> **Security & Privacy** -> App Store / Gatekeeper controls
- UI path drift risk: **High**. This is one of the most version-sensitive and label-sensitive areas in Jamf Pro.

### 3) Minimum macOS version: current stable minus one point release

- Payload type: **No direct configuration profile payload**
- Value: Enforce with **Smart Group**, **Extension Attribute**, and, if needed, a remediation policy.
- Effect: Devices below the approved macOS version are flagged or remediated so the fleet stays on a supported build.
- False-positive risk:
	- Devices in the middle of a staged upgrade can legitimately sit one step behind.
	- Apple may not yet have offered the target update to all supported models.
	- Users can defer restart prompts and temporarily remain on an older build.
- Setup notes:
	- Define the approved version as a full build string, not a vague “latest” value.
	- Use a Smart Group predicate that compares the current OS version to your approved baseline.
	- Treat this as an operational compliance check, not a security profile toggle.
- UI path (likely current):
	- Computers -> Smart Computer Groups -> New -> Criteria -> Operating System Version
	- If needed, pair with a Policy under Computers -> Policies for remediation
- UI path drift risk: **Medium**. Smart Group criteria are stable, but naming and available comparison logic can vary by Jamf release.

### 4) Firewall must be enabled

- Payload type: **Firewall**
- Value: **Enable the application firewall**
- Effect: Turns on the built-in macOS firewall to reduce unsolicited inbound traffic.
- False-positive risk:
	- Security tools or remote support software can appear to conflict with the firewall check.
	- The device may report inventory before the firewall state is fully synchronized.
	- Administrative troubleshooting can temporarily toggle the firewall and then restore it.
- Setup notes:
	- Keep the firewall on by default across the fleet.
	- If your team uses remote support or creative plug-ins, test them first so the firewall does not block required workflows.
	- Prefer a simple on/off posture rather than custom per-device exceptions unless there is a documented business need.
- UI path (likely current):
	- Computers -> Configuration Profiles -> New -> **Firewall**
- UI path drift risk: **Low to medium**.

### 5) Login password required after sleep/screen saver

- Payload type: **Security & Privacy** or **Passcode**, depending on Jamf Pro version and macOS management path
- Value: **Require password immediately after sleep or screen saver begins**; set the grace period to **0 seconds**
- Effect: Prevents a user or bystander from waking the device and using it without re-authentication.
- False-positive risk:
	- Apple Watch unlock can make the user believe the setting is not working as expected.
	- Devices with delayed profile application may not show the final setting immediately.
	- Some users confuse this with the screen-lock timer rather than the password prompt timer.
- Setup notes:
	- Set the delay to zero seconds for the strictest posture.
	- Confirm the profile is not being overridden by a second, conflicting profile.
	- If the fleet has both shared and assigned Macs, keep the shared-device exception list explicit.
- UI path (likely current):
	- Computers -> Configuration Profiles -> New -> **Security & Privacy** -> password after sleep/screen saver setting
- UI path drift risk: **High**. This setting is commonly renamed, regrouped, or exposed differently across versions.

### 6) Automatic security updates enabled

- Payload type: **Software Update**
- Value: **Enable automatic installation of security updates**; if your version exposes them, also enable security responses and related system files
- Effect: Keeps security fixes flowing without waiting on a manual user action.
- False-positive risk:
	- Devices can sit in a deferred or pending-restart state and look out of policy.
	- Apple may not have released the update for every supported model at the same time.
	- A user can postpone the restart long enough to make a healthy machine look behind.
- Setup notes:
	- Pair this with a restart reminder workflow so the device actually completes the update cycle.
	- Use a separate reporting mechanism to distinguish “update available” from “update installed but waiting on reboot.”
	- Test security response behavior on the current macOS version before relying on the exact field labels.
- UI path (likely current):
	- Computers -> Configuration Profiles -> New -> **Software Update**
- UI path drift risk: **High**. Apple and Jamf have both changed wording in this area over time.

---

## Step-by-Step Implementation Guide

### Step 1 — Build the Jamf structure first

Create the objects in this order:
1. Smart Group for compliant OS version
2. Configuration Profile for FileVault
3. Configuration Profile for Firewall
4. Configuration Profile for Security & Privacy controls
5. Configuration Profile for Software Update
6. Optional remediation policy for devices outside the approved OS version

This order keeps the most stable payloads in place before the reporting/remediation logic.

### Step 2 — Decide which items are enforced vs reported

- Enforced directly:
	- FileVault
	- Firewall
	- Gatekeeper
	- Password after sleep/screen saver
	- Automatic security updates
- Reported or remediated:
	- Minimum macOS version

The OS version item is the one most likely to require a separate compliance workflow.

### Step 3 — Validate the payload labels in your Jamf console

Use the Jamf UI search or payload picker and confirm the exact terms before deployment.

Search for these concepts:
- FileVault
- Security & Privacy
- Firewall
- Password after sleep
- Software Update
- Operating System Version

If the portal label differs from this document, trust the Jamf console and update the local baseline note.

### Step 4 — Pilot on a small device subset

For a 25-device design fleet, pilot on 3 to 5 devices first.

Pilot checklist:
- One standard design Mac
- One newly enrolled Mac
- One older Mac that is still supported
- One Mac with a known creative tool stack

That mix usually exposes profile drift, app compatibility issues, and update lag quickly.

### Step 5 — Confirm the device sees the final state

After the profile is scoped, confirm:
- FileVault is active and the recovery key is escrowed
- Firewall is on
- Gatekeeper is restricted to identified developers
- Password after sleep is immediate
- Software update automation is enabled
- Devices below the approved OS version are correctly flagged by Smart Group

### Step 6 — Expand to the full fleet

Only widen scope after the pilot devices look clean for at least one inventory cycle.

For the design team, watch for app exceptions from:
- Adobe creative suite integrations
- Browser plug-ins
- License tools
- Remote support helpers

These are the most common places where a healthy device can appear to be failing the baseline.

---

## Operational Notes

- Keep the baseline simple and resist the urge to add extra controls that are not part of the requirement.
- Use an exception process for approved creative software rather than weakening the security posture.
- Review the OS version rule monthly so the approved build does not drift behind Apple’s support window.
- If a setting repeatedly flags healthy devices, confirm whether the problem is a real policy failure or a Jamf reporting delay.

## Drift Risk Summary

- Highest drift risk: **Security & Privacy**, **Passcode/password after sleep**, **Software Update**
- Medium drift risk: **FileVault**, **Smart Group OS version logic**
- Lower drift risk: **Firewall**

## Final Practical Recommendation

Implement the baseline as a small set of targeted Jamf configuration profiles plus one OS-version Smart Group rule. That gives you a clean, supportable baseline for a 25-device Design team fleet without forcing every requirement into a single payload model Jamf was not designed to handle.