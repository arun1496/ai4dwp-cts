# Microsoft 365 Copilot – Support Ticket Triage (Legal Team)
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Triage principle:** Default to non-Copilot causes. "Genuine Copilot fault" is the last resort, not the first hypothesis.

---

## Ticket 1
**Reporter:** Paralegal  
**Description:** *"Asked Copilot to summarise a client NDA in SharePoint, got 'I don't have access to that content.' The file is in a folder she's never actually opened before, just heard about it in a meeting."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Permissions/access boundary** — the paralegal has never opened the folder and has no confirmed direct access. Copilot honours SharePoint permissions exactly as set; it cannot access content the user is not authorised to read. Hearing about a file in a meeting does not grant permissions. <br>2. **Sensitivity label restriction** — NDAs are high-value legal documents commonly labelled Confidential or Highly Confidential with encryption applied. Such labels can block Copilot from reading document body content even where the file is browsable. |
| **Fastest check** | Ask the paralegal to navigate directly to the SharePoint folder URL in her browser. If she receives **Access Denied**, the ticket is resolved — this is a permissions issue, not a Copilot issue. |
| **Is this actually a Copilot bug?** | **No.** Copilot returning "I don't have access to that content" is the correct and expected behaviour when the user lacks SharePoint read rights. The system is working as designed. |

---

## Ticket 2
**Reporter:** New associate (started this week)  
**Description:** *"Copilot in Outlook can't find any of the case emails I need context on."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **License/client prerequisite issue** — new starters frequently have the Microsoft 365 Copilot licence assignment delayed or missing entirely. A licence assigned within the last 24–48 hours may not have fully propagated. <br>2. **Data indexing lag** — a brand-new mailbox can take 24–72 hours to be fully indexed by Microsoft Search. With minimal email history there is very little for Copilot to draw on. <br>3. **Permissions/access boundary** — case emails may reside in shared mailboxes or distribution groups not yet delegated to the new associate. |
| **Fastest check** | In M365 Admin Centre → **Users → Active users**, confirm the Copilot add-on service plan shows as **Active** (not Pending) for this user's account. |
| **Is this actually a Copilot bug?** | **No.** A missing or recently assigned licence and a near-empty mailbox index fully explain this behaviour. Both are expected conditions for a day-one account. |

---

## Ticket 3
**Reporter:** Partner  
**Description:** *"Copilot surfaced and summarised a draft settlement from a matter I'm not assigned to. I didn't know I could even see that folder."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Permissions/access boundary (over-provisioned)** — Copilot never elevates permissions. If it surfaced the document, the partner already holds read access to that SharePoint location. The root cause is a SharePoint ACL or group membership misconfiguration, not Copilot. This should be treated as a data governance incident. |
| **Fastest check** | Ask the partner to open the SharePoint document URL directly in their browser. If the file opens without a prompt, they have standing permissions to that location. Escalate immediately to the matter team to review folder permissions and apply an appropriate sensitivity label. |
| **Is this actually a Copilot bug?** | **No.** Copilot surfacing content the user can already access is correct behaviour. This is a SharePoint permissions misconfiguration and a potential data governance incident — it should be escalated accordingly, not logged as a Copilot defect. |

---

## Ticket 4
**Reporter:** Legal ops manager  
**Description:** *"All 40 people on the Legal team suddenly lost Copilot access this morning, worked fine all last week."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **License/client prerequisite issue** — a bulk licence reassignment, licence expiry, or admin policy change is the most common cause of sudden team-wide simultaneous loss. Check for licence changes applied overnight. <br>2. **Sensitivity label restriction** — a DLP or Information Protection policy change applied at tenant or group level overnight could restrict Copilot for the entire team. <br>3. **Permissions/access boundary** — a change to a security group or Entra ID group membership that maps to the Copilot-enabled population could remove access for all affected users at once. |
| **Fastest check** | In M365 Admin Centre → **Billing → Licences**, confirm Copilot licences are still assigned to the Legal group or its members; then check the **Audit log** for any licence assignment, DLP policy, or Entra ID group changes since yesterday close of business. |
| **Is this actually a Copilot bug?** | **No.** A simultaneous 40-user outage with no prior symptoms is almost always an administrative or licensing change. A genuine Copilot service fault affecting a single team but not others would be highly unusual and should only be considered after admin-side causes are fully eliminated. |

---

## Ticket 5
**Reporter:** Contract specialist  
**Description:** *"Copilot gives vague, generic answers when I ask about clauses in our contract templates library, doesn't seem to actually read the documents."*

| | |
|---|---|
| **Likely cause (ranked)** | 1. **Sensitivity label restriction** — contract template libraries are frequently labelled in a way that blocks Copilot from reading document body content (e.g., an encryption-backed label prevents grounding against the file text). Copilot responds with generic knowledge rather than document content when grounding fails silently. <br>2. **Data indexing lag** — if the library was recently migrated, restructured, or if templates were recently uploaded, content may not yet be fully indexed by Microsoft Search. <br>3. **Permissions/access boundary** — Copilot may lack grounding access to the library even if the user can open files in their browser (site-level vs. item-level permission discrepancies). |
| **Fastest check** | Ask the specialist to copy a short clause directly into the Copilot chat prompt (no file reference) and ask the same question. If the answer is suddenly accurate and specific, the issue is with file grounding (indexing or label restriction), not Copilot's reasoning capability. |
| **Is this actually a Copilot bug?** | **Unclear, leaning No.** Vague answers when documents exist and are accessible can occasionally indicate a Copilot grounding failure, but sensitivity labels silently blocking content extraction are far more common in legal environments. Eliminate label restrictions and indexing lag before escalating as a product fault. |
