# Triage Summary - INC-C Floor 6 Missing Desktop Shortcuts

Date raised: 2026-08-14
Source: Floor 6 Monday escalation
Incident ID: INC-C (Endpoint User Environment Track)
Prepared for: Endpoint Engineering, Service Desk L2

## Incident Statement
At least one Floor 6 user reports missing desktop shortcuts after Monday login during the same incident window as login slowness.

## Business Impact
- Immediate usability friction and reduced user productivity.
- Lower enterprise risk than SEC-B and OPS-A, but high user-visible disruption.

## First 30 Minutes Triage Plan

### 0-10 minutes: Confirm symptom type
1. Determine whether shortcuts are actually deleted, hidden, or profile-path inaccessible.
2. Check User Desktop and Public Desktop path presence.
3. Check whether affected session loaded temporary profile.

Why:
- Avoids wrong fix path and quickly identifies profile vs shell causes.

### 10-20 minutes: Correlate with Floor 6 change window
1. Compare affected endpoint with control endpoint.
2. Check post-install actions or cleanup tasks from Friday deployment.
3. Check shell and profile event signals around login.

Why:
- Tests whether shortcut loss is a side effect of same change causing login degradation.

### 20-30 minutes: Safe restoration and containment
1. Provide short-term access workaround via Start menu/search.
2. Restore expected shortcut baseline for pilot users if path is healthy.
3. Document restoration success and recurrence after reboot.

Why:
- Restores user function while root cause remains under investigation.

## Likely Causes Ranked
1. Profile-load or shell-init regression linked to Friday change
2. Desktop path redirection or permissions mismatch
3. Cleanup/post-install script removed links unintentionally
4. User-specific profile corruption

## Evidence Required
1. Desktop path state and link inventory (before/after)
2. Profile service and shell-related events
3. Deployment timeline correlation
4. Comparison with unaffected control endpoint

## Immediate Actions
1. Keep this track linked to OPS-A timeline but managed separately.
2. Run structured evidence script and shortcut restoration only on pilot first.
3. Expand restoration in waves if stable.

## Escalation Triggers
- If shortcut loss recurs after restoration and reboot: escalate to profile engineering.
- If deletion pattern maps to deployment action: escalate to change owner and halt assignment.

## Current Recommended Status
Active endpoint incident with pilot restoration and evidence correlation to OPS-A.
