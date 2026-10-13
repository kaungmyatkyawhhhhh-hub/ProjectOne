---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - NPCs stuck lying on the floor

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Gym regulars lay on the floor and never got up.
- **Cause:** Their body was re-applied while they walked, which knocked them over, and an earlier fix had also switched off getting up, so they could never stand.
- **Fix:** Falling and ragdoll states off, getting up on, the body only re-applied when needed, NPCs dressed before they start walking, and fallen NPCs are stood back up. All 12 upright over 40 s.
- **Commit:** a076754
