# RCA Investigation Report: Floor 6 Multi-Issue Event (2026-08-14)

## Incident Summary
- Incident set: Floor 6 Monday escalation with mixed security and operational symptoms
- Source notes reviewed: triage summary and executive hypothesis assessment
- Tracks investigated:
  - SEC-B: Potential unauthorized data exposure via Copilot
  - OPS-A: Login failures or extreme sign-in slowness for multiple users
  - OPS-C: Missing desktop shortcuts or degraded shell state

## Investigation Inputs and Scope
- Reviewed investigation notes from:
  - Project triage summary
  - Project executive incident hypothesis assessment
- Constraints:
  - No raw security or endpoint telemetry artifacts were attached to this file set
  - Findings below identify current most likely causes and closure evidence required

## Reconstructed Event Timeline (Plain English)
1. Friday afternoon: Floor 6 receives a new document management app deployment (change event).
2. Monday morning: Floor 6 reports broad sign-in failures or severe delay symptoms (OPS-A).
3. Monday morning: At least one user reports missing desktop shortcuts after login (OPS-C).
4. Monday morning: A user reports Copilot surfaced a client matter believed to be outside entitlement (SEC-B).
5. Initial triage splits the single escalation into SEC and OPS tracks to avoid risk mixing.
6. Security-first handling is initiated for Copilot evidence preservation and entitlement validation.

## What the Current Evidence Means
- A single message contained three distinct incident classes; this is a coordination risk, not proof of a single technical cause.
- Time correlation to the Friday deployment is meaningful for OPS-A and OPS-C and weak for SEC-B until access-path proof exists.
- The Copilot allegation is high risk but currently unproven; it must remain an active security incident until entitlement and data lineage checks complete.

## Track-Level Root Cause Assessments

### SEC-B: Potential unauthorized data exposure via Copilot
Most likely current cause: unresolved entitlement or retrieval-path mismatch scenario, pending formal verification.

Evidence supporting this current cause position:
1. User-reported symptom explicitly claims access to matter data believed out-of-scope.
2. Triage appropriately requires prompt-response preservation and entitlement verification before closure.
3. No confirmed artifact yet proves either true unauthorized disclosure or false alarm.

Evidence required to confirm root cause:
1. Preserved prompt and exact Copilot response with timestamp and app context.
2. User entitlement state at event time (groups, permissions, token claims).
3. Source-path lineage for returned content.

RCA statement (current): Security root cause remains unconfirmed; the working root-cause candidate is entitlement or retrieval-path mismatch until disproven with auditable evidence.

Confidence and limitations:
- Confidence: Medium for risk classification, Low-Medium for technical root trigger.
- Limitation: No security evidence package is embedded in current notes.

### OPS-A: Floor 6 login failures and extreme slowness
Most likely root cause: change-correlated endpoint sign-in degradation from Friday floor-targeted deployment and or overlapping policy processing.

Evidence supporting this cause:
1. Floor-scoped symptoms align to floor-scoped change window.
2. Reported behavior includes login delay pattern consistent with startup, profile, or policy-phase contention.
3. Triage and hypothesis documents both rank deployment and policy overlap as top operational candidates.

RCA statement (current): OPS-A is most likely driven by a change-correlated sign-in processing regression in the Floor 6 cohort, with deployment and targeting-policy overlap as the primary technical branch.

Confidence and limitations:
- Confidence: Medium.
- Limitation: No sign-in phase timings, Intune assignment deltas, or backend auth latency logs are attached yet.

### OPS-C: Missing desktop shortcuts
Most likely root cause: user-shell or profile-state regression linked to the same Monday onset and change window as OPS-A.

Evidence supporting this cause:
1. Missing shortcuts are a known output of profile-load or shell-initialization failures.
2. Symptom onset is co-timed with broader login degradation reports.
3. Triage explicitly flags deployment side effects and profile state as primary checks.

RCA statement (current): OPS-C is most likely a secondary manifestation of the same operational change domain affecting OPS-A, rather than an isolated standalone failure.

Confidence and limitations:
- Confidence: Medium.
- Limitation: No profile-service event evidence or desktop path validation artifacts are attached.

## Cross-Incident Correlation Analysis

### Correlation Matrix
1. OPS-A <-> OPS-C: Strongly related
   - Shared cohort, shared timeframe, and compatible technical mechanisms (policy, profile, shell startup).
2. OPS-A <-> SEC-B: Possibly related but unproven
   - Common timing exists, but no verified causal path from sign-in performance regression to unauthorized Copilot data exposure.
3. OPS-C <-> SEC-B: Weak relation
   - Co-occurrence in user reports only; no direct evidence that shortcut loss changes Copilot authorization behavior.

