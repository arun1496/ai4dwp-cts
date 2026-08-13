# Root Cause Analysis (RCA)
## Legal Floor 6 - Application Crash Wave
## Date: 2024-03-25

## Executive Summary
Legal users on Floor 6 experienced a significant increase in application crashes after Legal Document Manager v2.1 was deployed to the Legal-Win11 fleet. Although SCCM reported 45/45 successful installations, endpoint experience deteriorated shortly after deployment completion. Nexthink showed a DEX decline, elevated crash rates, and sustained high disk I/O, with DocManager.exe contributing the majority of failures. Evidence indicates a runtime behavior issue rather than an installation-delivery failure.

## Probable Root Cause
Legal Document Manager v2.1 introduced an auto-save indexing feature that triggered high disk I/O and intermittent DocManager.exe crashes during initial index creation, especially on devices with less than 8GB RAM, after rollout to the Legal-Win11 collection.

## Why This Is the Most Likely Cause
- Clear post-change onset: degradation starts after deployment completion (09:44 -> 10:00 onward).
- Process-level alignment: DocManager.exe accounts for 74% of crashes.
- Performance signature alignment: high disk I/O appears with crash spike.
- Vendor alignment: release notes explicitly call out this behavior under 8GB RAM during first-hours indexing.
- Hardware susceptibility present: 18 of 45 devices are 4GB RAM.

## Contributing Factors
- v2.1 auto-save indexing is new and resource-intensive during first-run index build.
- Vendor known limitation for devices under 8GB RAM.
- 40% of the fleet (18 devices) is below 8GB.
- Simultaneous deployment to all 45 Legal devices increased blast radius.
- Deployment occurred during business hours, maximizing user-visible impact.

## Impact Assessment
- User productivity: frequent interruptions to document workflows for Legal teams.
- Application stability: pronounced increase in DocManager.exe crashes.
- Endpoint performance: high disk I/O likely degraded overall responsiveness.
- Uneven impact: lower-spec (4GB) devices likely saw higher severity.

## Immediate Remediation Actions
- Pause additional v2.1 rollout.
- Identify and prioritize devices under 8GB RAM.
- Roll back affected/high-risk devices to v2.0.
- Disable or tune auto-save indexing if vendor supports configuration.
- Monitor DEX, crash rate, disk I/O, and DocManager.exe stability after action.
- Escalate to vendor for hotfix or documented workaround.

## Preventive Actions
- Introduce pilot deployments across representative hardware tiers.
- Require low-spec device validation before production rollout.
- Add vendor release-note risk checks as a go/no-go gate.
- Schedule high-risk upgrades outside business hours.
- Implement post-deployment monitoring guardrails with rollback thresholds.

## Final Conclusion for Leadership
This was a user experience and runtime stability failure triggered by application behavior in v2.1, not a software distribution failure. SCCM confirms the package installed successfully; Nexthink confirms users were materially impacted afterward. Future deployment governance should explicitly separate install success from operational success and enforce hardware-aware pilot validation.