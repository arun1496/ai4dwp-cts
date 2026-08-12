# Microsoft 365 Copilot – Readiness Checklist
**Department:** Finance (~200 users)  
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Classification:** INTERNAL – RESTRICTED

---

## Context & Risk Summary

| Factor | Detail |
|---|---|
| Users | ~200 Finance staff |
| Current licensing | M365 E5 — Copilot add-on **not yet assigned** |
| Data sensitivity | Payroll, board packs, M&A documents, client financial data |
| Permission posture | SharePoint permissions inherited from 2019 migration — **never audited** |
| Copilot risk if deployed now | HIGH — Copilot surfaces any content the user can access. Overly permissive inherited permissions mean Copilot could expose payroll or M&A data to users who should not see it. **Do not assign Copilot licences until Section 2 is complete and signed off.** |

---

## ⚠️ PRIORITY 1 — SharePoint/OneDrive Permissions & Oversharing Audit
> **This section must be completed and formally signed off before Copilot licences are assigned.**  
> Copilot respects Microsoft 365 permissions exactly as configured — it does not add extra access controls. Inherited permissions from the 2019 migration that were never reviewed are the single highest risk item in this deployment.

### 2019 Migration Permission Remediation

- [ ] **Enumerate all Finance SharePoint sites** created before or during the 2019 migration. Document site URLs, owners, and primary data classification (payroll, board, M&A, client data).
- [ ] **Run SharePoint Access Reviews** for every Finance site via Entra ID Access Reviews (Identity Governance → Access Reviews). Set reviewers to site owners + Finance IT lead.
- [ ] **Export permission reports** for each site using SharePoint Admin Centre → Active Sites → select site → Permissions, or via PnP PowerShell (`Get-PnPSiteCollectionAdmin`, `Get-PnPGroupMember`). Export to CSV and retain for audit trail.
- [ ] **Identify and remove stale access:** Former employees, contractors, or third-party accounts still holding permissions from the 2019 migration — revoke immediately.
- [ ] **Identify broken inheritance:** List all libraries and folders where unique permissions were applied during or after the 2019 migration. Review each one; remove unique permissions where they are no longer justified.
- [ ] **Check "Everyone" and "Everyone except external users" grants:** Search for any SharePoint sites, libraries, or folders where these groups have been granted access. Remove unless explicitly business-justified and documented.
- [ ] **Audit sharing links:** Run the SharePoint sharing report (SharePoint Admin Centre → Reports → Sharing) and identify "Anyone" (anonymous) links and "People in your organisation" links pointing at highly sensitive libraries (payroll, M&A). Convert to specific-person links or revoke.
- [ ] **Classify sites by sensitivity and apply site-level access controls:**
  - Payroll data: restrict to Payroll team + HR Business Partners only.
  - Board packs: restrict to Board members, EA team, named senior Finance leads.
  - M&A documents: restrict to deal team only; consider a dedicated private site with IRM.
  - Client financial data: restrict to named account team members.
- [ ] **Enable SharePoint Advanced Management (SAM)** if not already active (included in M365 E5). Use **Data Access Governance (DAG) reports** to get a continuous oversharing dashboard post-cleanup.
- [ ] **Restrict site creation and external sharing** at tenant level to prevent re-introduction of oversharing after remediation.
- [ ] **OneDrive – Finance users' personal drives:** Remind Finance users that Copilot can surface content from their own OneDrive. Advise against storing departmental data (payroll, M&A) in personal OneDrive; redirect to dedicated SharePoint sites with appropriate controls.
- [ ] **Document sign-off:** Permissions audit report reviewed and approved by Finance Director + DWP Security Lead before proceeding to Section 3.

---

## 1 — Licensing Prerequisites

- [ ] Confirm all ~200 Finance users hold an **M365 E5** licence (or M365 E3 + E5 Security/Compliance add-on as minimum for Copilot eligibility — E5 is confirmed here).
- [ ] Confirm **Microsoft 365 Copilot add-on** licences have been procured for the Finance cohort (200 × Copilot add-on SKU).
- [ ] Identify the licence assignment method: group-based licensing via Entra ID security group (recommended) rather than per-user manual assignment.
- [ ] Create a dedicated Entra ID security group `SG-Finance-CopilotEnabled` — do **not** add members until all readiness gates are passed.
- [ ] Verify no conflicting licence blocks exist (e.g., service plan disablement policies that suppress Copilot service plans).

---

## 3 — Microsoft 365 Apps Client Version Requirements

- [ ] Confirm all Finance endpoints are running **Microsoft 365 Apps for Enterprise** (not Office 2019 / 2021 perpetual — Copilot requires the subscription client).
- [ ] Minimum build required: **Version 2302 (Build 16130.xxxxx)** or later. Target: Current Channel or Monthly Enterprise Channel.
- [ ] Run an Intune Device Compliance or Microsoft 365 Apps Health report to identify any Finance endpoints below the minimum build.
- [ ] Remediate out-of-date endpoints: force update via Intune / M365 Apps Admin Centre before licence assignment.
- [ ] Verify **Microsoft Teams** is on a supported version (Teams New Client, or Teams classic up to date). Copilot in Teams meetings requires the new Teams client.
- [ ] Confirm **OneDrive sync client** is current (build 23.xxx or later) — required for Copilot to surface OneDrive content reliably.
- [ ] Check that Finance endpoints are **not** configured with a deferred update channel (Semi-Annual Channel) unless an exception is approved — Semi-Annual may lag Copilot feature releases by up to 6 months.

