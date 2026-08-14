# Triage Summary — Floor 6 Multi-Issue Incident (Monday Morning)

**Date raised:** 2026-08-14  
**Source:** Slack escalation from Floor 6  
**Prepared for:** Service desk lead, endpoint engineering, security/privacy, partners briefing

---

## Executive Summary (Non-Technical)
Three separate issues are mixed together in one message and must be handled on different tracks:

1. **Potential data exposure incident:** A Copilot response appears to have surfaced a client matter the user believes they should not see.
2. **Access/Performance incident:** Many users cannot log in or logins are extremely slow.
3. **User environment regression:** Desktop shortcuts have disappeared for at least one user.

The most likely shared trigger for #1 and #3 is the **new document management app deployed Friday afternoon to Floor 6**, but this must be proven with evidence. The Copilot item (#2) is **not a normal troubleshooting ticket**; it is a potential privacy/security incident requiring immediate formal escalation.

---

## Triage — First 30 Minutes

### 0-5 minutes: Split the incident and assign owners
Create three child incidents immediately:

- **INC-A:** Floor 6 logon failures/extreme slowness (Major Incident track)
- **INC-B:** Potential unauthorized data exposure via Copilot (Security/Privacy Incident track)
- **INC-C:** Missing desktop shortcuts after changes (Endpoint/User Environment track)

Why first: one Slack message currently mixes risks with different urgency, controls, and communications duties.

### 5-10 minutes: Handle highest-risk item first (INC-B)
First checks and why:

1. **Preserve evidence from reporter:** exact prompt used, exact Copilot response, timestamp, app/context where shown.
   - Why: chain-of-custody and reproducibility are required for incident response.
2. **Confirm user identity and entitled matter list through approved internal records (do not use public AI with real case data).**
   - Why: quickly determine if this was actual unauthorized disclosure vs misunderstanding of matter naming.
3. **Open Security/Privacy incident and engage legal/compliance liaison immediately.**
   - Why: charter requires immediate incident route for any possible exposure.

### 10-20 minutes: Stabilize business impact (INC-A)
First checks and why:

1. **Scope blast radius by floor and building:** count affected users, device models, and whether issue is only Floor 6.
   - Why: validates whether this is localized to the Friday deployment scope.
2. **Time-correlation check:** compare first-failure times Monday to deployment completion window Friday.
   - Why: strongest fast signal for change-related regression.
3. **Known-good comparison:** test one unaffected floor/device versus one affected Floor 6 device.
   - Why: isolates environment delta quickly.
4. **Quick rollback readiness check for the new app policy/package.**
   - Why: if evidence points to deployment, controlled rollback can restore service fastest.

### 20-30 minutes: Parallel containment for user environment issue (INC-C)
First checks and why:

1. **Confirm profile state:** temporary profile load, shell policy changes, or redirected desktop path.
   - Why: these are common reasons shortcuts appear missing while files may still exist.
2. **Check app deployment side effects:** file association/shortcut cleanup scripts, post-install actions, or profile migration behavior.
   - Why: same change window and same floor imply possible causal link.
3. **Recover user productivity quickly:** provide alternate launch path (Start menu/search) and restore shortcuts from known template if safe.
   - Why: low-risk immediate mitigation while root cause continues.

---

## The Copilot Incident — Correct Handling
This is a **potential unauthorized information disclosure** and must be treated as a **security/privacy incident**, not a routine support defect.

### What not to do
- Do not close as "AI weirdness" or "user confusion" without formal review.
- Do not ask users to paste real client matter details into public AI tools.
- Do not continue broad troubleshooting before evidence is preserved.

### Two-sentence escalation (use as-is)
"We have a potential unauthorized data exposure event: a Floor 6 user reports Copilot displayed a client matter they believe they are not entitled to access. Please open a Security/Privacy incident immediately, preserve prompt/response evidence and timestamps, and initiate entitlement and access-path validation with Legal/Compliance oversight."

---

## Security-Risk Re-Ranking (All Incident Tracks)

1. **INC-B (Copilot potential data exposure): Critical priority**
   - Rationale: possible confidentiality and regulatory impact; requires immediate security/legal governance.
2. **INC-A (login failures/extreme slowness): High priority**
   - Rationale: broad operational productivity impact and service continuity risk.
