---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M2)
---
# SPEED ARC - Coaches

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Original characters built from runner archetypes (no real names, faces, poses or nicknames).

## How it works
- **Roll** at Coach Corner or the COACHES button: price = 1.5 minutes of coins at your league (min 50). The roll screen shows the odds and the pity counters.
- **Odds:** Benji 40% (Common), Rae Miles 28%, Ivo Dash 18%, Mara Leap 9.5%, Zephyr Reign 3.5% (Legendary), Kai Highland 0.8% (Mythic), The Flying Ghost 0.17% (Secret), Mercury 0.03% (Secret+).
- **Pity:** Rare in 30, Epic in 80, Legendary in 150, Mythic in 500 rolls without one. Saved.
- **Reveal:** name roller with rising ticks, a silent beat, then a card with rays scaled by rarity and a sound scaled by rarity. Legendary and up first play a themed cutscene under 4 s (Zephyr storm wind, Kai sunrise, Flying Ghost old film, Mercury golden temple); SKIP shows after the first time.
- **Slots:** 2 free (Config `FreeSlots`; `ExtraCoachSlot` / `ExtraCoachSlot2` passes add one each in M5). Tap EQUIP to put a coach in / out; BEST EQUIP picks the strongest.
- **Evolve:** 3 of the same coach at the same stage -> one at the next stage. BASE x1, PRO x1.5, ELITE x2.2, LEGEND x3 of the boost.
- **Caps:** all coaches together +300% training, +15% race pace, +300% coins.
- **Follow:** your first coach walks behind you (server moves it 4 times a second, the owner's machine simulates it; it hides during races; teleports if more than 45 studs away). Evolved coaches have a coloured ring at their feet. Name tag shows name + stage. Others: portrait chips under the coins.

## Studio test switches
`TestRollCoach` = coach id (forces the next roll), `TestGiveCoach` = "Zephyr,3", `TestOpenWindow` = "Coaches:ROLL" / "Coaches:ROLLNOW".

## Where it lives
`Config/Coaches`, `Server/Services/CoachService`, `Client/Controllers/CoachController`, `Util/Art` (portraits).
