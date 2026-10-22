---
date: 2026-10-23
tags: [gymarc, prompt]
status: todo
---
# 54 Alters shop, bicep icons, and fixes

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Owner list, 23 Oct. Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Save after each part; checklist in the progress note.

UPLOAD RULE: list the images before uploading and wait for my OK; one at a time, stop at the first moderation problem.

1) BICEP ICONS FOR ALTERS (replace the flame icons and the skin circles)
Folder: C:\Users\kaung\Downloads\gym_arc_alter_bicep_icons\ (512 transparent PNGs, cartoon flexed arm):
bicep_natural, bicep_pumped, bicep_shredded, bicep_tanned, bicep_vascular, bicep_golden, bicep_peak, and bicep_base_tint (light grey, for tinting).
- Use them as THE alter icon everywhere: Coach Dex ALTERS tab, Inventory > Looks > Alters (tiles + detail panel), alter popups, the NEXT alter pill, toasts, quest rewards.
- Alters without their own icon: bicep_base_tint.png tinted with ImageColor3 = that alter's accent colour (from prompt 22's theme).
- Undiscovered / "???" alters: the same bicep as a black silhouette with a thin rim in the tier colour.
- This replaces "alter_bodies" and the skin-swatch circles. Never use body pictures for alters.

2) COACH DEX > ALTERS TAB = WORKS LIKE THE INVENTORY ALTERS TAB
Now it's a row of 5 flat cards and you can't tap them. Make it the same layout and behaviour as Inventory > Looks > Alters:
- LEFT: the grid of alter tiles (same tile design as the inventory: bicep icon, name, background theme), with header "ALTERS 2 / 30 DISCOVERED". Owned = check; the NEXT alter = its progress bar + "NEXT ALTER"; later ones = "???" UNDISCOVERED.
- Tapping a tile SELECTS it (gold border) and shows it in a DETAIL PANEL on the right: big bicep icon, name, "GAINS x1.30", "ALTER 2 · HUMAN TIER", the goal ("1.3M EXP in every group"), progress bar with %, and the button:
  - ready -> big gold "ALTER NOW"
  - in progress -> "WHAT TO TRAIN" (opens the hint)
  - owned -> "OWNED" (and "MY SKINS" opens Inventory > Alters)
  - undiscovered -> "???" and "Reach the previous alter first".
- Opens with the NEXT alter selected.

3) SELECT FEEDBACK (Inventory, Trainers, Coach Dex shop, PUMP SHOP, Store)
- Tapping any item tile: a quick bounce (scale 1.0 -> 0.92 -> 1.06 -> 1.0, ~0.25 s, back-out easing) + a short soft "select" click sound (low volume, slight random pitch ±5% so it doesn't get annoying). The detail panel content fades/slides in (0.15 s).
- Same for tabs (a lighter tick sound).

4) TRAINERS BUTTON = MY TRAINERS ONLY. AGENCY = THE ROLLING PLACE
- The left-nav TRAINERS button opens ONLY the trainer inventory (MY TRAINERS, prompt 52 layout). Remove the AGENCY tab from that window.
- The Trainer Agency (rolling) opens ONLY at the Agency desk in the Starter Gym (ProximityPrompt "ROLL TRAINERS"). It's its own window (prompt 52 Agency layout), with a small "MY TRAINERS" button in its corner.
- In MY TRAINERS, with no trainers: "GO TO TRAINER AGENCY" teleports to the desk.

5) COACH DEX BACK BEHIND HIS DESK
- The owner MOVED the desk. Do NOT move the desk. Move Coach Dex so he stands behind it again, centred, leaning on it with both forearms (his idle pose), facing out into the gym, no clipping into the counter.
- Move his shop ProximityPrompt, name sign (if separate), tutorial target, GO TO / teleport point and GuidePath target to match.

6) PHYSIQUE: "MAX GROWTH SPURT REACHED" FLICKERS
- The label switches between big and small text every frame. Find what's resizing it (TextScaled fighting a size constraint, two scripts updating it, or a loop re-setting the text) and fix it: fixed TextSize (fits the box on phones), set it ONCE when the state changes, not every frame.
- Check the other Physique labels for the same bug.

7) OVERHEAD: ALTER TAG AND CREW (CLAN) TAG OVERLAP
- Stack the overhead lines with fixed spacing, top to bottom: crew tag, name / title, alter tag (or the order that's there now), with ~4 px between lines, never on top of each other. Works for every combination (no crew, no alter, both) and for big 7'0" players.

TEST (phone first): Coach Dex ALTERS tab (select 3 different tiles), Inventory with the bicep icons, a tile tap (bounce + sound), TRAINERS button vs the Agency desk, Coach Dex behind the moved desk, Physique at max growth spurt (no flicker), and a player with a crew + alter tag. Screenshots. Short progress note in the vault.
```
