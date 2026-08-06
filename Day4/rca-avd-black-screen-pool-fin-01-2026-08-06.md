# Root Cause Analysis: AVD Black Screen – POOL-FIN-01
**Incident Date:** 2026-08-06
**RCA Date:** 2026-08-06
**Author:** IT Operations
**Status:** Resolved

---

## 1. Executive Summary

On 2026-08-06, approximately 40% of users connecting to the Azure Virtual Desktop host pool POOL-FIN-01 experienced a persistent black screen immediately after login. Affected sessions either auto-recovered after roughly 30 seconds or remained unusable. The incident began around 07:00 and was fully resolved by 10:00. Root cause was confirmed as a defective Intel graphics driver (igdumd64.dll) introduced into the POOL-FIN-01 host image during an overnight update at 02:00. The driver caused Desktop Window Manager (DWM) to crash on session initialisation, producing the observed black screen and immediate session disconnect loop. POOL-FIN-02, which was not updated, was entirely unaffected throughout.

---

## 2. Incident Timeline

| Time (2026-08-06) | Event |
|---|---|
| 02:00 | Overnight image update applied to POOL-FIN-01. POOL-FIN-02 not included in update. |
| 02:03:11 | POOL-FIN-01 hosts rebooted into updated image (confirmed via Event 1, Kernel-General on SHFIN-01-A). |
| 07:00 (approx.) | First user reports of black screen on POOL-FIN-01 begin. |
| 07:02:10 | Event 21 (TerminalServices-LocalSessionManager): logon succeeded for FINBRIDGE\mlopez on SHFIN-01-A. |
| 07:02:14 | Event 1 (Kernel-General): host boot time 02:03:11 confirmed – post-update reboot state on affected host. |
| 07:02:16 | Event 1000 (Application Error): dwm.exe faults in igdumd64.dll, exception 0xc0000005 on SHFIN-01-A. |
| 07:02:17 | Event 40 (TerminalServices-LocalSessionManager): session disconnected for mlopez. |
| 07:02:18 | Event 9009 (Desktop Window Manager): DWM exited with code 0x40010004. |
| 07:02:44 | Event 21: reconnect logon succeeded for mlopez. |
| 07:02:46 | Event 1000: repeat dwm.exe crash in igdumd64.dll. |
| 07:02:47 | Event 40: repeat disconnect. |
| 07:03:01 | Event 9009: repeat DWM exit. |
| 07:03:10 | Event 21: second reconnect logon succeeded for mlopez. |
| 07:08:22 | Event 21: logon succeeded for FINBRIDGE\akapoor on SHFIN-01-A. |
| 07:08:24 | Event 1000: identical dwm.exe + igdumd64.dll crash signature for akapoor. |
| 07:01:44 | (Comparison) Event 21 on SHFIN-02-A (POOL-FIN-02): session logon succeeded, no issues. |
| 07:01:46 | (Comparison) Event 9011 (Desktop Window Manager) on SHFIN-02-A: DWM started successfully. No Event 1000 in observation window. |
| ~07:15–08:00 | Triage completed; image regression and driver fault confirmed as root cause. Affected POOL-FIN-01 hosts placed in drain mode; new sessions directed to POOL-FIN-02. |
| ~08:00–09:30 | Graphics driver downgraded/replaced on POOL-FIN-01 image. Canary host built from corrected image and validated with repeated multi-user login tests. |
| ~09:30–10:00 | Corrected image rolled out to remaining POOL-FIN-01 hosts in staged batches. Pilot monitoring confirmed no recurrence. |
| 10:00 | Incident declared resolved. Users logging into POOL-FIN-01 successfully; no further reports of black screen. |

---

## 3. Scope and Impact

| Attribute | Detail |
|---|---|
| Affected pool | POOL-FIN-01 |
| Unaffected pool | POOL-FIN-02 |
| User impact | ~40% of POOL-FIN-01 users; black screen post-login, recurring disconnect loop |
| Business impact | Finance team access disrupted from 07:00 to 10:00 (3 hours) |
| Confirmed affected hosts | SHFIN-01-A (and others on POOL-FIN-01 updated image) |
| Confirmed unaffected hosts | SHFIN-02-A (POOL-FIN-02 – no update applied) |
| Duration | Approximately 3 hours (07:00 – 10:00) |

---

## 4. Supporting Evidence

### 4.1 Event Log Evidence – Affected Host (SHFIN-01-A, POOL-FIN-01)

