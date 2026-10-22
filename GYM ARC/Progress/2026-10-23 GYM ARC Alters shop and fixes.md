---
date: 2026-10-23
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Alters shop, bicep icons and fixes

Prompts:
- [[2026-10-23 GYM ARC Prompt - 54 Alters shop, bicep icons, fixes]]
- [[2026-10-23 GYM ARC Prompt - NEXT alter pill full art]]
- [[2026-10-23 GYM ARC Prompt - Strength leaderstat]]
- [[2026-10-23 GYM ARC Prompt - Alter ready pill and popup]]
- "ALTERS x / 30 UNLOCKED" (asked in chat)

Game commits 84f7ae8 and 3149b92.

## Prompt 54 checklist
- [x] **1. Bicep icons.**
  - All 8 uploaded with your OK, one at a time, no moderation problems.
  - Ids are in `Config/AlterThemes.Icons`:

    | Icon | Id |
    |---|---|
    | natural | 130526825586547 |
    | pumped | 137729197869293 |
    | shredded | 71992766167225 |
    | tanned | 128096768249425 |
    | vascular | 120797137969021 |
    | golden | 109478944715600 |
    | peak | 123133557518612 |
    | base tint | 82746046688271 |

  - `Shared/UI/AlterIcon` shows them in Inventory alters (tiles + detail), Coach Dex's ALTERS tab and the NEXT pill. They replace the skin circles.
  - Alters without their own picture use the grey base tinted with the alter's accent.
  - "???" alters are a black silhouette with a thin rim in the tier colour.
- [x] **2. Coach Dex > ALTERS** is the Inventory alters layout (tiles + detail, 3 columns) and opens on the next alter.
  - A tap selects the tile (gold border).
  - The detail shows GAINS, ALTER n · TIER, the goal and a bar with %.
  - **Buttons:**
    - ALTER NOW when ready;
    - WHAT TO TRAIN while in progress;
    - OWNED + MY SKINS when reached;
    - "Reach the previous alter first" for "???".
- [x] **3. Select feedback.**
  - **Item tiles:** a bounce (1, 0.92, 1.06, 1) and a soft select click (quiet, ±5% pitch), and the detail slides and fades in. This covers Inventory, alters, auras, trainers, the shops and the Store.
  - **Tabs:** a lighter tick.
  - **One sound per tap.**
- [x] **4. TRAINERS** opens only MY TRAINERS.
  - The Agency opens only at the desk; its MY TRAINERS button switches over and carries the new-trainer dot.
  - With no trainers, the "GO TO TRAINER AGENCY" teleport still works.
- [x] **5. Coach Dex** stands centred behind the moved desk, facing into the gym and leaning on it (`Quests.CoachSpot`). The desk wasn't touched. His prompt, name tag, GO TO and tutorial target follow him.
- [x] **6. Physique flicker** is fixed.
  - **Cause:** `Kit.Fit` refitted the self-sizing label every time its own size changed, a loop of 9, 10 and 16 px.
  - **Fix:** a fixed 12 px label that fits the pill, and `Kit.Fit` no longer refits self-sizing labels.
- [x] **7. Overhead lines** stack with a fixed gap above the head, bottom to top: ALTER pill, title, crew tag. A missing line takes no room.

## The other requests
- **NEXT pill art:** the alter art fills the whole pill (clipped to the corners) under a dark gradient (55% on the left, 25% on the right) and drifts slowly sideways. It stays still with Reduced Motion on.
- **Alters header:** "ALTERS 1 / 30 UNLOCKED" (the alters you've reached).
- **Strength leaderstat:** "Strength" (all muscle EXP, the same number as your STRENGTH label) is on the player list for everyone and updates as muscles change.
- **Alter ready pill:** the same pill as while progressing.
  - "PUMPED READY" in the alter's colour with a dark outline, "TAP TO ALTER" in white, a gold "!" chip in place of the %.
  - The outline pulses in the alter's colour and the art drifts faster.
  - A tap opens the BODY ALTER READY popup.
- **BODY ALTER READY popup:** 15% narrower, same height.
  - Text: no arm icon; "ALTER 1" small and white; "x1.15 GAINS" in a gold pill with a dark outline.
  - **ALTER:** the alter's colour, a faint texture of its art, a 3 px dark outline, a 6 px darker bottom edge, a soft glow.
  - **LATER:** graphite, the same outline, edge and height.
  - Both press down into their bottom edge.
  - Every alter's popup uses this layout in its own colour.
- **Also fixed:** a short one-line toast was cut off with "...".

## Tested (Studio, temporary save, a 7'0" player)
- **844x390:**
  - the NEXT pill progressing and ready, and tapping the ready pill opens the popup;
  - the popup;
  - Physique at max (0 size changes in 90 frames);
  - Inventory and Coach Dex alters (3 tiles picked);
  - TRAINERS vs the Agency desk;
  - Dex behind the desk;
  - the overhead stack;
  - Strength going from 0 to 104,474,118.
- **667x375:** the popup.
- No script errors; the tests pass.

## Not tested
- The bounce and the sounds (screenshots can't show motion or sound).
- A second real player seeing your Strength.

![[GYM ARC/Screenshots/prompt54/01_next_card_bicep.jpg]]
![[GYM ARC/Screenshots/prompt54/02_physique_max_no_flicker.jpg]]
![[GYM ARC/Screenshots/prompt54/03_inventory_alters_bicep.jpg]]
![[GYM ARC/Screenshots/prompt54/04_coach_alters_next.jpg]]
![[GYM ARC/Screenshots/prompt54/05_coach_alters_owned.jpg]]
![[GYM ARC/Screenshots/prompt54/06_coach_alters_undiscovered.jpg]]
![[GYM ARC/Screenshots/prompt54/07_trainers_button_my_trainers.jpg]]
![[GYM ARC/Screenshots/prompt54/08_agency_desk.jpg]]
![[GYM ARC/Screenshots/prompt54/09_dex_behind_desk.jpg]]
![[GYM ARC/Screenshots/prompt54/10_dex_side.jpg]]
![[GYM ARC/Screenshots/prompt54/11_overhead_stack.jpg]]
![[GYM ARC/Screenshots/prompt54/12_next_pill_progressing.jpg]]
![[GYM ARC/Screenshots/prompt54/13_next_pill_ready.jpg]]
![[GYM ARC/Screenshots/prompt54/14_alter_popup_844.jpg]]
![[GYM ARC/Screenshots/prompt54/15_alter_popup_667.jpg]]
