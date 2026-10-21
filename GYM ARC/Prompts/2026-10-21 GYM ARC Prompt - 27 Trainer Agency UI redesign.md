---
date: 2026-10-21
tags: [gymarc, prompt]
status: todo
---
# 27 Trainer Agency UI + roll reveal redesign

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text

TRAINER PORTRAITS (owner, 21 Oct): Downloads\gym_arc_trainer_portraits\ has transparent PNGs for all 8: 01_coach_sam ... 08_atlas (512 square, waist-up) and *_full.png (full body). Upload them and use these as the tile/detail/reveal art (crop to the visible pixels and fit the art area).
The owner says the Trainer Agency panel and the roll reveal look very bad. Redesign both. Follow CLAUDE.md Speed rules. UI is Black + Gold, mobile first (must fit 844x390 and 667x375; scale the whole panel with UIScale).
Files in C:\Users\kaung\Downloads\gym_arc_agency_ui\:
  now_agency.png, now_roll_card.png, now_roll_reveal.png = how it looks now
  (agency_mockup.png and agency_mockup_v2.png were both rejected; don't use them)
  now_stand.png = the stand now (rejected)
  mock_roll_at_stand.png, mock_trainers_tab.png, mock_trainers_empty.png = rejected too (too professional)
  game_agency_stand.png + game_trainers_inventory.png = rejected (too cartoony)
  kit_agency_stand.png + kit_trainers.png = THE DESIGNS TO BUILD. Silhouettes and tinted portraits are placeholders: use the real trainer portraits.

OWNER UPDATE (21 Oct): the panel mockups were rejected too. NO big Agency panel. Do it the pet-simulator egg way instead, plus a Trainers tab and a nicer stand.

0) STYLE (owner, 21 Oct: the cartoon style didn't fit the game): use the game's own BLACK + GOLD kit (Downloads\gym_arc_ui_final\, GYM_ARC_UI_final.md), with a little extra game feel. Match kit_agency_stand.png and kit_trainers.png:
- Graphite panel, heavy italic white title (no ribbon) with a short gold underline, same X button as the other panels. Kit fonts only (no cartoon font).
- Slots: dark tiles with a deep rarity-colored radial glow and faint light rays behind the trainer, a thin border in a darker rarity color, a gold border on the selected one. Empty slots dark with a faint "?".
- Odds/rarity text: rarity name small in its color, chance in white heavy italic.
- Buttons: kit CTA style. ROLL = red CTA (only red thing on screen). X3, AUTO, gear, UNEQUIP = quiet dark buttons. EVOLVE = gold. Key hints E / R / T in small dark keycaps.
- Owned/equipped = small gold check badge. Counts "x2" bottom-right in white.
- Trainers detail card: big portrait on the rarity glow, rarity word, name, "LV 14" in gold on the right, boosts as clean label/value rows, an EVOLVE 1/3 gold progress bar.
- Pills at the top (EQUIPPED 2/3 with a gold dot, OWNED 6/50 with a teal dot).
- TILE + GRID UPDATE (owner, 21 Oct, overrides the slot look above): every trainer tile uses the single tile design from prompt 33 (trainers_inventory_v5.png): dark tile, bright full-opacity art, name / glowing tier tag / colored bottom strip with LV, LuckiestGuy with a dark stroke. The Trainers screen is a dense 4-wide grid with PREV / PAGE x / y / NEXT paging (no empty slots, no "+38 more"). If prompt 33 isn't built yet, build the tile now and show every trainer as BASE.
- Owner polish (21 Oct, already in the updated mockups):
  - Trainers grid: a small "OWNED" subheader with a faint divider, the owned trainers, then just a "+ 38 MORE SLOTS" bar (no empty "?" rows).
  - Trainers the player has NOT owned yet (in the Agency odds board) are a designed "unrevealed" state: pure black silhouette with a thin rim light in the rarity color, on a brighter, high-contrast rarity burst (like the Secret "?" tile). Owned trainers always show their real render, including in the big detail preview (the black figure in kit_trainers.png's detail card is only a placeholder).
  - Detail card stats (EXP / COINS / PROGRESS) each in a small dark pill with a colored dot icon on the left (like the Store price pills).
  - Agency: the rarity name is the louder text (bigger, its color), the % under it is smaller and gray.
  - Pity bar sits in a dark pill backing like the stamina bar.
  - X3, AUTO, gear and UNEQUIP are FLAT (no bevel, no gloss, darker) so ROLL / EVOLVE are clearly the primary buttons.
  - The EQUIPPED / OWNED chips one size bigger.
- Small motion only: slots fade/scale in, the selected slot gets the gold border, evolution backgrounds animate (prompt 33).

1) ROLLING AT THE STAND (pet-sim egg style, no panel)
- When a player walks within ~15 studs of the Trainer Agency stand, the odds display appears above the stand (BillboardGui, like game_agency_stand.png): the kit panel titled "TRAINER AGENCY", the 8 trainers in 2 rows of 4 as rarity slots, the rarity name and the chance under each slot ("50%", "2%", "1/167"), and a small gold check on ones the player owns. No X button (it fades when you walk away). Secret = black "?" silhouette. Big readable portraits, no long text, no boost lines (tap/hover a portrait shows its boost in a small tooltip).
- At the same time buttons appear at the bottom center (above the hotbar): red ROLL CTA with "525 COINS" [E], quiet X3 with its cost [R], quiet AUTO ON/OFF [T] (teal glow when on), and a quiet gear button that opens a small popover with the auto-delete toggles. Above them: "EPIC GUARANTEED IN 63 ROLLS" in small gray text with a thin teal bar.
- Walk away = the display and bar fade out. Phone: big tap targets, never covers the stamina bar.

1b) TRAINERS SCREEN (the TRAINERS side button), like a pet inventory (game_trainers_inventory.png)
- Title "TRAINERS" (kit). Pills next to it: "EQUIPPED 2/3" and "OWNED 6/50" (storage).
- LEFT: a grid of slots (6 per row, scrolls), owned trainers first (rarest first), then empty "?" slots.
- RIGHT: the selected trainer's detail card (see kit_trainers.png): big portrait on its rarity glow, rarity word, name, LV, boosts as label/value rows, the EVOLVE progress (prompt 33), and buttons UNEQUIP/EQUIP (quiet) and EVOLVE (gold). The Robux "+1 SLOT" button sits under the EQUIPPED chip.
- No trainers yet: the grid shows only "?" slots, and the right card says "NO TRAINERS YET" with a red CTA "GO TO TRAINER AGENCY" that teleports to the stand (cooldown 10 s).

