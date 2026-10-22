---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 56 Roll result card comes alive

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Roll result card (after the roller/cutscene): the owner says it feels boring (it only floats a little). Make the result screen carry the trainer's theme and feel alive. Do this AFTER prompt 55 (cutscenes); it builds on prompts 49 + 55. Follow CLAUDE.md Speed rules. Mobile first.

1) THEMED CARD BACKGROUND (no more sunburst stripes inside the card)
- Each trainer's card uses his own animated background (same themes as the prompt 55 cutscenes; Common-Epic use their rarity colour theme):
  - Volta: a dark blue storm with lightning flickering behind him and sparks crawling along the card border.
  - Duke: dark steel with glowing orange forge cracks and drifting sparks.
  - The Shadow: black-purple smoke drifting, purple eyes glinting.
  - Atlas: white-gold clouds, slow light beams, a faint laurel.
  - Common-Epic: the hex texture in the rarity colour with soft drifting particles (calm).
- The screen behind the card keeps a faint version of the same theme (lightning flashes lighting up the dark world for Volta, etc.), not just a plain blur.

2) THE CARD COMES ALIVE
- The trainer art slowly breathes/flexes (or a ViewportFrame of his model doing his flex loop), not a still picture.
- A bright highlight travels around the border (UIGradient on UIStroke), and a soft glow in the theme colour bleeds past the card edge (the glow component from the evolve button).
- The card floats gently (±4 px) and tilts slightly toward the mouse / finger.
- Legendary+: small particles escape out of the card edges (sparks, smoke, petals...).

3) TEXT
- Rarity pill: glows in its colour.
- NAME: bigger, with a shimmer sweep once.
- BOOSTS: not one tiny line. 2-3 stat rows with icons, like MY TRAINERS ("+35% EXP", "+35% COINS", "+9% PROGRESS"), popping in one by one with a tick sound.
- NEW! sticker stamps in with a bounce; dupes show the "x2 · 2/3 TO IRON-BORN" bar filling.

4) BOTTOM BAR
- "1 NEW" in white in the NEW sticker style; "TAP TO CONTINUE" pulses gently (not flat grey).
- ROLL AGAIN: red with a coin icon + price, a soft glow, press animation. CLOSE stays dark.
- The bar slides up after the stat rows finish.

5) KEEP IT LIGHT on phones (few particles, effects paused when closed). Reduced Motion: no tilt, no flicker.

TEST: result cards for Coach Sam, Coach Rex, Volta, The Shadow and Atlas (force in Studio) + an X3. Screenshots and a short clip if possible. Short progress note in the vault.
```
