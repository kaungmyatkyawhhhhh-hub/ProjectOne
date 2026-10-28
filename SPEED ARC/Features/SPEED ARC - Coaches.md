---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M2); windows redone 28 Oct (GYM ARC style)
---
# SPEED ARC - Coaches

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Original characters built from runner archetypes (no real names, faces, poses or nicknames).

## Windows and the agency (28 Oct, owner: "like GYM ARC's Trainer Agency and My Trainers")
- **COACH AGENCY = the only place to roll.** A stand in every world: the hub's kiosk on the shop row, plus one in City Park (west of the spawn plaza) and one in Big Stadium (inside the bowl by the tunnel). Each has a candy desk, a board of the 8 coach cards and a giant floating name (`builder_lib` L.agency, hub kiosk "COACH AGENCY"). The server refuses a roll more than 30 studs from an agency (`Coaches.AgencyRange`); the client says "Rolls happen at the COACH AGENCY".
- **COACH AGENCY window** (the stand's ROLL prompt): 2x4 rarity tiles. Each has a 3D coach, the rarity name in its colour and the chance; coaches you don't own yet are black silhouettes, Secret and Secret+ show "???". Owned ones get a gold check and "x2" for copies; tap a tile to see its boost. On the right: your coins, the nearest pity ("RARE IN 30 ROLLS" + bar), the gold ROLL (price or FREE ROLL), X3 (with the Faster Rolls pass, otherwise it opens the pass) and MY COACHES.
- **MY COACHES window** (the COACHES button, anywhere): EQUIPPED x/y and OWNED pills, BEST EQUIP, a COACH AGENCY button (takes you there). The grid shows 8 tiles a page (tile colour = stage: BASE sky, PRO mint, ELITE orange, LEGEND pink; name, stage, main boost, gold check when equipped) with PREV / PAGE / NEXT. The detail panel has a big tile, boost lines (SPEED / COINS / RACE PACE), "NEEDS 3x BASE 2/3" with 3 squares, EQUIP / UNEQUIP (green) and EVOLVE (pink when you have 3).
- **3D coaches, no pictures:** the server keeps one still model per coach in `ReplicatedStorage.CoachPreviews`, and `Shared/Util/CoachView` puts it in a ViewportFrame (silhouette = black). The roll card shows the 3D coach too.
- Not done: the roll reveal is still the old name roller + card (it now shows the 3D coach). A GYM ARC-style reveal (orb, burst, card) would be a next step. The coaches all use plain Roblox bodies with colours, so they look alike.

![[2026-10-28 coach agency window.jpg]]
![[2026-10-28 my coaches window.jpg]]
![[2026-10-28 park coach agency.jpg]]

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
