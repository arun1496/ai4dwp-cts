# Intune Phased Deployment Plan: FinBridge Connect v3.1
**Prepared by:** DWP Engineer  
**Date:** 2026-08-12  
**Deadline:** 2026-09-02 (3 weeks)  
**Scope:** 10,000 Windows 11 endpoints  
**Package:** FinBridge Connect v3.1 (.intunewin, uploaded to app catalog)  
**Rollback version:** FinBridge Connect v3.0 (retained in app catalog)

---

## 1. RING STRUCTURE

### Overview

| Ring | Label | Size | Duration | Timing |
|------|-------|------|----------|--------|
| Ring 0 | Finance Priority | 120 Finance users | Days 1–2 | Week 1 |
| Ring 0 Expand | Finance Remainder | 380 Finance users | Days 3–5 | Week 1 |
| Ring 1 | Pilot | 300 endpoints | Days 3–5 | Week 1 |
| Ring 2 | Early Adoption | 2,200 endpoints | Days 6–10 | Week 2 |
| Ring 3 | Broad Rollout | 7,000 endpoints | Days 11–15 | Week 3 |

> Note: Ring 0 is the Finance priority track and runs in parallel with Ring 1. See Section 4 for Finance deadline resolution.

---

### Ring 1 — Pilot

**Size:** 300 endpoints  
- 200 standard-hardware endpoints (IT, Service Desk, power users from mixed business units)  
- 100 endpoints from the 4 GB RAM at-risk cohort

**Duration:** Minimum 3 full business days (Days 3–5), with at least one full business day of observation after 90% of devices have reported status.

**Who to include:**
- IT engineers, EUC support staff, and a nominated power user from each major department
- A proportional sample of the 500 at-risk 4 GB RAM devices (100 devices = 20% of that cohort)

**Purpose:**
- Validate install command, detection rule (registry version string), and exit-code mapping in production
- Surface hardware-specific failures on low-spec devices before wider release
- Generate a clean baseline success rate and ticket rate for advance criteria

**Intune assignment group type:**
- Microsoft Entra ID dynamic device security group
- Group name: `APP-FinBridge-v3.1-Ring1-Pilot`
- Assignment type: **Required**

---

### Ring 2 — Early Adoption

**Size:** 2,200 endpoints  
- Operations, HR, Legal, and other moderate-criticality departments
- Remaining 400 at-risk 4 GB RAM devices (only if Ring 1 at-risk sub-criteria pass — see Section 2)
- Remaining standard-hardware endpoints to reach the 2,200 total

**Duration:** Minimum 5 business days (Days 6–10)

**Who to include:**
- Departments with moderate business criticality and reasonable IT support ratios
- Broader geographic and network-segment coverage to surface site-specific issues

**Purpose:**
- Prove stability at meaningful scale before full fleet deployment
- Validate performance under typical daily usage load
- Final check before the large-volume Ring 3 wave

**Intune assignment group type:**
- Microsoft Entra ID dynamic device security group (filtered by department + approved device filter)
- Group name: `APP-FinBridge-v3.1-Ring2-Early`
- Assignment type: **Required**

---

### Ring 3 — Broad Rollout

**Size:** 7,000 endpoints (remaining fleet after Rings 0–2)

**Duration:** 7 business days (Days 11–15) in two internal waves:
- Wave 3A: 3,500 endpoints — Days 11–12
- Wave 3B: 3,500 endpoints — Days 13–15

**Who to include:**
- All remaining eligible Win11 endpoints not covered by prior rings
- 4 GB RAM devices released from Hold (if cleared) join Wave 3B

**Purpose:**
- Complete fleet deployment within 3-week SLA while preserving at least one intermediate control point (Wave 3A gate before 3B)

**Intune assignment group type:**
- Microsoft Entra ID dynamic device security group (all eligible Win11 devices minus ring exclusions)
- Group name: `APP-FinBridge-v3.1-Ring3-Broad`
- Assignment type: **Required**

---

### Pre-Created Supporting Groups

