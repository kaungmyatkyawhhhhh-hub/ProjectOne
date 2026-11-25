---
date: 2026-11-25
tags: [gymarc, christmas, advent-calendar, build-brief, claude-code]
---
# GYM ARC CHRISTMAS UPDATE: build brief for Claude Code (launch Sat 5 Dec)

**How to use:** tell Claude Code on the Studio PC: *"Read `GYM ARC/2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec).md` and build Phase 1. Don't publish."* Then one phase per chat.

## Read first (in this order)
1. `Brain/00 BRAIN.md` → `GYM ARC/CLAUDE.md` (the map placement rules) → `Roblox Playbook/Roblox Playbook - Rules for every game.md`
2. Decisions:
   - [[2026-11-12 GYM ARC - Christmas update decision (Advent calendar, 5 Dec)]]
   - [[2026-11-12 GYM ARC - Christmas calendar style decisions (owner OK)]]
3. Research:
   - [[2026-11-12 Research - Modern Roblox advent calendar and pass UI (videos watched)]] (the look and the reveal motion)
   - [[2026-11-12 Research - Tap Simulator REBORN secret reveal sound breakdown (measured)]] (the sound recipe)
4. Systems to REUSE, don't rebuild:
   - [[GYM ARC - Live Update Events]] (`Config/LiveEvents`, countdown, launch cutscene, `LiveEvents.Unlocked()`)
   - [[GYM ARC - Economy and Daily Rewards]] (DailyService)
   - [[GYM ARC - Body Alters]] (alter variants, `SkinStages.Alter_<id>`)
   - [[GYM ARC - UI System]] (the kit)
   - ComeBackClient (23 Nov)
5. Why it matters (25 Nov):
   - [[2026-11-25 GYM ARC - Ad creatives study (5 percent CTR, audience)]]
   - [[2026-11-24 GYM ARC - Slow revive plan to 50 CCU before Christmas]]
   - Home first-play bounce over 56 days: **15.2% < 60 s, 22.6% at 61-180 s.** The Christmas version must make minutes 1-3 stronger.

## Owner rules that apply (do not break)
- **UI:**
  - the GYM ARC kit (black + gold, kit fonts) with Tap Simulator REBORN energy;
  - **no sunburst / ring of rays anywhere**;
  - no placeholder-looking UI;
  - account for the mobile joystick + jump button zones.
- **Windows:** never open by themselves while the player is training. Reveals play OFF the machine.
- **Lighting:** never dark (the winter gym is bright and cosy, not night-blue gloom).
- **Models:**
  - HIGH quality but LOW triangles;
  - built with the `roblox-3d-model-from-sheet` skill;
  - map changes follow `GYM ARC/CLAUDE.md` (layout table → place by code → MapAudit → player-eye screenshots).
- **Sounds:** synthesized in code from the measured recipe (no Fish Audio / ElevenLabs).
- **Art** (present renders, tile backgrounds, the event icon): ChatGPT via the `roblox-chatgpt-art-pipeline` skill, one-try prompts, then cleaned. Character art: the approved icon G look (Bacon Hair, the classic "Man" face, glossy golden-orange skin).
- **Code:**
  - no mid-line comments (they caused two bugs on 18 Nov);
  - run `ThumbnailRigBuilder.RestoreTemplates()` before any save if BodyStages was required in Edit;
  - check `game.PlaceId` before editing.
- **Never publish.** The owner publishes.

## Scope (in priority order; if time runs short, cut from the bottom)
| # | Part | Must have by |
|---|---|---|
| 1 | **Advent calendar** (24 days, opened from a Christmas tree in the gym) + claim reveal + sound | 30 Nov |
| 2 | **Candy Canes** event currency (earned from training) + the day-one free present for new players (first-3-minutes hook) | 30 Nov |
| 3 | **Winter gym** (snow outside, garlands, a big tree, warm lights) + the LiveEvents launch (countdown, cutscene, reward) | 2 Dec |
| 4 | **Christmas Alters** (3 limited skins bought with Candy Canes, worn from Inventory > Alters) | 3 Dec |
| 5 | **Gift drops** in servers (a present falls every ~10 min; the first player to tap it gets Candy Canes, everyone nearby gets a small share) | 3 Dec |
| 6 | **Holiday pass** (one limited pass, ≤449 R$: x2 Candy Canes + a gold Santa-hat title) | 3 Dec |
| 7 | Test day: full checklist below, phone + PC, fixes | 4 Dec |
| - | Owner publishes early with everything hidden; launch **Sat 5 Dec 15:00 UTC** (9:30 PM Myanmar) via LiveEvents | 4-5 Dec |

