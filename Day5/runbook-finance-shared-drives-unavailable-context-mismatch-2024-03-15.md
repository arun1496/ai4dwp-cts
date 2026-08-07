## Version Header

**Title:** Runbook - Finance Shared Drives Unavailable (Execution Context Mismatch)  
**Version:** 1.0  
**Date:** 07/08/2026  
**Author:** Sathishbabu  
**Reviewed:** self  
**Status:** draft  
**Change:** initial version from RCA

# Runbook - Finance Shared Drives Unavailable (Execution Context Mismatch)

**Incident Pattern:** Finance users cannot access mapped drive `S:` after drive-mapping migration from GPO logon script (USER context) to Intune script (SYSTEM context).
**Source RCA:** `Day4/rca-finance-shared-drives-2024-03-15.md`
**Audience:** L2/L3 DWP engineers
**Use When:** Multiple Finance users on `DESKTOP-FB*` report missing `S:` drive and access failure to `\\finbridge-fs01\\Finance`.

---

## Prerequisites

1. Obtain a valid incident/change reference ID for audit tracking.
2. Confirm you are assigned to endpoint remediation for `OU=Finance`.
3. Ensure you have Intune Administrator (or equivalent script/app assignment management) access. **[ELEVATED]**
4. Ensure you have read access to endpoint event logs (System and Applications and Services Logs) on at least one affected `DESKTOP-FB*` device. **[ELEVATED]**
5. Ensure you can sign in as, or shadow, a real Finance test user for post-fix validation. **[ELEVATED if shadowing/remote admin tools are used]**
6. Open these tools before starting:
   - Microsoft Intune admin center
   - Event Viewer (or equivalent centralized log viewer)
   - Remote endpoint management tool (if device access is remote)
7. Identify one pilot affected endpoint and one pilot Finance user for safe-first remediation.
8. Confirm current symptom on pilot endpoint: `S:` is missing or inaccessible for the Finance user.

---

## Procedure

1. Sign in to Microsoft Intune admin center at `https://intune.microsoft.com`. **[ELEVATED]**
   - Expected result: Intune home page loads and your account shows admin access.

2. Open `Devices` > `Scripts and remediations` > `Platform scripts`.
   - Expected result: The Platform scripts list is visible.

3. Search for `Map-FinBridgeDrives` in the Platform scripts search box.
   - Expected result: The script object used for Finance drive mapping appears in results.

4. Open the `Map-FinBridgeDrives.ps1` script object.
   - Expected result: Script overview page opens with `Properties`, `Assignments`, and status tabs.

5. Capture a screenshot of the `Properties` tab showing execution context and run settings, then attach it to the incident record. **[ELEVATED]**
   - Expected result: Incident ticket contains timestamped pre-change evidence.

6. Open the `Assignments` tab for `Map-FinBridgeDrives.ps1`.
   - Expected result: Current assignment groups are listed.

7. Remove Finance-targeted assignments (for example Finance device/user groups) from the SYSTEM-context script. **[ELEVATED]**
   - Expected result: No Finance group remains assigned to the SYSTEM-context script.

8. In Intune, open the approved USER-context replacement object (script or policy) for Finance drive mapping. **[ELEVATED]**
   - Expected result: Replacement object opens and is available for assignment.

9. Open the `Assignments` tab on the USER-context replacement object.
   - Expected result: Assignment editor opens.

10. Assign only the pilot Finance test group/user to the USER-context replacement object. **[ELEVATED]**
   - Expected result: Assignments show only pilot scope and do not include full Finance population.

11. On the pilot endpoint in Intune, open `Devices` > `Windows` > `Windows devices` and select the pilot device. **[ELEVATED]**
   - Expected result: Pilot device overview page opens.

12. Click `Sync` on the pilot device page. **[ELEVATED]**
   - Expected result: Notification confirms sync command sent successfully.

13. Wait until the pilot device `Last check-in` time updates to a newer timestamp.
   - Expected result: `Last check-in` reflects a recent time after the sync action.

14. Sign out from Windows on the pilot endpoint.
   - Expected result: Pilot user session ends and returns to Windows sign-in screen.

15. Sign back in to Windows on the pilot endpoint as the pilot Finance user.
   - Expected result: Pilot user desktop loads normally.

16. Open File Explorer and select `This PC`.
   - Expected result: Drive list is visible.

17. Confirm drive `S:` appears in the drive list.
   - Expected result: `S:` is listed and shows as a mapped network drive.

18. In File Explorer address bar, enter `\\finbridge-fs01\\Finance` and press Enter.
   - Expected result: The Finance share opens and displays folders without error pop-ups.

19. Open Event Viewer on the pilot endpoint and go to `Windows Logs` > `System`. **[ELEVATED]**
   - Expected result: System log events are visible.

20. Filter current System log for Event ID `98` in the post-change validation window.
   - Expected result: No Event ID `98` entries appear for drive `S:` after the fix logon.

21. Assign the USER-context replacement object to the full Finance target group(s). **[ELEVATED]**
   - Expected result: Assignment list includes required Finance production group(s).