| Group Name | Purpose |
|-----------|---------|
| `APP-FinBridge-v3.1-Ring0-Finance` | Finance Ring 0 priority track |
| `APP-FinBridge-v3.1-Ring1-Pilot` | Ring 1 pilot devices |
| `APP-FinBridge-v3.1-Ring2-Early` | Ring 2 early adoption |
| `APP-FinBridge-v3.1-Ring3-Broad` | Ring 3 broad rollout |
| `APP-FinBridge-v3.1-Hold` | Paused devices (cohort-level hold) |
| `APP-FinBridge-v3.1-Rollback` | Devices receiving v3.1 Uninstall |
| `APP-FinBridge-v3.0-Rollback-Required` | Devices being reverted to v3.0 |
| `APP-FinBridge-4GB-AtRisk` | All 500 low-spec hardware devices |

---

## 2. ADVANCE CRITERIA

All success/failure metrics are sourced from **Intune > Apps > Monitor > App install status**, filtered by ring assignment group. Ticket rate is measured from service desk incidents tagged `FinBridge-v3.1` and the ring label (e.g., `Ring1`). All percentages are calculated against devices that have returned any status (Installed or Failed), not total assigned devices.

---

### Ring 1 → Ring 2 Advance Gate

| Criterion | Threshold | Source |
|-----------|-----------|--------|
| Install success rate | ≥ 98.0% | Intune app install status report |
| Error rate | ≤ 2.0% Failed status | Intune app install status report |
| User-reported issue rate | ≤ 1.5 tickets per 100 deployed users | Service desk, tagged `FinBridge-v3.1-Ring1` |
| At-risk hardware (4 GB) sub-criterion | ≤ 5.0% failed installs in `APP-FinBridge-4GB-AtRisk` Ring 1 subset | Intune device filter report |
| **Minimum monitoring period** | 24 hours after ≥ 90% of Ring 1 devices have reported Installed or Failed | Intune install status timestamp |
| **Time-bound decision** | Go/No-Go decision made within 4 business hours after monitoring period closes | Change record |

**4 GB sub-criterion caveat:** If the at-risk hardware sub-criterion is not met (failure > 5.0%), the 4 GB cohort is moved to `APP-FinBridge-v3.1-Hold` and excluded from Ring 2. Standard-hardware devices advance independently if all other criteria pass.

---

### Ring 2 → Ring 3 Advance Gate

| Criterion | Threshold | Source |
|-----------|-----------|--------|
| Install success rate | ≥ 97.0% | Intune app install status report |
| Error rate | ≤ 3.0% Failed status | Intune app install status report |
| User-reported issue rate | ≤ 2.0 tickets per 100 deployed users | Service desk, tagged `FinBridge-v3.1-Ring2` |
| **Minimum monitoring period** | 48 hours after ≥ 90% of Ring 2 devices have reported Installed or Failed | Intune install status timestamp |
| **Time-bound decision** | Go/No-Go decision made within 4 business hours after monitoring period closes | Change record |

---

### Hold Condition — Pause Without Full Rollback

**Trigger:**  
Any single site, department, or hardware cohort sustains > 5.0% failed installs over a rolling 12-hour window, while the global failure rate for the active ring remains at or below the rollback trigger threshold (< 7.0%).

**Action on hold:**
1. Pause all progression to the next ring.
2. Move the affected cohort from the active ring group to `APP-FinBridge-v3.1-Hold`.
3. Remove the cohort from the active Required assignment group.
4. Continue deployment in unaffected cohorts only after CAB duty engineer approval (documented in the change record).
5. Review cohort for remediation (driver update, prerequisite check) before re-introducing into the ring.

**Specific example:**  
Ring 2 overall failure rate is 2.8% (below the 7.0% rollback trigger), but `APP-FinBridge-4GB-AtRisk` shows 9.0% failed installs in a 12-hour window. Result: isolate `APP-FinBridge-4GB-AtRisk` to `APP-FinBridge-v3.1-Hold`, continue Ring 2 standard-hardware deployment with no change, and open an incident to investigate RAM-related install failures.

---

## 3. ROLLBACK TRIGGERS

All rollback triggers below are hard stop conditions for further v3.1 deployment expansion. Rollback means: remove v3.1 Required assignment, assign v3.0 as Required, assign v3.1 as Uninstall — for the affected device group.

---

### Trigger A — Install Failure Rate: Automatic Halt

**Condition:**  
≥ 7.0% Failed install status in Intune for any active ring group, sustained for 4 continuous hours, with at least 200 devices in that ring having reported status.

**Timeframe:** 4-hour sustained window after reporting threshold is met.

**Decision owner:** Incident Commander (EUC Engineering Lead), with Change Manager notified.

