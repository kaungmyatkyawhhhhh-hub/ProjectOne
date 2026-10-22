---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 50 Pro Gym rearrange and makeover

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The owner says the Pro Gym is messy: e.g. one "ProTreadmill" stands alone somewhere, while 4 normal Treadmills with only the Pro SKIN stand somewhere else. Make every machine a REAL Pro machine, rearrange the whole gym, and make it look much, much better. Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes (if something looks hand-placed by the owner, keep it and mention it in the note). Before changing anything, copy the whole Pro Gym to ServerStorage.ProGymBackup_23Oct.

1) AUDIT FIRST (put the table in the progress note)
- List EVERY machine inside the Pro Gym: name, type, which config it uses (Pro or Starter), weight tiers, whether it only has the Pro skin, and where it stands.
- Mark the problems: Starter machines with a Pro skin, duplicates, machines standing alone, machines facing walls or blocking paths, anything floating or clipping.

2) EVERY MACHINE IS A REAL PRO MACHINE
- Each machine in the Pro Gym uses the Pro config: the Pro weight tiers (start at the Starter top weight and go up, prompt 36), the Pro Gym +10% gains bonus, "PRO ..." label in gold. No Starter machine with just a skin.
- Merge duplicates into clean sets: e.g. ONE row of 4 Pro Treadmills (the lone ProTreadmill joins that row). Same for every other machine type: same machines stand together.
- Keep the sub-muscle machines (they're the Pro Gym's reason to exist) and give each one the Pro look too.
- Starter Gym machines stay exactly as they are.

3) NEW LAYOUT (one big hall, clear zones)
- Zones with walking aisles between them (at least ~10 studs, so big 7'0" players and trainers fit), every machine facing INTO the room or toward a mirror, never at a wall:
  - ENTRANCE: a wide open front with a black + gold "PRO GYM" sign on the wall, the front desk, lockers, the Pro boost/shop counter if there is one. Nothing blocks the door.
  - CARDIO strip along one wall: all Pro treadmills / bikes in one row facing big windows or a screen wall.
  - FREE WEIGHTS in the middle-back: racks, benches and the dumbbell rack in front of a long mirror wall, on black rubber flooring.
  - MACHINES by muscle: chest / back / shoulders / arms / legs / abs, each group together, with a small hanging zone sign (gold text on black) over each group.
  - SUB-MUSCLE corner (the specialty machines) as its own clearly marked "ELITE" area.
  - A small stretching / posing mat area with a mirror (players love flexing there).
- Symmetry and rhythm: rows lined up on a grid, equal spacing, same facing direction in a row. It must look planned, not dropped in.

4) MAKE IT LOOK 1000x BETTER (premium, black + gold, still kid-friendly)
- Floor: black rubber tiles in the weight areas, a dark polished floor in the aisles, thin gold lines marking the zones.
- Walls: dark charcoal with gold trim, one long mirror wall, a big original GYM ARC mural (flexing-arm / dumbbell, black, gold and red, no real brands or people).
- Ceiling + light: warm spotlights over each zone (rows of hanging lamps or LED strips), a gold LED strip along the walls, slight light haze. No dark corners. Few lights with shadows; most props without shadows.
- Details: chalk bowls, plate trees with gold plates, towel racks, water fountain, benches by the walls, plants, speakers, a TV wall above cardio, a leaderboard or "PRO RECORDS" board near the entrance.
- Every machine gets the Pro look from prompt 47 (black frame, gold handles/pins, gold plates, gold-stitched pads, PRO badge, soft gold glow on the floor). Make sure it's the SAME look on every machine.

5) KEEP IT FAST
- Reuse existing models and simple parts. Props: no collisions, no shadows, Anchored. Check the part count before/after and that the Pro Gym streams in smoothly on a phone (no lag walking in).
- Keep every ProximityPrompt, teleport point, GO TO target and GuidePath target working (update positions that moved). Unlock rules and saves unchanged.

TEST (phone first): walk in from the entrance and around every zone, train on 3 Pro machines (one treadmill, one free weight, one sub-muscle) and check the Pro tiers and +10%. Screenshots: top-down view of the whole gym, the entrance, each zone, and before/after of the same corner. Short progress note in the vault with the audit table.
```
