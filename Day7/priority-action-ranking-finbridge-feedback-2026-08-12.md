# Priority Action Ranking — FinBridge Win11 Migration Feedback
**Date:** 2026-08-12  
**Source:** 50 post-migration end-user comments, clustered into 10 themes  
**Ranking method:** Impact tier first (Blocker > Friction > Minor), then within Blocker tier: workaround availability, data integrity risk, and systemic indicators — not volume

---

## Rank 1 — Account Lockout
**Theme count:** 5 comments | **Severity:** Blocker

**Why it ranks here:**  
Complete work stoppage with no workaround — a locked account cannot be self-resolved. Repeat lockouts (one user locked out three times in a week) are a strong indicator of a systemic policy or MFA configuration fault introduced during migration, not isolated bad-password events. Ranks above the higher-volume Printer theme because the printer team has a workaround (walk to floor 2); lockout has none.

**Manager summary:**  
Five users have been locked out post-migration — several repeatedly — suggesting a systemic identity or policy configuration fault causing full work stoppages with no self-service recovery path.

---

## Rank 2 — OneDrive Files Missing or Not Syncing
**Theme count:** 4 comments | **Severity:** Blocker

**Why it ranks here:**  
Data integrity risk elevates this above other Blockers of similar or higher volume. Missing files cannot be worked around — and at least two users have active same-day deadlines (client meeting, Q1 report). If files are genuinely lost rather than pending sync, the recovery window is narrow and closing.

**Manager summary:**  
Four FinBridge staff report missing OneDrive files after migration with at least two facing same-day deadlines, making this a time-sensitive data-integrity risk requiring immediate triage before end of business today.

---

## Rank 3 — Shared Drive Inaccessible
**Theme count:** 3 comments | **Severity:** Blocker

**Why it ranks here:**  
No workaround exists for a permission-denied shared drive. Month-end financial reporting is explicitly blocked, and the S: drive is a team-wide dependency. Ranks above the Floor 3 Printer (higher volume) because the printer team has an active workaround; these users are fully stopped on time-critical financial deliverables with no alternative path.

**Manager summary:**  
Three users — including at least one mid month-end reporting — cannot access the finance shared drive at all since migration, with no workaround available and a direct impact on financial deliverables.

---

## Themes not in top 3 (for reference)

| Theme | Count | Severity | Reason not ranked |
|---|---|---|---|
| Floor 3 Printer Not Mapping | 6 | Blocker | Workaround exists (walk to floor 2); disruptive but not a complete work stoppage |
| AVD Access Failure | 2 | Blocker | Blocker but lowest volume among complete-stoppage themes |
| VPN Instability | 4 | Friction | Friction tier ranks below all Blockers |
| Slow Login | 3 | Friction | Friction tier |
| Missing Shortcuts | 3 | Friction | Friction tier |
| UI / Cosmetic Changes | 11 | Minor | Highest volume but lowest impact tier |
| Positive Experience | 9 | Positive | No action required |