22. Send `Sync` from Intune to at least two additional affected Finance endpoints. **[ELEVATED]**
   - Expected result: Sync command accepted for each selected endpoint.

23. Sign out and sign in on each sampled additional endpoint as a Finance user.
   - Expected result: New user sessions start on each sampled endpoint.

24. Confirm `S:` is present and `\\finbridge-fs01\\Finance` opens on each sampled additional endpoint.
   - Expected result: Both checks pass on each sampled endpoint with no access errors.

25. Record final evidence in the incident ticket (screenshots, event check results, tested users/devices, and timestamp).
   - Expected result: Incident contains complete audit trail and is ready for closure decision.

---

## Verification

Complete all checks before closure:

1. Verify on pilot endpoint in File Explorer > `This PC` that drive `S:` is visible after sign-in.
   - Success looks like: `S:` is listed as a mapped network drive and is clickable.

2. Verify on pilot endpoint that `\\finbridge-fs01\\Finance` opens in File Explorer.
   - Success looks like: Share contents load and no access, path, or network-name error dialog appears.

3. Verify the same two checks (`S:` present and share opens) on at least two additional affected endpoints.
   - Success looks like: All sampled endpoints pass both checks on first post-fix sign-in.

4. Verify in Intune `Devices` > `Scripts and remediations` > `Platform scripts` > `Map-FinBridgeDrives.ps1` > `Assignments` that Finance groups are not assigned.
   - Success looks like: Finance production groups are absent from assignments on the SYSTEM-context script.

5. Verify in Intune that the USER-context replacement object shows Finance production group assignments.
   - Success looks like: Required Finance groups are present and assignment save timestamp matches rollout window.

6. Verify in Event Viewer (`Windows Logs` > `System`) on pilot endpoint that no new Event ID `98` for `S:` occurred after remediation.
   - Success looks like: Zero post-fix Event ID `98` entries tied to `S:` in the validation window.

7. Verify incident trend in service desk queue for one business hour after rollout.
   - Success looks like: No new Finance shared-drive outage incidents are created during that hour.

Closure criteria:
- All verification checks pass.
- Resolution evidence is attached to incident record.
- Known Error/reference links are updated if required by process.

---

## Rollback

Use this section if post-change impact increases. Target completion time: under 3 minutes.

1. Open `https://intune.microsoft.com` and go to `Devices` > `Scripts and remediations` > `Platform scripts`. **[ELEVATED]**
   - Expected result: Platform scripts list is visible.

2. Search for the USER-context replacement object used in Procedure Step 8 and open it. **[ELEVATED]**
   - Expected result: Replacement object page opens.

3. Open `Assignments` on the replacement object and remove all Finance production groups, then click `Review + save` > `Save`. **[ELEVATED]**
   - Expected result: Assignment summary shows Finance production groups are no longer targeted.

4. Return to `Platform scripts`, search `Map-FinBridgeDrives.ps1`, and open it. **[ELEVATED]**
   - Expected result: `Map-FinBridgeDrives.ps1` overview opens.

5. Open `Assignments` on `Map-FinBridgeDrives.ps1` and restore the pre-change assignment snapshot captured in Procedure Step 5, then click `Review + save` > `Save`. **[ELEVATED]**
   - Expected result: Assignment list matches the recorded pre-change state.

6. Go to `Devices` > `Windows` > `Windows devices`, open the pilot impacted device, and click `Sync`. **[ELEVATED]**
   - Expected result: Sync command confirmation appears.

7. On the pilot endpoint, sign out and sign back in as the pilot Finance user.
   - Expected result: Fresh user session starts.

8. On the pilot endpoint, open File Explorer > `This PC` and confirm drive `S:` is present.
   - Expected result: `S:` appears as a mapped network drive.

9. On the pilot endpoint, open `\\finbridge-fs01\\Finance` in File Explorer.
   - Expected result: Share opens without access or network-name error.

10. If Step 8 or Step 9 fails, open a Major Incident immediately and attach two Intune assignment screenshots (replacement object and `Map-FinBridgeDrives.ps1`) plus pilot endpoint test timestamp. **[ELEVATED]**
   - Expected result: Escalation is active with evidence attached.

Rollback success criteria:
- Finance production groups are removed from the new USER-context replacement object.
- Pre-change assignment state is restored on `Map-FinBridgeDrives.ps1`.
- Pilot user regains `S:` and can open `\\finbridge-fs01\\Finance` after sync and sign-in.

---

## Notes

- This incident pattern is specifically caused by execution-context mismatch: USER-dependent drive mapping run as SYSTEM.
- A script that works as a GPO user logon script is not automatically valid as an Intune SYSTEM script.
- Startup timing matters: early execution before Workstation service readiness can produce false-negative share access failures.
- No-retry behavior amplifies transient startup issues into persistent user outages.
- Always pilot with a real Finance user before broad assignment.
- Related artifacts:
  - `Day4/rca-finance-shared-drives-2024-03-15.md`
  - `Day4/hypothesis-finance-shared-drives-2024-03-15.md`
  - `Day4/known-error-finance-shared-drives-2024-03-15.md`
