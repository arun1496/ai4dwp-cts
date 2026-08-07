# Runbook: AVD Black Screen on POOL-FIN-01 (Intel Driver Regression)

| Field | Value |
|---|---|
| Title | Runbook: AVD Black Screen on POOL-FIN-01 (Intel Driver Regression) |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Sathishbabu |
| Reviewed | self |
| Status | draft |
| Change | initial version from RCA |

**Source RCA:** Day4/rca-avd-black-screen-pool-fin-01-2026-08-06.md  
**Incident Pattern:** Users log in to AVD and see black screen, then session disconnects/reconnects.

## Prerequisites

1. Confirm you have Azure Portal access to subscription and resource group hosting POOL-FIN-01.
Expected result: You can open Azure Portal and browse to host pool POOL-FIN-01.

2. Confirm you have one of these RBAC roles on the AVD resources: Owner, Contributor, or Desktop Virtualization Contributor.
Expected result: In Azure Portal, your account can edit host pool session host settings and assign image versions.

3. Confirm you have VM-level rights on session hosts (VM Contributor or equivalent) and Just-In-Time/PIM elevation if your tenant uses it.
Expected result: You can run Run command on a session host VM.

4. Confirm you have local administrator rights on session hosts for event log and driver inspection actions.
Expected result: Driver query commands run successfully on the host.

5. Confirm you can access Azure Compute Gallery image versions used by POOL-FIN-01.
Expected result: You can list available image versions and identify the previous known-good version.

6. Open three browser tabs before starting:
- Tab 1: Azure Portal -> Azure Virtual Desktop -> Host pools -> POOL-FIN-01
- Tab 2: Azure Portal -> Virtual machines (filtered to SHFIN-01-* hosts)
- Tab 3: Azure Portal -> Azure Monitor -> Logs (or host VM Run command pane)
Expected result: All three tabs are open and reachable.

7. Identify the fallback host pool (POOL-FIN-02) and confirm it has healthy capacity.
Expected result: POOL-FIN-02 has available session host capacity and accepts new sessions.

## Procedure

**Permission legend:** [ELEVATED] means step requires elevated privileges.

1. Open Azure Portal path: Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Session hosts.
Expected result: Session hosts list for POOL-FIN-01 is displayed.

2. Set session host SHFIN-01-A to Drain mode by selecting the host -> Update -> Allow new sessions = Off -> Save. [ELEVATED]
Expected result: SHFIN-01-A shows Allow new sessions = No.

3. Repeat the same drain action for each host in POOL-FIN-01. [ELEVATED]
Expected result: Every POOL-FIN-01 host shows Allow new sessions = No.

4. Open Azure Portal path: Azure Virtual Desktop -> Host pools -> POOL-FIN-02 -> Session hosts.
Expected result: Session hosts list for POOL-FIN-02 is displayed.

5. Confirm at least one POOL-FIN-02 host shows Available sessions greater than 0.
Expected result: New user connections can land on POOL-FIN-02.

6. Open Azure Portal path: Virtual machines -> SHFIN-01-A -> Operations -> Run command -> RunPowerShellScript. [ELEVATED]
Expected result: Run command pane is open for SHFIN-01-A.

