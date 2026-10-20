---
date: 2026-10-20
tags: [gymarc, prompt]
status: done
---
# 16 Beta tester badge

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Add a "BETA TESTER" badge award. Badge ID: <471600537426484>.
- Server: on PlayerAdded, if not BadgeService:UserHasBadgeAsync, call AwardBadge. Wrap both in pcall, retry once after 5 s, never block joining.
- Put the badge ID and a BETA_BADGE_ENABLED = true flag in the config module, so I can turn it off when beta ends.
- Show a small Black + Gold toast "BETA TESTER badge earned!" only the first time.
- Don't award in Studio test sessions.
```
