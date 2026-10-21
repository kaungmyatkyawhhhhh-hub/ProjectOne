---
date: 2026-10-22
tags: [gymarc, progress, ui]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC New UI applied (prompt 40)

Prompt: [[2026-10-22 GYM ARC Prompt - 40 Apply all new UI]] (specs in [[2026-10-21 GYM ARC Prompt - 37 UI style match A and B]], [[2026-10-21 GYM ARC Prompt - 27 Trainer Agency UI redesign]], [[2026-10-22 GYM ARC Prompt - 39 Unlock guides]]). Mockups: Downloads\gym_arc_ui_style_match\. Screenshots: Screenshots\ui_v3\.

## Checklist (a fresh session continues from the first open box)
- [x] 1. Components (prompt 37): ChunkyButton, RankBadge, ChunkyBar, RewardTile, rarity colour table, 2 fonts, minimum text size
- [x] 2. Left nav (done in 39b), main HUD, REP screen
- [x] 3. Inventory: Items, Gear, Auras, Looks > Alters, Looks > Titles
- [x] 3. Store: tab order PASSES · AURAS · BOOSTS · COINS, Passes tiles + hero, Auras
- [x] 4. Quests Daily, Quests Streak, Physique Muscles, Physique Genes, Genetics, Settings
- [x] 5. Title screen, Loading screen
- [x] 6. Trainer Agency + reveal (prompt 27, done trimmed), unlock guides (39, done): check against mockups
- [x] 7. Tutorial (done 22 Oct): check against tutorial.png / tutorial2.png

## Done so far
- **Components** (code commit ea71cae): ChunkyButton through the one button style (LuckiestGuy + dark stroke, 3 px outline, thick edge, green / gold / red / dark-hex), hex mesh + gold inner line on HUD cards and panels, ChunkyBar, `Theme.RarityColor` (the prompt 37 table), `Kit.RewardTile`. Numbers, labels and small titles are LuckiestGuy; screen titles, tabs and body text stay Montserrat (2 fonts).
- **Store:** PASSES · AURAS · BOOSTS · COINS, opens on PASSES (BOOSTS before Growth Spurt 1); coloured hex tiles, price pills, owned = dimmed + small green OWNED + check; requirement pills dark with a coloured outline.
- Fixed: 4 SideMenu helpers I'd dropped in 39b (only the hidden Wardrobe used one).
- Couldn't match: the top bar pills stay Roblox/TopbarPlus style (changing their font shrank the pills); shop / aura art has its own dark square backgrounds (needs new transparent art).

![[GYM ARC/Screenshots/ui_v3/store_passes.jpg]]
![[GYM ARC/Screenshots/ui_v3/store_auras.jpg]]
![[GYM ARC/Screenshots/ui_v3/title.jpg]]
![[GYM ARC/Screenshots/ui_v3/hud.jpg]]
- **Inventory** (commit 7c79f45): Items (tinted hex tiles, xN badge, empty slots, detail with YOU HAVE n / USE / EQUIP), Gear empty state (gold dumbbell, NOTHING TO WEAR YET, GO TO PUMP SHOP), Auras (OWNED x / y, wide tiles: owned / teased / ??? with a moving spark, detail with EQUIP and SHOW EFFECT: hides only your own aura's look, new setting `myAura`), Titles (rarity nameplates, lock + condition), Alters (ALTER x / 30, a winding path, banner tiles, NEXT ALTER bar, ??? later tiles, detail with GAINS and WEAR).
- **Quests, Physique, Genetics, Settings** (6a7bf50): RankBadge (S gold, A silver, B bronze, C grey, D iron), green CLAIM, "+60", DNA streak days gold; rank-metal bars; MAX GROWTH SPURT REACHED gold-edged; REROLL red / KEEP green / OVERALL gold; Settings ON gold, OFF dark.
- **Loading, REP** (f479ff4): full-width red bar, chunky words, hex tip card; REP chunky.
- Title, Agency, unlock guides, tutorial: checked, they take the new kit (no changes needed beyond the components).

## Couldn't match (and why)
- Top bar pills (coins, LVL, Daily, Quests): TopbarPlus draws them; a font change shrank them, so they stay as they are.
- Shop / aura art has its own dark square backgrounds, so tiles show a square behind the art and "locked" can't be a clean black silhouette (needs transparent PNGs).
- Alters: no body renders per alter yet, so tiles show the skin swatch, not a body.
- Auras benefit pill ("+15% COINS"): auras have no bonus in the game, so the pill only shows if an aura gets a `bonus` in Config/Auras.
- Item / boost art in Inventory > Items uses the coloured icon tiles (no shake / DNA renders for items).
- Not done: the store PASSES hero art and the HUD TAP TO GROW CTA kept their current layout; Agency X3 word still italic.

![[GYM ARC/Screenshots/ui_v3/inv_auras.jpg]]
![[GYM ARC/Screenshots/ui_v3/inv_titles.jpg]]
![[GYM ARC/Screenshots/ui_v3/inv_alters.jpg]]
![[GYM ARC/Screenshots/ui_v3/inv_items.jpg]]
![[GYM ARC/Screenshots/ui_v3/inv_gear_before_empty_state.jpg]]
![[GYM ARC/Screenshots/ui_v3/quests_streak.jpg]]
![[GYM ARC/Screenshots/ui_v3/quests_daily.jpg]]
![[GYM ARC/Screenshots/ui_v3/phys_muscles.jpg]]
![[GYM ARC/Screenshots/ui_v3/phys_genes.jpg]]
![[GYM ARC/Screenshots/ui_v3/genetics.jpg]]
![[GYM ARC/Screenshots/ui_v3/settings.jpg]]
![[GYM ARC/Screenshots/ui_v3/rep_screen.jpg]]
![[GYM ARC/Screenshots/ui_v3/loading.jpg]]
![[GYM ARC/Screenshots/ui_v3/agency.jpg]]
