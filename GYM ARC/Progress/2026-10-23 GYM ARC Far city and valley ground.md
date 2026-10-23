---
date: 2026-10-23
tags: [gymarc, progress, world, progym]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Far city and valley ground (prompt 62b)

Prompt: [[2026-10-23 GYM ARC Prompt - 62b Far city and valley ground|62b Far city and valley ground]]. Feature: [[GYM ARC - Pro Gym expansion]]. Game commit ae5e298.

## What changed
- **Far city** (`ReplicatedStorage.Backdrops.ProGymFarCity`, builder `tools/builders/ProGymFarCity`): 149 parts. Dark asphalt over the whole valley floor with lighter roads on the same grid as the detailed city, 57 dark blocks (one per city block, as tall as most of its buildings, coloured from them and pulled dark) and 4 landmark towers, so the skyline keeps its shape. 48 window strips glow warm / cool white at night. Also the river, the park and the 22 horizon hills. No collisions, no shadows, no details.
- **The swap** (`BackdropClient`): near the Pro Gym / east side of town the detailed city shows (as before); everywhere else (west of town, high above the town, the menu flyover) the far city shows. They are never drawn at the same time.
- **Why the ground looked bare:** with streaming on, Roblox draws far-away terrain at low detail, and that rough surface sits a few studs above the real valley floor, so it covered the city's ground and roads in the distance (also the detailed city's, near the cliffs). Both cities now stand 6 studs higher (floor y -66 instead of -72). Nobody can walk there, and from the gym windows the drop looks the same.

## Tested (Studio, PC window)
- High above the east side: before = light grey floor; after = dark ground, road grid, river, park, blocks.
- Above the west of town, day and night: the far skyline behind the gyms, window strips lit at night.
- East streets: the detailed city shows (far one hidden); before the lift the far streets were grey near the cliff, after it the roads and river show.
- Inside the Pro Gym: detailed city as before.
- No script errors.
- Not checked: a real phone screen size (MCP can only use the Studio window). The far city is 149 parts and the detailed city is unchanged, so phones draw less than before when away from the Pro Gym.

![[GYM ARC/Screenshots/p62b/high_before.jpg]]
![[GYM ARC/Screenshots/p62b/high_after.jpg]]
![[GYM ARC/Screenshots/p62b/west_above_day.jpg]]
![[GYM ARC/Screenshots/p62b/west_above_night.jpg]]
![[GYM ARC/Screenshots/p62b/east_street_before.jpg]]
![[GYM ARC/Screenshots/p62b/east_street_after.jpg]]
![[GYM ARC/Screenshots/p62b/progym_inside.jpg]]
