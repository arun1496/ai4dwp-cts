# Microsoft 365 Copilot – Rollout Readiness Tiering
**Department:** Finance (~200 users)  
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Reference document:** `m365-copilot-readiness-checklist-finance.md`

---

## Why Permissions/Oversharing Is a MUST — Not Just High Priority

Before the tiered list, this justification addresses the most common push-back during Finance Copilot deployments: *"Licensing and client version checks are quicker — why can't we assign licences while the permissions audit runs in parallel?"*

### The core risk

Microsoft 365 Copilot is a **reasoning layer over your existing permission model**. It does not introduce new access controls and it does not know that a SharePoint site's permissions were inherited in 2019 and never reviewed. When a Finance user sends a prompt like *"summarise our current M&A pipeline"* or *"what does our payroll look like this month?"*, Copilot will return results from every file that user — or any user in a broad inherited group — can access.

The Finance department's SharePoint estate contains:

| Data type | Likely blast radius if oversharing exists |
|---|---|
| Payroll files | Any staff member in an over-permissioned inherited group could surface salary data via Copilot prompt |
| Board packs | Documents intended for Board/ExCo visible to all Finance staff |
| M&A documents | Deal-sensitive content surfaced to staff with no need-to-know |
| Client financial data | Regulatory and contractual breach risk (FCA, GDPR) |

A misconfigured file permission is a latent risk today — it requires a user to navigate to a folder they may not know exists. **Copilot removes that friction entirely.** Natural language prompts make it trivially easy to surface content the user can technically access but was never intended to see. The 2019 migration inherited permissions are not a theoretical risk; they are an unknown quantity in a high-sensitivity environment. Unknown permissions + Copilot = unacceptable exposure.

Licensing and client version checks are **binary and reversible**: a user without a valid client build cannot use Copilot; assign the licence and it works. Oversharing is **silent and cumulative**: there is no error message, no alert, no indication that the content returned should not have been visible. By the time it is noticed, data has already been exposed.

**This is why permissions remediation is MUST, not SHOULD, and why it must precede licence assignment — not run alongside it.**

---

## Tier 1 — MUST Complete Before Rollout (Blocking)

These items are hard gates. Copilot licences must not be assigned until every item in this tier is confirmed complete and documented.

### Permissions & Oversharing Audit *(highest priority in this tier)*

- [ ] Enumerate all Finance SharePoint sites from the 2019 migration and document owners and data classification
- [ ] Export permission reports (CSV) for every Finance site — retained as audit evidence
- [ ] Identify and revoke access for former employees, contractors, and third-party accounts still present from 2019
- [ ] Identify all broken-inheritance libraries and folders; review and remove unjustified unique permissions
- [ ] Remove any "Everyone" or "Everyone except external users" grants on Finance sites, libraries, or folders
- [ ] Audit and revoke/convert "Anyone" (anonymous) sharing links on sensitive libraries
- [ ] Restrict access to payroll, board pack, M&A, and client financial data to named, justified groups only
- [ ] Run Entra ID Access Reviews on all Finance SharePoint sites
- [ ] Formal sign-off from Finance Director and DWP Security Lead that remediation is complete

### Identity & MFA

- [ ] MFA enforced via Conditional Access for all 200 Finance users — no exclusions without documented justification
- [ ] All Finance accounts confirmed as Entra ID cloud or hybrid-synced (no on-premises-only accounts)
- [ ] Service accounts excluded from the Copilot licence group

### Sensitivity Labelling (minimum viable)

- [ ] Sensitivity labels published to Finance users via label policy
- [ ] Finance-relevant labels exist for payroll, M&A, board, and client financial data
- [ ] SharePoint site default labels configured on Finance sites so new content is labelled automatically

### Licensing

- [ ] M365 Copilot add-on licences procured for the Finance cohort
- [ ] Entra ID security group `SG-Finance-CopilotEnabled` created — **members not added until all MUST items are complete**

---

## Tier 2 — SHOULD Complete Before Rollout (High Risk If Skipped)

