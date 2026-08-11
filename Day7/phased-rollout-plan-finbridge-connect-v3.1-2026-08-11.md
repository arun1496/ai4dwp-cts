# Phased Intune Deployment Plan: FinBridge Connect v3.1

Scope: 10,000 Windows 11 endpoints, 3-week deadline, with Finance (500 users) required by end of Week 1.

## 1. RING STRUCTURE

### Ring design and schedule

- Total target: 10,000 endpoints
- At-risk hardware cohort: 500 endpoints (5%) with 4 GB RAM
- Deadline window: 3 weeks

Ring 1 (Pilot)
- Size: 300 endpoints total
  - 200 standard hardware endpoints across IT, Service Desk, and business power users
  - 100 endpoints from the 4 GB RAM at-risk cohort
- Duration: 3 full business days minimum (Day 1-Day 3)
- Who to include:
  - IT engineers and support users who can provide high-quality feedback quickly
  - A small sample of each major business unit
  - Explicit inclusion of 4 GB RAM devices for early validation
- Purpose:
  - Validate install command behavior, detection rule accuracy, and return-code mapping in production conditions
  - Identify regressions on low-spec hardware before wide release
- Intune assignment group type:
  - Microsoft Entra security device group (dynamic membership preferred)
  - Assignment type: Required for FinBridge Connect v3.1

Ring 2 (Early)
- Size: 2,200 endpoints total
  - Includes Finance 500 users
  - Includes remaining 400 endpoints from 4 GB RAM cohort, only if Ring 1 at-risk criteria pass
  - Remaining ~1,300 endpoints from mixed departments
- Duration: 5 business days minimum (Day 4-Day 8)
- Who to include:
  - Finance team (highest priority)
  - Operations teams with moderate business criticality
  - Broader sampling across geography/site/network segments
- Purpose:
  - Prove stability at meaningful scale
  - Confirm Finance outcomes before end of Week 1 requirement
  - Validate behavior under peak daily usage and support load
- Intune assignment group type:
  - Microsoft Entra security device group (dynamic membership by department + approved device filters)
  - Assignment type: Required for FinBridge Connect v3.1

Ring 3 (Broad)
- Size: 7,500 endpoints
- Duration: 7 business days (Day 9-Day 15) with 2 internal waves
  - Wave 3A: 3,500 endpoints (Day 9-Day 11)
  - Wave 3B: 4,000 endpoints (Day 12-Day 15)
- Who to include:
  - All remaining eligible Win11 endpoints not in prior rings
- Purpose:
  - Complete fleet deployment within 3-week SLA while preserving control points
- Intune assignment group type:
  - Microsoft Entra security device group (dynamic all eligible Win11 devices minus exclusions)
  - Assignment type: Required for FinBridge Connect v3.1

Recommended supporting groups to pre-create
- APP-FinBridge-v3.1-Ring1-Pilot
- APP-FinBridge-v3.1-Ring2-Early
- APP-FinBridge-v3.1-Ring3-Broad
- APP-FinBridge-v3.1-Hold
- APP-FinBridge-v3.1-Rollback
- APP-FinBridge-v3.0-Rollback-Required
- APP-FinBridge-4GB-AtRisk

## 2. ADVANCE CRITERIA

All criteria are evaluated from Intune app install status and monitored for the minimum period shown below. Ticket rate is measured from service desk incidents tagged FinBridge-v3.1 plus ring label.

### Ring 1 -> Ring 2 advance gate

- Install success rate: >= 98.0% on Ring 1 devices
- Error rate threshold: <= 2.0% failed status in Intune
- User-reported issue threshold: <= 1.5 tickets per 100 deployed users over monitoring period
- Monitoring period: minimum 24 hours after 90% of Ring 1 devices report Installed/Failed
- Time-bound decision: go/no-go must be made within 4 business hours after the monitoring period ends

### Ring 2 -> Ring 3 advance gate

- Install success rate: >= 97.0% on Ring 2 devices
- Error rate threshold: <= 3.0% failed status in Intune
- User-reported issue threshold: <= 2.0 tickets per 100 deployed users over monitoring period
- Monitoring period: minimum 48 hours after 90% of Ring 2 devices report Installed/Failed
- Time-bound decision: go/no-go must be made within 4 business hours after the monitoring period ends

### Hold condition (pause without full rollback)

Trigger to hold:
- Any single site, department, or hardware cohort has > 5.0% failed installs over any rolling 12-hour window, while global failure remains <= rollback trigger.

Action on hold:
- Pause progression to next ring.
- Move affected cohort to APP-FinBridge-v3.1-Hold (exclude from active rollout group), continue deployment in unaffected cohorts only after CAB duty engineer approval.

Specific example:
- Ring 2 overall failure is 2.2% (below rollback), but 4 GB RAM subgroup shows 8.0% failed installs in 12 hours. Result: isolate 4 GB cohort to Hold, continue standard hardware rollout with increased monitoring.

## 3. ROLLBACK TRIGGERS

All rollback triggers below are explicit halt conditions for further v3.1 expansion.

