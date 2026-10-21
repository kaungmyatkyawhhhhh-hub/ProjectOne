---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# 25 New trainers for ranks 5-8

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Make (or replace the placeholders for) the 4 new trainers for the roll system (prompt 24): ranks 5-8. Ranks 1-4 stay the existing trainers. First tell me what you made for 5-8 in prompt 24 (screenshot), then upgrade them to these designs. Follow CLAUDE.md Speed rules. Never undo the owner's manual Studio changes.
Rules for all: original characters (no real people, no famous characters, no real brands), kids' game (clean, not scary), same body system as other NPCs (low-poly stage meshes, wide frames, never thin), shirtless or gym clothes like the others. Each rank must look clearly more impressive than the one below: bigger, more detail, a stronger aura.

5) LEGENDARY: "DUKE IRONSIDE" (veteran powerlifting coach)
- 6'9", very wide and thick (powerlifter build: huge traps, thick waist, big forearms), grey short beard, buzz cut.
- Black hoodie with the sleeves cut off, gold trim, a thick leather lifting belt, chalk on his hands, wrist wraps.
- Aura: warm gold glow + slow gold embers. Idle: claps chalk off his hands, cracks his neck.
- Line when equipped: "Lock in. No excuses."

6) MYTHIC: "VOLTA" (strongwoman coach, energetic)
- 6'10", athletic and very muscular (wide shoulders, strong legs), long high ponytail.
- Red and purple tracksuit top tied at the waist over a black training top, red knee sleeves, lightning-bolt pattern on the sleeves.
- Aura: red-purple energy with small lightning crackles (lightning flipbook tinted red/purple). Idle: bounces on her toes, shadow-boxes.
- Line: "Faster! Stronger! Again!"

7) SECRET: "THE SHADOW" (mysterious trainer)
- 7'2", huge mass-monster build, wearing a deep black hood that hides the face in shadow, with two calm glowing white eyes (not scary, more cool and mysterious).
- Black outfit with faint purple seams. Shows as a black "???" silhouette in the odds board until the player owns it.
- Aura: dark smoke wisps (smoke_shaded flipbook, dark purple) drifting up, faint purple glow at the feet. Idle: arms crossed, slowly turns his head to watch you.
- Line: "..." (shows only dots, then "Train." once).

8) ETERNAL: "ATLAS" (legendary living-statue trainer, the top rank)
- 7'6", the biggest trainer, perfect golden-ratio proportions (Classic + Mass), skin like polished white marble with gold veins (use or extend the alter skin style), a gold laurel wreath.
- Simple white and gold training shorts, gold wrist cuffs.
- Aura: white-gold glow, slow orbiting small star sparkles, soft god rays above him. A faint shimmer on the ground where he walks.
- Idle: a slow front double biceps pose every ~8 s. Line: "Strength is forever."

FOR EACH
- Uses the trainer follow / walk / run / look-at behaviors, scaled to its height.
- A portrait icon for the Agency board, the Trainers tab and the roll reveal (render it in Studio from a fixed camera, Black + Gold frame in the rarity color).
- The roll reveal uses the trainer's own pose and line.
- Performance: max ~15 aura particles per trainer, low-poly meshes, no extra shadows.

Screenshots: all 8 trainers standing side by side (rank 1 to 8, left to right), and the Agency board. Short progress note in the vault.
```

## Owner decisions on prompt 24 (given with this prompt)
```text
1) Keep the 1.6-minute roll price. Change odds instead: Mythic 0.6%, Secret 0.15%, Eternal 0.035%, Common takes the difference. Re-check the times (target Mythic ~3-4 h, Secret ~15 h) and report.
2) Replacing the old coach perks is OK, but give the Uncommon trainer +15% stamina regen on top of +10% coins. The pump perk can go.
3) Gains cap: keep the current cap before 7'0", then raise it by about +1x per alter tier. Show a small "MAX BOOST" tag in the boosts display when a player is capped. All in config.
HTTP requests: fine as you did it.
```