3. **INC-C (missing desktop shortcuts): Medium priority**
   - Rationale: user experience and productivity degradation, typically lower enterprise risk than data exposure and access outage.

This ranking is by **security and business risk**, not by change chronology. Friday deployment remains a testable hypothesis, not an assumed root cause.

---

## Ranked Differential — Login/Performance Problem (Most Likely to Least)

### 1) Change-induced regression from Friday document management app deployment
Why likely:
- Exact floor-targeted deployment
- Symptoms appeared next business day
- Includes both logon delay and environment anomalies (shortcuts)

Fastest check:
- Compare install status + app version + deployment assignment on affected vs unaffected devices.

Evidence confirming:
- Strong correlation: most affected devices show deployment success shortly before first issue.
- Pilot rollback/uninstall on a sample device restores normal login/performance.
- Reproducible degradation when app/policy reapplied.

Evidence ruling out:
- Affected users include many devices with no deployment.
- Performance remains bad after controlled uninstall/rollback on test set.

### 2) Login stack contention caused by new startup hooks (shell extensions, sync, or credential provider interactions)
Why likely:
- "Can’t log in or takes forever" suggests Winlogon/User Profile Service/startup serialization pressure.

Fastest check:
- Measure sign-in phase durations on affected devices and compare to baseline; inspect startup items/services introduced by deployment.

Evidence confirming:
- Delays cluster in profile load/shell init and coincide with new service/extension startup.

Evidence ruling out:
- Sign-in phases normal but delays occur only in downstream network operations.

### 3) Identity or policy processing regression scoped to Floor 6 OU/group targeting
Why plausible:
- Floor-scoped targeting may include GPO/Intune assignment differences.

Fastest check:
- Compare policy/resultant set between affected Floor 6 and unaffected adjacent floor.

Evidence confirming:
- Recent policy assignment change aligned to Floor 6 and onset time.

Evidence ruling out:
- No meaningful policy delta; unaffected devices have same policy set.

### 4) Shared infrastructure degradation (DC/auth path, network segment, VDI broker, storage profile backend)
Why plausible:
- "Dozen users" could indicate underlying platform issue, not endpoint-only.

Fastest check:
- Check central service health and auth latency for the same time window.

Evidence confirming:
- Cross-floor or multi-app auth slowness and correlated backend alerts.

Evidence ruling out:
- Health normal elsewhere and impact tightly bound to deployed cohort.

### 5) User profile corruption affecting subset of machines/users
Why plausible:
- Missing shortcuts can be profile-level, but scale suggests this is less likely as primary cause.

Fastest check:
- Test fresh profile/new user login on an affected machine.

Evidence confirming:
- Fresh profile works quickly while existing profile remains slow/broken.

Evidence ruling out:
- Fresh profiles equally slow across many machines.

---

## Evidence Plan (No Logs Provided Yet)
Collect in this order to balance speed and risk:

1. **Security evidence package (Copilot incident):** prompt/response screenshot or transcript, timestamp, session context, reporter statement.
2. **Entitlement evidence:** Microsoft 365 permissions, group membership, and access-path validation data.
3. **Affected-user matrix:** user, device, floor, symptom class, first-seen time.
4. **Change correlation sheet:** deployment assignment, install timestamp, app version, reboot status.
5. **Authentication timeline:** sign-in start, desktop ready time, first app usable time.
6. **Comparison baseline:** at least two unaffected users/devices from non-Floor 6.

Note: Per charter, do not place real user identifiers, client matter details, hostnames, tokens, or raw incident artifacts into public AI prompts.

---

## Immediate Actions (Now)

1. Open Security/Privacy incident for Copilot report with legal/compliance visibility and preserve evidence immediately.
2. Trigger major incident bridge for Floor 6 login/performance and assign incident commander.
3. Freeze further rollout of the document management app to additional groups.
4. Start controlled rollback test on 2-3 affected devices while collecting timing evidence.
5. Send floor-level user advisory: issue acknowledged, workaround path, next update time.

---

## Partner Update by Lunch (Suggested Plain-Language Message)
"We are handling three separate issues: widespread login slowness on Floor 6, a potential Copilot data-access concern, and missing desktop shortcuts for some users. We have paused further app rollout, started targeted rollback and evidence collection on affected machines, and opened a formal security/privacy incident for the Copilot report; next update will include confirmed cause, containment status, and recovery timeline."
