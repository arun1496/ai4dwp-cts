# Microsoft 365 Copilot – User Communications
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Audience:** Individual ticket reporters — plain English, no technical jargon

---

## Ticket 1 — Finance Lead: Copilot won't summarise the Q3 board pack

**Subject:** RE: Copilot can't access the Q3 board pack

Hi,

Thank you for getting in touch. We can see why this is confusing — if you can open the file yourself, it's reasonable to expect Copilot to be able to read it too.

Here's what's happening: Copilot works through a background search index, and that index applies the same security rules that protect the file. The most likely reason Copilot can't access the board pack is one of two things:

- The file has a security label applied that restricts automated tools from reading it (this is intentional for highly sensitive documents like board packs).
- Your access to the file came through a permission that the index doesn't fully recognise yet.

**What we're doing:** We'll check the permissions and security label on that specific file and let you know what we find. We may need to make a small adjustment — we'll confirm with the file owner before doing anything.

**What you can do in the meantime:** If you need the summary urgently, open the document in Word and use Copilot in Word directly (the Copilot button in the Home ribbon) rather than asking from Teams or the Copilot chat. This sometimes works where the other route doesn't.

We'll update you within one business day.

Thanks,  
DWP Engineering

---

## Ticket 2 — New Hire: Copilot seems to know nothing about my recent emails

**Subject:** RE: Copilot in Outlook — limited results for new account

Hi,

Welcome to the team, and thanks for flagging this straight away.

This is completely expected for a brand-new account and nothing is broken. There are two things happening:

1. **Your licence needs a little time to fully activate.** When a new account is set up and Copilot is switched on, it can take 24–48 hours for everything to fully propagate in the background.
2. **There isn't much email to work with yet.** Copilot works best once you have a reasonable history of emails and meetings for it to draw on. After your first week you should notice it becoming much more useful.

**What you can do right now:** Keep using Copilot normally — it will improve automatically as your mailbox fills up. If it's still showing no useful results by the end of your first week, please reply to this message and we'll take a closer look at your account.

No action needed from you at this stage.

Thanks,  
DWP Engineering

---

## Ticket 3 — HR Manager: Got "I don't have access to that content" for salary spreadsheet

**Subject:** RE: Copilot access error on salary review file

Hi,

Thank you for reporting this. The message "I don't have access to that content" is Copilot telling you exactly what it found — it hit a security boundary on that file and stopped there. This is the system working as intended for sensitive documents.

The most likely reason is that the salary review spreadsheet has a **security label** applied to it that prevents automated tools (including Copilot) from reading it. This is a deliberate protection for payroll-class data.

**What this means for you:** You can still open and work with the file yourself in Excel — the restriction only applies to Copilot reading it in the background. If you need Copilot to help with the content, open the file directly in Excel, and then use Copilot within that Excel session (via the Copilot button in the ribbon). Copilot in-app can work with a file you have open in a way that background access cannot.

**What we're doing:** We'll confirm which security label is on the file and whether the current setup is correct for your role. We won't change anything without checking with your data owner first.

We'll come back to you within one business day.

Thanks,  
DWP Engineering

---

## Ticket 4 — Sales Rep: Copilot can't find client contract shared via guest link

**Subject:** RE: Copilot can't find the client contract

Hi,

Thanks for raising this. We can see what's happened here, and the short answer is: Copilot is only able to work with files that are stored inside our own company systems.

The contract was shared with you via a link from the other organisation's systems — it lives on their side, not ours. Copilot can't reach across into another company's systems to read that file, and that's actually an important security feature, not a limitation we can switch off.

**What you can do:**

1. **Save a copy into our SharePoint or Teams** — ask the contact at the other organisation to share the document in a way that lets you save it into our environment. Once it's stored here and appropriately labelled, Copilot will be able to work with it.
2. **Open it directly** — if you just need to work with the contract now, open it via the link as normal. Copilot won't be able to summarise it in the background, but you can read it yourself.

If saving a copy is the right route, let us know and we can advise on the best place to store it and how to label it correctly.

Thanks,  
DWP Engineering

---

## Ticket 5 — IT Admin: Copilot stopped working for whole Finance team

**Subject:** RE: Copilot outage — Finance team

Hi,

