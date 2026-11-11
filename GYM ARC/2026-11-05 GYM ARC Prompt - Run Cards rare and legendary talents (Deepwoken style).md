---
date: 2026-11-05
tags: [gymarc, runcards, prompt, design]
---
# GYM ARC - Prompt: Run Cards, Rare + Legendary = talents (Deepwoken style)

Owner (5 Nov): "the rare shouldnt be more boost multipliers, it should be rare cards like from deepwoken and legendary cards from deepwoken".
Today ([[GYM ARC - Run Cards]]): every card is the same stat at 4 sizes (Common +12% … Legendary +60%).
Deepwoken (Pocket Tactics guide): talents come in common / rare / advanced rarities; they ADD A MECHANIC, often with conditions and prerequisites - e.g. Aerogliding (rare: hold space to glide, needs 35 Galebreathe + 30 agility), Spine Cutter (rare: a second slash when you hit an enemy's back after a roll cancel), Alloyblood (advanced: bleed halved, your bleed +15%), Brazen Blow (common: hyper armor vs enemies you slowed). Commons can be small stats; rares change how you play; prerequisites gate them.

## Design
- COMMON = stat cards (keep today's Common values).
- RARE = a new rule that changes how you train (situational, needs you to play a certain way).
- LEGENDARY = build-defining, with a prerequisite (Deepwoken-style), shown on the card.
- Remove the Rare/Epic/Legendary % versions from new offers; cards players already hold KEEP working (shown as "Classic").

## Rare talents (draft, numbers for Claude Code to tune)
| Card | Does |
|---|---|
| Second Wind | When stamina hits 0, refill 30% (once every 3 min) |
| Mind-Muscle | Same machine 10 reps in a row → +30% EXP until you switch |
| Heavy Day | Reps on your heaviest unlocked weight: +25% EXP |
| Negative Reps | Every 10th rep counts twice |
| Spotter's Call | Another player within 15 studs: you both +10% EXP (stacks to 3 players) |
| Lucky Plate | 2% per rep: a coin burst (20x that rep's coins) |
| Iron Lungs | Cardio/treadmill refills stamina 2x faster |
| Rest-Pause | After 20 s rest, the next 15 reps +40% EXP |
| Specialist | Your highest muscle group +20% EXP (lopsided builds) |

## Legendary talents (prerequisite on the card)
| Card | Needs | Does |
|---|---|---|
| Adrenaline | 2 Rare cards | A Growth Spurt starts a 30 s frenzy: reps 2x faster |
| Titan's Grip | Heavy Day | Every NEW PR this run: +5% EXP for the rest of the run (max +50%) |
| Golden Hour | Lucky Plate | Every 5 min, 30 s of 3x coins (gold screen edge + sound) |
| Unbreakable | Second Wind | At 0 stamina you keep repping at 50% EXP |
| Lopsided Legend | Specialist | If one group's EXP is 2x every other group's, that group +60% |
| Iron Bond | Spotter's Call | Spotting / training next to a friend: your trainers' bonus x1.5 |

## v2 (owner 5 Nov: "check deepwoken logic too, rare cards are more like some stuff than just boosts")
Deepwoken logic: a rare talent gives you something NEW TO DO or something NEW THAT HAPPENS (Aerogliding = hold space to glide; Spine Cutter = an extra slash after a roll cancel; Scorched Peak = lightning strikes on a condition), often with only a small stat on top. So: Rare = an ability/action or a visible triggered event, not a % boost. Names kept so the 15 icons still fit.
| Card | Rarity | New "stuff" |
|---|---|---|
| Second Wind | R | At 0 stamina a BREATHE button appears: tap 3 times in rhythm -> refill 60% (90 s cooldown) |
| Mind-Muscle | R | A timing ring on the rep button: a rep in the sweet spot counts x2 + a "PERFECT" pop (skill) |
| Heavy Day | R | MAX OUT button every 2 min: one huge slow rep worth 25 reps, floor-slam VFX + sound |
| Negative Reps | R | Hold the rep button for a slow rep worth 3 reps (choose tap vs hold) |
| Spotter's Call | R | Walk up to any lifting player -> SPOT prompt: they get +10% for 30 s, you get coins |
| Lucky Plate | R | Reps sometimes drop a gem shard on the floor; walk over it for coins |
| Iron Lungs | R | Double-tap to SPRINT anywhere; sprinting refills stamina like a treadmill |
| Rest-Pause | R | Sit on any bench: stamina refills 3x faster and the next 15 reps +40% (chalk-cloud VFX) |
| Specialist | R | Pick a focus muscle at the Progress Mirror: it grows visibly faster (+20% EXP), changeable once per alter |
| Adrenaline | L (needs 2 Rares) | Body Alter / Growth Spurt -> 30 s frenzy: reps 2x faster, red screen edge, heartbeat |
| Titan's Grip | L (needs Heavy Day) | Every new heaviest weight = a PR ATTEMPT moment: hold to lift, floor cracks, server message |
| Golden Hour | L (needs Lucky Plate) | Every 5 min, 30 s gold time: 3x coins, gold screen edge |
| Unbreakable | L (needs Second Wind) | Stamina never fully empties: at 0 you keep repping at 50% |
| Lopsided Legend | L (needs Specialist) | Your focus muscle can grow past max size visually + that group +60% if 2x every other |
| Iron Bond | L (needs Spotter's Call) | Link with a friend: while you train within 20 studs, 25% of each other's rep EXP is shared to both |
