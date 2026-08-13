# IT Support Capstone Project: "Operation Stability"

## Project Overview

You are a senior service-desk analyst for a mid-sized financial services organization (Apex Financial Corp). On **August 13, 2026**, your organization has experienced a critical outage affecting multiple services. Your task is to triage, investigate, remediate, and document five concurrent incidents using the frameworks and skills taught throughout this training program.

**Duration:** 2-3 days (simulated)  
**Difficulty:** Advanced  
**Prerequisites:** Completion of Days 1–4 training  

---

## Learning Objectives

By completing this capstone, you will:

1. **Triage** complex, multi-faceted incidents under time pressure
2. **Prioritize** incidents based on business impact and scope
3. **Investigate** root causes using logs, event data, and system analysis
4. **Remediate** issues using safe, tested PowerShell scripts
5. **Document** incidents following DWP house style
6. **Communicate** technical findings to non-technical users
7. **Close** incidents with proper RCA and known-error records

---

## Project Structure

```
Capstone/
├── README.md (this file)
├── SCENARIO.md (detailed incident brief)
├── EVALUATION.md (grading rubric)
├── incident-data/
│   ├── incident-001-vdi-authentication.txt
│   ├── incident-002-teams-call-quality.txt
│   ├── incident-003-sharepoint-upload-fails.txt
│   ├── incident-004-windows-update-stall.txt
│   └── incident-005-profile-corruption-outbreak.txt
├── scripts/
│   ├── remediate-vdi-auth.ps1
│   ├── remediate-teams-qos.ps1
│   ├── remediate-profile-corruption.ps1
│   ├── investigate-update-status.ps1
│   └── diagnostic-suite.ps1
└── documentation/
    ├── triage-summaries/
    ├── investigations/
    ├── resolutions/
    ├── rca-reports/
    ├── end-user-communications/
    └── closure-notes/
```

---

## How to Approach This Project

### Phase 1: Initial Response (Triage)
1. Read `SCENARIO.md` for the business context and incident list
2. Read each incident file in `incident-data/`
3. Create triage summaries for each incident using the DWP template
4. Prioritize incidents by impact and urgency
5. Document your prioritization decision

### Phase 2: Investigation (Diagnosis)
1. Review the investigation notes provided in `SCENARIO.md`
2. Create investigation documents following Day 3 RCA patterns
3. Identify root causes
4. Cross-reference incidents (they may be related)

### Phase 3: Remediation (Resolution)
1. Review and customize the PowerShell scripts in `scripts/`
2. Document remediation steps
3. Create end-user communications using the DWP template
4. Write closure notes and known-error records

### Phase 4: Documentation (Handover)
1. Complete all documentation in `documentation/`
2. Ensure consistency across all artifacts
3. Generate a summary report for management

---

## Deliverables

You should produce the following artifacts in the `documentation/` folder:

| Artifact | File Pattern | Example |
|----------|--------------|---------|
| Triage Summary | `triage-[incident-name].md` | `triage-vdi-authentication.md` |
| Investigation Report | `investigation-[incident-name].md` | `investigation-vdi-authentication.md` |
| Resolution Summary | `resolution-[incident-name].md` | `resolution-vdi-authentication.md` |
| RCA Report | `rca-[incident-name].md` | `rca-vdi-authentication.md` |
| End-User Communication | `enduser-[incident-name].md` | `enduser-vdi-authentication.md` |
| Closure Note | `closure-[incident-name].md` | `closure-vdi-authentication.md` |
| Known Error Record | `known-error-[incident-name].md` | `known-error-vdi-authentication.md` |
| Management Summary | `management-summary.md` | (single file) |

---

## Success Criteria

### Triage Phase
- [ ] All 5 incidents triaged within 30 minutes (simulated time)
- [ ] Clear prioritization with reasoning
- [ ] Consistent use of DWP triage template
- [ ] No invented facts; all unknown items marked "to confirm"

### Investigation Phase
- [ ] Root causes identified for all incidents
- [ ] Log/event references included
- [ ] Cross-incident correlations noted where applicable
- [ ] Investigation follows Day 3 RCA structure

### Remediation Phase
- [ ] PowerShell scripts are safe and tested (include `-WhatIf` modes)
- [ ] Remediation steps clearly documented
- [ ] End-user communications are non-technical and under 120 words
- [ ] Closure notes reference investigation findings

### Documentation Phase
- [ ] All artifacts follow DWP house style
- [ ] Consistent terminology and formatting
- [ ] No spelling or grammar errors
- [ ] Cross-references between documents are accurate
- [ ] Management summary provides executive overview

---

## Evaluation Rubric

See `EVALUATION.md` for detailed grading criteria.

---

## Notes

- **Data Protection:** All incidents are anonymized and fictional; no real user data is included
- **Network Access:** Scripts include dry-run modes for safe testing before deployment
- **Time Pressure:** This project simulates real on-call conditions; prioritize ruthlessly
- **Collaboration:** In a real scenario, you would coordinate with network, security, and infrastructure teams; this project assumes you have access to their findings

---

## Getting Started

1. Open `SCENARIO.md` to understand the business context
2. Read the incident files in `incident-data/`
3. Begin triage summaries
4. Check `EVALUATION.md` to understand expectations

**Good luck, analyst!**
