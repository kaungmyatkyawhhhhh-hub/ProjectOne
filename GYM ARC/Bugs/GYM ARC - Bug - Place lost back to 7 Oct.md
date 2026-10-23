---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Place lost back to 7 Oct

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The GYM ARC cloud place fell back to about 7 Oct 21:00: all 8 Oct work in Studio was gone.
- **Cause:** The place had not been saved to Roblox since 7 Oct 9:54 PM, so the work only existed in the repo.
- **Fix:** Rebuilt in the real cloud place from the repo (370 scripts, regenerated data, builders re-run), saved to Roblox (v296-299). New rule: Save to Roblox and a dated backup after every task.
- **Commit:** de4c285

![[GYM ARC/Screenshots/rebuild_starter_gym.jpg]]
