---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# 40 Apply ALL the new UI (master list)

Back to [[00 GYM ARC Home|GYM ARC Home]] - done: [[2026-10-22 GYM ARC New UI applied]]

```text
Put EVERY new UI design from the planner into the game. This is the master list: it points to the mockups and to prompts 27, 37 and 39, which hold the detailed specs. Follow CLAUDE.md Speed rules. Mobile first (667x375 and 844x390). Never undo the owner's manual Studio changes. Work screen by screen, save after each, and keep a checklist in the progress note so a fresh session can continue.

READ FIRST
- Prompt 37 "UI style match A and B" = the shared components (ChunkyButton, RankBadge, ChunkyBar, RewardTile), the rarity colour table, the 2-font rule and the minimum text size rule.
- Prompt 27 "Trainer Agency UI redesign" = the Agency + roll reveal (rarity-scaled reveal, sounds, VFX).
- Prompt 39 "Unlock guides" = locked buttons/tabs, badges (NEW / "!"), teaser toasts, unlock guides.
If any of those is already done, skip that part and only check it matches the mockup.

MOCKUPS (the spec: match them). Folder C:\Users\kaung\Downloads\gym_arc_ui_style_match\
"Before" screenshots of the current game: C:\Users\kaung\Downloads\gym_arc_ui_current\

| Screen | Mockup file |
|---|---|
| Left nav (8 buttons, lock/NEW/! badges, POSES = flexing stick-figure icon from the current STATS button, STATS = dumbbell) | real\left_nav_badges.png |
| Main HUD (dark graphite + gold, chunky TAP TO GROW) | 05_hud_dark_chunky.png |
| Lifting / REP screen | 06_rep_screen.png |
| Title screen | real\title.png |
| Loading screen | real\loading.png |
| Store: Passes (tiles + Auto Rep hero) | 01_store_A.png |
| Store: Auras | real\store_auras.png |
| Trainer Agency: ROLL / X3 / AUTO + pity bar | 02_agency_roll_A.png, 02b_roll_closeup.png |
| Quests: Daily | real\quests_daily.png |
| Quests: Streak | real\quests_streak.png |
| Physique: Muscles | real\phys_muscles.png |
| Physique: Genes | real\phys_genes.png |
| Genetics | real\genetics.png |
| Settings (chunky toggles) | real\settings.png |
| Inventory > Items | real\inv_items.png |
| Inventory > Gear (empty state) | real\inv_gear_empty.png |
| Inventory > Auras (its own top tab, animated) | real\inv_auras_anim.mp4 (+ .gif, still inv_auras.png) |
| Inventory > Looks > Alters (animated) | real\inv_alters_anim.mp4 (+ .gif, still inv_alters.png) |
| Inventory > Looks > Titles (grid + tooltip, no side panel) | real\inv_titles.png, title text styles in real\titles_styles.png |
| Tutorial (marker over target, dim + arrow on a button, small SKIP pill) | real\tutorial.png, real\tutorial2.png |

IGNORE these older files (replaced): real\inv_alters_owned.png, 03_hud_tap_to_grow.png, 03b_tap_to_grow_closeup.png, 04_quests_claim.png, 04b_claim_closeup.png, 07_title.png, 08_physique.png, 09_loading.png.

DECISIONS TO APPLY EVERYWHERE (some were sent as quick messages; do any that aren't done yet)
- Inventory top tabs: ITEMS · GEAR · AURAS · LOOKS. Looks has only ALTERS and TITLES (no ALL tab anywhere). All tabs visible from the start; locked ones use the prompt 39 lock style.
- Store tabs in this order: PASSES · AURAS · BOOSTS · COINS. Opens on PASSES (new players before Growth Spurt 1 open on BOOSTS).
- Alters tab: owned alters with their body art + VFX, the NEXT alter teased (silhouette, EXP bar, NEXT ALTER), later alters as smaller dim "???" tiles with one moving detail, laid out as a path (Vascular under Tanned). Detail panel on the right.
- Auras tab: tiles with the big orb + its own VFX, next aura teased, "???" tiles; detail panel: name, rarity, big gold benefit pill ("+15% COINS", always bright), tall EQUIP/EQUIPPED, "SHOW EFFECT" toggle with "Boost stays active when hidden." (hiding only hides the visual).
- Titles: grid only + tooltip (tap on phones). Each tile is a nameplate: title in its rarity text style + thin rarity bar, rarity label top-left, EQUIP / gold-outlined EQUIPPED, locked = dimmed + lock + condition.
- Header counters: "OWNED x / y" on Alters ("ALTER x / y"), Auras and Titles.
- Odds: always as percentages (0.035%, never 1/1000). Secret AND Eternal trainers show as "???" until owned.
- Boosts: tap slot = hold it, tap again/activate = drink (1 s animation + cooldown, server checked). Unequipped items stay unequipped after rejoin.
- GO TO buttons teleport (fade, whoosh, 3 s cooldown) instead of walking.
- Tutorial: hide non-tutorial UI (quests, machine labels, boost popups) while it runs; real Coach Dex portrait; gold marker + arrow over targets; small dark SKIP pill top-right; shake step = "tap to hold, then tap to drink".
- Lifting voices: no screams; short strained grunts on heavy reps only, quieter, with a "Lifting voices" setting.
- Text: only 2 fonts; nothing smaller than the smallest HUD label; tile names are the loudest text.
- Rarity colours from the one table in prompt 37, everywhere.

ORDER
1. Components from prompt 37 (if not built yet).
2. Left nav + main HUD + REP screen (what players see most).
3. Inventory (all tabs) and Store.
4. Quests, Physique, Genetics, Settings.
5. Title + Loading.
6. Trainer Agency + roll reveal (prompt 27) and unlock guides/badges (prompt 39) if not done.
7. Tutorial changes.

TEST: phone size. For each screen, one screenshot next to its mockup (save in the vault Screenshots\ui_v3\). List anything you couldn't match and why. Short progress note in the vault with the checklist ticked.
```
