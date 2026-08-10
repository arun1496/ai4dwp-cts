# Windows 11 Intune Compliance Policy Baseline Translation

Date: 2026-08-10  
Role context: DWP engineer  
Target platform: Windows 10 and later (Windows 11 endpoints)

## Policy Scope
This document translates baseline security requirements into Microsoft Intune **Device compliance policy** settings for Windows 11.

Recommended policy object:
- Intune admin center -> Devices -> Compliance policies -> Policies -> Create Policy
- Platform: Windows 10 and later
- Profile type: Windows 10/11 compliance policy

## Global Compliance Action
Set grace period for all settings:
- Action for noncompliance: Mark device noncompliant
- Schedule: 7 days after noncompliance

UI path (likely current):
- Devices -> Compliance policies -> Policies -> <Your Policy> -> Properties -> Actions for noncompliance

---

## Requirement Mapping

### 1) BitLocker must be enabled on the OS drive
- Setting name: **Require BitLocker**
- Value: **Require**
- Effect: Device is compliant only if OS volume encryption is enabled with BitLocker.
- False-positive risk: 
  - Encryption in progress but not yet fully reported by MDM inventory.
  - Device recently enrolled or reimaged; compliance state not refreshed yet.
  - Third-party full-disk encryption in use (not recognized as BitLocker compliance).
- Recommendation:
  - Keep setting as **Require**.
  - Use dynamic assignment delay for fresh builds (for example, first check after provisioning completion).
  - Keep 7-day grace period to absorb reporting lag.
- UI path (likely current):
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> Device Health -> Require BitLocker
- UI path drift risk: **Low to medium** (labels are stable; menu grouping can shift).

### 2) Secure Boot must be enabled
- Setting name: **Require Secure Boot to be enabled on the device**
- Value: **Require**
- Effect: Device is compliant only if UEFI Secure Boot is enabled.
- False-positive risk:
  - Legacy BIOS mode devices cannot satisfy this.
  - VM configurations or custom firmware templates missing Secure Boot.
  - Reporting lag after BIOS/UEFI remediation.
- Recommendation:
  - Keep as **Require** for corporate Windows 11 fleet.
  - Exclude legacy exception group temporarily only where hardware remediation is planned.
- UI path (likely current):
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> Device Health -> Require Secure Boot to be enabled on the device
- UI path drift risk: **Low to medium**.

### 3) Minimum OS build N-1 (22621.2861)
- Setting name: **Minimum OS version**
- Value: **10.0.22621.2861**
- Effect: Devices below build 22621.2861 are noncompliant.
- False-positive risk:
  - Build formatting mistakes (missing major/minor prefix) causing unexpected evaluations.
  - Feature update staged rollout where some healthy devices are intentionally one patch behind.
  - Devices pending reboot after patch install still report older build.
- Recommendation:
  - Use exact 4-part format: **10.0.22621.2861**.
  - Pair with update rings and reboot deadlines so compliance and patch orchestration align.
  - Review monthly and advance N-1 baseline with change control.
- UI path (likely current):
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> Device Properties -> Minimum OS version
- UI path drift risk: **Medium** (property grouping names have changed over time).

### 4) Windows Defender real-time protection must be on
- Setting name: **Microsoft Defender Antimalware - Real-time protection**
- Value: **Require**
- Effect: Device is compliant only if Defender AV real-time protection is enabled.
- False-positive risk:
  - Third-party AV may disable Defender real-time engine intentionally.
  - Tamper protection or security tooling transition windows can delay state synchronization.
  - MDE onboarding timing mismatches can temporarily report stale state.
- Recommendation:
  - If third-party AV is approved, validate compliance strategy before enforcing this setting tenant-wide.
  - Prefer consistent AV standard per device group to avoid dual-stack ambiguity.
- UI path (likely current):
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> Microsoft Defender for Endpoint (or System Security section, tenant-dependent labeling) -> Microsoft Defender Antimalware - Real-time protection
- UI path drift risk: **High** (Defender-related sections have seen naming/path adjustments across portal iterations).

### 5) Firewall must be enabled for all profiles
- Setting name: **Firewall**
- Value: **Require**
- Effect: Device is compliant only if Windows Firewall is enabled.
- False-positive risk:
  - Local troubleshooting scripts or security agents temporarily disable a profile.
  - State reporting delays immediately after policy application.
  - Conflicting local GPO/security baseline causing flip-flop states.
- Recommendation:
  - Keep as **Require**.
  - Ensure endpoint security firewall policies are authoritative and conflict-free.
  - Validate Domain/Private/Public profiles in endpoint security profile, not only compliance policy.
- UI path (likely current):
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> Device Health (or System Security) -> Firewall
- UI path drift risk: **Medium**.

### 6) A PIN or password must be configured
- Setting name: **Password** category settings in compliance policy
- Value:
  - **Require a password to unlock mobile devices** = Require
  - **Simple passwords** = Block
  - **Minimum password length** = 6 or greater (recommend 8)
  - **Password type** = Device default or Alphanumeric (depending org standard)
- Effect: Device is compliant only if user has configured a qualifying unlock credential.
- False-positive risk:
  - Windows Hello for Business deployments can create interpretation gaps if password rules conflict with PIN strategy.
  - Existing devices may need user sign-in cycle before reporting updated credential state.
- Recommendation:
  - Align with Windows Hello for Business policy: enforce PIN complexity there, and use compliance password requirements that do not conflict.
  - Recommend **minimum length 8** unless a documented exception exists.
- UI path (likely current):
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> System Security / Password
- UI path drift risk: **High** (password setting labels differ between platforms and have changed in UI wording).

### 7) Device must not be jailbroken or rooted
- Setting name: **Jailbroken devices**
- Value: **Block**
- Effect: Device is noncompliant if tampering/root/jailbreak indicators are detected.
- False-positive risk:
  - Rare on Windows 11, but integrity sensor/reporting issues can transiently misreport.
  - Co-management or sensor onboarding issues may cause unknown state.
- Recommendation:
  - Keep as **Block**.
  - Monitor first 1-2 weeks for unexpected noncompliance spikes before broad enforcement.
- UI path (likely current):
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> Device Health -> Jailbroken devices
- UI path drift risk: **Medium**.

---

## Notes on UI Path Accuracy
The Intune portal is updated frequently. The following areas are most likely to have moved or renamed since historical documentation:
- Defender section naming and placement (high drift risk).
- Password subsection labels and platform-specific wording (high drift risk).
- Device Health vs System Security grouping labels (medium drift risk).

Practical validation step:
- In policy editor, use the setting picker/search box and search exact strings:
  - "BitLocker"
  - "Secure Boot"
  - "Minimum OS version"
  - "Real-time protection"
  - "Firewall"
  - "Password"
  - "Jailbroken"

---

## Recommended Baseline Summary (Ready to Implement)
- Require BitLocker: Require
- Require Secure Boot to be enabled on the device: Require
- Minimum OS version: 10.0.22621.2861
- Microsoft Defender Antimalware - Real-time protection: Require
- Firewall: Require
- Password controls: Require unlock password/PIN posture (with org-approved complexity)
- Jailbroken devices: Block
- Action for noncompliance grace period: 7 days

## Implementation Tip
Create one pilot assignment group first, monitor compliance outcomes for 3-7 days, then expand scope tenant-wide.