7. Run this command on SHFIN-01-A: Get-WinEvent -FilterHashtable @{LogName='Application';ID=1000;StartTime=(Get-Date).AddHours(-4)} | Where-Object { $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64.dll' } | Select-Object -First 5 TimeCreated,Id,ProviderName,Message | Format-List
Expected result: Output contains Application Error 1000 entries mentioning dwm.exe and igdumd64.dll.

8. Run this command on SHFIN-01-A: Get-WinEvent -FilterHashtable @{LogName='System';ID=9009;StartTime=(Get-Date).AddHours(-4)} | Select-Object -First 5 TimeCreated,Id,ProviderName,Message | Format-List
Expected result: Output shows Desktop Window Manager Event ID 9009 entries around user login attempts.

9. Run this command on SHFIN-01-A: Get-Item 'C:\Windows\System32\igdumd64.dll' | Select-Object FullName,@{Name='FileVersion';Expression={$_.VersionInfo.FileVersion}}
Expected result: File version is returned for igdumd64.dll and is newer than the approved known-good baseline.

10. Open Azure Portal path: Compute Galleries -> <your gallery> -> Images -> <AVD base image for POOL-FIN-01> -> Versions.
Expected result: Image versions list is visible with publish timestamps.

11. Select the last known-good image version published before 2026-08-06 02:00 and note the exact version string.
Expected result: You have one specific fallback image version identified.

12. Open Azure Portal path: Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Properties.
Expected result: Host pool properties page is displayed.

13. Update Image reference in POOL-FIN-01 to the known-good gallery image version and save. [ELEVATED]
Expected result: Host pool image reference shows the selected known-good version.

14. Open Azure Portal path: Virtual machines -> SHFIN-01-A -> Overview -> Redeploy or Reimage using the updated host pool image process used by your environment. [ELEVATED]
Expected result: SHFIN-01-A rebuild task starts and provisioning state changes to Updating.

15. Wait for SHFIN-01-A provisioning state to return to Succeeded.
Expected result: SHFIN-01-A shows Running and Succeeded with recent activity completed.

16. Set SHFIN-01-A Allow new sessions = On in POOL-FIN-01 -> Session hosts. [ELEVATED]
Expected result: SHFIN-01-A shows Allow new sessions = Yes.

17. Initiate one test login using a non-privileged test account through the AVD client to POOL-FIN-01.
Expected result: Desktop appears within 30 seconds and stays usable for at least 2 minutes.

18. Run this command on SHFIN-01-A to check post-fix crash signals: Get-WinEvent -FilterHashtable @{LogName='Application';ID=1000;StartTime=(Get-Date).AddMinutes(-15)} | Where-Object { $_.Message -match 'dwm.exe' -or $_.Message -match 'igdumd64.dll' } | Select-Object TimeCreated,Id,Message
Expected result: No new Event 1000 entries for dwm.exe or igdumd64.dll after the canary login.

19. Run this command on SHFIN-01-A to check DWM exits: Get-WinEvent -FilterHashtable @{LogName='System';ID=9009;StartTime=(Get-Date).AddMinutes(-15)} | Select-Object TimeCreated,Id,Message
Expected result: No new Event 9009 entries after canary login.

20. Reimage the next batch of POOL-FIN-01 hosts (maximum 25% of pool at a time) using the same known-good image version. [ELEVATED]
Expected result: Batch hosts return to Running and Succeeded.

21. Turn Allow new sessions = On only for successfully rebuilt hosts in that batch. [ELEVATED]
Expected result: Rebuilt hosts accept new sessions; unrepaired hosts remain drained.

22. Repeat batch rebuild and enablement until all POOL-FIN-01 hosts are rebuilt.
Expected result: All POOL-FIN-01 hosts are on known-good image and can accept new sessions.

23. Capture incident evidence (commands used, image version, host list, timestamps) in the ticket timeline.
Expected result: Ticket contains auditable remediation evidence.

## Verification

1. Verify login experience: complete 3 consecutive logins to POOL-FIN-01 from two separate test users.
Success looks like: Desktop appears in under 30 seconds each time, no black screen, no forced reconnect.

2. Verify event stability on each rebuilt host: check last 30 minutes for Event 1000 (dwm.exe/igdumd64.dll), Event 9009, and Event 40.
Success looks like: Zero new matching Event 1000, zero Event 9009, and no repeating Event 40 disconnect loop.

3. Verify service health in AVD session hosts view.
Success looks like: All POOL-FIN-01 hosts show Available or Unavailable only for planned maintenance; none show recurring heartbeat/session issues.

4. Verify user-impact channel (service desk queue or Teams bridge) for 30 minutes after full rollout.
Success looks like: No new black-screen tickets tied to POOL-FIN-01.

5. Verify image consistency.
Success looks like: Every POOL-FIN-01 host reports the same approved image version and expected igdumd64.dll file version.

## Rollback

Use this section immediately if black screens increase, disconnect loops return, or canary host fails validation.

1. Set Allow new sessions = Off for every POOL-FIN-01 host from Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Session hosts. [ELEVATED]
Expected result: No new user sessions land on unstable hosts.

2. Set Allow new sessions = On for POOL-FIN-02 hosts with available capacity. [ELEVATED]
Expected result: New sessions are redirected to stable pool POOL-FIN-02.

3. Revert POOL-FIN-01 host pool image reference to the exact previously known-good gallery version used before the current change. [ELEVATED]
Expected result: Host pool configuration points to previously stable image version.

4. Rebuild one rollback canary host (SHFIN-01-A) from the reverted image. [ELEVATED]
Expected result: Canary host reaches Running and Succeeded.

5. Enable new sessions only on the rollback canary host. [ELEVATED]
Expected result: Only one host is exposed for risk-controlled validation.

6. Run one test login to rollback canary host.
Expected result: Desktop loads within 30 seconds and remains stable for 2 minutes.

7. Validate rollback canary logs for last 15 minutes (no Event 1000 dwm.exe/igdumd64.dll and no Event 9009).
Expected result: Crash signatures are absent.

8. Rebuild remaining POOL-FIN-01 hosts from reverted image in 25% batches. [ELEVATED]
Expected result: Each batch returns to healthy state before next batch starts.

9. Keep any non-rebuilt hosts in drain mode until their rebuild is complete. [ELEVATED]
Expected result: Users are not routed to unverified hosts.

10. If POOL-FIN-02 capacity is insufficient, trigger incident command and request temporary scaling of POOL-FIN-02 before reopening POOL-FIN-01.
Expected result: Capacity risk is controlled and user impact reduced.

11. Update the incident record with rollback decision time, approver, reverted image version, and host-by-host completion status.
Expected result: Full rollback audit trail is recorded.

## Notes

- Warning: Do not enable new sessions on any host that has not been rebuilt to the approved image version.
- Edge case: If Event 1000 references a module other than igdumd64.dll, pause this runbook and start fresh triage for a different failure mode.
- Edge case: If users still see black screen but logs are clean, test FSLogix/profile mount and shell startup separately because this runbook targets DWM driver crash pattern only.
- Related incident set: Day4/known-error-avd-black-screen-pool-fin-01-2026-08-06.md, Day4/closure-note-avd-black-screen-pool-fin-01-2026-08-06.md, Day4/enduser-communications-avd-black-screen-pool-fin-01-2026-08-06.md.
- Operational caution: Keep POOL-FIN-01 and POOL-FIN-02 on staggered maintenance windows to preserve a safe fallback pool.