## Phase 1: Advent calendar (the most important piece)
**Data and rules**
- `Config/Advent`: 24 days, each with a reward, a rarity (Common / Rare / Epic / Legendary), and `big = true` on days 7, 14, 21, 24.
- Dates (owner decision):
  - opens with the update on Sat 5 Dec, **days 1-5 claimable at once** (catch-up burst);
  - then one new day per UTC day, so **day 24 = 24 Dec**;
  - ends 6 Jan.
- Missed days are shown **frozen in ice** with a **Restore** button (Robux developer product, ~25 R$). Restore only works for days already past.
- Server pays everything. Save the claimed days set first (no double pay across servers or rejoins).
- **Reward ideas** (tune with the economy; minutes of coins at the player's stage, like `Economy.Rewards`):
  - coins
  - Candy Canes
  - serums (BEAST FORMULA / MONSTER MIX / TITAN SERUM)
  - DNA tokens
  - 1.5x EXP boosts
  - day 7: a Christmas title
  - day 14: Christmas Alter #1 (free)
  - day 21: a gold Santa hat cosmetic
  - **day 24: the Legendary "Frostbite Titan" Christmas Alter**, free only through the calendar. This is the reason to come back 24 days.

**Opening it**
- A big lit Christmas tree in each gym's lobby area (follow the map rules: facing the spawn path, 4×4 standing spot, ProximityPrompt 8-10).
- A calendar pill in the HUD right column with a red dot when a present is ready.
- Never auto-opens while training.

**Look** (Tap REBORN energy in the GYM ARC kit)
- A chunky outlined panel. Title "ADVENT CALENDAR" half outside the panel edge.
- A 6×4 grid of present tiles: 3D-rendered presents (ChatGPT art, 4 colour variants + gold for big days) that overflow their tiles.
- Day numbers in the heavy stroked kit font.
- Big-day tiles are holographic (a rainbow sheen sweeping across).
- Today's tile pulses gently. Claimed tiles show the opened box + the reward icon. Future tiles are dim with a lock. Missed tiles are under ice.
- A countdown line: "Next present in 6h 12m".

**Claim reveal** (plays off the machine)
- **Normal days, ~2.5 s, something new every ~0.3 s:**
  1. the present shakes, with light in the rarity colour leaking from its seams;
  2. a white flash;
  3. a burst of ribbon, snow and shards plus speed streaks (NO sunburst);
  4. the reward pops with a scale bounce;
  5. its name slams in;
  6. coins / canes fly to the HUD.
- **Big days (7, 14, 21, 24):** the full cutscene, a short camera shot of the tree in the gym → heartbeat → vacuum → drop → full-spectrum reveal → title slam.
- **Sound** (synthesized, from the measured research):
  - normal days: a sub thump on tap → rising ratchet ticks while it shakes (~938→1266 Hz, 0.12 s apart) → reveal impact + sparkle → a small title hit → coin ticks;
  - big days: the full recipe, a 47 Hz heartbeat (a barbell-plate thud) + air shimmer → vacuum (cut the highs) → sub drop → accelerating heartbeat (0.5 → 0.2 s) → full-spectrum reveal → title slam 1.8 s later;
  - a clean 20 ms UI click on every button.
- Reduced Motion setting: fades instead of punches.

## Phase 2: Candy Canes + the first-3-minutes hook
- **Candy Canes** (event currency, its own HUD pill during the event):
  - +1 per N reps (tune so ~40-60 an hour of normal play);
  - more from gift drops, the calendar, quests;
  - x2 with the holiday pass;
  - x1.5 in Rush Hour.
- **First 3 minutes for a NEW player during the event** (this is the bounce fix):
  - **0-30 s:** right after spawning, a present glows under the tree with "FREE GIFT!" and an arrow. Walking to it = the first claim (day 1, no tutorial block). Coins + 25 Candy Canes with the full short reveal. The tutorial continues after.
  - **Within the 1st minute:** the first visible muscle growth (already in Chapter 1: check it still lands before 60 s).
  - **Minutes 1-3:** show something to chase. A small "CHRISTMAS ALTERS: 0 / 150 🍬" goal chip appears once, with the first alter's picture.
  - **After the first Growth Spurt:** ComeBackClient shows TOMORROW's present ("Day 2: a mystery present!").
  - Analytics funnel steps: `Xmas_FreeGift_Claimed`, `Xmas_First60s_Growth`, `Xmas_GoalChip_Seen`.

## Phase 3: Winter gym + launch
- **Winter look** (gated by `LiveEvents.Unlocked("Christmas")`, removable after 6 Jan):
  - snow on roofs, ledges and the street outside;
  - garlands with warm bulbs on the racks;
  - a big tree per gym;
  - a few presents by the walls;
  - frosted window edges.
- Lighting stays bright and warm (check with the gym lighting config; never darker than now).
- Snowfall particles only outside or near windows (phone FPS: test on the A06 phone profile).
- **LiveEvents entry "Christmas":** 24 h countdown card, the launch cutscene (camera to the big tree, lights switch on, snow starts, fireworks, "CHRISTMAS UPDATE"), the launch reward (Launch Day 2 title + 30 min 1.5x), NEWS entry, the "NEW: CHRISTMAS" popup for 7 days.
- Creator Hub configs:
  - `Launch_Christmas_Time` = `2026-12-05 15:00`;
  - `Launch_Christmas_Enabled`;
  - `Xmas_Enabled` (kill switch).

## Phase 4: Christmas Alters (3)
- Reuse the alter **variant** system (a variant's skin = `SkinStages.Alter_<id>` with a new colour map; worn from Inventory > Alters; cosmetic only, no gains bonus change).
- **The three** (ChatGPT skin textures through the art pipeline, like the ELEMENTS alters):
  1. **Candy Cane:** red and white stripes, glossy.
  2. **Gingerbread:** warm brown with white icing lines.
  3. **Frostbite Titan** (calendar day 24 only, Legendary): icy white-blue with frost cracks + a soft cold glow.
- Candy Cane and Gingerbread are sold for Candy Canes (e.g. 150 / 400) at a "Christmas Shop" stall next to the tree.
- Limited: can't be bought after 6 Jan; owners keep them forever.

## Phase 5: Gift drops
- Every ~10 min per server, a present parachutes to a random open spot in the current gym (on the ground, not inside anything; reuse the loose-plate spawn spots).
- Big glow + a jingle.
- The first tap gets 30 Candy Canes; everyone within 40 studs gets 10 (co-play signal: being near friends pays).
- Despawns after 60 s.

## Phase 6: Holiday pass
- One game pass, ≤449 R$: x2 Candy Canes + a gold "Santa's Strongest" title + gold present tiles.
- Sold from the Christmas Shop and the calendar window footer (never a popup while training).

## Test checklist (Phase 7: every line PASS before the owner publishes)
**Calendar**
- [ ] New player, phone size: free gift claimed within 30 s; first growth before 60 s; goal chip seen before 3 min; 0 errors.
- [ ] Calendar: days 1-5 claimable on 5 Dec; day 6 locked until 6 Dec 00:00 UTC (test by faking the date in Studio).
- [ ] Each day pays once across rejoin + a second server.
- [ ] Missed day shows ice; Restore works only for past days.
- [ ] Big-day cutscene plays off the machine; a normal claim ≤ 3 s.
- [ ] All sounds play; none clip.

**Economy and alters**
- [ ] Candy Canes: earn rate in range (~40-60/h); pass doubles them; saved.
- [ ] Christmas Alters: buy, wear, unwear, rejoin; other players see the skin.
- [ ] Gift drop: lands on the ground, the first tap pays, nearby players get their share, despawns.

**Launch**
- [ ] LiveEvents: countdown, launch cutscene with 2 players, launch reward once, NEWS entry, the NEW popup.
- [ ] Kill switch `Xmas_Enabled` = false hides everything.

**Map, phone and performance**
- [ ] MapAudit clean; player-eye screenshots from every spawn.
- [ ] Phone FPS on the A06 profile not worse than v1914 (± 5%).
- [ ] Memory not higher than v1914 by more than 50 MB.
- [ ] Mobile: no button under the joystick / jump zones; text ≥ 14 px.

## Ads tie-in (owner)
- Ad creative #6 "CHRISTMAS UPDATE" goes live the moment the update launches (it's in `Assets\ads_creatives_25nov\`).
- The $200 burst starts 5-6 Dec: [[2026-11-25 GYM ARC - Ad creatives, the 10 for the test]].
- Update the game title for the event: `[🎄CHRISTMAS] GYM ARC` and the description's first line.

## Report after each phase
A Progress note in `GYM ARC/Progress/` with:
- what changed and where;
- screenshots (phone + PC);
- the test lines passed;
- anything not done.
