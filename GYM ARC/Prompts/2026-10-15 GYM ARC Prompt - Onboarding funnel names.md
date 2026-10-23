---
date: 2026-10-15
tags: [gymarc, prompt, analytics]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: onboarding funnel step names (15 Oct)

```text
ANALYTICS: the onboarding funnel shows step 13 AND step 14 both named "First Growth Spurt" (13: 77 users, 14: 11 users, 85.7% drop).

1. Find every LogOnboardingFunnelStepEvent / funnel call. Tell me exactly what triggers step 13 and step 14 (which moment in the game, which script and line).
2. Give every step a unique, clear name that matches what it really measures, e.g. "13. Growth Spurt goal reached", "14. First Growth Spurt done" (or "Second Growth Spurt" if that's what it is).
3. Make sure each step fires only once per player ever (saved flag), never twice, and in order.
4. If step 14 really is "goal reached but spurt not done", tell me why players might not be finishing it (is the button easy to see on mobile, does it need coins, is there any error?).
5. List the full funnel (all 14 steps) with their final names in PROGRESS.md and Obsidian.
Note: renaming starts a fresh funnel in the Creator Dashboard; that's fine.
Commit.
```
