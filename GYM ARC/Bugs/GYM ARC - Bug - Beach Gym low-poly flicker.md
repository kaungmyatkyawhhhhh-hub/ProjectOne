---
date: 2026-11-01
tags: [gymarc, bug, performance, streaming]
---
# Bug: Beach Gym flickers to a low-poly version (1 Nov)
Owner: "sometimes the map glitches out and it goes to the low poly version for less than a millisecond and flickers in beach gym".
- Cause: Workspace.Town.BeachGym (one 110 x 98 stud model, 2,209 parts, players walk inside it) had Model.LevelOfDetail = StreamingMesh. With instance streaming on, Roblox draws a low-resolution "imposter" mesh of a StreamingMesh model while it is (partly) streamed out; inside a big model its far parts stream in/out as you move, so the imposter flashes in for a frame.
- Fix: BeachGym and the ClothingStore (players also walk inside) LevelOfDetail = Disabled (attribute LodNote says why). The 38 town buildings you never enter keep StreamingMesh (that's what it's for: far scenery).
- Not WorldLodClient (that only hides small/medium props 140+ studs away on slow devices).
- Can't be reproduced in Studio (no real streaming delay): check on live after publishing.
- Rule for later: never StreamingMesh on a model players go inside.
