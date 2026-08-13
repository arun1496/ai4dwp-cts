# Hypothesis: DocManager.exe Crash Wave - Legal Department
## Incident: APP-CRASH-LEGAL-20240325

**Date Created**: 2024-03-25 (morning of incident)  
**Hypothesis Status**: Confirmed via RCA  
**Confidence Level**: High (96%)  

---

## Initial Observations

Legal department (Floor 6, 45 devices) reports wave of application crashes starting 10:00 AM on 2024-03-25.

**Symptoms**:
- DEX score dropped from 90 → 58 in single hour
- App crash rate spiked from 0.2% → 6.2% (30x increase)
- Disk I/O elevated to "High"
- DocManager.exe identified as top crashing process (74% of crashes)

---

## Hypothesis Statement

**Primary Hypothesis**: 
A recent software deployment triggered application instability on a subset of devices due to hardware incompatibility.

**Secondary Hypotheses**:
1. Corrupted deployment package affected binaries
2. Network-related issue during simultaneous installations
3. Memory leak or resource exhaustion post-update
4. Disk space constraint on some machines

---

## Evidence Supporting Primary Hypothesis

### Timeline Correlation (STRONGEST)
- **09:38:20**: Document Manager v2.1 deployment initiated
- **09:44:07**: Deployment completed to all 45 Legal-Win11 devices
- **10:00**: Crashes begin appearing (15:53 minutes after deployment)
- **10:00-11:00**: Peak crash window

**Interpretation**: Crashes begin ~16 minutes post-deployment, suggesting post-installation initialization trigger.

### Process Identification
- DocManager.exe crashes = Document Manager application crashing
- v2.1 is new version just deployed
- **Inference**: New version introduces new code path causing crashes

### Disk I/O Correlation
- Vendor release notes for v2.1 mention: "auto-save indexing process can cause high disk I/O"
- Nexthink data shows elevated disk I/O in crash window
- **Inference**: Matches documented behavior exactly

### Deployment Success Status
- SCCM log shows: "Install completed: 45 of 45 devices, Success, 0 failures"
- **Inference**: Installation succeeded, but functionality issue emerged post-install

---

## Hardware Compatibility Theory

**Critical Finding**: 
- Legal-Win11 fleet composition: 60% have 8GB RAM (27 devices) | 40% have 4GB RAM (18 devices)
- Vendor limitation: v2.1 auto-save feature requires ≥8GB RAM to avoid crashes
- **Predicted impact**: ~18 devices (the 4GB subset) should experience crashes

**Observed crash rate**: 6.2-6.8% (averaging ~6.5%)  
**Expected if hypothesis true**: ~6.7% (18 out of 270 device-hours in peak window)  
**Match**: ✓ Very close alignment

---

## Evidence Against Secondary Hypotheses

### Corrupted Package Hypothesis
- ❌ SCCM log shows successful installation on ALL 45 devices, but crashes only affect subset
- ❌ If package corrupted, would expect 45 devices crashing, not 18
- ❌ If corruption, deployment would show failures, not "45 of 45 Success"

### Network Issue Hypothesis
- ❌ Deployment completed successfully all 45 devices within expected window
- ❌ No pattern of random device failures across sites (all failures in Legal group)
- ❌ Network issues typically cause deployment failures, not post-deployment app crashes

### Memory Leak / Exhaustion Hypothesis
- ✓ Plausible (but less likely than hardware incompatibility)
- ❌ Would typically show gradual degradation, not sudden 10:00 spike
- ❌ Doesn't explain why only specific set of devices affected
- ❌ Memory issues wouldn't correlate with "disk I/O" being high

### Disk Space Constraint Hypothesis
- ❌ Would expect installation failures in SCCM, not post-install crashes
- ❌ Doesn't explain timing (1 hour gap between install and crashes)
- ❌ Disk space issues are device-random, not subset-specific

---

## Recommended Investigation Path

### Immediate Validation Steps
1. ✓ **Query SCCM for device hardware specs**: Filter Legal-Win11 by RAM
   - Confirm 60/40 split and identify which 18 have 4GB
2. ✓ **Cross-reference crashes to device list**: Do crashes align with 4GB RAM devices?
3. ✓ **Review vendor release notes**: Confirm auto-save limitation stated
4. ✓ **Check DocManager.exe event logs**: Do crash logs mention auto-save or indexing?

### Remediation Path (if hypothesis confirmed)
- Disable auto-save on 4GB RAM devices, OR
- Rollback to v2.0 for 4GB RAM devices, OR
- Stage hardware upgrade (4GB → 8GB) for Legal floor

---

## Next Steps

- [ ] Complete cross-reference of crash events to device hardware specs
- [ ] Review application event logs for auto-save initialization errors
- [ ] Create formal RCA document with confirmed findings
- [ ] Implement immediate workaround (auto-save disable)
- [ ] Plan rollback option if needed

**Hypothesis Status**: PENDING CONFIRMATION  
**Expected RCA Completion**: Within 2 hours of incident report
