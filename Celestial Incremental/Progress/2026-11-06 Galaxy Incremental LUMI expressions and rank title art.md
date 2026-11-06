---
date: 2026-11-06
tags: [galaxy, progress, tutorial, ui]
status: built and tested in Studio; NOT published, place NOT saved to Roblox
---
# Galaxy Incremental - LUMI expressions + rank title art (6 Nov, Claude Code)

Your prompt "LUMI EXPRESSIONS + RANK TITLE ART" (6 Nov).

Checklist rows: **#114 #257 #271 #339 #396** + new **#495 #496 #497**.

## Art ids
- **42 files** from `Assets/lumi`, `Assets/titles`, `Assets/vfx/lumi`, all uploaded.
- **One config: `ReplicatedStorage.Galaxy.ArtIds`**, which holds every id; there are no ids anywhere else:
  - lumi / lumi128
  - lumiFx / lumiFxAdd
  - rank / rank128
  - plate
- The old single LUMI portrait id is gone from EconConfig.
- **FLAG: Studio test uploads under your account.** Please bulk-import to the **P&L Studios XP group** and swap the ids in ArtIds.

## 1. LUMI (#114, new #495 #496)
- **6 expressions.** Each tutorial step has a `face` (EconConfig.Tutorial).
- **happy** is shown for 0.6 s when any step is done, with the **heart star** popping, then the next step's face.

| step | goal | face |
|---|---|---|
| 1 | UPGRADE your Asteroid | pointing |
| 2 | PERK: FIRST LIGHT | excited |
| 3 | Build your island: STONE ISLAND | pointing |
| 4 | UNLOCK the Moon | excited |
| 5 | +BODY: a 2nd Asteroid | thinking |
| 6 | Tap 2 comets | talking |
| 7 | Asteroid to ROCK (Lv 10) | talking |
| 8 | UNLOCK the Planet | excited |
| 9 | Build 4 island pads | pointing |
| 10 | Reach Cosmic LVL 3 | thinking |
| 11 | UNLOCK the Gas Giant | excited |
| 12 | Grow to 100% SUPERNOVA | thinking |
| 13 | Go SUPERNOVA! | proud |
| 14 | TREE: buy STARFIRE | pointing |
| 15 | TREE: open the STAR | excited |
| 16 | Go SUPERNOVA again | talking |
| 17 | Build 12 island pads | pointing |
| 18 | Cosmic LVL 10: new PERKS | excited |
| 19 | Go SUPERNOVA 6 times | proud |
| 20 | Light SECTOR 1: IGNITION | proud |

- **Why:**
  - pointing = a board or pad you walk to
  - excited = a new unlock
  - thinking = a step that needs a tip (copies, levels, the 100% wait)
  - proud = Supernova + Ignition
  - talking = the rest
- **Halo:** lumi_halo behind the portrait, breathing (2.6 s a breath).
- **Card opens:** lumi_appear_poof + a short lumi_sparkle_trail flying in, and LUMI pops in.
- **Pointing steps:** lumi_pointer floats from LUMI toward the board / pad / button on screen, every 1.6 s.
- **Reduced Motion:** no poof, trail, heart or pointer, and the halo doesn't breathe. The portrait just swaps.
- **Phone:** card x0.8. The portrait grows inside the card to stay at least 72 px; it measured **83 px** on the 667x375 frame and pops out above the card.
- **Screens:** `lumi-6-expressions-pc`, `lumi-6-expressions-phone-667x375`.

## 2. RANK TITLES (#271 #339 #396, new #497)
- **New kit component `ReplicatedStorage.Galaxy.RankPlate`:**
  - the rank's plate is the background
  - the rank emblem sits in the plate's left slot
  - the title is on top in **Luckiest Guy**, white with a dark outline
- **The plate is 9-sliced** (SliceCenter on a plain strip of the bar): a long title widens the bar, and the ends + the emblem slot never stretch.
- **Rank → art:**
  - NEW STAR / RISING STAR → new_star
  - SPARK → spark
  - FLARE → flare
  - BLAZE → blaze
  - NOVA → nova
  - SUPERGIANT, HYPERGIANT, QUASAR → supergiant (6 plates for 7 bands)
- **Over the head:**
  - plate + a sparkle with your Supernovas
  - your Forge COLLECTOR title as a gold line under it
  - sized in pixels (30 PC / 26 phone), so it reads at 60 studs and more
  - **past 140 studs only the emblem**
- **Island name plate:**
  - the owner's name in Luckiest Guy, the rank plate, then "GALAXY 22% · ✦17"
  - past 140 studs, the emblem only
- **Leaderboards (TOP SUPERNOVAS wall + PLAYERS NEAR YOU):** a small rank emblem before every row, picked from the row's Supernovas (SPARK at 1 ... SUPERGIANT at 12).
- **Rank-up after a Supernova:**
  - the new emblem scales in
  - the plate + title slide in
  - a sparkle_star burst
  - the rising chime
- **Screens:**
  - `titles-all-plates-60px-and-30px` (every plate, plus a long title)
  - `overhead-every-rank-pc`
  - `island-plate-pc`, `leaderboard-emblems-pc`
  - `rankup-pc-1`, `rankup-pc-2`
  - `phone-overhead-nova`, `phone-island-plate`
- **Bug found + fixed:** the over-head tag was drawn 3 times (two quick rebuilds while the text was being measured). The measure no longer waits.

## FLAGS
1. **#257 sound:** there's no rank-up sound of its own. I used a rising 3-note chime (the buy-body bell pitched up, like the Forge's Rare). The SFX plan's chime arpeggio needs a licensed stinger.
2. **Special / Ignition titles:** RankPlate has `keyOfTier(n)` to pick a plate by tier, but the Forge COLLECTOR titles still show as a plain gold line under the plate. No special title uses its own plate yet.
3. **Not screenshotted:** the leaderboard and the rank-up on phone, the pointer floating, and Reduced Motion.
4. **Re-upload to the group** (see Art ids).
