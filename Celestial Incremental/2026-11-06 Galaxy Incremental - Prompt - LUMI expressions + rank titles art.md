---
date: 2026-11-06
tags: [galaxy, prompt, lumi, ranks, titles]
---
# Galaxy Incremental - Prompt: LUMI expressions + rank titles art

Art: `Celestial Incremental\Assets\lumi\`, `Assets\titles\`, `Assets\vfx\lumi\`.
- Made with ChatGPT on 6 Nov.
- The owner chose these to replace LUMI's single Blender render (changes #114).

```text
GALAXY INCREMENTAL – LUMI EXPRESSIONS + RANK TITLE ART. Quality over speed. Don't publish.

FILES (vault Celestial Incremental\Assets\):
- lumi\lumi_{happy,talking,excited,pointing,thinking,proud}_512.png (+ _128)
- titles\rank_{new_star,spark,flare,blaze,nova,supergiant}_512.png (+ _128)
- titles\plate_{new_star,spark,flare,blaze,nova,supergiant}_1024.png (empty banners, text goes on top)
- vfx\lumi\vfx_lumi_{halo,sparkle_trail,appear_poof,heart_star,pointer,twinkle}_512_add/_alpha.png
Upload everything to the P&L Studios XP group. Put the IDs in one config module (ArtIds). Nothing hard-coded anywhere else.

1. LUMI (tutorial card, #114):
- Replace the single portrait with the 6 expressions. Each tutorial step gets an expression field:
  - talking = default line;
  - pointing = "go to this board";
  - excited = a new unlock;
  - happy = step done;
  - proud = a big milestone (Supernova, Ignition);
  - thinking = a hint or tip.
  Pick a fitting one for all 20 steps and list them in the Progress note.
- Behind the portrait: lumi_halo, slowly breathing (2.6 s).
- When the card opens: lumi_appear_poof plus a short lumi_sparkle_trail.
- When a step completes: lumi_heart_star pops (0.6 s), then the next expression.
- Pointing steps: lumi_pointer floats toward the target board on screen.
- Reduced Motion: no poof or trail, the portrait just swaps.
- Phone: card x0.8, and the portrait stays at least 72 px.

2. RANK TITLES (#271, #290, #339, #396, #257):
- Over-head title + island name plate: the plate for your rank as the background, the rank emblem on the left slot, rank text on top.
  - Text: Luckiest Guy, white, dark outline. Size it to fit; never stretch the plate (9-slice the plate image with SliceCenter so long titles fit).
- Leaderboard: a small rank emblem before each name.
- Rank-up moment after a Supernova:
  - the new emblem scales in;
  - then the plate slides in;
  - sparkle_star burst;
  - the rising chime (#257 sound if it exists, otherwise flag it).
- Ignition titles and other special titles use the same plate system: pick the plate colour that matches the title's tier.
- Everyone's plates stay readable at 60 studs. Past ~140 studs, emblem only.

3. TEST + REPORT (stop after):
- Screenshots PC + 667x375 phone of: the LUMI card in each expression, each rank's over-head title, the island name plate, the leaderboard, a rank-up strip.
- The step → expression list.
- Checklist rows updated (#114, #257, #271, #339, #396, new rows for the expressions).
```
