---
date: 2026-10-22
tags: [gymarc, progress, trainers]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC Roll reveal screen (prompt 49)

Prompt: [[2026-10-23 GYM ARC Prompt - 49 Roll reveal screen]]. It replaces the 27b reveal ([[2026-10-22 GYM ARC Roll reveal and trainer boost fix]]). Feature: [[GYM ARC - Personal Trainers]].

## Done
- **One config module:** `Config/RollReveal`. Every timing, size and volume of the reveal is there.
- **The card** is the trainer tile at a larger scale:
  - a dark hex base with small cells (~15%), a 4 px outline and sunburst rays in the rarity color, no colored fill;
  - his full body (~65% of the card, bigger than before), sitting right on the rarity pill;
  - a near-black rarity pill with the rarity name in its color, his NAME in white chunky with a dark stroke, his boost in stroked gold (one size up);
  - for a dupe, a small pill "X2 · 2/3 TO IRON-BORN" with a bar under it ("READY: EVOLVE TO IRON-BORN" at 3, "DUPLICATE: +9 COINS" when auto-deleted); for a new one, a tilted gold NEW! sticker on the top-left corner;
  - the card ends 20 px under its last line.
- **Rarity scaling:** Common / Uncommon 90%, Rare / Epic 100%, Legendary 110%, Mythic / Secret / Eternal 115% and lifted a little, with a bigger glow past the edge. The best card in a batch is the biggest. Legendary+ rays turn ~10°/s.
- **Fits every screen:** one shared scale for the batch, so the cards sit between Roblox's top bar (its real height + 8) and the bottom bar. Checked at 844x390 and 667x375 (Studio's `TestPhoneSize`).
- **Screen chrome:** the backdrop is ~90% black. The HUD steps aside (side menu and top bar hidden; the reveal sits over the tutorial band and toasts). The Agency window hides behind it. Gameplay music is ducked to ~30% until the reveal closes. The speech bubble (a dark tile with the rarity outline) shows only when there's room, so not on phones.
- **Per card:**
  1. the orb drops into its slot with a bounce and a trail; its glow is bigger for rarer;
  2. pulses: Common 1, Uncommon / Rare 2, Epic 3 slowing down with the edges tinting, Legendary+ 4 slowing down with everything else black and a 0.4 s hold, then a shake tick;
  3. the burst: Common / Uncommon small with no flash, the rest a hard white flash. The card snaps 0 -> 1.15 -> 1. Legendary+ plays it at half speed, with a shockwave and rays fading in;
  4. the dress, staggered: the pill slides in, the name slams 1.3 -> 1 with a stroke flash (Legendary+ also gets a gold shimmer sweep), the boost fades up, NEW! stamps in, the dupe bar fills;
  5. the hold: the card floats ±4 px, its glow breathes and a quiet hum plays.
- **Batch:** dashed dark slots in a row. The cards resolve lowest to highest; earlier ones dim to 80% while the next plays, then all brighten and the slots fade. Then a 0.4 s beat, a fanfare, and the bar slides up: "1 NEW · 2 DUPES" with TAP TO CONTINUE pulsing, ROLL AGAIN (red, with its price; "FREE" for a free roll, "SPURT 2" when X3 isn't open yet) and CLOSE (dark, outlined).
- **Skip:** a tap during a reveal finishes every card at once (a quick pop-pop-pop) and shows the bar. The next tap closes.
- **Auto Roll:** the cards snap in and close by themselves, unless the roll is Epic or better (then the full reveal plays and Auto stops).
- **Reduced Motion:** no shakes, no slow motion, a shorter, softer flash. The pulses stay.
- The Mythic lightning, Eternal stars and Legendary brass from prompt 24 still play on top of the Legendary+ burst. Rays and rings use each rarity's own color (gold for Legendary, as you asked in 27b).
- **Sounds:** layered from Roblox's library sounds the game already uses (list in [[GYM ARC - Music and Sounds]]). Rarer is louder, capped at about +4 dB over Common, and every one-shot is cut to 1.5 s except the Legendary+ shine.

## Tested (Studio, temporary save; phone first at 844x390, then 667x375)
- Single Common, Epic and Legendary reveals.
- An X3 batch with the Legendary last.
- A skip mid-batch.
- ROLL AGAIN: it used the free roll, then 90 coins, and showed the next reveal. CLOSE.
- Auto Roll: Commons snap in and close by themselves until the coins run out; with an Epic forced, the full reveal plays and Auto turns OFF.
- An X3 of three Mythic+ cards at 667x375.
- No errors.
- No video clip (owner: screenshots are fine). The Legendary sequence is in screenshots 05-07.

![[GYM ARC/Screenshots/prompt49/01_common_orb.jpg]]
![[GYM ARC/Screenshots/prompt49/02_common_final_bar.jpg]]
![[GYM ARC/Screenshots/prompt49/03_epic_pulses_edges.jpg]]
![[GYM ARC/Screenshots/prompt49/04_epic_final.jpg]]
![[GYM ARC/Screenshots/prompt49/05_legendary_darkness.jpg]]
![[GYM ARC/Screenshots/prompt49/06_legendary_burst_rays.jpg]]
![[GYM ARC/Screenshots/prompt49/07_legendary_final.jpg]]
![[GYM ARC/Screenshots/prompt49/08_x3_slots_first_card.jpg]]
![[GYM ARC/Screenshots/prompt49/09_x3_legendary_last.jpg]]
![[GYM ARC/Screenshots/prompt49/10_x3_skipped.jpg]]
![[GYM ARC/Screenshots/prompt49/11_roll_again_ready.jpg]]
![[GYM ARC/Screenshots/prompt49/12_after_roll_again.jpg]]
![[GYM ARC/Screenshots/prompt49/13_auto_roll_epic.jpg]]
![[GYM ARC/Screenshots/prompt49/14_x3_mythic_plus_667.jpg]]

## Please check by ear
- I can't hear the sounds from here. Everything is built from sounds already in the game, pitched and layered. Owner will listen and say what to change (all volumes and pitches are in `Config/RollReveal`).
