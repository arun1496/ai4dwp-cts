# Triage Summary — New Win11 Laptop BitLocker Recovery Prompt

**Ticket:** T-1001  
**Date raised:** to-verify  
**Raised by:** to-verify

---

## Summary
New Windows 11 laptop is prompting for the BitLocker recovery key at every boot.

## Impact
- **Who affected:** 1 user/device to-verify
- **How many:** 1 new laptop reported; wider impact unknown to-verify
- **Business urgency:** High if this is the user's only working device, because the laptop may be unavailable at sign-in and cannot be used until startup is restored

## Known Facts
- Device is a new Windows 11 laptop
- BitLocker recovery prompt appears on every boot
- The issue is happening consistently rather than as a one-off event
- No error code, screen photo, or exact recovery prompt text has been provided to verify

## Missing Information to Gather
1. User name, contact details, and device asset ID to-verify
2. Exact text shown on the BitLocker screen and whether any recovery key ID is displayed
3. Whether the prompt appears before Windows starts or after a reboot from a recent change
4. Whether the device is newly imaged, recently reissued, or has just had a hardware change to-verify
5. Whether the user can enter the recovery key successfully and reach the desktop
6. Whether the issue started after a BIOS/firmware update, security setting change, docking event, or TPM-related event to-verify
7. Whether any other new Win11 laptops are showing the same behavior to-verify
8. Whether the recovery key is available in the approved management record to-verify

## Likely Category
**Endpoint startup / BitLocker / device encryption**

Possible sub-categories to verify:
- TPM or secure boot state change
- Hardware or firmware change causing BitLocker to re-prompt
- Imaging or provisioning issue on the new laptop
- Device encryption policy or compliance mismatch

## First Diagnostic Step
Confirm the exact BitLocker recovery screen details, including any key ID, and verify whether the device was recently imaged or had any firmware, TPM, secure boot, or hardware changes before the repeated prompts began.