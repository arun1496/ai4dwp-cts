# Triage Summary - INC-A Floor 6 Login and Performance

Date raised: 2026-08-14
Source: Floor 6 Monday escalation
Incident ID: INC-A (OPS Major Incident Track)
Prepared for: Service Desk Lead, Endpoint Engineering, Major Incident Manager

## Incident Statement
Multiple Floor 6 users report login failure or severe login delay Monday morning after a Friday floor-targeted document management app deployment.

## Business Impact
- Users cannot start work on time.
- Productivity impact across a legal floor cohort.
- Risk of missed legal timelines if unresolved.

## First 30 Minutes Triage Plan

### 0-5 minutes: Scope and ownership
1. Assign incident commander and technical owner.
2. Build affected-user matrix: user, device, first-seen time, symptom type.
3. Confirm whether impact is Floor 6 only or cross-floor.

Why:
- Confirms blast radius and whether this is change-local or platform-wide.

### 5-15 minutes: Fastest high-value checks
1. Compare one affected device to one unaffected control device.
2. Correlate symptom onset with Friday deployment completion time.
3. Verify app install state, version, and assignment status for affected devices.
4. Check sign-in and profile event signals in incident window.

Why:
- Gives fastest confirm/rule-out path for top-ranked cause (change-induced regression).

### 15-30 minutes: Containment and pilot remediation
1. Freeze further deployment expansion.
2. Start controlled rollback pilot on 2-3 affected devices.
3. Capture before/after login timings and desktop readiness.
4. Prepare wave expansion only if pilot improves without side effects.

Why:
- Restores service quickly while preserving evidence quality.

## Ranked Differential for INC-A
1. Friday app deployment regression (most likely)
2. Policy targeting overlap regression (Intune/Win11 assignments)
3. Identity/profile backend latency
4. Startup contention unrelated to deployment
5. Profile corruption as primary cause (least likely at this scale)

## Evidence Required
1. Deployment assignment and install timestamps
2. First-symptom timestamps by user/device
3. Sign-in/profile event data from affected vs control
4. Pilot rollback outcomes
5. Reproduction result on re-apply (pilot only)

## Immediate Actions
1. Keep rollout freeze active.
2. Continue evidence script collection on pilot set.
3. Execute ring rollback if pilot validates improvement.
4. Send floor update every 60-90 minutes.

## Escalation Triggers
- If cross-floor impact appears: escalate to infrastructure/authentication bridge.
- If rollback fails to improve pilot: pause wave expansion and re-rank hypotheses.

## Current Recommended Status
Active major incident with controlled rollback and evidence-led decision gates.
