# Triage Summary - INC-B Copilot Potential Data Exposure

Date raised: 2026-08-14
Source: Floor 6 Monday escalation
Incident ID: INC-B (Security and Privacy Incident Track)
Prepared for: Security Incident Lead, Legal, Compliance, Privacy Officer

## Incident Statement
A Floor 6 user reports Copilot surfaced a client matter they believe is outside their entitlement.

## Correct Classification
This is a potential unauthorized information disclosure signal, not a routine support defect.

Reasoning:
- The claim is entitlement-based and confidentiality-sensitive.
- Regulatory and legal exposure risk can exist even before technical root cause is confirmed.

## What Not To Do
1. Do not close as AI odd behavior.
2. Do not ask for extra sensitive client details in uncontrolled channels.
3. Do not merge this workflow into the login/performance incident workflow.

## First 30 Minutes Triage Plan

### 0-5 minutes: Open formal security track
1. Open SEC incident and assign security incident lead.
2. Mark as potential confidentiality exposure until disproven.

Why:
- Ensures correct governance and chain-of-custody controls.

### 5-15 minutes: Preserve evidence
1. Capture exact prompt, exact response, timestamp, and app context.
2. Record user statement and environment context.
3. Preserve artifacts in approved incident repository.

Why:
- Evidence integrity is required for defensible investigation.

### 15-30 minutes: Entitlement and source-path checks
1. Validate user entitlement at event time.
2. Validate source lineage of returned content.
3. Check for token/group drift or retrieval-path mismatch.

Why:
- Distinguishes true unauthorized exposure from false-positive interpretation.

## Required Two-Sentence Escalation
We have a potential unauthorized information disclosure event: a Floor 6 user reports Copilot returned a client matter they believe is outside their entitlement. Please open a Security and Privacy incident immediately, preserve prompt-response artifacts with timestamps, and begin entitlement plus source-lineage validation with Legal and Compliance oversight.

## Evidence Observed So Far (Current Case)
1. Direct user report: user states Copilot returned a client matter they believe they were never entitled to.
2. Timing signal: report occurred in the same Monday incident window as Floor 6 operational disruption.
3. Cohort signal: user belongs to Floor 6, which received a Friday floor-targeted app deployment.
4. Missing proof artifacts (still required): no verified prompt-response capture, entitlement snapshot, or source-lineage audit has yet been attached.

Interpretation:
- Items 1-3 justify immediate security triage and preserve urgency.
- Item 4 means no final causality claim is defensible yet.

## Secondary Engineering Assumption: Treat as Potential Copilot Bug
For engineering triage only, maintain a temporary bug hypothesis in parallel:
1. Assume a possible Copilot retrieval or grounding defect until entitlement and lineage checks complete.
2. Create a product-bug subtask to test reproducibility with sanitized test data.
3. Compare results across affected user, unaffected control user, and known-good tenant policy baseline.

Important boundary:
- This bug assumption does not replace the security/privacy incident track.
- Security handling remains primary until unauthorized exposure is disproven.

## Evidence Required
1. Prompt-response artifact set with timestamps
2. User entitlement snapshot at event time
3. Source-content lineage audit
4. Incident log with legal/compliance engagement timestamps
5. Reproducibility test results from sanitized prompts (bug-hypothesis track)

## Decision Gates
- Confirmed exposure: trigger formal breach workflow and executive notification per policy.
- Not confirmed: document proof trail and closure rationale at security standard.

## Current Recommended Status
Active security/privacy incident pending entitlement and lineage validation.
