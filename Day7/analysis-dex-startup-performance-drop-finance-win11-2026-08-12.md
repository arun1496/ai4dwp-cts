# Ranked Likely Causes - DEX Startup Performance Drop (Finance-Win11)

Date: 2026-08-12
Signal: Startup score dropped from 84 to 61 on 2026-08-04, immediately after a 2026-08-04 02:00 config deployment to Finance-Win11 only; IT-Win11 (no change) remained stable.

## 1) Startup compliance-logging script added by the new baseline (Most probable)

Why it fits the evidence:
- Timing aligns exactly: script was introduced in the 02:00 baseline, and the first post-change day (2026-08-04) shows the step change in startup time/score.
- Scope aligns cleanly: only Finance-Win11 received the change, and only that group degraded; IT-Win11 did not receive the change and stayed flat.
- Pattern fits sustained impact: elevated startup times continue on 2026-08-05 and 2026-08-06, consistent with a script that runs at every login/startup.

Fastest check to confirm or eliminate:
- On 5-10 affected Finance-Win11 devices, review script execution duration in startup/logon traces for sessions before desktop usability.
- Temporarily exclude a small pilot subset from the script assignment (or disable script execution) and compare next-login startup times against still-scoped Finance devices.

## 2) Additional Defender scan policy in the same baseline causing login-time scan overhead

Why it fits the evidence:
- Timing aligns exactly with baseline deployment at 02:00 and immediate day-over-day degradation on 2026-08-04.
- Scope matches the comparison: Finance-Win11 had policy change and degraded; IT-Win11 had no policy change and stayed stable.
- Persistence across multiple days fits a recurring policy-driven workload.

Fastest check to confirm or eliminate:
- Compare Defender operational/performance counters during login window on affected Finance devices versus IT controls (CPU/disk activity and scan events at sign-in/startup).
- Create a short controlled exception on a pilot subset (revert only the new scan policy element) and observe next-login startup delta versus unchanged Finance peers.

## 3) Combined baseline interaction effect (script + Defender policy together) increasing startup critical-path contention

Why it fits the evidence:
- Both changes landed in the same Finance-only baseline at the exact inflection point.
- The unaffected group is a clean negative control: no baseline change, no degradation.
- Magnitude jump (84 to 61; startup about 17.5s to 41.3s) can be consistent with additive contention from two concurrent startup-time tasks.

Fastest check to confirm or eliminate:
- Run a two-step A/B pilot within Finance: remove script only for one subset, remove Defender addition only for second subset, keep both for control subset.
- Compare next-login median startup and score movement across subsets to isolate single-effect vs interaction effect.

## Ranking Weighting Note

Ranking is weighted primarily on:
- Exact temporal alignment to the 2026-08-04 02:00 Finance-only config deployment.
- Clean comparison behavior from IT-Win11, which had no deployment and no corresponding degradation.