Thank you for reporting this immediately — a whole-team failure is always our highest priority to investigate.

We are looking into this now. The most common causes for a sudden team-wide failure are:

- A licence or policy change that took effect overnight
- A service issue on Microsoft's side affecting our tenant

**What we're doing right now:**

1. Checking Microsoft's Service Health dashboard for any active incidents affecting Copilot.
2. Checking whether any licence or access policy changes were made to the Finance group in the last 24 hours.

**What you can tell your users:** Please ask Finance staff not to log repeat tickets for the same issue — we are aware and investigating. If anyone has an urgent business need that Copilot was supporting, please let us know and we'll prioritise a workaround.

We will send an update within 2 hours, or sooner if we identify the cause.

Thanks,  
DWP Engineering

---

## Ticket 6 — Manager: Copilot found a file I don't remember ever opening

**Subject:** RE: Copilot surfaced unexpected file

Hi,

Thank you for letting us know about this — it's an important observation and we're glad you flagged it rather than ignoring it.

To reassure you first: **Copilot has not accessed anything it wasn't supposed to.** It can only ever surface files that you already have permission to see. What's happened here is that you have access to a folder — possibly from a permissions setup that goes back a few years — and Copilot found it because your account has always technically been allowed to see it.

Think of it this way: if a filing cabinet in your office has always had your name on the access list, Copilot will tell you what's in it when you ask. The filing cabinet was never locked to you — you just hadn't looked inside it recently.

**What we're doing:** We're currently reviewing Finance SharePoint permissions as part of a planned audit. Your experience is helpful evidence that some permissions may be broader than intended, and we will look at that folder specifically as part of this work.

**What you should do:**

- If the content of that file is something you should genuinely have access to, no action is needed.
- If you believe you should **not** have access to it, please reply with the file name and location and we will review it urgently.

Thank you again for raising this — it's exactly the kind of thing we need to know about.

Thanks,  
DWP Engineering

---

## Ticket 7 — Analyst: Copilot gives generic answers, ignores internal content

**Subject:** RE: Copilot not using SharePoint content

Hi,

Thanks for flagging this. If Copilot is giving you answers that could have come from the internet rather than our internal documents, it means it either can't find your SharePoint content or can't access it — and there are a few reasons that could be the case.

The most common causes are:

- **Your account is relatively new** — it can take some time for all of your SharePoint content to be fully indexed and available to Copilot.
- **The content you're thinking of may be in a location you don't have access to** — Copilot only uses files within your permission scope.
- **Some files may be protected** — highly sensitive documents with security labels may be excluded from Copilot's reach by design.

**A quick test you can do yourself:** Go to [sharepoint.com](https://sharepoint.com) and use the search bar at the top to search for a document you know exists and you can access. If the search finds it, Copilot should also be able to use it (though it may take a little extra time). If SharePoint search can't find it either, let us know — that points to an indexing issue we can investigate.

**What we're doing:** We'll check your search index coverage and confirm your access to the main Finance SharePoint sites. We'll report back within two business days.

Thanks,  
DWP Engineering

---

## Ticket 8 — Executive Assistant: Copilot can't see shared mailbox calendar

**Subject:** RE: Copilot and your director's shared mailbox calendar

Hi,

Thank you for raising this. We want to be straightforward with you: this is a **current limitation of Copilot in Outlook**, not something that's broken or that we can fix with a configuration change.

Copilot in Outlook is currently designed to work with your own mailbox and calendar. Even if you have delegate or management access to your director's calendar — which you do, and that access works correctly in Outlook itself — Copilot cannot yet extend into shared mailboxes and delegate calendars in the same way.

**What this means for you:** For tasks involving your director's calendar (scheduling, summarising upcoming meetings, drafting responses on their behalf), you will need to use standard Outlook rather than Copilot for now.

**What we're doing:** We've logged this as a feature gap and will track Microsoft's roadmap updates. This is an area Microsoft is actively developing and we expect improved support in a future update. We'll let you know as soon as it becomes available for your account.

In the meantime, if there are other Copilot workflows we can help you get value from — such as drafting emails from your own mailbox or summarising your own meetings — we're happy to set up a short session.

Apologies for the inconvenience.

Thanks,  
DWP Engineering

---

*All communications prepared by DWP Engineering — 2026-08-12*
