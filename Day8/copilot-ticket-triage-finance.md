# Microsoft 365 Copilot – Support Ticket Triage
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Triage principle:** Default to non-Copilot causes. "Genuine Copilot fault" is the last resort, not the first hypothesis.

---

## Ticket 1
**Reporter:** Finance lead  
**Description:** *"Copilot won't summarise the Q3 board pack in SharePoint. It's right there, I can see it myself."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Permissions/access boundary** — the user can see the file via direct navigation, but Copilot queries the Microsoft Search index which honours permission scopes. Unique permissions, inheritance breaks, or a sensitivity label with encryption may prevent indexing or access at query time even if the file is browsable. <br>2. **Sensitivity label restriction** — board packs are high-value documents; if labelled with a protection label that encrypts content and restricts programmatic access, Copilot cannot read the file body. <br>3. **Data indexing lag** — if the file was recently uploaded or moved, the Search index may not yet have processed it. |
| **Fastest check** | In SharePoint, open the file's **Manage Access** panel and confirm the Finance lead has direct or group-based permissions — then check whether a sensitivity label with encryption is applied (visible in the document info pane or via the label badge). |
| **Is this actually a Copilot bug?** | **No.** "I can see it myself" is the classic mismatch between browser-render access and Copilot's index-time permission check. The most probable cause is a permissions boundary or label restriction, not a product fault. |

---

## Ticket 2
**Reporter:** New hire (started yesterday)  
**Description:** *"Copilot in Outlook seems to know nothing about my recent emails."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **License/client prerequisite issue** — new hire accounts are commonly staged and licences (including the Copilot add-on) may not yet be fully provisioned. A licence assigned in the last 24–48 hours may not have fully propagated. <br>2. **Data indexing lag** — a brand-new mailbox has little to no indexed content. Microsoft 365 Search indexes mailbox content progressively; a mailbox created yesterday may have minimal index coverage. <br>3. **License/client prerequisite issue (client build)** — the endpoint may not yet have been configured with the minimum M365 Apps build required for Copilot. |
| **Fastest check** | In M365 Admin Centre → **Users → Active users**, confirm the Copilot add-on service plan shows as **Active** (not Pending) for this user's account. |
| **Is this actually a Copilot bug?** | **No.** A new hire account with a recently assigned licence and an empty mailbox index is exactly what "knows nothing about recent emails" looks like. Both causes are expected behaviour for a day-one account. |

---

## Ticket 3
**Reporter:** HR manager  
**Description:** *"Asked Copilot in Word to pull data from a sensitive salary review spreadsheet, got 'I don't have access to that content.'"*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Sensitivity label restriction** — salary review documents are prime candidates for a `RESTRICTED – Payroll` or equivalent label with IRM/encryption applied. Labels that encrypt with rights management restrict Copilot's ability to read content programmatically, even for the document owner in some configurations. <br>2. **Permissions/access boundary** — the spreadsheet may be stored in a location where the HR manager does not hold the required permission level (e.g., a Payroll-only SharePoint library). The error message "I don't have access" is Copilot correctly reporting a permission denial. |
| **Fastest check** | Open the spreadsheet directly and check the **sensitivity label** shown in the ribbon or document info bar. If it carries an encryption-backed label, that is the cause — no further investigation needed. |
| **Is this actually a Copilot bug?** | **No.** The error message "I don't have access to that content" is Copilot's expected response when it encounters an access-denied condition — either from permissions or label-enforced encryption. This is the permission model working as designed. |

---

## Ticket 4
**Reporter:** Sales rep  
**Description:** *"Copilot in Teams can't find a client contract that was shared with her via a guest link from another org."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Guest/external sharing limitation** — content shared via a guest or "Anyone" link from an external organisation lives outside the tenant's Microsoft Search index. Copilot only indexes content within the tenant boundary. A file shared as an external guest link is not indexed and cannot be retrieved by Copilot regardless of whether the user can open it. <br>2. **Permissions/access boundary** — even if the file was copied into the tenant, it may be in a location the user cannot access via the index (e.g., a Teams channel the user is not a member of). |
| **Fastest check** | Establish **where the file lives** — is it in the external org's SharePoint/Teams, or has it been copied into the company tenant? If it is still hosted externally, Copilot cannot access it by design. |
| **Is this actually a Copilot bug?** | **No.** Copilot does not index or traverse external guest content. This is an expected and documented scope limitation, not a fault. The user needs to save the contract into the tenant (with appropriate labelling) if Copilot access is required. |

---

