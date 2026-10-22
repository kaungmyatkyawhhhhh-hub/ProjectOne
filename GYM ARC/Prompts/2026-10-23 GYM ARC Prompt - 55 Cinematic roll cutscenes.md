---
date: 2026-10-23
tags: [gymarc, prompt]
status: todo
---
# 55 Cinematic roll cutscenes

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The owner says the spinning sunburst ("circus") behind the roll reveal is ugly. Make the trainer roll feel like an RNG game's rare-roll cutscene (the owner's reference: Sol's RNG aura cutscenes): a name roller that slows down, and for rare pulls a short cinematic IN THE WORLD around the player. Build our OWN version: our own effects, sounds and text, nothing copied from another game. Follow CLAUDE.md Speed rules. Mobile first. This changes the background/build-up of prompt 49; the card itself, the bottom bar (ROLL AGAIN / CLOSE / summary), skip and sounds rules stay. All timings in one config.

1) REMOVE
- The rotating sunburst stripes behind the card (all rarities). No big spinning rays anywhere on this screen.

2) NEW BACKGROUND (all rarities)
- The world stays visible but dark: a heavy vignette, blur, and a soft haze in the rarity colour from the bottom. A few slow particles drifting up (rarity colour). Calm, not busy.

3) THE ROLLER (every roll)
- Centre of the screen: trainer names flick past one by one, each in its rarity colour with a soft glow ("COACH SAM", "COACH NIA", "VOLTA", ...), fast at first, then slowing down like a slot machine, with a tick sound per name. The last few names hover on rarer ones to build tension. It ends on the real result.
- Common / Uncommon / Rare / Epic: the roller lasts ~1.2 s, the result name pops (scale 1.2 -> 1.0) with its sound, then the card slides up into place. No cutscene.
- X3: the roller runs once per card, lowest rarity first (prompt 49 order).

4) CINEMATIC CUTSCENE (Legendary and above)
After the roller lands on a Legendary+ name, cut to the world:
- Black letterbox bars slide in from top and bottom. All HUD hides. Music ducks to silence.
- Lighting tweens: the sky and ambient darken and tint to the rarity colour (ColorCorrection + Atmosphere tween, restored after).
- The camera slowly orbits the player (scriptable camera, ~90° over the cutscene), low angle looking up.
- Particles swirl in around the player in the rarity colour, building up; a low rumble and a rising tone.
- Peak: a beam of light hits the ground next to the player, a shockwave ring spreads over the floor, a white flash. The trainer's 3D model appears in the beam, doing his flex pose, standing beside the player.
- Camera pushes in on the two of them. Big text fades in over the scene: the trainer NAME (white, stroked, wide letter spacing), under it the rarity word in its colour and the chance as a percentage ("MYTHIC · 0.6%"). Gold shimmer sweeps across the name once.
- Then the bars slide away, lighting returns, and the card appears on the normal reveal screen (prompt 49 card + bottom bar).
- Lengths: Legendary ~3.5 s (light version: no sky change, smaller beam), Mythic ~5 s, Secret ~6 s.
- SECRET (Atlas) is special: the roller suddenly STOPS on "???" , the screen cuts to full black and silence for 1 s, a single heartbeat, a glitch flicker of the screen, then the full cutscene with white-gold light.

5) OTHER PLAYERS
- Players near you see the beam + shockwave in the world (no letterbox, no camera change). Combined with the server banner for The Shadow and Atlas (prompt 48).

6) RULES
- Tap to skip: the first tap skips the roller/cutscene straight to the card. A player's FIRST ever Mythic/Secret can't be skipped for the first 2 s.
- Auto Roll: Common-Epic show only the fast roller (0.6 s); Legendary+ play the full cutscene and stop auto roll.
- Reduced Motion: no camera orbit or shake, no flicker; a fade instead.
- Phones: keep particles low (≤ 60), no extra shadows, restore Lighting/Camera even if the player resets or leaves mid-cutscene.
- Sounds: our own layered sounds (Roblox library), music ducked during the cutscene, a short sting at the name reveal.

TEST (phone first): Common, Epic, Legendary, Mythic and Secret rolls (force in Studio), an X3 with a Legendary last, a skip mid-cutscene, Auto Roll hitting a Legendary, and a second player watching. Screenshots of each step and a short clip if possible. Short progress note in the vault.
```
