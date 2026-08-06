# AVD Black Screen Triage Summary - POOL-FIN-01

## Scope Facts
- Symptom: black screen post-login; clears after about 30 seconds for some users, persists for others.
- Impact: about 40% of users on POOL-FIN-01.
- POOL-FIN-02 is completely unaffected.
- Since: around 07:00 this morning.
- Change: overnight image update to POOL-FIN-01 at 02:00.
- POOL-FIN-02 was not updated.

## Timing Clue Assessment
The strongest discriminator is the overnight image update that only affected POOL-FIN-01. That makes an image-borne regression in the updated pool the most consistent explanation. The fact that POOL-FIN-02 was not updated and has no impact weighs heavily against tenant-wide, shared-service, or environment-wide causes.

## Ranked Likely Causes
1. Image regression in the POOL-FIN-01 logon path, especially shell start, profile load, or GPO processing.
   - Why it fits: It directly matches the only change that happened on the affected pool and explains why the issue is isolated to POOL-FIN-01.
   - Fastest check: Compare an affected POOL-FIN-01 host against POOL-FIN-02 for image version and logon timing events.

2. Display or graphics driver issue introduced by the new image.
   - Why it fits: Black screen after login is a common graphics-hand-off symptom and remains strongly pool-specific.
   - Fastest check: Compare GPU/display driver versions and test a non-accelerated session on one affected host.

3. Broken shell extension or user-startup application in the updated image.
   - Why it fits: A bad component in the new image would only affect POOL-FIN-01 and could cause delayed desktop rendering.
   - Fastest check: Review Explorer and shell startup failures, or test with nonessential startup items disabled.

4. Startup script, GPO, or logon extension regression introduced with the image.
   - Why it fits: If the update changed policy application or logon behavior, the issue would remain confined to the updated pool.
   - Fastest check: Compare applied GPOs and script execution results between POOL-FIN-01 and POOL-FIN-02.

5. Profile or container mount delay/failure for a subset of users.
   - Why it fits: This aligns with the 40% user split, but it is weaker against the timing clue unless the image changed the profile path or mount behavior.
   - Fastest check: Inspect profile/container attach logs for affected and unaffected users on POOL-FIN-01.

## Provisional Hypothesis
The leading hypothesis is an image-related regression in the POOL-FIN-01 logon path. Do not commit to a single root cause yet; use the fastest discriminator first to confirm whether the regression is in shell launch, graphics initialization, or user-state/profile handling.

## Addendum: Event Evidence Analysis (2024-03-15 07:00-07:30)

### Evidence Snapshot
- Affected host: SHFIN-01-A (POOL-FIN-01)
  - 07:02:10 Event 21 (TerminalServices-LocalSessionManager): session logon succeeded for FINBRIDGE\mlopez.
  - 07:02:14 Event 1 (Kernel-General): host boot time 02:03:11 after overnight image update.
  - 07:02:16 Event 1000 (Application Error): dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
  - 07:02:17 Event 40 (TerminalServices-LocalSessionManager): session disconnected.
  - 07:02:18 Event 9009 (Desktop Window Manager): DWM exited with code 0x40010004.
  - 07:02:44 Event 21: reconnect logon succeeded.
  - 07:02:46 Event 1000: repeat dwm.exe crash in igdumd64.dll.
  - 07:02:47 Event 40: repeat disconnect.
  - 07:03:01 Event 9009: repeat DWM exit.
  - 07:03:10 Event 21: second reconnect succeeded.
  - 07:08:22 Event 21: logon succeeded for FINBRIDGE\akapoor.
  - 07:08:24 Event 1000: same dwm.exe + igdumd64.dll crash signature.
- Comparison host: SHFIN-02-A (POOL-FIN-02, unaffected)
  - 07:01:44 Event 21: session logon succeeded.
  - 07:01:46 Event 9011 (Desktop Window Manager): DWM started successfully.
  - No Application Error Event 1000 entries in the same window.

### Evidence-to-Hypothesis Mapping
1. Image regression in POOL-FIN-01 logon path (shell/profile/GPO)
   - Judgement: Support
   - Determining events:
     - 07:02:14 Event 1 confirms post-update reboot state on affected host.
     - 07:02:10 Event 21 followed by 07:02:16 Event 1000 and 07:02:17 Event 40 indicates repeatable post-logon failure on updated host.

2. Display or graphics driver issue introduced by the new image
   - Judgement: Support
   - Determining events:
     - 07:02:16, 07:02:46, 07:08:24 Event 1000: dwm.exe faulting in igdumd64.dll.
     - 07:02:18 and 07:03:01 Event 9009: DWM exited after crash.
     - 07:01:46 Event 9011 on unaffected SHFIN-02-A plus no Event 1000 in that window.

3. Broken shell extension or user-startup application in updated image
   - Judgement: Contradicts
   - Determining events:
     - Repeated graphics stack crash signature in Event 1000 (07:02:16, 07:02:46, 07:08:24) and DWM exits in Event 9009 (07:02:18, 07:03:01) outweigh shell-extension/startup-app pattern.

4. Startup script, GPO, or logon extension regression introduced with image
   - Judgement: Contradicts
   - Determining events:
     - Event 21 logon success at 07:02:10 and 07:02:44 followed by immediate Event 1000/9009 crash sequence and Event 40 disconnect points to compositor/driver failure rather than script-policy execution failure.

5. Profile or container mount delay/failure for a subset of users
   - Judgement: Contradicts
   - Determining events:
     - Cross-user identical crash signature (mlopez and akapoor) in Event 1000 at 07:02:16, 07:02:46, and 07:08:24 with matching disconnect sequence (Event 40 at 07:02:17 and 07:02:47).

### Surviving Hypotheses After Event Elimination
1. Image regression in the updated POOL-FIN-01 logon path.
2. Display/graphics driver regression in that image (DWM crashing in igdumd64.dll).

## Addendum: Resolution Against Surviving Hypotheses

### Hypothesis 1: Image Regression In The Updated POOL-FIN-01 Logon Path
1. Contain impact by putting affected POOL-FIN-01 hosts in drain mode and directing new sessions to POOL-FIN-02.
2. Confirm scope by matching affected hosts to the post-02:00 image lineage and unaffected hosts to the pre-update lineage.
3. Build one canary host from the last known-good image version and run repeated login/reconnect tests.
4. If canary is stable, replace remaining affected hosts in staged batches from the known-good image.
5. Keep suspect hosts quarantined for evidence retention and rollback confidence.
6. Exit criteria for this hypothesis:
   - Black-screen behavior returns to baseline.
   - No post-logon disconnect loop after successful Event 21 logons.

### Hypothesis 2: Display/Graphics Driver Regression In Updated Image
1. Validate the driver fault signature on affected hosts:
   - Event 1000 dwm.exe faulting module igdumd64.dll
   - Event 9009 DWM exited
   - Event 40 disconnects after logon
2. Create a lab clone of the failing image and downgrade/replace the Intel graphics driver tied to igdumd64.dll.
3. Pin the known-good graphics driver version to prevent automatic drift during pilot.
4. Apply temporary conservative session graphics settings during testing.
5. Execute repeated multi-user login/reconnect validation on pilot hosts.
6. Promote to production in phases only if all pass criteria hold:
   - No new Event 1000 for dwm.exe in igdumd64.dll
   - No new Event 9009 DWM exits
   - No recurring Event 40 disconnect loop

### Common Validation And Closure
1. Monitor pilot and then full rollout for at least 30-60 minutes under real user load.
2. Capture before/after event evidence and user-impact metrics.
3. Publish final RCA with image version, driver version, and rollout guardrails.
