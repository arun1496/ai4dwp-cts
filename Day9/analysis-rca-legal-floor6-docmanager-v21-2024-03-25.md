# Analysis and Root Cause Analysis (RCA)
## Incident: Legal Floor 6 Application Crash Wave
## Date of Incident: 2024-03-25

## 1. Executive Summary
On the morning of 2024-03-25, Legal users on Floor 6 experienced a sharp increase in application crashes and performance degradation. Baseline endpoint health was stable at 08:00 and 09:00, then deteriorated after Legal Document Manager v2.1 was deployed to all Legal-Win11 devices and installation completed at 09:44. Between 10:00 and 11:00, crash rates rose from 0.1-0.2% to 6.2-6.8%, DEX score fell from 90/91 to 58/55, and disk I/O moved from Normal to High. DocManager.exe contributed 74% of crashes in the same window. The most likely root cause is v2.1 auto-save indexing behavior causing high disk I/O and intermittent runtime crashes, especially on devices under 8GB RAM.

## 2. Scope Facts (Established from Both Sources)
- Department/Floor: Legal, Floor 6
- Device Group: Legal-Win11
- Total devices in scope: 45
- Deployment scope (SCCM): v2.1 deployed to 45/45 devices, install success 45/45
- Experience impact scope (Nexthink): DEX and crash degradation observed across the Legal-Win11 population window after deployment
- Dominant crashing process: DocManager.exe (74% of crashes from 10:00-11:00)
- Higher-risk hardware subset: 40% of fleet has 4GB RAM (18 devices), below vendor 8GB threshold

## 3. Correlated Timeline (Cross-Source)

| Time | Source | Event / Metric | Evidence | Correlated Interpretation |
|---|---|---|---|---|
| 08:00 | Nexthink | DEX 91, crash 0.1%, disk I/O Normal | Stable baseline before change | No pre-existing broad instability signal |
| 09:00 | Nexthink | DEX 90, crash 0.2%, disk I/O Normal | Still stable | Environment remains healthy pre-deployment |
| 09:38:20 | SCCM | Deployment started: Legal Document Manager v2.1 to Legal-Win11 (45 devices) | Change introduced | Start of potential causal window |
| 09:44:07 | SCCM | Install completed 45/45, success 0 failures | Distribution/install technically successful | Installation success confirms delivery only, not runtime quality |
| 10:00 | Nexthink | DEX 58, crash 6.2%, disk I/O High | First major degradation point | Symptoms emerge shortly after deployment completion |
| 10:00-11:00 | Nexthink | Top crashing process DocManager.exe, 74% of crashes | App-specific concentration | Strong linkage to newly deployed application behavior |
| 11:00 | Nexthink | DEX 55, crash 6.8%, disk I/O High | Degradation persists | Ongoing post-install runtime issue, not transient noise |

## 4. Cross-Source Correlation Analysis
The two data sources align on both timing and behavior:

- Timing correlation:
  - Pre-change baseline at 08:00 and 09:00 is healthy.
  - SCCM deployment starts at 09:38 and completes at 09:44.
  - Experience degradation appears in the immediate post-deployment hour (10:00 onward).
- Content correlation:
  - Nexthink shows simultaneous app crash increase and high disk I/O.
  - Nexthink identifies DocManager.exe as the dominant crashing process (74%), directly matching the deployed application family.
  - Vendor v2.1 notes describe a known limitation: auto-save indexing can cause high disk I/O and intermittent crashes during initial index build, especially on devices with under 8GB RAM.
  - Fleet profile includes a large under-threshold segment (18 devices at 4GB RAM), increasing likelihood and scale of impact.

Why SCCM "Success, 0 failures" does not contradict the incident:
- SCCM success validates package delivery and install execution state.
- It does not validate runtime stability, application behavior under user load, or post-install indexing side effects.
- Therefore, a technically successful deployment can still produce operational user experience failure.

## 5. Technical Findings
- DEX score dropped from 90/91 to 58/55 after v2.1 deployment completion.
- App crash rate increased from 0.1-0.2% to 6.2-6.8%.
- Disk I/O shifted from Normal to High in the same window as crash increase.
- DocManager.exe accounted for 74% of crashes between 10:00 and 11:00.
- 40% of Legal-Win11 devices (18/45) are 4GB RAM, below the vendor's 8GB threshold called out in v2.1 release notes.

## 6. Probable Root Cause
Legal Document Manager v2.1 introduced an auto-save indexing feature that triggered elevated disk I/O and intermittent DocManager.exe runtime crashes during initial index creation, with greater susceptibility on devices below 8GB RAM, after deployment to the Legal-Win11 collection.

The deployment itself completed successfully (45/45), but runtime behavior degraded post-installation.

## 7. Contributing Factors
- New auto-save indexing process in v2.1.
- Vendor-documented limitation on devices under 8GB RAM.
- 40% of in-scope fleet at 4GB RAM (18 devices).
- Broad deployment to all 45 Legal devices at once.
- Initial indexing period occurred during business hours.

## 8. Impact Assessment
- User productivity impact: Legal staff experienced frequent app interruptions during active work hours.
- Application stability impact: Marked increase in DocManager.exe crash frequency.
- Endpoint performance impact: High disk I/O likely reduced device responsiveness beyond the target app.
- Differential impact: 4GB RAM devices likely experienced higher severity due to lower hardware headroom.

## 9. Immediate Remediation Actions
- Pause further rollout of Legal Document Manager v2.1.
- Identify and tag all Legal-Win11 devices with less than 8GB RAM.
- Roll back affected/high-risk devices to Document Manager v2.0.
- Disable or tune auto-save indexing if vendor-supported.
- Monitor DEX, crash rate, disk I/O, and DocManager.exe crash trend hourly.
- Engage vendor for hotfix, workaround, or supported configuration guidance.

## 10. Preventive Actions
- Pilot future versions on a representative hardware mix before wide deployment.
- Include low-spec devices (4GB RAM) in mandatory validation.
- Add vendor release-note risk review as a deployment gate.
- Schedule potentially heavy post-install processing outside business hours.
- Use Nexthink post-deployment watch dashboards for the first 4-8 hours.
- Define rollback triggers using explicit thresholds (DEX drop, crash spike, sustained high disk I/O).

## 11. Final Conclusion
This incident is most consistent with a post-deployment runtime regression linked to Document Manager v2.1 auto-save indexing behavior, not a deployment delivery failure. SCCM confirms installation success, while Nexthink confirms user-experience degradation immediately afterward. The evidence supports a clear distinction between deployment success and operational application health.