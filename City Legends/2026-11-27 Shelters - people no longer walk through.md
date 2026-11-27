---
tags: [city-legends, pedestrians, street-props]
created: 2026-11-27
---
# Shelters: people no longer walk through them (27 Nov 2026)

**Owner:** "fix the people walking through the shelters". Follows [[2026-11-27 Street props - main roads]] and [[2026-11-27 Pedestrians - realistic people]]. Saved in Studio as version 2291, not published.

## Why it happened
The walkers' pavement paths (`streetlife_1to1.py`) were made before any shelter existed, and in Play the path ran right through the middle of a shelter. Walkers never looked at props.

## The fix
- **Tag `PedBlock`:** anything walkers must go round.
  - The street kit's shelter body template `ReplicatedStorage.YgnKit.Templates.SMT_busd` carries it (set in Studio; clones keep tags). That covers both P1's street-layer shelters and `YangonRoadside`'s own.
  - `YangonRoadside` tags its free-standing ad panels.
- **`client/YangonStreetLife`:**
  - keeps tagged parts in a 32-stud grid (added and removed as they stream);
  - `clearOf(p, kerbSide)` moves a point out of any tagged box (grown 0.9 studs) toward the kerb.
  - Each walker's next target is cleared, so they bend round in front of the shelter, between it and the kerb.
  - Its position is also cleared after each step (corners) and at spawn.
- **Standers** (people waiting at stops) are unchanged.

## Checked (Play, test store, put back on `CityLegends_v1`)
- 40 walkers over 40 s near a shelter on Kabar Aye: up to 5 near it at once, **0 inside it**.
- The ones passing it walked 3.6 studs out from its middle, on its front edge.
- Others further along the same path walked through its line (z 0.2-0.5), which shows the path itself still goes through.

![[2026-11-27 Shelters - walkers pass in front (Play).jpg]]

## Not checked
- A shelter where the pavement in front is very narrow: the walker could step onto the kerb line.
- Phones (the extra work is one grid lookup per walker step).

## Rule for later
New street furniture that walkers could walk through: add the `PedBlock` tag to its template (or the part), nothing else needed.