**Decision window:** 2 business hours from trigger detection to execute or formally defer with written justification.

**Exact Intune action:**
1. Remove **Required** assignment for FinBridge Connect v3.1 from the affected ring group and all not-yet-started rings.
2. Add affected devices to `APP-FinBridge-v3.0-Rollback-Required`.
3. Assign **FinBridge Connect v3.0 → Required** to `APP-FinBridge-v3.0-Rollback-Required`.
4. Assign **FinBridge Connect v3.1 → Uninstall** to `APP-FinBridge-v3.1-Rollback` for the same device set.

---

### Trigger B — Application Crash Rate: Rollback Consideration

**Condition (either):**  
- ≥ 3.0 application crashes per 100 active devices per 24-hour period, OR  
- ≥ 1.5% of active devices report 2 or more FinBridge Connect crashes within any rolling 24-hour period.

**Timeframe:** Any rolling 24-hour window during active rollout, sourced from Endpoint Analytics or Windows Event Log data surfaced via Intune device diagnostics.

**Decision owner:** EUC Engineering Lead and Application Owner (joint approval required for rollback).

**Decision window:** 4 business hours from threshold breach.

**Exact Intune action if rollback approved:**
1. Freeze all new v3.1 Required assignments (set remaining ring groups to Not Assigned).
2. Re-target affected ring devices to `APP-FinBridge-v3.0-Rollback-Required`.
3. Assign v3.0 as Required and v3.1 as Uninstall for `APP-FinBridge-v3.0-Rollback-Required`.
4. Keep unaffected ring groups in `APP-FinBridge-v3.1-Hold` until a 24-hour stability review completes.

---

### Trigger C — Business-Critical Failure: Immediate Rollback

**Condition:**  
Finance users are unable to complete the payment release workflow in FinBridge Connect for 30 consecutive minutes during core business hours (08:00–18:00 local) due to a confirmed v3.1 defect (not infrastructure or network cause).

**Percentage dependency:** None. This trigger is absolute and fires regardless of the proportion of users affected.

**Decision owner:** Major Incident Manager declares immediate rollback; EUC Engineering Lead executes.

**Decision window:** Immediate — execution must begin within 30 minutes of incident declaration.

**Exact Intune action:**
1. Remove v3.1 Required assignment from `APP-FinBridge-v3.1-Ring0-Finance` immediately.
2. Add Finance devices to `APP-FinBridge-v3.0-Rollback-Required`.
3. Assign **FinBridge Connect v3.0 → Required** to `APP-FinBridge-v3.0-Rollback-Required`.
4. Assign **FinBridge Connect v3.1 → Uninstall** to `APP-FinBridge-v3.1-Rollback` for Finance devices.
5. Halt all other active ring progression pending Major Incident review.

---

### Trigger D — 4 GB RAM Device Failures: Ring Isolation

**Condition:**  
≥ 10.0% failed installs within `APP-FinBridge-4GB-AtRisk` over any rolling 24-hour period, with at least 100 devices in the group having reported status.

**Decision owner:** Deployment Manager (EUC) with Service Owner sign-off.

**Decision window:** 4 business hours from threshold breach.

**Exact Intune action:**
1. Remove `APP-FinBridge-4GB-AtRisk` from all active v3.1 Required assignment groups.
2. Add `APP-FinBridge-4GB-AtRisk` to `APP-FinBridge-v3.1-Hold`.
3. Open a defect investigation (RAM/installer compatibility review).
4. **If failure rate remains > 10.0% after one remediation cycle (24 hours):** move `APP-FinBridge-4GB-AtRisk` to `APP-FinBridge-v3.0-Rollback-Required` and assign v3.0 as Required + v3.1 as Uninstall.
5. The at-risk cohort does not re-enter the rollout until a hardware-specific fix or workaround is validated in a separate test group.

---

## 4. FINANCE DEADLINE RESOLUTION

The Finance team (500 users) requires FinBridge Connect v3.1 by end of Week 1 (Day 5). The standard ring plan places Ring 2 (where Finance would sit) starting on Day 6, missing this deadline.

---

### Option A — Compress Pilot to Fit Finance into Ring 2 by End of Week 1

**How it works:** Reduce Ring 1 from 3 business days to 1–2 days, allowing Ring 2 (including Finance) to begin on Days 3–4 and complete by Day 5.