| Timestamp | Source | Event ID | Description |
|---|---|---|---|
| 07:02:10 | TerminalServices-LocalSessionManager | 21 | Logon succeeded – FINBRIDGE\mlopez |
| 07:02:14 | Kernel-General | 1 | Host boot time 02:03:11 (post-image-update reboot) |
| 07:02:16 | Application Error | 1000 | dwm.exe faulting module: igdumd64.dll – exception 0xc0000005 |
| 07:02:17 | TerminalServices-LocalSessionManager | 40 | Session disconnected – mlopez |
| 07:02:18 | Desktop Window Manager | 9009 | DWM exited with code 0x40010004 |
| 07:02:44 | TerminalServices-LocalSessionManager | 21 | Reconnect logon succeeded – mlopez |
| 07:02:46 | Application Error | 1000 | Repeat dwm.exe crash in igdumd64.dll |
| 07:02:47 | TerminalServices-LocalSessionManager | 40 | Repeat disconnect – mlopez |
| 07:03:01 | Desktop Window Manager | 9009 | Repeat DWM exit |
| 07:03:10 | TerminalServices-LocalSessionManager | 21 | Second reconnect succeeded – mlopez |
| 07:08:22 | TerminalServices-LocalSessionManager | 21 | Logon succeeded – FINBRIDGE\akapoor |
| 07:08:24 | Application Error | 1000 | Same dwm.exe + igdumd64.dll crash – akapoor |

**Key observations:**
- The crash sequence (Event 1000 → Event 40 → Event 9009) is repeatable and consistent across multiple users and sessions.
- The identical faulting module (igdumd64.dll) across both mlopez and akapoor confirms a host-level regression, not a user-specific profile issue.
- The crash occurs within 2–6 seconds of logon, pointing to DWM initialisation failure at session start.

### 4.2 Event Log Evidence – Comparison Host (SHFIN-02-A, POOL-FIN-02)

| Timestamp | Source | Event ID | Description |
|---|---|---|---|
| 07:01:44 | TerminalServices-LocalSessionManager | 21 | Logon succeeded – no issues |
| 07:01:46 | Desktop Window Manager | 9011 | DWM started successfully |
| (none) | Application Error | 1000 | No entries in the observation window |

**Key observations:**
- DWM started cleanly (Event 9011) on POOL-FIN-02 with no crash or disconnect.
- The absence of any Event 1000 on the unaffected pool directly contrasts with the crash loop on POOL-FIN-01.
- POOL-FIN-02 was not updated overnight, isolating the image update as the differentiating variable.

### 4.3 Hypothesis Elimination Summary

| Hypothesis | Verdict | Basis |
|---|---|---|
| Image regression in logon path (shell/profile/GPO) | **Supported** | Post-update boot confirmed; repeatable post-logon failure on updated hosts only |
| Display/graphics driver regression in updated image | **Confirmed root cause** | Repeated Event 1000 (igdumd64.dll) + Event 9009 across users; clean DWM start on unaffected pool |
| Broken shell extension or startup application | **Eliminated** | Crash signature is compositor/driver, not shell or startup component |
| Startup script, GPO, or logon extension regression | **Eliminated** | Logon succeeds (Event 21); crash occurs in DWM compositor phase, not policy/script phase |
| Profile or container mount delay/failure | **Eliminated** | Cross-user identical crash signature rules out user-state cause |

---

## 5. Root Cause

The overnight image update to POOL-FIN-01 introduced an incompatible or defective version of the Intel graphics driver component **igdumd64.dll**. On session initialisation, DWM (Desktop Window Manager) loaded this driver and immediately faulted with a memory access violation (exception `0xc0000005`). DWM exited (Event 9009), causing the user's session to disconnect (Event 40) within seconds of a successful logon (Event 21). This crash-reconnect loop produced the observed black screen experience. Because POOL-FIN-02 was not updated, its hosts carried the prior known-good driver version and DWM started cleanly on every session.

---

## 6. Five Whys Analysis

| Why | Question | Answer |
|---|---|---|
| **Why 1** | Why did users on POOL-FIN-01 see a black screen and get disconnected after login? | DWM crashed immediately after session logon because igdumd64.dll threw a memory access violation (0xc0000005). |
| **Why 2** | Why did igdumd64.dll crash DWM on POOL-FIN-01 but not on POOL-FIN-02? | POOL-FIN-01 received an overnight image update that introduced a new (incompatible or defective) version of the Intel graphics driver; POOL-FIN-02 was not updated and retained the prior working driver version. |
| **Why 3** | Why did an incompatible graphics driver get included in the updated image? | The image build process incorporated an Intel graphics driver update without verifying compatibility against the AVD host configuration, GPU virtualisation layer, and existing DWM behaviour. |
| **Why 4** | Why was driver compatibility not verified before the image was deployed to production? | The image validation and testing pipeline did not include a mandatory post-login DWM stability check or graphics driver smoke test against a representative AVD session workload. |
| **Why 5** | Why did the image validation pipeline lack a DWM/graphics driver smoke test? | There was no documented requirement to test compositor stability as part of image acceptance criteria; AVD-specific logon path validation (including DWM initialisation) was not defined in the image release checklist. |

**Root cause (5 Whys conclusion):** The absence of AVD-specific graphics and DWM validation in the image acceptance and release process allowed a defective Intel graphics driver to reach production, causing DWM to crash on every session initialisation on the updated pool.

---

## 7. Resolution Applied

