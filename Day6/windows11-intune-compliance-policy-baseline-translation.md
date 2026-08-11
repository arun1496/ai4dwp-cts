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
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> **Device Health** -> Require BitLocker
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
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> **Device Health** -> Require Secure Boot to be enabled on the device
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
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> **Device Properties** -> Minimum OS version
- UI path drift risk: **Low** ("Device Properties" is a stable, dedicated section in the current portal).

#### Step-by-step implementation guide (Windows 11)

**Step 1 — Understand the build number format**

Windows 11 uses a 4-part version string:

| Part | Meaning | Example |
|---|---|---|
| `10` | Major (always 10 for Win10/11) | `10` |
| `0` | Minor (always 0) | `0` |
| `22621` | Feature release build (22H2) | `22621` |
| `2861` | Cumulative update revision | `2861` |

Full value to enter in Intune: **`10.0.22621.2861`**

**Step 2 — Where to set it in Intune**

Navigate to:
> Intune admin center → **Devices** → **Compliance policies** → **Policies** → your policy → **Properties** → **Device Properties** → **Minimum OS version**

The **Device Properties** section is a dedicated category in the compliance policy editor (alongside Device Health, System Security, Microsoft Defender for Endpoint, etc.).

Enter exactly: `10.0.22621.2861`

**Step 3 — What happens when a device is checked**

- Build **≥ 10.0.22621.2861** → device is **Compliant**
- Build **< 10.0.22621.2861** → device is **Noncompliant** → 7-day grace period starts
- After 7 days still noncompliant → marked noncompliant (Conditional Access can block access)

**Step 4 — Watch for false positives**

| Scenario | Why it happens | What to do |
|---|---|---|
| Device just patched, reboot pending | Still reports old build until reboot | Enforce reboot deadlines in Update Rings |
| Staged feature update rollout | Some healthy devices intentionally behind | Coordinate N-1 baseline with rollout schedule |
| Wrong format entered (`22621.2861` without `10.0.` prefix) | Intune evaluates unexpectedly | Always use full 4-part format |

**Step 5 — Maintain the baseline monthly**

1. When a new cumulative update ships, the new build becomes **N**.
2. The previous patch level becomes **N-1** — update the policy value via change control.
3. Devices that haven't patched yet will get the 7-day grace period to catch up.

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
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> **Microsoft Defender for Endpoint** -> Microsoft Defender Antimalware - Real-time protection
- UI path drift risk: **Medium** (section is now a dedicated "Microsoft Defender for Endpoint" category; internal label wording may still shift).

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
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> **System Security** -> Firewall
- UI path drift risk: **Low to medium** (Firewall sits under System Security in the current editor).

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
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> **System Security** -> Password
- UI path drift risk: **High** (password setting labels differ between platforms and have changed in UI wording).

### 7) MDE machine risk score must be Low or lower
- Setting name: **Require the device to be at or under the machine risk score**
- Value: **Low**
- Effect: Device is compliant only if Microsoft Defender for Endpoint reports a machine risk score of Low, Clear, or None. Medium, High, or Informational scores result in noncompliance.
- False-positive risk:
  - Active threat investigation or open alert on an otherwise healthy device can temporarily elevate the score.
  - MDE onboarding not yet complete — device reports no score and may be evaluated as noncompliant.
  - Transient detections (for example, test files, pen-test tooling) triggering a score spike.
- Recommendation:
  - Ensure all devices are fully onboarded to MDE before enforcing this setting.
  - Use the 7-day grace period to absorb onboarding lag and score stabilisation.
  - Review MDE alerts dashboard alongside Intune noncompliance reports to distinguish real threats from false positives.
- UI path (likely current):
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> **Microsoft Defender for Endpoint** -> Require the device to be at or under the machine risk score -> **Low**
- UI path drift risk: **Medium** (section label is stable; inner setting wording may change with portal updates).

### 8) Device must not be jailbroken or rooted
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
  - Devices -> Compliance policies -> Policies -> <Policy> -> Properties -> **Device Health** -> Jailbroken devices
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
- MDE machine risk score: Low (or under)
- Firewall: Require
- Password controls: Require unlock password/PIN posture (with org-approved complexity)
- Jailbroken devices: Block
- Action for noncompliance grace period: 7 days

## Implementation Tip
Create one pilot assignment group first, monitor compliance outcomes for 3-7 days, then expand scope tenant-wide.

---

## Post-Assignment Validation Steps

### Where to Check Device Compliance Status

**Route A — From the policy (fleet view):**
> Intune admin center → Devices → Compliance policies → Policies → WIN11-Baseline-Compliance-Policy → **Device status**

Lists every assigned device with its per-policy compliance state. Click any device row to drill into per-setting results.

**Route B — From the device (most useful for diagnosis):**
> Intune admin center → Devices → All devices → \<device name\> → **Device compliance** → \<policy name\>

Expand each setting to see Compliant / Not compliant / Not applicable / Unknown per individual setting.

**Route C — From the user:**
> Intune admin center → Users → \<user\> → Devices → click device → **Device compliance**

Use this when a user reports an access issue and you need to trace from their account.

---

### Compliance States and Conditional Access Impact

| State | Meaning | Conditional Access impact |
|---|---|---|
| **Compliant** | All policy settings satisfied and reported | CA grants access normally |
| **In grace period** | One or more settings failing; 7-day grace period has not expired | CA **still grants access** — grace period is a countdown, not a block |
| **Not compliant** | One or more settings failing AND grace period has expired | CA **blocks access** to all protected resources (M365, SharePoint, Teams) |

> **Operational note:** "In grace period" is not safe to ignore. A real failure exists and the 7-day clock is running. Investigate immediately.

---

### BitLocker False Positive — Three Most Common Causes

If a device shows non-compliant on BitLocker despite BitLocker being visibly enabled:

#### Cause 1 — Encryption in progress, not yet fully reported

BitLocker is actively encrypting the drive. Windows reports the volume as "encrypting" — Intune reads this as non-compliant.

**Fastest check (run on the device):**
```powershell
manage-bde -status C:
```
If `Conversion Status` shows `Encryption in Progress`, wait for `Fully Encrypted` then force an Intune sync:
```powershell
Start-ScheduledTask -TaskName "\Microsoft\Windows\EnterpriseMgmt\*"
```

---

#### Cause 2 — Recovery key not escrowed to Entra ID

The drive is encrypted but Intune does not own it — the device self-encrypted before Intune enrollment was established, so no recovery key has been backed up.

**Fastest check (in the portal):**
> Intune admin center → Devices → All devices → \<device\> → **Recovery keys**

If no recovery key is listed, run on the device:
```powershell
BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId (
    (Get-BitLockerVolume -MountPoint "C:").KeyProtector |
    Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
).KeyProtectorId
```
Sync the device. Compliance resolves on the next evaluation cycle.

---

#### Cause 3 — Stale compliance evaluation after reimage or policy reassignment

The portal is showing a result from a previous evaluation. The device has not yet completed a full MDM sync cycle since the policy was assigned or the device was reimaged.

**Fastest check — look at the evaluation timestamp:**
> Intune admin center → Devices → \<device\> → Device compliance → **Last evaluation** timestamp

If the timestamp is older than 1 hour since the sync completed, the result is stale. Force a fresh evaluation:
> Intune admin center → Devices → \<device\> → **Sync** (top action bar)

Wait 5–10 minutes and refresh the compliance view.