---
date: 2026-10-20
tags: [gymarc, prompt]
status: done
---
# 16 All machines in starter gym + dumbbell exercises

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Two changes. Follow CLAUDE.md Speed rules. UI is Black + Gold, mobile first. Never undo the owner's manual Studio changes. Update docs/DESIGN.md sections 2 and 15 to match.

1) STARTER GYM HAS EVERY MACHINE
- Add 1 copy of every pro gym machine to the starter gym: Dips, Lateral Raise, Reverse Fly, Shrugs, Leg Curl, Hip Thrust, Calf Raise, Bicep Curl, Tricep Pushdown, Hanging Leg Raise, Cable Woodchop.
- Use the same copy system as the beach gym (same model, config, tiers, EXP and MachineId, so unlocks, the NEW tag and quests are shared). Remove the pro gym gate for these machines (Machines.GymOpenAt).
- Fit them into the starter gym zones (machines area, cable corner, etc.). Make the room bigger if needed, keeping walkways wide. Keep the starter gym's warm brick look and check the part count. Small props stay non-colliding with no shadows.
- The tutorial path (spawn -> Flat Bench -> Squat Rack) must stay short and clear.
- Tell me: the pro gym now needs its own reason to unlock. Suggest 2-3 options (for example heavier top weight tiers only in the pro gym, or a gains bonus there), but DON'T build one yet.

2) FUNCTIONAL DUMBBELLS IN EVERY GYM
- Every dumbbell rack (starter, pro, beach) gets interact spots in front of it (ProximityPrompt "Train", E on PC, a tap on mobile). Allow several players per rack, one per spot. Starter gym: at least 6 spots.
- Interacting opens a Black + Gold exercise picker: a card grid with an icon, the exercise name and the muscles trained (names only, no percentages). Show the last used exercise first.
  - Bicep Curl: Biceps; Forearms
  - Hammer Curl: Forearms; Biceps
  - Shoulder Press: Front Delts; Side Delts, Triceps
  - Lateral Raise: Side Delts
  - Rear Delt Fly: Rear Delts; Rhomboids
  - Overhead Tricep Extension: Triceps
  - Dumbbell Shrugs: Traps; Forearms
  - One-Arm Row: Lats; Rhomboids, Biceps
  - Goblet Squat: Quads; Glutes
  - Lunges: Glutes; Quads, Hamstrings
  - Standing Calf Raise: Calves
- Picking one: the character takes the dumbbells from the rack (dumbbell models in the hands, sized by weight tier) and does the exercise with a proper animation for each one. It uses the same rep, stamina, EXP, weight tier and machine HUD systems as the machines (config table per exercise, like machines). Dumbbells give slightly less EXP than the matching machine (about 85%).
- A "Change exercise" button on the HUD reopens the picker. Leaving puts the dumbbells back on the rack.
- Weight tiers: same unlock rules as machines, shown as dumbbell size and number (10, 20, 35, 50...).
- Phones: the picker fits 667x375 and scrolls, with big tap targets.

Test: every dumbbell exercise once at g000 and gmon (no clipping with big arms), 2 players on the same rack, and a phone layout screenshot of the picker. Short progress note in the vault.
```
