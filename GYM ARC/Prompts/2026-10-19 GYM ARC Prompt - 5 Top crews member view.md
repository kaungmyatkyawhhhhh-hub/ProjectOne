---
date: 2026-10-19
tags: [gymarc, prompt]
status: todo
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 5 Top crews member view

```text
CREWS: in TOP CREWS, tapping a crew row opens that crew's member view, like MY CREW (reuse the same component, black + gold kit).
Shows read-only: name, tag, leaderboard rank, total score, member count; members with headshot, name, role, level, height, contribution, online dot; leader first then by contribution.
Buttons: REQUEST TO JOIN / JOIN / FULL / IN A CREW (greyed), and a back arrow that returns to TOP CREWS at the same scroll position. No kick/promote/leave.
Load members from the server, cache 60s, loading shimmer instead of an empty panel, "This crew no longer exists" for deleted crews. Tapping your own crew opens MY CREW.
Test phone 844x390 + PC with 1 member and a full crew; long names don't overflow. Screenshot. Commit.
```