### Trigger A: Install failure rate automatic halt

- Trigger condition:
  - >= 7.0% Failed status in Intune for any active ring
  - Timeframe: sustained for 4 continuous hours after at least 200 devices in that ring have reported status
- Decision owner:
  - Incident Commander (EUC Engineering Lead) with Change Manager notified
- Decision window:
  - 2 business hours from trigger detection
- Exact Intune action:
  - Remove Required assignment for v3.1 from active and not-yet-started ring groups
  - Add affected devices to APP-FinBridge-v3.0-Rollback-Required
  - Assign FinBridge Connect v3.0 as Required to APP-FinBridge-v3.0-Rollback-Required
  - Assign FinBridge Connect v3.1 as Uninstall to APP-FinBridge-v3.1-Rollback for same device set

### Trigger B: Application crash rate rollback consideration

- Trigger condition:
  - >= 3.0 crashes per 100 active devices per 24 hours, or
  - >= 1.5% of active devices report 2 or more app crashes in 24 hours
- Timeframe:
  - Measured over any rolling 24-hour period during active rollout
- Decision owner:
  - EUC Engineering Lead + Application Owner (joint approval)
- Decision window:
  - 4 business hours from threshold breach
- Exact Intune action if rollback approved:
  - Freeze all new v3.1 Required assignments
  - Re-target affected ring devices to APP-FinBridge-v3.0-Rollback-Required
  - Keep unaffected ring groups in Hold until 24-hour stability review is complete

### Trigger C: Business-critical failure immediate rollback

- Trigger condition:
  - Finance users cannot complete payment release workflow in FinBridge Connect for 30 consecutive minutes during business hours due to v3.1 defect.
- Percentage dependency:
  - None. Immediate rollback regardless of affected percentage.
- Decision owner:
  - Major Incident Manager may declare immediate rollback; Engineering Lead executes
- Decision window:
  - Immediate, execution start within 30 minutes of incident declaration
- Exact Intune action:
  - Remove v3.1 Required assignment from Finance-targeted group
  - Add Finance devices to APP-FinBridge-v3.0-Rollback-Required
  - Assign v3.0 as Required and v3.1 as Uninstall for Finance rollback group

### Trigger D: 4 GB RAM device failure isolation

- Trigger condition:
  - >= 10.0% failed installs in APP-FinBridge-4GB-AtRisk over any rolling 24-hour period, with at least 100 devices reported
- Decision owner:
  - Deployment Manager (EUC) with Service Owner sign-off
- Decision window:
  - 4 business hours
- Exact Intune action:
  - Remove APP-FinBridge-4GB-AtRisk from all active v3.1 Required assignments
  - Add APP-FinBridge-4GB-AtRisk to APP-FinBridge-v3.1-Hold
  - If failures remain > 10.0% after one remediation cycle (24 hours), move at-risk devices to APP-FinBridge-v3.0-Rollback-Required

## 4. FINANCE DEADLINE RESOLUTION

### Option A - Compress pilot and place Finance in Ring 2 by end of Week 1

- Minimum safe pilot duration:
  - 3 business days with at least one full business-day observation after > 90% reporting
- Risk introduced:
  - Reduced time to detect low-frequency regressions (for example, next-day startup issues or delayed crash patterns)
- Compensating control:
  - Increase Ring 2 monitoring intensity: 4-hour cadence checks, pre-staged rollback groups, and a freeze checkpoint after first 250 Finance devices before scaling to all 500

### Option B - Finance as separate priority Ring 0 before main pilot

- Ring 0 structure:
  - Size: 120 Finance users (mix of power users, payment approvers, and branch variance)
  - Timing: Day 1-Day 2
  - Assignment: Required to APP-FinBridge-v3.1-Ring0-Finance
- Ring 0 advance conditions:
  - >= 98.0% install success in Intune
  - <= 2.0% failure rate
  - <= 1 ticket per 100 users over minimum 24-hour observation
  - No critical workflow outage
- Ring 0 rollback plan:
  - If threshold breach occurs, remove v3.1 Required for Ring 0 group immediately
  - Assign v3.0 Required + v3.1 Uninstall to APP-FinBridge-v3.0-Rollback-Required for Ring 0 devices
  - Incident review within 2 hours before allowing any non-Finance ring movement

### Recommendation

Recommend Option B (Finance Ring 0), because it best satisfies the end-of-Week-1 Finance commitment while preserving risk control for the remaining 9,500 endpoints.

Justification:
- It decouples Finance urgency from the main pilot signal, so timeline pressure does not weaken quality gates for enterprise-wide rollout.
- It gives Finance an earlier, targeted validation lane with explicit rollback mechanics.
- It preserves full Ring 1 evidence quality for hardware-risk and broader population before mass deployment.

Execution timeline with Option B:
- Day 1-Day 2: Ring 0 (Finance 120)
- Day 3-Day 5: Expand to remaining Finance 380 plus Ring 1 Pilot devices (300)
- Week 2: Ring 2 Early non-Finance expansion
- Week 3: Ring 3 Broad completion to 10,000 endpoints