### Most Likely Shared Cause Cluster
- Shared cluster likely for OPS incidents: Friday floor-targeted change set (app deployment and or policy targeting interaction).
- SEC incident remains an independent high-risk track until entitlement and data lineage checks prove linkage or separation.

## Consolidated Root Cause Position
1. Confirmed root cause: None yet at forensic standard.
2. Most likely operational root cause cluster: Floor 6 change-correlated regression impacting sign-in and shell readiness.
3. Most likely security root-cause candidate: entitlement or retrieval-path mismatch, pending formal security evidence.

## Suggested Validation Steps to Close RCA
1. SEC-B: Complete entitlement and source-lineage audit for the preserved Copilot prompt-response artifact.
2. OPS-A: Compare sign-in phase metrics and policy deltas between affected Floor 6 devices and unaffected control cohort.
3. OPS-A/OPS-C: Run controlled rollback on a small affected sample and measure login and desktop restoration before and after.
4. OPS-C: Validate profile load state, desktop redirection paths, and shell-init event sequence on impacted users.
5. Correlation closure: Decide whether SEC-B is independent or change-linked only after entitlement audit and timestamp-level cross-correlation.

## Required Reflection

Initial instinct:
The first instinct was to treat the Friday Floor 6 app deployment as the single root cause for all Monday symptoms, including the Copilot exposure concern.

Evidence checked:
- Incident-class separation in triage notes (SEC-B vs OPS-A/OPS-C).
- Symptom correlation across OPS tracks (login slowness and missing shortcuts) versus the weaker causal link to SEC-B.
- Security evidence requirements for SEC-B: preserved prompt/response artifact, entitlement state at event time, and source-path lineage.

What changed my mind:
The available evidence supported strong operational linkage between OPS-A and OPS-C, but did not provide a defensible technical chain that linked endpoint performance degradation to unauthorized Copilot data access. The Copilot allegation therefore remained a high-risk but unproven security event requiring separate governance.

Final learning:
Do not collapse mixed incidents into one narrative based on timing alone. Separate security exposure risk from operational outage signals early, then require track-specific evidence before declaring shared causality.

## 8) Final Incident Commander Recommendation

| Decision Area | Recommendation |
|---|---|
| Most likely operational root cause | Change-correlated sign-in and shell-readiness regression in the Floor 6 cohort, most likely from Friday app deployment and/or overlapping policy targeting. |
| Most likely security concern | Potential unauthorized information disclosure via Copilot caused by entitlement mismatch or retrieval-path mismatch; unconfirmed and still active. |
| Immediate decision required | Approve continued separation of SEC and OPS bridges, and authorize controlled OPS rollback expansion only if pilot evidence remains positive. |
| Recommended containment | Keep rollout freeze for additional cohorts, maintain SEC evidence hold, restrict incident access to need-to-know responders, and continue pilot-scoped remediation waves. |
| Recommended recovery path | Complete pilot rollback/remediation validation, expand in measured waves with verification gates, and restore desktop baseline for affected users before closure. |
| Recommended communication path | Use dual-track communication: non-technical productivity updates for users/partners and precise incident-language updates for security/legal stakeholders. |
| Open risks | Security exposure remains unresolved; partial OPS recovery could mask residual defects; token/permission drift may recur if identity-state root trigger is not confirmed. |
| Evidence still needed before final RCA | [SEC-INC-ID], preserved Copilot prompt/response artifact, Microsoft 365 entitlement snapshot at event time, source-content lineage audit, sign-in phase timings before/after remediation, Intune assignment delta, and affected-vs-control comparison matrix. |

### Communication Path Detail

| Audience | Message Style | Update Cadence | Owner |
|---|---|---|---|
| Floor 6 users | Plain-language service status, what to do now, next update time | Every 60-90 minutes during active remediation | Service Desk Major Incident Manager |
| Legal partners | Non-technical business-impact summary, restoration progress, expected stabilization window | Lunch update and end-of-day update, then as needed | Incident Commander |
| Security/Compliance/Legal review team | Precise security incident wording, evidence status, entitlement/path validation status, decision gates | At each material evidence milestone | Security and Compliance Incident Lead |

## Final RCA Statement (Current Revision)
This incident set contains one active security incident and two likely related operational incidents. The operational pair (login slowness and missing shortcuts) most likely shares a change-correlated root-cause cluster tied to Friday Floor 6 rollout conditions. The Copilot data-exposure allegation remains unconfirmed and must remain on a formal security/privacy track until entitlement and content-lineage evidence conclusively confirms or disproves unauthorized disclosure.
