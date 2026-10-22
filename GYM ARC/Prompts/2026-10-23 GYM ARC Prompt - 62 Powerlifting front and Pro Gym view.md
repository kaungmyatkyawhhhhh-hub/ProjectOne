---
date: 2026-10-23
tags: [gymarc, prompt]
status: todo
---
# 62 Powerlifting Gym front + Pro Gym window view

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Owner review of prompt 58 (screenshots). Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Back up before changing.

1) POWERLIFTING GYM: IT'S HIDDEN BEHIND THE TOWN BUILDINGS
What's wrong: it's a giant plain black box (like the old PUMP SHOP problem). From the street you only see a narrow alley between two town buildings with a small rusty door, "LOCKED" in red and a tiny sign. The Starter and Pro Gym face the street with real fronts; this one doesn't.
Fix:
- Give it a REAL street front like the other two gyms: move/remove the town buildings in front of it (back them up in ServerStorage) so its whole front wall faces the main street, lined up with the Starter Gym's front, with the same wide sidewalk. The three gyms then read as one "gym row" (Powerlifting - Starter - Pro).
- FACADE (old warehouse, raw and heavy, not a black box): red/brown brick lower walls, dark steel upper walls with vertical ribs, a row of tall industrial windows (lit from inside, so you see platforms and bars), steel beams/columns on the front, a big roll-up loading door as the entrance + a normal steel side door, wall-mounted industrial lamps (white light), a big painted sign "POWERLIFTING" across the top (white/red letters on black, lit), and smaller "GYM ARC" under it. Chalk-white paint marks / a painted barbell mural on one side wall. No blank black walls anywhere visible.
- ROOF: not a flat black slab: a sawtooth or ridged warehouse roof with skylights, vents and an AC unit or two, in dark grey.
- LOCKED STATE: the roll-up door is down with a clean black + white sign "UNLOCKS AT GROWTH SPURT 5" (white text, not red "LOCKED"), a small padlock icon, and the locked toast + progress when tapped. When unlocked, the door is rolled up and you see the gym inside.
- Size: big but not taller than the tallest town buildings next to it; footprint can shrink a bit if needed to fit the street.

2) PRO GYM WINDOWS LOOK INTO A VOID
What's wrong: the big windows show grey fog/void, a cliff edge and the backs of town buildings. No city.
Fix:
- Below the cliff (the valley), build the CITY the windows were meant to show: a ground plane (no void), a grid of streets with street lights, and blocks of buildings at different heights (low near, tall skyscrapers further away) with lit windows (SurfaceGui/Decal window textures or Neon window strips), a few landmarks (a bridge, a stadium roof, a river), and soft distant fog/haze + hills on the horizon.
- Cheap: far-away, low-poly blocks, no collisions, no shadows, Anchored; it only streams with the Pro Gym. Day and night: windows light up at night.
- From inside the Pro Gym, the view must look like a city below at every window. Check from the posing mats and the cardio row.
- Cover the cliff edge with greenery/rocks so it looks natural from the window, and hide the backs of the town buildings from that view (trees, a wall, or move the windows' view angle).

TEST: screenshots from the street in front of all three gyms, the Powerlifting front locked and unlocked, from above (same angle as the owner's), and from inside the Pro Gym at 3 windows (day + night). Short note in the vault.
```
