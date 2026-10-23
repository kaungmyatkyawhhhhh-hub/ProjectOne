---
date: 2026-10-15
tags: [gymarc, prompt, feature]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: tap a crew in TOP CREWS to see its members (15 Oct)

```text
CREWS: in the TOP CREWS tab, tapping a crew row opens that crew's member view, like MY CREW.

1. Reuse the same member view component as MY CREW (same layout, same black + gold kit). Don't build a second version.
2. It shows, read-only:
   - Crew name, tag, rank on the leaderboard, total crew score, member count (e.g. 8 / 20).
   - Member list: avatar headshot, name, role (Leader / Officer / Member), level, height, their contribution score, online dot (green if in any server, only if cheap to know; otherwise just "in this server").
   - Sorted: leader first, then by contribution.
3. Buttons (not the MY CREW management ones, no kick/promote/leave):
   - "REQUEST TO JOIN" if the player has no crew and the crew is open (or "JOIN" if it's public), "FULL" greyed out if full, "IN A CREW" greyed out if the player is already in another crew.
   - A back arrow (top-left) to return to the TOP CREWS list, keeping the scroll position.
4. Data: load the crew's members from the server (DataStore/MemoryStore), cache it for 60s, and show a loading shimmer for the rows instead of an empty panel. Handle crews that were deleted (show "This crew no longer exists").
5. Tapping your own crew in TOP CREWS opens MY CREW instead.
6. Test on phone 844x390 and PC with a crew of 1 and a full crew. Long names must not overflow. Screenshot. Commit, update PROGRESS.md and Obsidian.
```
