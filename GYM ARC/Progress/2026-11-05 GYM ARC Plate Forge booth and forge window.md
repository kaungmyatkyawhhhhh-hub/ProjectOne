---
date: 2026-11-05
tags: [gymarc, progress, plates, ui, gem-update]
---
# GYM ARC - Plate Forge: booth + forge window (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plates: [[2026-11-04 GYM ARC Prompt - Plate tiers FINAL (7 Nov part 9)]] · Look: `GYM ARC/Assets/plates/gymarc_plates_concept_v3.png`

In Studio only. **Not published.** No player data, weights, PRs or coins changed. Old booth kept in `ServerStorage.PlateForgeBackup_5Nov`. Builder: `ClaudeOne/tools/builders/PlateForgeBooth.luau`.

![[GYM ARC/Screenshots/2026-11-05_plate_forge/01_booth_before.jpg]]
![[GYM ARC/Screenshots/2026-11-05_plate_forge/04_booth_after_bronze.jpg]]

## Booth (Gem Mine)
1. **Rack:** dark steel wall rack, two rows, a peg per plate. The 7 real in-game plates (`PlateLook`, the same plates as on the bars: band, recessed face, hub, M WEIGHTS + number up close), sized by tier (Standard smallest → Diamond biggest), tilted 10° to the walkway. An engraved steel tag under each: name in the tier colour + price.
   - Per player (local): **OWNED** in colour with a slow shine sweep, tag "OWNED"; **NEXT** in colour under a small pulsing spotlight, gold NEXT tag, tag "NEXT · price"; **LOCKED** dark silhouette + lock. Ruby / Diamond glow only when owned.
   - A white key light on the rack so Silver / Platinum / Gold keep their colours (the fire light alone turned them all orange).
2. **Sign:** forged steel plate with a steel frame and rivets, "PLATE FORGE" embossed, hot-orange edge, a few embers falling off it.
3. **Forge:** fire in the furnace (flames + flickering orange light, range ~16), embers rising, light smoke from the chimney. Brann swings his hammer: 3 hits then a rest (~4 s), sparks + a quiet 3D clank each hit. The half-forged plate on the anvil cools from orange to steel and heats again. Quench barrel: dark water (no Glass) with steam.
4. **Smith:** Brann now stands at the anvil, hammer in hand, prompt **"Open Plate Forge"** on him. The bench's Shop prompt stays.
5. **Light + ground:** steel diamond plate under the anvil; the neon outline is gone: dark edge stones with glowing lava cracks (zig-zag). Bench: 3 stacks of bronze / silver / gold bars + tongs.
6. **Perf:** every emitter, the flicker, the swing and the shine stop beyond 60 studs. Booth: 192 parts, 6 emitters, 6 lights (fire, rack, NEXT spot, hot plate, Ruby / Diamond glow when owned).

## Forge window (UI kit)
![[GYM ARC/Screenshots/2026-11-05_plate_forge/05_forge_window.jpg]]
- Opens from: Brann, the bench prompt, tapping the rack (within 12 studs), the weight panel's Plate Forge tap.
- Title PLATE FORGE + "n / 7 TIERS". Left: the picked plate turning slowly, name in its colour. Middle: the 7-tier ladder (plate, name, OWNED / NEXT / LOCKED, price); NEXT picked first.
- Right: real game numbers: "+13 heavier weights on every machine", "Your top on <best machine>: X lb → Y lb (your strength today: Z lb)", the strength for the first new weight per machine type ("Flat Bench · needs Mid Chest 15.6M exp", green when met), price, one BUY (grey with the reason: "Need n more coins", "Forge Bronze first", "Owned").
- **Buy moment** (~2 s, tap to skip, Reduced Motion = short): dim, the plate drops on an anvil, 3 hammer hits with sparks + clanks, red-hot → its colour, stamp "BRONZE PLATES FORGED", toast "Heavier weights unlocked on every machine"; the rack lights it up. ![[GYM ARC/Screenshots/2026-11-05_plate_forge/06_buy_moment_hits.jpg]] ![[GYM ARC/Screenshots/2026-11-05_plate_forge/07_buy_moment_stamp.jpg]]
- Buying still goes through the old server path (`PumpShopService` → `PlayerData.BuyPlateTier`: order, coins, place). No timers, no discounts.

## Tested (Studio, temporary save: FreshPlayer + test coins, Gem Mine opened with the test switch)
- Bought Bronze through the window: coins 5,001,000 → 4,951,000, 2 / 7 TIERS, Silver became NEXT, rack updated, toast shown, tap-to-skip works, no console errors.
- Rack states for a new player and after Bronze (screens above). Smith swing + sparks running.
- Phone layout flag on: same window (Kit scales it).

## Not done / differences (honest)
- **≤50 triangles per plate:** not possible with the real plate (the outer plate mesh is ~1,120 triangles). The rack uses the real plates (7 of them) so they match the bars.
- **"+8 heavier weights":** the game has 13 steps per tier (owner's 13-per-side rule, 4 Nov), so the window says +13.
- **"Main shop PLATES tab":** not added: owner rule of 4 Nov says plates are sold only at the Forge (Coach Dex's PLATES tab was removed). Tell me if you want a PLATES tab back somewhere.
- Before the Gem launch, every Gem Mine light is off in Studio (pre-launch rule), so the booth's lights were switched on locally for the screenshots. Check the booth right after the launch.
- FPS: Studio PC with the test tools attached ~38 average (noisy). Not tested on a real phone, not in a 2-player server. Brann still has the default face.
- Studio test switch added: `TestForgeHold` (seconds the stamp stays, Studio only).