1c) THE STAND (owner: it looks ugly and futuristic)
- Put the Trainer Agency in the STARTER GYM (one stand, near the front desk / Coach Dex but not blocking him). Remove copies in other gyms unless they're needed; the Trainers tab can teleport players there.
- Make it look like a real gym's personal-training desk, warm and old-school, NOT futuristic: a wooden desk, a cork board on the wall behind it with the 8 trainer "photo cards" pinned on it (portraits; Secret is a covered card with "?"), a hand-lettered chalkboard sign "PERSONAL TRAINERS", a clipboard sign-up sheet, a desk lamp with warm light, a framed certificate, a shaker bottle and a small plant.
- Remove the neon yellow glowing screen/board with the text table, the dark "PERSONAL TRAINERS" banner and its small text. No LED/neon here.
- All small props sit flat on surfaces (no floating), no collisions, no shadows.

2) ROLL REVEAL (what's wrong: a plain grey card with a "?", the Agency panel stays visible behind it, the trainer is cropped and posed awkwardly, small text)
New reveal (about 2 s, tap to skip, like a pet-sim hatch):
- Same kit style as the rest of the game (graphite, gold, heavy italic). Full-screen dark backdrop (hide the Agency behind it), slight blur, a spotlight in the middle.
- A designed card BACK: black + gold with the GYM ARC logo / a dumbbell emblem and a gold border pattern (not a plain grey card).
- Build-up: the card shakes harder and harder, and its glow climbs through the rarity colors (grey -> green -> blue -> purple -> gold...) and STOPS at the rolled rarity, so the player feels the suspense. Rising sound with each color step.
- Reveal: the card flips / bursts open in the rarity color: rotating light rays behind, a shockwave ring, sparks (VFX from Downloads\gym_arc_aura_vfx), a hit sound. Bigger effects for rarer pulls (as in prompt 24 section 3).
- Show the trainer FULL BODY, centered, in a good pose (their idle/flex pose, arms not cut off), large (about 55% of the screen height), slowly turning or breathing in a ViewportFrame.
- Under it: the rarity banner (pill in the rarity color), the NAME big (Luckiest Guy, white with the rarity color outline), the boost line, the quote in a small speech bubble, and "NEW!" (gold burst) if it's the first one, otherwise "x2 · 2/5 to Golden" with a small progress bar.
- "Tap to continue" pulsing at the bottom.
- X3 rolls: 3 cards side by side, revealed left to right one after another, then all three shown together.
- Auto Roll: a faster reveal (0.6 s) unless it's Epic or better, which plays the full reveal and stops auto roll.

Test on a phone layout (667x375): the odds display, the action bar, the Trainers tab (with and without trainers), the stand, and the reveal for a Common, an Epic and a Legendary. Screenshots of each. Short progress note in the vault.
```