---

## 4 — Identity & MFA Readiness

- [ ] Confirm all 200 Finance users are **cloud-only or hybrid-synced** in Entra ID (no on-premises-only accounts).
- [ ] Verify **MFA is enforced** for all Finance users — either via Conditional Access policy or Security Defaults. Per-user MFA (legacy) should be migrated to CA.
- [ ] Check that **no Finance accounts are excluded** from MFA Conditional Access policies (exclusion groups, named locations carve-outs, etc.). Finance is high-risk; exclusions must be reviewed and justified.
- [ ] Confirm **Entra ID Privileged Identity Management (PIM)** is in use for any Finance users with elevated roles (SharePoint Admin, Exchange Admin, Global Admin).
- [ ] Verify **passwordless or phishing-resistant MFA** (FIDO2 / Windows Hello for Business) is deployed or roadmapped for Finance — recommended for high-sensitivity departments.
- [ ] Confirm **Conditional Access policies** cover Copilot-relevant scenarios: compliant device required, approved client apps, sign-in frequency appropriate for Finance risk profile.
- [ ] Check that **no Finance service accounts** have been inadvertently included in the Copilot licence group — service accounts must be excluded.

---

## 5 — Sensitivity Labelling

- [ ] Confirm **Microsoft Purview sensitivity labels** are published to Finance users via a label policy.
- [ ] Verify Finance-relevant labels exist and are configured appropriately, e.g.:
  - `OFFICIAL – SENSITIVE`
  - `RESTRICTED – Payroll`
  - `RESTRICTED – M&A`
  - `RESTRICTED – Client Financial`
- [ ] Confirm **auto-labelling policies** are configured for payroll and M&A content types (keyword/regex or trainable classifier-based).
- [ ] Ensure **SharePoint site default labels** are set on Finance sites so new content inherits the correct label without user action.
- [ ] Verify **Copilot interaction data labelling**: in M365 Copilot settings (Purview), confirm that Copilot prompt and response data is covered by your retention and DLP policies.
- [ ] Run a **Content Explorer** scan (Purview) on Finance SharePoint sites to identify unlabelled content — remediate before go-live.
- [ ] Confirm **DLP policies** exist that prevent Copilot (and general sharing) from surfacing labelled-restricted content outside Finance. Review any Finance-specific DLP exceptions.
- [ ] Confirm **label downgrade justification** is enforced — users must provide a reason when removing or lowering a sensitivity label.

---

## 6 — End-User Communications & Enablement

- [ ] Draft and send **pre-launch communication** to Finance users explaining: what Copilot is, what data it can access (their own accessible content), and the importance of correct sensitivity labelling.
- [ ] Confirm **Finance management sponsorship**: a named Finance Director or Head of Finance to endorse the rollout communication — avoids perception of IT-led imposition.
- [ ] Deliver **mandatory awareness session** (30 min) covering: Copilot capabilities, what it can/cannot access, how to label content correctly, and how to report concerns.
- [ ] Publish a **Finance-specific Copilot quick-start guide** to the Finance SharePoint intranet page covering: key prompts for Finance workflows, do's and don'ts, sensitivity label guidance.
- [ ] Establish a **feedback channel** (Teams channel or ticketing queue) for Finance users to report unexpected Copilot behaviour or suspected data exposure.
- [ ] Identify **2–3 Finance Copilot Champions** (power users) to support peer adoption and escalate issues to DWP.
- [ ] Brief the **Finance Director and any Data Protection Officer** on Copilot's data handling, Microsoft's data privacy commitments (no training on tenant data), and the audit controls in place.
- [ ] Schedule a **30-day post-launch review** — review Copilot usage reports (M365 Admin Centre → Copilot usage), review any support tickets, and reassess permission posture.

---

## Sign-Off Gates

| Gate | Owner | Status |
|---|---|---|
| Permissions audit complete and documented | DWP Security Lead + Finance Director | ☐ |
| Oversharing remediation verified | DWP Engineer | ☐ |
| Sensitivity labels deployed and content labelled | Purview/Compliance team | ☐ |
| MFA enforced for all 200 users | Identity team | ☐ |
| Client version compliance confirmed | Endpoint team | ☐ |
| End-user awareness session delivered | Change/Comms | ☐ |
| **Copilot licences assigned to Finance** | DWP Licensing | ☐ |

---

*Do not assign Copilot licences until all gates above are checked. The permissions and oversharing risk from the unaudited 2019 migration represents a data exposure risk that Copilot would amplify — remediation is a prerequisite, not a parallel workstream.*
