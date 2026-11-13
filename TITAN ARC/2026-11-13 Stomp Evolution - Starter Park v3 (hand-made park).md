# Stomp Evolution - Starter Park v3 (13 Nov 2026, 10:50-11:15)

**Owner (10:49):** "this area look so bad". The overhead shot showed the K06 tell "empty generic map": a flat lawn with scattered tiny trees, straight paths to nowhere, and a playground alone in a field. This is the spawn district, so it is the first impression.

- Saved: v124.
- Backup: ServerStorage.Park_preRedo_13Nov (old trees, paths, benches, 30 park props). The original ground slab was split into pieces.
- Builder: ServerStorage.SE_ParkKit (smoothed paths with an edge strip and round joints, a path-distance check, keep-out zones). Everything new is in ToyTown.ParkV3.

## What's there now
- **Spawn plaza (fountain, -100,0):**
  - A round paved plaza with an inner ring.
  - Flower planters (smashable), benches with bins, and lamps.
  - 4 blossom trees in round beds.
  - The east side is open to the main street.
- **Paths:** curving paths (Catmull-Rom) connecting everything.
  - Routes: plaza → playground ring → pond loop → back down to the playground; plaza → flower garden → playground; pond → suburbs.
  - They cross the train loop on the level.
- **Pond (-255, 330):**
  - A terrain pond with a wobbly organic outline, a sandy shore and a sloped bed.
  - A path loops around it.
  - The ground slab has a hole cut for it, made from strips, with terrain grass filling the gaps.
- **Flower garden (-250, -330):**
  - A hedge square with 4 gates and cross paths.
  - 4 soil beds of 16 flowers each (smashable), and a big blossom tree in the middle.
- **Trees:** about 545 trees in groves (bigger in the middle, varied mix).
  - Groves frame the pond, playground, garden and the plaza ring.
  - North and south belts, and the west edge.
- **West hills:** terrain hills along the west edge with trees climbing them, so there is no flat edge.
- **Props:** about 73 smashable props along the paths (flowers, bins, bikes, mailboxes), 48 lamps and 23 benches. Nothing sits on the rails.

## Fixed on the way
SE_Modes had a syntax error that I introduced (a comment swallowed an `end`), so the INDEX/SUMO buttons didn't load. It's fixed and checked in Play.

## Open
- The terrain grass around the pond is a slightly different green from the part slab (colour tuned to 124,204,84). Trees hide most of it.
- The pond has no ducks or lily pads yet. Those would be new models, so they need the model-from-sheet skill.
