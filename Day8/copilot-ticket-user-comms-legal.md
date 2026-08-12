# Microsoft 365 Copilot – User Communications (Legal Team)
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Audience:** Individual ticket reporters — plain English, no technical jargon

---

## Ticket 1 — Paralegal: "I don't have access to that content" on client NDA

**Subject:** RE: Copilot can't access the NDA in SharePoint

Hi,

Thank you for getting in touch. The message you received — "I don't have access to that content" — is Copilot telling you exactly what it found: it hit a security boundary on that file and stopped there.

Here's the most likely reason: the folder you mentioned was one you hadn't opened before, which suggests your account may not yet have been granted access to it. Copilot applies the same security rules as SharePoint itself, so if the folder isn't accessible to you, Copilot can't read it either.

**What we're doing:** We'll check whether your account has the right permissions for that folder and whether a security label on the file is restricting access. If a permissions change is needed, we'll co-ordinate with the folder owner before making any adjustments.

**What you can do in the meantime:** If you need access to that NDA urgently, please contact the matter lead or whoever shared the folder information in the meeting. They can grant you access directly in SharePoint.

We'll update you within one business day.

Thanks,  
DWP Engineering

---

## Ticket 2 — New Associate: Copilot in Outlook can't find case emails

**Subject:** RE: Copilot in Outlook — limited results for new account

Hi,

Welcome to the team, and thanks for flagging this straight away.

This is completely expected for a brand-new account and nothing is broken. There are two things happening:

1. **Your Copilot licence needs a little time to fully activate.** When a new account is set up and Copilot is switched on, it can take 24–48 hours for everything to propagate in the background.
2. **There isn't much email history to work with yet.** Copilot works best once your mailbox has a reasonable history of messages and meetings. After your first week you should notice it becoming significantly more useful.

**What you can do right now:** Keep using Copilot normally — it will improve automatically as your mailbox fills up and your licence fully activates. If it's still showing no useful results by the end of your first week, please reply to this message and we'll take a closer look at your account setup.

No action needed from you at this stage.

Thanks,  
DWP Engineering

---

## Ticket 3 — Partner: Copilot surfaced a settlement document from another matter

**Subject:** RE: Copilot showing document from matter I'm not assigned to

Hi,

Thank you for reporting this promptly — this was absolutely the right thing to do.

To be clear: Copilot has not done anything wrong here. Copilot can only ever surface documents that your account already has permission to access in SharePoint. The fact that it showed you that document means your account currently has read access to that matter folder — which sounds like it may have been set up more broadly than intended.

**What we're doing:** We are treating this as a data access review. We will check the permissions on that folder with the matter team and tighten access so that only the people who should see it can do so. We will also look at whether a security label should be applied to restrict access further.

**What you should do:** Please do not share or act on the content of that document. If you have any concerns about what you saw, please also notify your supervisor.

We'll confirm the steps taken with you within one business day.

Thanks,  
DWP Engineering

---

## Ticket 4 — Legal Ops Manager: Whole Legal team lost Copilot access this morning

**Subject:** RE: Copilot access lost for Legal team — urgent

Hi,

Thank you for letting us know so quickly. We understand how disruptive this is for the team and we are treating this as a priority.

We believe the most likely cause is a change made to licences or account settings overnight — this is the most common reason for a large group to lose access at the same time. This is not a Copilot fault; it's an account configuration issue we can resolve.

**What we're doing right now:**
- Checking the licence assignments for all 40 affected accounts
- Reviewing the admin audit log for any changes made since yesterday
- Escalating to our Microsoft licence admin if a bulk change needs to be reversed

**What your team can do in the meantime:** Standard Microsoft 365 features (Outlook, Teams, Word, etc.) should be completely unaffected. Only the Copilot AI features are impacted.

We aim to have this resolved or have a clear update for you within two hours. We'll message you directly as soon as we have more information.

Thanks,  
DWP Engineering

---

## Ticket 5 — Contract Specialist: Copilot gives vague answers about contract templates

**Subject:** RE: Copilot not reading contract template documents

Hi,

Thank you for raising this. What you're describing — Copilot giving general answers rather than specific ones drawn from your documents — usually means it isn't successfully reading the files themselves, rather than any problem with Copilot's intelligence.

There are a couple of likely reasons this is happening:

- **The files may have a security label that restricts automated tools from reading them.** This is common for contract templates, which are often labelled as sensitive documents. Copilot responds with general knowledge when it can't access the file text.
- **If the library was recently updated or moved, the documents may not yet be fully indexed.** Microsoft's search index can take some time to catch up after changes.

**What we're doing:** We'll check the security labels and indexing status on the contract templates library and let you know what we find.

**A quick workaround in the meantime:** Open a specific contract template in Word and use the **Copilot button in the Word ribbon** to ask your question there. Copilot in Word reads the open document directly and may give you the specific answers you need while we investigate the broader library access.

We'll update you within one business day.

Thanks,  
DWP Engineering
