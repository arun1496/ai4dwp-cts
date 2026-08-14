# Copilot Incident Handling (Security/Privacy)

## What this actually is
This is not a normal support defect ticket. It is a potential unauthorized information disclosure signal and must be treated as a security/privacy incident until disproven.

Reasoning:
- The user claim is entitlement-based ("I should not have access"), not usability-based.
- Entitlement boundaries and content lineage must be validated under incident controls.

## What not to do
- Do not close as "AI weirdness".
- Do not continue broad troubleshooting before evidence capture.
- Do not ask users to post client-identifying matter details in public tools.

## Two-Sentence Escalation (Required)
We have a potential unauthorized information disclosure event: a Floor 6 user reports Copilot returned a client matter they believe is outside their entitlement. Please open a Security/Privacy incident immediately, preserve prompt-response artifacts with timestamps, and start entitlement plus source-lineage validation with Legal/Compliance oversight.

## Minimum Security Evidence Bundle
1. Prompt/response artifact with timestamp and context.
2. User entitlement snapshot at event time.
3. Source data lineage for returned content.
4. Initial legal/compliance incident log entry.

## Pass/Fail Marker for Exercise
Correct handling requires classifying this as a security signal first, then validating facts. Treating it as a routine bug is incorrect.
