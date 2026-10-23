---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 49 Roll reveal screen

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Rebuild the Trainer Agency ROLL REVEAL screen (single and multi-card). This replaces the trimmed card-back + flip reveal from prompt 27 (see Progress "2026-10-22 GYM ARC Trainer Agency redesign") and any earlier reveal notes. Follow CLAUDE.md Speed rules. Mobile first (667x375 and 844x390). Never undo the owner's manual Studio changes. Textures: Downloads\gym_arc_aura_vfx (shockwave_ring, spark_star, rim_glow). All timings, sizes and volumes in one config module.

1) CARD STYLE
- The trainer tile from prompt 33, at a larger scale: dark hex background (15% opacity, small cells), a 4 px outline and sunburst rays in the rarity colour, NO coloured fill.
- Trainer art fills ~65-70% of the card, 15% larger than now, vertically centred in the art area, no gap above the pill.
- Rarity pill: near-black fill, rarity-colour stroked text (readable on every tier).
- Name: stroked chunky white.
- Bonus line (e.g. "+15% EXP and coins"): stroked gold, one size larger than now.
- Duplicate line (only for dupes): a small pill "x2 · 2/3 TO IRON-BORN" (the NEXT EVOLUTION STAGE; Golden was removed, never "Golden", never "???") with a progress bar under it.
- "NEW!": a tilted gold sticker on the card's top-left corner, not a text row.
- Card height ends 20 px under the last line. No dead space.

2) RARITY SCALING
- Card size: Common/Uncommon 90%, Rare/Epic 100%, Legendary 110%, Mythic/Secret/Eternal 115% and lifted slightly, with a soft glow bleeding past the card edge and particles.
- The best card in a batch is visibly the biggest.
- Sunburst rays rotate slowly (~10°/s) on Legendary and above.

3) SCREEN CHROME
- Background dimmed to ~90% black. Gameplay HUD hidden.
- Speech bubble: dark tile style with the rarity outline (or remove it if it crowds the card on phones).
- "TAP TO CONTINUE" fully on screen, pulsing.
- After the last card: a bottom bar slides up with the batch summary ("1 NEW · 2 DUPES") and two chunky buttons: ROLL AGAIN (red, with the coin price) and CLOSE (dark, outlined).

4) ANIMATION, PER CARD (seconds)
0. Setup (0.3): background fades to 90% black, HUD hides. Batch: three dark slots appear in a row with a faint dashed outline; each card lands in its slot.
1. Orb arrival (0.3): a glowing orb in the card's rarity colour drops from above into the slot with an ease-out bounce, trailing particles in the same colour. Glow radius is the first rarity tell: small for Common, large for Legendary+.
2. Pulse:
   - Common: one quick pulse (scale 1.0 -> 1.1 -> 1.0, 0.25).
   - Uncommon / Rare: two pulses, 0.35 each, glow brighter on each.
   - Epic: three pulses slowing down (0.3, 0.4, 0.5), screen edges tint the rarity colour, a low rising tone.
   - Legendary and above: everything else darkens to black, four pulses each slower (0.3 -> 0.5 -> 0.7 -> 1.0), rising pitch, a 0.4 hold on the last beat with the orb almost still, then a camera shake tick.
3. Burst (0.15-0.4): Common/Uncommon: small burst, no flash. Others: hard white flash (0.1), the orb bursts into particles, the card snaps in with an overshoot (0 -> 1.15 -> 1.0, 0.3, ease-out back). Legendary+: the burst plays at 0.5x speed, a shockwave ring expands outward, gold rays fade in behind the card and start rotating.
4. Card dress (0.6): top to bottom with a 0.08 stagger: rarity pill slides in, name slams in (scale 1.3 -> 1.0) with a stroke flash, bonus line fades up, NEW! sticker stamps in with a slight rotate, dupe bar fills. Legendary+ names get one shimmer sweep across the text.
5. Hold: the card floats gently (±4 px, 2 s loop), the glow breathes, rays keep rotating, particles drift up.

BATCH: repeat 1-5 for each card left to right, sorted LOWEST to HIGHEST rarity, with a 0.2 gap. Revealed cards stay in their slots dimmed to 80% while the next one reveals, then all brighten together. After the last card: a 0.4 beat, then the bottom bar slides up and TAP TO CONTINUE starts pulsing.
SKIP: any tap during steps 1-4 instantly finishes that card AND every remaining card (no orbs, cards snap in with a quick pop), then shows the bottom bar. A second tap closes.
AUTO ROLL: the fast version (skip straight to snapped-in cards) unless the roll has Epic or better, which plays the full reveal and stops auto roll.
REDUCED MOTION: no shakes, no slow-motion, shorter flash. Pulses stay.

5) SOUND (per step)
- Orb arrival: soft low thud on landing + a short particle shimmer (same for all rarities).
- Pulse: one tone per pulse, rising each time. Common: one muted tick. Uncommon/Rare: two clean tones a minor third apart. Epic: three climbing tones with a low synth swell growing underneath. Legendary+: four tones climbing a full octave, the swell building to near-silence on the held beat, with a tiny heartbeat under the hold.
- Burst: Common: short pop. Uncommon/Rare: pop + light chime. Epic: whoosh + chime + bass thump. Legendary+: hard impact with a sub-bass drop, a long rising cymbal/choir shine, a slow-motion whoosh as the rays appear; the shockwave ring has its own low boom.
- Card dress: rarity pill a small click; name slam a punchy stamp hit (pitched slightly higher for higher rarities); NEW! sticker a rubber-stamp thunk; dupe bar a quick tick-tick-tick.
- Hold: a faint ambient hum looping quietly in the rarity's mood (warm for gold, cold for blue, airy for white).
- Batch: each card's sounds in turn, a soft riser between cards. After the last card: a short fanfare (two notes for a common batch, a full four-note sting if the batch has Legendary+). Bottom bar: a soft swoosh.
- Skip: one combined pop-pop-pop, no pulses; the fanfare still plays once.
- Buttons: ROLL AGAIN a chunky click + coin-spend jingle; CLOSE a soft click.
- Mix: duck gameplay music to ~30% from orb arrival until close. Every one-shot under 1.5 s except the Legendary+ shine. Higher rarity = louder and longer, capped at about +4 dB over Common so repeat rollers don't get tired of it.
- Sounds: use Roblox audio library sounds (list the IDs in the note) or build them from layered sounds. No real-brand or copyrighted audio.

TEST (phone first): single Common, Epic and Legendary reveals; an X3 batch with a Legendary last; a skip mid-batch; ROLL AGAIN and CLOSE; Auto Roll hitting an Epic. Screenshots of each (and a short clip of the Legendary). Short progress note in the vault.
```
