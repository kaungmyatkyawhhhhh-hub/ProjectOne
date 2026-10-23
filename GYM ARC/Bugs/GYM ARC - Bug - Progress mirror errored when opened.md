---
date: 2026-10-06
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Progress mirror errored when opened

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Opening the progress mirror gave an error and nothing showed.
- **Cause:** The muscle tier work called a helper (BodyService.OriginalDescription) that was never written.
- **Fix:** Helper added; the Day one / Now screen opens with no errors.
- **Commit:** b336a33
