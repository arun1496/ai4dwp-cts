# Incident Analysis
## Legal Floor 6 - Application Crash Wave
## Date: 2024-03-25

## Objective
Establish incident scope facts from Nexthink DEX and SCCM, then correlate timing and content to determine the most likely causal pattern.

## Source-Validated Scope Facts
- Department/Floor: Legal, Floor 6
- Device group: Legal-Win11
- Population in scope: 45 devices
- SCCM deployment scope: Legal Document Manager v2.1 deployed to 45/45 devices
- Nexthink observed degradation window: 10:00 to 11:00
- Dominant crash process: DocManager.exe (74% of crashes in the window)
- Hardware profile in scope:
  - 8GB RAM: 60% (27 devices)
  - 4GB RAM: 40% (18 devices)

## Correlated Timeline
| Time | Evidence | Observation |
|---|---|---|
| 08:00 | Nexthink | DEX 91, crash rate 0.1%, disk I/O Normal (stable baseline) |
| 09:00 | Nexthink | DEX 90, crash rate 0.2%, disk I/O Normal (still stable) |
| 09:38:20 | SCCM | Deployment started: Legal Document Manager v2.1 to Legal-Win11 (45 devices) |
| 09:44:07 | SCCM | Install complete: 45/45 success, 0 failures |
| 10:00 | Nexthink | DEX 58, crash rate 6.2%, disk I/O High (first major degradation) |
| 10:00-11:00 | Nexthink | DocManager.exe = 74% of all crashes |
| 11:00 | Nexthink | DEX 55, crash rate 6.8%, disk I/O High (degradation persists) |

## Cross-Source Correlation Analysis
### 1) Timing correlation
- The environment was stable before 09:38.
- Change introduction occurred at 09:38 and completed at 09:44.
- Performance and stability degradation emerged in the first post-deployment hour (10:00 onward).

### 2) Content correlation
- Nexthink indicates crash concentration in DocManager.exe, directly tied to the deployed product family.
- Nexthink also shows high disk I/O in the same interval as crash escalation.
- Vendor notes for v2.1 describe a known limitation: new auto-save indexing can cause high disk I/O and intermittent crashes during initial index build, especially on devices under 8GB RAM.
- Fleet composition includes 18 under-threshold devices (4GB), increasing expected risk surface.

### 3) Interpretation of SCCM success state
- SCCM "Success, 0 failures" confirms deployment execution and install completion only.
- It does not validate runtime stability, user experience, or post-install application behavior.
- Therefore, deployment success and operational health can diverge, which is consistent with this incident.

## Technical Analysis Findings
- DEX drop: 90/91 to 58/55
- Crash rate increase: 0.1-0.2% to 6.2-6.8%
- Disk I/O shift: Normal to High
- App-specific crash concentration: DocManager.exe at 74%
- Risk-relevant hardware fact: 40% of scope below 8GB RAM threshold

## Analytical Conclusion
The strongest evidence-based pattern is a post-deployment runtime degradation linked to Legal Document Manager v2.1 behavior during initial indexing. The timing, process-level crash concentration, disk I/O behavior, and vendor-stated limitation are mutually reinforcing and point to a single likely causal chain rather than unrelated concurrent faults.