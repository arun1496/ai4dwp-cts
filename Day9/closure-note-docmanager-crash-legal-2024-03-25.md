# Closure Note: DocManager.exe Crash Wave - Legal Floor 6
## Incident ID: APP-CRASH-LEGAL-20240325

**Report Date**: 2024-03-25  
**Closure Date**: 2024-03-25 (same day)  
**Severity**: High  
**Status**: ✓ RESOLVED  

---

## Incident Summary

Legal department experienced widespread application crashes (6.2-6.8% crash rate) affecting an estimated 18 devices on 2024-03-25 from 10:00-11:00 AM.

**Root Cause**: Document Manager v2.1 deployment (completed 09:44) to a fleet with heterogeneous RAM configuration. The new version's auto-save feature requires ≥8GB RAM; 40% of Legal-Win11 fleet (18 devices) has only 4GB RAM, triggering documented vendor limitation causing DocManager.exe crashes during initial index building.

**Time to Resolution**: <2 hours from incident report to remediation deployment

---

## Resolution Actions Taken

### Phase 1: Immediate Mitigation (10:00-10:30)
- **Action 1**: Identified root cause through data correlation (Nexthink + SCCM)
- **Action 2**: Communicated findings to Legal management and IT operations
- **Action 3**: Prepared rollback package

### Phase 2: Remediation Deployment (10:30-11:00)
- **Action 4**: Deployed Document Manager v2.0 rollback to 18x 4GB RAM devices
  - SCCM targeted deployment to `Legal-Win11 AND RAM < 8GB`
  - Deployment status: 18 of 18 devices successful
- **Action 5**: Verified DEX score and crash rate recovery
  - Post-remediation: DEX score improved to 87, crash rate dropped to 0.3%

### Phase 3: Post-Incident (11:00+)
- **Action 6**: Created hypothesis and RCA documents for future reference
- **Action 7**: Notified Legal department of resolution status
- **Action 8**: Scheduled follow-up actions (see below)

---

## Verification of Resolution

| Metric | Before (10:00) | After Remediation (11:15) | Status |
|--------|--------|---------|--------|
| DEX Score | 58 | 87 | ✓ Recovered |
| App Crash Rate | 6.2% | 0.3% | ✓ Resolved |
| Disk I/O | High | Normal | ✓ Normalized |
| DocManager.exe Crashes | 74% of all crashes | <1% | ✓ Stopped |
| Affected Devices | 18 | 0 | ✓ Restored |

**User Impact**: All 18 affected users regained full application access. Estimated productivity recovery: ~1.5 hours per user.

---

## Follow-Up Actions (Assigned)

### Short-term (Next 48 hours)
- [ ] Hardware upgrade planning: Schedule 4GB → 8GB RAM upgrades for Legal-Win11 fleet (18 devices)
  - **Owner**: Infrastructure/Procurement
  - **Timeline**: Plan for completion within 30 days
  - **Benefit**: Enables v2.1 deployment without workarounds; future-proofs for similar scenarios

### Medium-term (Next 2 weeks)
- [ ] **Policy Update**: Implement pre-deployment hardware compatibility checks
  - Add automated script to SCCM deployment workflow
  - Scan target collection for minimum hardware requirements
  - Reject deployment if compatibility threshold not met
  - **Owner**: SCCM Admin / Deployment Team

- [ ] **Vendor Review Process**: Establish review protocol for vendor release notes
  - Add checklist step before major version deployments
  - Escalate known limitations to stakeholders
  - Document compatibility constraints in deployment notes
  - **Owner**: Applications / Desktop Support

### Long-term (Next quarter)
- [ ] **Hardware Audit**: Assess entire user base for RAM adequacy
  - Identify all devices with <8GB RAM
  - Prioritize upgrades based on application requirements
  - **Owner**: Infrastructure / Asset Management

---

## Knowledge Base Entries Created

1. **RCA Document**: `rca-docmanager-crash-legal-floor6-2024-03-25.md`
2. **Hypothesis Document**: `hypothesis-docmanager-crash-legal-2024-03-25.md`
3. **Enduser Communication**: `enduser-communications-docmanager-legal-2024-03-25.md`

**Purpose**: Future reference if similar deployment issues occur with other applications.

---

## Lessons Learned

1. **Data Correlation is Key**: Nexthink + SCCM data together told complete story; neither alone was sufficient
2. **Vendor Notes Matter**: Release notes must be reviewed pre-deployment for known limitations
3. **Hardware Inventory Critical**: Heterogeneous fleets require compatibility checks before rollout
4. **Staged Deployments Prevent Incidents**: Full fleet deployment without pilot testing failed to catch issue
5. **Timing Correlation Works**: 16-minute post-deployment lag clearly indicated deployment-induced issue

---

## Cost Impact

| Item | Cost | Notes |
|------|------|-------|
| User productivity loss | ~$2,700 | 18 users × 1.5 hours × $100/hr |
| Incident investigation | ~$200 | 2 hours engineer time |
| Remediation deployment | ~$0 | Automated via SCCM |
| **Total Cost (without prevention)** | **~$2,900** | |
| **Prevention via pre-flight checks** | ~$500 | One-time policy update cost |
| **Net savings if policy implemented** | **80% reduction** | Future incidents prevented |

---

## Stakeholder Sign-Off

- **IT Operations**: ✓ Acknowledged and approved
- **Legal Department Manager**: ✓ Notified of resolution
- **Document Manager Vendor**: ⏳ Technical advisory case closed
- **DWP Engineering**: ✓ RCA complete

---

## Incident Closed

**Status**: ✓ RESOLVED AND DOCUMENTED  
**Escalation Risk**: Low (root cause identified, remediation verified, prevention plan in place)  
**Recurrence Risk**: Low (hardware upgrade and policy changes planned)  

**Closed by**: DWP Engineer  
**Date**: 2024-03-25 12:00 UTC  
**Case Number**: APP-CRASH-LEGAL-20240325

---

## Related Documentation
- Root Cause Analysis: [rca-docmanager-crash-legal-floor6-2024-03-25.md](./rca-docmanager-crash-legal-floor6-2024-03-25.md)
- Hypothesis Document: [hypothesis-docmanager-crash-legal-2024-03-25.md](./hypothesis-docmanager-crash-legal-2024-03-25.md)
- User Communication: [enduser-communications-docmanager-legal-2024-03-25.md](./enduser-communications-docmanager-legal-2024-03-25.md)
