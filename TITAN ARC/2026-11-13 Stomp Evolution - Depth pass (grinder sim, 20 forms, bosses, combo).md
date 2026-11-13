---
date: 2026-11-13
game: Stomp Evolution
build: v138
tags: [titanarc, pacing, grinder-sim, forms, bosses, combo]
---
# Stomp Evolution: depth pass (grinder sim, 20 forms, bosses, combo, statue, footprint UI), v138

Asked: "how do we make it better" → "do all in order". Based on [[K02 First session and retention]], [[K03 Incremental design and pacing]] and [[2026-11-11 Reference study - +1 Venom Evolution (art, models, UI, VFX, loop)]].

## 1. Grinder sim (hour 1 / day 7) on the LIVE v132 numbers: `Calc/grind_v1.py`, `grind_v2.py`
Live economy:
- Height = 1.7·(1+Mass/40)^0.24.
- Every click pays 1.2× the biggest prop you can smash, × (1 + 0.35·Power).
- Cards, combo, events and index multiply on top.
- AWAKEN at STAR resets for ×1.5.

**Two problems found:**

| clicks/s | STAR reached | height at 60 min |
|---|---|---|
| 3.4 (holding) | 2.5 min | 149 m |
| 1.5 (casual) | 5.4 min | 112 m |
| 0.7 (kid-sim pace) | 11.2 min | 72 m |

- **All 8 forms were done in 2.5-11 min.** By an hour you can smash everything (Crown Tower needs 90 m).
- **The AWAKEN loop collapsed.** It needed the same STAR height but compounds ×1.5 each time. Runs went 5.4 → 3.9 → 2.7 → … → 9 s. A holder did 1,270 Awakens in 30 min, so the economy was broken within the first hour.

## 2. Fix: 20 forms + AWAKEN that needs more height each time
- **Forms:** STARTER, BRAWLER, then STONE / IRON / MAGMA / STORM / CRYSTAL / STAR, each in 3 tiers (base, WARDEN, TITAN).
  - Heights: 2.4 / 3.2 / 4.2 · 5.5 / 7 / 9 · 11.5 / 14 / 17 · 21 / 25 / 30 · 35 / 41 / 48 · 56 / 65 / 75 m.
  - All tiers of a set share the same armour kit.
  - A tier shows as a stronger aura (×1.7 / ×2.6 particles, bigger) plus a glow light.
  - Character attribute: `FormTier`.
- **AWAKEN:** needs STAR TITAN and 75 m × 1.25^n (`C.AwakenNeed(n)`), still ×1.5 Mass per Awaken.
- **Power-ups:** one per evolve (19), then one every +15% of height after the top form (max 30). The hand opens 2.6 s after the evolve card.
- **Areas spread over the run:** Suburbs 2.4, Downtown 4.5, Harbour 10, Titan 28, Crown 50.
- **Quests:** form indices moved to STONE 3, IRON 6, MAGMA 9, STORM 12, CRYSTAL 15, STAR 18.
- **Sumo:** brackets = ceil(form / 5).
- **Evolve card:** "YOU EVOLVED!" or "TIER UP!", the name, one story line per set (C.FormStory, Venom-style, our own words), 20 pips, "FORM n/20". The cutscene stays at 1 s (owner rule).

**Result (sim v2/v3, with the bosses and combo below):**

| player | runs (min) | longest gap with nothing new in 30 min |
|---|---|---|
| holder | 10 → 8 → 8.6 → 10.7 → 15 → 23 | 4.3 |
| casual (chases props) | 17 → 16 → 17 → 21 → 29 → 44 | 3.4 |
| slow kid | 35 → 33 → 36 → 44 | 4.6 |

Runs now grow instead of collapse. Cards, city events every 90 s and the Rogue Alert every 8 min fill the gaps.

## 3. District bosses (`ServerScriptService.SE_Bosses`, C.Bosses)
| gate | boss | kit | HP (hits × players^0.85) |
|---|---|---|---|
| Harbour 10 m | SCRAP KING | Iron | 140 |
| Titan 28 m | STORM COLOSSUS | Storm | 280 |
| Crown 50 m | CRYSTAL TYRANT | Crystal | 450 |

- Each stands at its gate at about 2× the gate player's size.
- You stomp near its glowing feet; damage uses the same formula as the Rogue.
- It stomps every ~4 s with a knockback shockwave, but only when players are near. With nobody near it heals.
- **On death:** everyone who hit it is paid (bestProp × 60-220 × 0.3 Mass); players tall enough get the **KEY**.
  - The key is saved in `d.keys` and shown as the attribute `Key_<area>`.
  - The area opens only with height + key (`C.AreaOpen`). Lock signs say "NEED 10.0 m + BOSS"; the toast says "BEAT THE SCRAP KING TO ENTER …".
- The boss topples and gets back up after 25 s.
- **UI (SE_Modes):** a red HP panel when you are near, with the hint "STOMP ITS GLOWING FEET! KEY: …". Then "<BOSS> DEFEATED!" + "<AREA> IS OPEN!". The pay comes 4.6 s later so the evolve card doesn't cover the cards.
- Tested in Play: hits register, the kill gives the key, Harbour opens.

## 4. Stomp combo (C.Chain, `SE_Combo` client)
- +2% Mass per smash in a row, max ×25 (+50%), lost after 2.5 s without a smash.
- Only stomps that HIT a prop count; holding the click on bare ground doesn't. Otherwise it would just be a free ×1.5.
- The counter sits low in the middle, clear of the phone joystick and jump button, and hides while a window or cutscene is open.

## 5. End goal in view from spawn + UI ornament
- **STAR TITAN statue** in the plaza at (-100, 0): the real Star armour kit at scale 11 (80 studs), on a stone plinth with a gold trim, the plaque "STAR TITAN · FORM 20 · 75 m · CAN YOU GET THIS BIG?" and a soft glow.
- **Footprint ornament** (ChatGPT, one try, magenta key cut in the browser): a cracked stone slab with a gold boot print.
  - Ids: A 102110357361041, B 119344319326107.
  - `K.Footprint` in UIKit is stamped on the bottom-left (A) and top-left (B) of every window built by `UI.window` (shop, daily, top, codes, index, awaken, talents).
- Prompt: a cartoon giant boot footprint pressed into a round grey stone slab, zig-zag cracks, chips flying, gold glow inside, chunky glossy Roblox UI sticker, thick navy outline, on #FF00FF.

## Backups (ServerStorage)
Config_preForms20_13Nov, StompServer_preForms20_13Nov, TalentUI_preForms20_13Nov, StompFX_preForms20_13Nov, StompClient_preForms20_13Nov, SE_AreasClient_preBoss_13Nov, SE_Modes_preBoss_13Nov, StompServer_preCombo_13Nov, UIKit_preFootprint_13Nov.

## Studio test hook
In Studio only, `plr:SetAttribute("SE_DevMass", m)` sets that player's Mass. It never runs live.

## Still for the owner
- Play a full first run (about 20 min at a normal pace) and judge whether the WARDEN/TITAN aura steps feel different enough.
- Test a boss with 2 players.
- Phone check of the combo counter position.
- The store video is next.