These items do not technically block Copilot functioning, but skipping them significantly raises the risk of data exposure, compliance failure, or a poor experience that undermines adoption.

### Permissions & Oversharing (extended)

- [ ] Enable SharePoint Advanced Management (SAM) / Data Access Governance reports for ongoing oversharing visibility
- [ ] Restrict tenant-level site creation and external sharing to prevent re-introduction of oversharing after remediation
- [ ] Brief Finance users that personal OneDrive is not appropriate storage for payroll or M&A content

### Sensitivity Labelling (extended)

- [ ] Auto-labelling policies configured for payroll and M&A content types
- [ ] Content Explorer scan of Finance SharePoint — unlabelled content remediated before go-live
- [ ] DLP policies reviewed to confirm they cover Copilot interaction data and Finance-labelled content
- [ ] Label downgrade justification enforced in Purview

### Identity (extended)

- [ ] Conditional Access policies reviewed for compliant-device requirement and appropriate sign-in frequency for Finance
- [ ] PIM in use for Finance users with elevated roles

### Client Version

- [ ] All Finance endpoints confirmed on Microsoft 365 Apps for Enterprise (not perpetual Office)
- [ ] Minimum build verified via Intune / M365 Apps Health report; out-of-date endpoints remediated
- [ ] Teams new client deployed to Finance endpoints
- [ ] Finance endpoints not on Semi-Annual Channel (or exception documented)

### End-User Comms (pre-launch)

- [ ] Pre-launch communication sent to Finance users covering what Copilot can access and labelling responsibilities
- [ ] Finance Director sponsorship confirmed for rollout communications
- [ ] Mandatory awareness session delivered before licence assignment

---

## Tier 3 — CAN Complete During or After Rollout (Lower Risk)

These items improve the quality of the deployment and adoption but do not introduce material data risk if deferred by a few weeks post-launch.

### Permissions & Oversharing (continuous improvement)

- [ ] OneDrive sync client version confirmed current for all Finance endpoints
- [ ] Periodic access reviews scheduled (quarterly recommended for Finance given data sensitivity)

### Sensitivity Labelling (optimisation)

- [ ] Copilot prompt and response data confirmed covered by retention policies — can be validated post-launch during first compliance review
- [ ] Trainable classifier refinement for Finance-specific content types (ongoing)

### Identity (optimisation)

- [ ] Phishing-resistant MFA (FIDO2 / Windows Hello for Business) roadmap confirmed — deployment can follow post-launch
- [ ] Legacy per-user MFA migrated to Conditional Access — high priority but does not block Copilot if CA is already enforcing MFA

### Enablement & Adoption

- [ ] Finance-specific Copilot quick-start guide published to intranet
- [ ] 2–3 Finance Copilot Champions identified and briefed
- [ ] Feedback and issue reporting channel established
- [ ] Finance Director and DPO briefed on Microsoft data privacy commitments
- [ ] 30-day post-launch usage and permissions review scheduled

---

## Summary Table

| Area | MUST | SHOULD | CAN |
|---|---|---|---|
| Permissions & Oversharing (2019 audit) | ✅ Core audit, sign-off | Extended controls, SAM | Periodic reviews |
| Identity / MFA | ✅ Enforcement confirmed, no exclusions | CA policy detail, PIM | Passwordless MFA rollout |
| Sensitivity Labels | ✅ Labels published, site defaults set | Auto-labelling, DLP, Content Explorer | Classifier tuning, retention validation |
| Licensing | ✅ Licences procured, group created | — | — |
| Client Versions | — | Build compliance, Teams new client | OneDrive sync client |
| End-User Comms | — | Pre-launch comms, awareness session | Champions, quick-start guide, post-launch review |

---

## Decision Checkpoint

Before assigning Copilot licences, confirm:

1. **All MUST items checked** — documented evidence retained
2. **Permissions sign-off obtained** from Finance Director and DWP Security Lead in writing
3. **SHOULD items assessed** — any deferred items formally risk-accepted with a named owner and target date

Only after this checkpoint should members be added to `SG-Finance-CopilotEnabled`.
