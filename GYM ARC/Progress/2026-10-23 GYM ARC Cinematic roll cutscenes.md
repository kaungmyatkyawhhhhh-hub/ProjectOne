---
date: 2026-10-23
tags: [gymarc, progress, trainers]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Cinematic roll cutscenes (prompt 55)

Prompts:
- [[2026-10-23 GYM ARC Prompt - 55 Cinematic roll cutscenes]]
- [[2026-10-23 GYM ARC Prompt - NEXT pill without bicep]]

Game commit 4a0c99d. Every timing is in `Config/RollReveal` (Roller, Background, Cinematic).

## What changed
- **Removed:** the orb, its pulses and every spinning sunburst behind the reveal.
- **Background (all rolls):** the world stays visible but dark: a black wash, a vignette, blur, a soft haze in the rarity colour from the bottom, and a few slow dots drifting up.
- **Roller (every roll):** trainer names flick past in their rarity colours with a tick each, slowing like a slot machine. The last 3 hover on rarer trainers, then it lands on the result with a pop and its sound.
  - Timing: ~1.2 s; Auto Roll uses a 0.6 s version.
  - Secret: it stops dead on "???" and cuts to black.
- **Cinematic (Legendary and better, `Shared/VFX/RollCinematic`):**
  - The setup: letterbox bars, all screens hidden, the music to silence, the camera low and orbiting ~90° around the player, particles swirling in, a rumble and a rising tone.
  - The peak: a beam of light hits the floor beside the player, with a shockwave ring, a white flash, and the trainer standing in the beam in his flex pose.
  - The ending: the camera pushes in, and "D U K E  I R O N S I D E" fades in (white, outlined) with "LEGENDARY · 5.75%" under it and a gold shimmer.
  - Then the bars go, and the card slides up on the reveal screen.

  | Rarity | Length | Look |
  |---|---|---|
  | Legendary | 3.5 s | light version: no colour grade, smaller beam |
  | Mythic | 5 s | screen tinted red |
  | Secret | 6 s | first 1 s of black and silence, one heartbeat, a glitch flicker, then white-gold light |

  - Everything (camera, lighting, screens, music) comes back even on a skip, a reset or an error.
- **Other players** within 150 studs see the beam and the shockwave beside you, timed to your peak. The server banner for The Shadow / Atlas is unchanged.
- **Rules:**
  - A tap skips straight to the card. A first-ever Mythic / Secret can't be skipped for 2 s.
  - Auto Roll stops on Legendary+ after the full cutscene.
  - Reduced Motion: the camera stays still, no flicker.
  - Particles ≤ 45 alive.
- **Unchanged:** the card, the bottom bar (ROLL AGAIN / CLOSE / summary) and the sounds rules. The card keeps its own still sunburst inside it; nothing turns.
- **NEXT alter pill:** the bicep icon is gone. Only the alter art, "NEXT: PUMPED", the % and "TAP FOR WHAT TO TRAIN", with the text back at the left. The icons stay in Coach Dex ALTERS, the Inventory and the popups.

## Tested (Studio 844x390)
- **Rolls:** Common (roller, card), Legendary (Volta), Mythic (The Shadow), Secret (Atlas: blackout, then "A T L A S", "SECRET · 0.15%").
- **X3 with a Legendary last:** order checked: roller → Common, roller → Rare, roller → cutscene → card → bar.
- **Skip mid-cutscene:** straight to the card; camera and colour grade restored.
- **Auto Roll** hitting a Legendary: full cutscene, then auto stops.
- **Fixed while testing:**
  - screens popping back during the cutscene;
  - the blur stacking up;
  - taps not reaching the skip.
- No script errors; the tests pass.
- **Group gift:** confirmed with a real membership: the Studio test account is in group 33151111 and got it once (+1,000 coins, the title, Coach Lou, a free roll).

## Not tested
- **A second real player watching the beam:** only the effect was triggered locally, and the reveal screen covered it.
- **By eye and ear:** the sounds and the cutscene's motion (screenshots only).
- **A real phone:** the cutscene's frame rate.
- **Note:** in Studio the test tool's first click after a window opens sometimes didn't register. The game's own button always fired on a real tap, so it looks like a tool quirk. Worth a quick check on a phone.

![[GYM ARC/Screenshots/prompt55/01_roller_background.jpg]]
![[GYM ARC/Screenshots/prompt55/02_common_card_no_rays.jpg]]
![[GYM ARC/Screenshots/prompt55/03_legendary_cutscene_build.jpg]]
![[GYM ARC/Screenshots/prompt55/04_mythic_beam_peak.jpg]]
![[GYM ARC/Screenshots/prompt55/05_mythic_card_after.jpg]]
![[GYM ARC/Screenshots/prompt55/06_secret_atlas_name.jpg]]
![[GYM ARC/Screenshots/prompt55/07_x3_legendary_last.jpg]]
![[GYM ARC/Screenshots/prompt55/08_next_pill_no_icon.jpg]]
