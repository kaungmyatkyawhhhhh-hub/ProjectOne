# Stomp Evolution - Iron set v1

Date: 2026-11-12 (owner said "go" at 14:48). Place saved as version 26 (not published).

## Design source
- Approved line-up v5, stage 4 (IRONBOOT): dark steel plates, cyan glow, blue chest gem, riveted plates, cyan-trimmed boots, a blade on one shoulder, a short cape.
- Owner rules applied on top: symmetric shoulders (a blade on BOTH sides, smaller), bundle body-part swap, bundle proportions, ROBLOX Boy hands, and the Stone v11 lessons (angled rims, no suit at joints, swept spikes, painted texture).
- The cape is not a body part: later, as an accessory.

## Build (iron_v1.py, from stone_v11.py)
- No moss.
- Wandering rock cracks become straight engraved glow channels (thigh: two vertical lines; shin: a line and a chevron).
- Pauldron lames faceted (8 sides) instead of round.
- The shoulder crystals become one swept blade fin per shoulder, rooted in the top plate with dome_top() and raking back and up.
- Iron vs Stone v11b size changes, applied as attachment shifts: UpperTorso (0, .0271, -.028), LowerTorso (0, 0, .0151), UpperArms (+-.1006, .0737, -.0016).

## Paint (iron_v1_paint.py, from stone_v10_paint.py)
- paint_metal():
  - steel blue plate (84,96,116), dark trim (46,52,66)
  - sky/ground reflection and a horizon highlight band
  - brushed streaks, sparse light scratches, grime in the gaps
  - dark outline on the edge with a crisp light bevel just inside
  - engraved border line on big plates
- Glow, grooves, suit cracks and spill switched to cyan. Gem is sapphire/cyan. Leather darker.

## Assets (group 33151111)
| Asset | ID |
|---|---|
| IronSet_v1 model | 115266239952023 |
| Torso | 138661678798460 |
| LeftArm | 72227016594809 |
| RightArm | 116121710670876 |
| LeftLeg | 136447146842752 |
| RightLeg | 76217958325919 |
Studio: ServerStorage.StompEvolution.Armour.Iron. ArmourKit.Apply(character, "Iron") tested in Play on the owner's avatar: 15 pieces textured.

## Notes / next
- In Studio light the steel reads lighter than in the Blender render. Fine for readability; can go darker if the owner wants gunmetal.
- Same size as Stone: the "each set bulkier" growth comes from the game's body scale.
- Test rigs in Workspace: IronTest, StoneTest, KorTest. Delete before publishing.
- Next sets: Magma, Storm, Crystal.