1. **Containment:** Affected POOL-FIN-01 hosts placed in drain mode; all new sessions redirected to POOL-FIN-02 to eliminate user impact while remediation was performed.
2. **Driver identification:** The faulty igdumd64.dll version was confirmed on affected hosts by matching Event 1000 crash records to the driver file version in the updated image.
3. **Fix:** A lab clone of the failing image was created. The Intel graphics driver tied to igdumd64.dll was downgraded to the last known-good version. The corrected driver version was pinned to prevent automatic drift.
4. **Canary validation:** One POOL-FIN-01 host was rebuilt from the corrected image and subjected to repeated multi-user login and reconnect tests. No Event 1000, 9009, or 40 recurrence observed.
5. **Staged rollout:** The corrected image was promoted to remaining POOL-FIN-01 hosts in batches, with monitoring at each stage.
6. **Verification:** At 10:00 all POOL-FIN-01 hosts confirmed healthy. Users logging in successfully with no black screen or disconnect loop reported.
7. **Evidence retained:** Suspect image artefacts and event logs from affected hosts retained for review and RCA closure.

**Closure criteria met:**
- No post-logon disconnect loop after successful Event 21 logons.
- No new Event 1000 for dwm.exe in igdumd64.dll.
- No new Event 9009 DWM exits.
- No recurring Event 40 disconnect loop.
- User-reported black screen behaviour returned to baseline.

---

## 8. Preventive Actions

| # | Action | Owner | Priority | Target |
|---|---|---|---|---|
| 1 | **Add DWM stability to image acceptance criteria.** Add a mandatory post-login DWM initialisation check (confirm Event 9011, absence of Event 1000 for dwm.exe, absence of Event 9009) to the image release checklist. | Image Engineering | High | Before next image release |
| 2 | **Implement AVD session smoke test in the image pipeline.** Automate a post-build AVD session test that performs a real login on a candidate host, captures logon-phase events, and fails the build if any DWM crash signature is detected. | DevOps / Image Pipeline | High | Within 2 sprints |
| 3 | **Enforce staged pool rollout with canary gate.** Formalise policy that image updates are applied to one canary host per pool at least 2 hours before full pool deployment. Full rollout is blocked unless canary passes a defined stability window (no DWM/session errors in 30 minutes under real or simulated load). | Change Management | High | Within 1 sprint |
| 4 | **Pin graphics driver versions in image builds.** Maintain an explicit approved-versions list for all graphics driver components (including igdumd64.dll) used in AVD images. Automatically block any driver version not on the approved list from entering the build. | Image Engineering | Medium | Within 2 sprints |
| 5 | **Separate pool update schedules.** Enforce a policy that equivalent pools (e.g., POOL-FIN-01 and POOL-FIN-02) are never updated in the same maintenance window. The second pool is only updated after the first has been confirmed stable under real load for a minimum observation period. | Change Management | High | Immediate – update change process |
| 6 | **Add AVD-specific alert for DWM crash loop.** Create a monitoring alert that fires when three or more Event 1000 (dwm.exe) entries occur within a 5-minute window on any AVD host, triggering immediate triage. | Monitoring / Operations | Medium | Within 2 sprints |
| 7 | **Document graphics driver validation in AVD image runbook.** Update the AVD image build and release runbook to include Intel/GPU driver compatibility verification steps, DWM test procedure, and rollback process for driver-related regressions. | IT Operations | Medium | Within 1 sprint |
| 8 | **Post-deployment monitoring window.** Mandate a minimum 60-minute active monitoring window after every production image deployment, covering logon success rates, DWM event counts, and session disconnect rates before closing the change. | Change Management | Medium | Immediate – update change process |

---

## 9. Lessons Learned

- **Pool isolation is a detection asset.** Having POOL-FIN-02 unaffected immediately narrowed the cause to the image change and accelerated triage. Maintaining distinct pools with staggered updates should be a standard practice.
- **Event 1000 (dwm.exe) + Event 9009 is a reliable black-screen discriminator.** This event pair, appearing within seconds of Event 21, uniquely identifies a DWM/graphics crash as opposed to profile, policy, or network causes.
- **Image regressions need compositor validation.** Standard OS-level acceptance tests do not catch AVD-specific DWM or graphics driver regressions. AVD image validation must include a real-session logon test.
- **Driver updates carry outsized risk in virtualised GPU environments.** Even minor Intel graphics driver version changes can break the virtualisation layer. These must be treated as high-risk changes with explicit compatibility confirmation.

---

## 10. Document References

- Triage summary: `Day4/triage-summary-avd-black-screen-pool-fin-01.md`
- Affected host event evidence: SHFIN-01-A event logs (2026-08-06 07:00–07:30)
- Comparison host evidence: SHFIN-02-A event logs (2026-08-06 07:00–07:30)
- Faulting component: igdumd64.dll (Intel graphics driver, version deployed in overnight update)
- Event IDs referenced: 21, 40, 1000, 9009, 9011 (sources: TerminalServices-LocalSessionManager, Application Error, Desktop Window Manager, Kernel-General)
