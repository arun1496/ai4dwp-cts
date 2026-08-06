# Personal AI Usage Charter (DWP Engineer, Public AI Assistants)

Version: 2026-08-03  
Applies to: My day-to-day desktop and endpoint engineering work

## Purpose
Use public AI assistants to improve speed and quality for low-risk technical work, while protecting DWP data, systems, and users.

## Scope
This charter applies when I use publicly hosted AI tools (for example, general web chat assistants) for endpoint engineering tasks on Windows desktop, device management, software packaging, patching, troubleshooting, and operational scripting.

## 1) Appropriate DWP Tasks for Public LLM Help
I may use public AI for tasks that are generic, non-sensitive, and reproducible without DWP-specific data:

1. Drafting or improving generic PowerShell patterns, command structure, error handling, logging, and script comments.
2. Creating sample scripts for common endpoint actions, such as service checks, disk cleanup logic, event log parsing, inventory collection format, or software detection methods.
3. Explaining Windows features and troubleshooting approaches at a conceptual level (for example, profile issues, startup performance, certificate chain basics, policy refresh flow).
4. Building test data structures, validation regex, CSV processing logic, and report formatting templates with mock values.
5. Producing documentation drafts: runbooks, checklists, rollback templates, and maintenance communication text that contains no sensitive details.
6. Reviewing script quality for readability, idempotency, exception handling, and safe execution practices using redacted or synthetic examples.

## 2) Tasks That Are Not Appropriate
I will not use public AI for any task requiring confidential context, privileged details, or production decision authority:

1. Sharing or analysing real DWP user records, claim data, case notes, tickets with personal identifiers, or any operational data extract.
2. Sharing hostnames, internal IP ranges, tenant identifiers, device IDs, AD group names, SCCM/Intune assignments, security tooling outputs, vulnerability findings, or incident details.
3. Asking AI to design or troubleshoot changes using real production configuration or architecture diagrams not already public.
4. Uploading logs, screenshots, memory dumps, registry exports, or command output that may contain user identifiers, machine identity, tokens, or secrets.
5. Using AI output directly as approval evidence for change, security, or compliance decisions.
6. Using AI to bypass policy controls, weaken endpoint security baselines, or automate actions beyond my role authority.

## 3) Data-Handling Rule for End-User PII and Credentials (Non-Negotiable)

1. Never paste, upload, or describe end-user PII, credentials, secrets, tokens, keys, or session artifacts into a public AI assistant.
2. Never include data that could re-identify a person or device when combined with other context.
3. If an example is needed, fully replace all sensitive values with synthetic values before prompt submission.
4. If I cannot confidently sanitize the content, I do not use public AI for that task.
5. Any accidental exposure is treated as a security incident and reported immediately through the DWP incident route.

## 4) Personal Generate-Then-Verify Rule for Scripts and System Changes
AI can generate; I remain accountable. I will not run AI-produced changes until verified.

### 4.1 Generate
Use AI to produce a first draft only.

### 4.2 Verify
I must complete all checks below before production use:

1. Read every line and confirm I understand intent and effect.
2. Validate assumptions: paths, services, registry keys, package IDs, execution context, and permissions.
3. Add safeguards: what-if mode where possible, input validation, explicit error handling, and logging.
4. Confirm rollback path and failure handling.
5. Test in a non-production endpoint or lab first.
6. Get peer review for medium or high-impact changes.
7. Run with least privilege required.
8. Capture evidence of test outcomes and approvals.

### 4.3 Deploy
Only deploy after successful validation and change control alignment. No blind copy-paste to production endpoints.

## Operational Decision Test (Before Prompting)
Proceed only if all answers are Yes:

1. Is this request generic and non-sensitive?
2. Can I describe it without DWP internal identifiers?
3. Would I be comfortable if this prompt became public?
4. Will I verify independently before execution?

If any answer is No, stop and use approved internal channels/tools instead.

## Accountability Statement
I am responsible for every command I run, every script I deploy, and every data element I share. Public AI is an assistant, not an authority.