**Minimum safe pilot duration:** 1 full business day with 100% status reporting and at least 4 business hours of post-completion observation.

**Risk introduced:**  
Compressed observation window eliminates the ability to detect low-frequency regressions — for example, crash-on-next-launch patterns, end-of-day process interference, or startup failures that only appear on day 2 of use. This is the highest-risk option for a 10,000-endpoint fleet.

**Compensating control:**  
Stage Finance deployment in two waves: first 100 Finance devices on Day 3 (4-hour observation), then remaining 400 on Day 4–5. Pre-stage rollback groups before Day 3. Require a senior engineer on standby throughout.

---

### Option B — Finance as Separate Priority Ring 0 Before Main Pilot

**How Ring 0 is structured:**
- **Size:** 120 Finance users on Days 1–2 (power users, payment approvers, branch variance roles)
- **Remaining Finance (380 users):** Days 3–5, after Ring 0 advance criteria are met
- **Intune group:** `APP-FinBridge-v3.1-Ring0-Finance`
- **Assignment type:** Required, scoped exclusively to Finance-managed devices
- **Ring 0 runs in parallel with Ring 1 Pilot** from Day 3 onward — the rings are independent tracks

**Ring 0 advance conditions (Ring 0 initial 120 → Ring 0 remaining 380):**

| Criterion | Threshold |
|-----------|-----------|
| Install success rate | ≥ 98.0% |
| Error rate | ≤ 2.0% Failed in Intune |
| User-reported issues | ≤ 1 ticket per 100 users |
| Critical workflow outage | None reported |
| Minimum observation | 24 hours after ≥ 90% of 120 devices report status |

**Ring 0 rollback plan:**
1. If any threshold is breached on the initial 120, immediately remove v3.1 Required assignment from `APP-FinBridge-v3.1-Ring0-Finance`.
2. Add Ring 0 Finance devices to `APP-FinBridge-v3.0-Rollback-Required`.
3. Assign v3.0 as Required and v3.1 as Uninstall for those devices.
4. Halt Ring 0 expansion to the remaining 380 Finance users.
5. Conduct incident review within 2 hours before any other ring is permitted to progress.

---

### Recommendation: **Option B — Finance Ring 0**

**Recommendation:** Implement Option B.

**Justification:**

1. **Finance deadline is met without compressing quality gates.** Ring 0 puts 120 Finance users on v3.1 from Day 1, with the remaining 380 following on Days 3–5 — well within the Week 1 commitment — while Ring 1 Pilot runs its full 3-day window independently.

2. **Risk isolation.** Ring 0 and Ring 1 are separate Intune assignment groups with independent monitoring. A failure in Finance Ring 0 does not pollute Ring 1 pilot signal and vice versa. This preserves the integrity of advance criteria for the full 9,500-endpoint rollout.

3. **Finance gets a dedicated rollback path.** Option A embeds Finance into Ring 2 and relies on a shared rollback mechanism. Option B gives Finance its own rollback group with a 30-minute execution window, which is proportionate to the business-critical nature of their payment workflows.

4. **Precedent alignment.** Treating Finance as Ring 0 is a formally documented deviation from the standard ring sequence — it can be reviewed by CAB, audited, and repeated in future deployments. Compressing a pilot (Option A) normalises cutting observation time under deadline pressure, which is a pattern that accumulates rollout risk over time.

---

### Execution Timeline (Option B)

| Day | Activity |
|-----|----------|
| Day 1–2 | Ring 0: Deploy to 120 Finance users. Monitor advance criteria. |
| Day 3 | Ring 0 advance decision. Begin Ring 0 expansion to remaining 380 Finance users. Begin Ring 1 Pilot (300 devices including 100 at-risk). |
| Day 4–5 | Ring 0 Finance (380) completes. Ring 1 Pilot observation period. Finance deadline met by Day 5. |
| Day 5 (EOD) | Ring 1 advance decision. |
| Day 6–10 | Ring 2 Early Adoption (2,200 devices). Finance fully deployed. |
| Day 10 (EOD) | Ring 2 advance decision. |
| Day 11–12 | Ring 3 Wave 3A (3,500 devices). |
| Day 13–15 | Ring 3 Wave 3B (3,500 devices). Deployment complete. |

---

*Document owner: EUC Engineering Lead — review required before Ring 0 deployment begins.*
