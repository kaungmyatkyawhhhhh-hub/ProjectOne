---
date: 2026-11-02
tags: [gymarc, progress, runcards]
status: built and tested in Studio, not published, locked until the GEM event
---
# GYM ARC - Run Cards built (2 Nov, Claude Code)

Prompt 105. How it works: [[GYM ARC - Run Cards]]. Screenshots: `GYM ARC/Screenshots/runcards/`.

## Tested in Studio
- An Alter 7 save from before the update got 7 picks waiting (save version 1 -> 2). An Alter 15 save got 15.
- The RUN CARDS card shows in the right column with the count; it stays hidden during the tutorial.
- Pick window: 3 cards with rarity tags and colours. Picking saves the card, and the next 3 come in. Reroll gives 3 new cards once, then shows "REROLL USED". The odds sheet works.
- MY BUILD: the totals per type, "1 card this run", "1 legacy".
- Hall of Fame: the keep window picks the best card first. A new life keeps the card as a legacy card and clears the run's cards and waiting picks. A card you no longer hold can't be kept. Turning a legacy card off and on works.
- The bonuses reach the gains math (an Arms card = +12% biceps EXP).
- No script errors.

## Fixed while testing
- The pick window was too short: the cards' bonus lines were cut off. It's taller now.
- After a pick, the new cards stayed dimmed. A dim fade still running overwrote the new look.
- The tracker called its methods wrong (count and text didn't show), and it showed during the tutorial.
- The keep window and the legacy tiles cut off two-line bonuses.
- **Not Run Cards (owner's report):** "[BodyStages] biceps reshape skipped ... Failed to load mesh" x14. The 14 arm stage templates had empty meshes; I restored them from the backup record. See [[GYM ARC - Muscles and Bodies]].

## Not done
- Phone-size screenshots: the Studio window can't be resized from here. The windows use the same Kit.Modal as Store and Physique, which scale down.
- Seen while testing (not Run Cards): on a fresh test save, the daily streak window sometimes opened again after Claim + Close. Not looked into.

## Switches
Locked until the GEM event (Config/LiveEvents "Gem" is `enabled = false` until Friday). Creator Hub `RunCards_Enabled`.