## Ticket 5
**Reporter:** IT admin  
**Description:** *"Copilot suddenly stopped working for the whole Finance team this morning, was fine yesterday."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **License/client prerequisite issue** — a group-based licence assignment change, a licence policy modification, or a Conditional Access policy update overnight could have removed the Copilot service plan from the Finance group or blocked the client from authenticating to the Copilot service. <br>2. **Permissions/access boundary** — a tenant-wide or SharePoint Admin Centre change (e.g., external sharing policy, site lock, or org-wide Conditional Access update) applied overnight. <br>3. **Genuine Copilot fault** — a service-wide or tenant-specific incident is possible but should be confirmed via the M365 Service Health Dashboard before assuming it. |
| **Fastest check** | Check **M365 Admin Centre → Service Health → Microsoft Copilot** for any active incidents or advisories affecting the tenant. Simultaneously verify that the Finance Copilot licence group still has the Copilot service plan showing as Active. |
| **Is this actually a Copilot bug?** | **Unclear.** A whole-team simultaneous failure is more consistent with a licence/policy change or a service incident than an individual configuration issue. Check Service Health first — if no incident is listed, pivot immediately to licence group and Conditional Access change history. |

---

## Ticket 6
**Reporter:** Manager  
**Description:** *"Copilot found and summarised a file I don't remember ever opening, from a folder I forgot I had access to."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Permissions/access boundary** — this is not a fault; it is the permission model surfacing content the user legitimately has access to. Copilot queries the Microsoft Search index for all content within the user's permission scope. If the user has (or inherited) access to a folder, Copilot can and will surface content from it. In a Finance environment with unaudited 2019 migration permissions, this is the expected consequence of overly broad inherited access. |
| **Fastest check** | Navigate to the file in SharePoint and check **Manage Access** — confirm whether the manager holds access via an inherited group from the 2019 migration. If so, this is an oversharing issue, not a Copilot issue. |
| **Is this actually a Copilot bug?** | **No.** This ticket is not a bug report — it is an oversharing symptom. Copilot behaved correctly. The manager's surprise indicates that existing permissions are broader than users realise, which is precisely the risk the permissions audit (see `m365-copilot-readiness-checklist-finance.md`) is designed to address. This ticket should be escalated to the permissions remediation workstream, not the Copilot fault queue. |

---

## Ticket 7
**Reporter:** Analyst  
**Description:** *"Copilot gives generic answers, doesn't seem to use any of our internal SharePoint content at all."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Data indexing lag** — if the analyst's SharePoint sites were recently created, migrated, or restructured, the Microsoft Search index may not have fully crawled the content. This is common post-migration. <br>2. **Permissions/access boundary** — the analyst may not have access to the SharePoint sites where relevant content lives, so Copilot correctly returns only what is in scope — which may be very little. <br>3. **License/client prerequisite issue** — if the Copilot licence was recently assigned, index scope for the user may still be building. <br>4. **Sensitivity label restriction** — if the bulk of Finance SharePoint content carries encryption-backed labels, Copilot may be unable to read most of it, resulting in generic responses. |
| **Fastest check** | Run a **Microsoft Search query** (search.microsoft.com or SharePoint home search) as the analyst for a known document they should be able to find. If Search also returns nothing, the issue is indexing or permissions — not Copilot specifically. |
| **Is this actually a Copilot bug?** | **No.** Copilot's knowledge of internal content is entirely dependent on Microsoft Search index coverage and the user's permission scope. If Search doesn't find it, Copilot won't either. Validate Search before concluding anything about Copilot. |

---

## Ticket 8
**Reporter:** Executive assistant  
**Description:** *"Copilot in Outlook can't see a shared mailbox's calendar that I manage on behalf of my director."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Permissions/access boundary** — Copilot in Outlook operates against the signed-in user's own mailbox and content in their permission scope. Delegate access to a shared mailbox calendar is a distinct permission construct; Copilot does not automatically inherit or traverse delegate/shared mailbox relationships in the same way the Outlook client does. <br>2. **License/client prerequisite issue** — shared mailboxes do not hold Copilot licences; Copilot can only act on content within the licensed user's own mailbox boundary. Calendar items in a shared mailbox the EA manages are outside that boundary. |
| **Fastest check** | Confirm whether the EA is trying to use Copilot **within the shared mailbox context** (not supported) or asking Copilot about the shared mailbox **from her own Outlook session** (limited support depending on client version and how delegate access is configured). |
| **Is this actually a Copilot bug?** | **No.** Shared mailbox and delegate calendar access is a known Copilot scope limitation — Copilot for Outlook is scoped to the licensed user's primary mailbox. The EA should be directed to Microsoft's published Copilot supported scenarios documentation and, if this is a critical workflow need, it should be logged as a feature gap rather than a fault ticket. |

---

## Triage Summary

| Ticket | Most Likely Cause | Copilot Bug? |
|---|---|---|
| 1 | Permissions/access boundary or sensitivity label restriction | No |
| 2 | Licence propagation delay or indexing lag (new account) | No |
| 3 | Sensitivity label restriction (encryption on payroll file) | No |
| 4 | Guest/external sharing limitation — outside tenant index | No |
| 5 | Licence/policy change or service incident | Unclear — check Service Health first |
| 6 | Oversharing — user has inherited access they forgot about | No — escalate to permissions audit |
| 7 | Indexing lag or insufficient permissions scope | No |
| 8 | Shared mailbox scope limitation — by design | No |

**0 of 8 tickets are confirmed Copilot product faults.** Tickets 1, 3, and 6 are directly connected to the unaudited 2019 SharePoint permission inheritance identified as the primary pre-deployment risk.
