---
tags: [mega-bite, build-log, ant-evolution, hud, pvp]
date: 2026-11-24
---
# 2026-11-24 MEGA BITE - Ant Evolution core loop (top bar, EVOLVE button, PvP stage drop, too small to fight)

Owner, 24 Nov 06:59: "ant evolution has 20k ccu so we should be close to ant evolution".
Decided from the research ([[2026-11-24 Research - Ant Evolution (evolution + rebirth system) and Deepwoken-style slots]]); the owner's rule is to decide from research, not ask.
Follows [[2026-11-24 MEGA BITE - Title screen, slots, Evolutions window, fossil sharks]].

- **Testing:** in Studio Play, 0 script errors.
- **Not saved and not published:** the place is Team Create, so the owner saves and publishes.
- **Backups:** `*_preAntLoop_24Nov` copies of MB_PvPServer, MB_FishServer, MB_SwimServer, MB_HUD and MB_PvPClient.
- **Config switch:** `GameConfig C.Evolve = {Manual = true, DropOnPvPDeath = true, GapBlock = 3}`. Set Manual to false to get the old auto-evolve back.

## 1. Ant's top-centre bar (`StarterPlayerScripts.MB_EvoBar`, new)
- **Layout:**
  - your shark in a round 3D portrait on the left;
  - the bar showing "have / need";
  - the next shark on the right, as a silhouette until reached;
  - "NAME n/N · xM EXP" under the bar;
  - a "+1.2K" gain pop beside it.
- **Full bar:** the bar becomes a pulsing lime **EVOLVE! [R]** button (tap, R, or gamepad Y), with a one-time key toast: "EVOLVE READY! Tap the bar to become a ...".
- **At your top shark:** the bar is the gold **FOSSIL** bar with a tooth icon. When it's full it reads **FOSSILIZE!** and opens the Fossilize tab.
- **Tapping a bar that isn't full** opens the Evolutions ladder (Ant's SPECIES book).
- **HUD changes:**
  - the NEXT UP card, event pill and toasts moved down (TopCentre y 6 → 80);
  - the old fading NEXT bar and the FOSSILIZE pill are retired (the bar does both jobs).

## 2. EVOLVE is a button (MB_FishServer, MB_SwimServer)
- `evolveCheck` only sets `EvolveReady` (the shark you would become). SwimAction "Evolve" calls `_G.MB_DoEvolve`, which re-checks the bar and the fossil gate and runs the old evolve: the cutscene, the new-ability card and growth reset.
- **Tested:**
  - a new slot at 30 EXP stayed a Yellow Fish with EvolveReady 2;
  - pressing it gave "CLOWNFISH! NEW ABILITY: FRENZY!";
  - the bar then read 30 / 200 with the Barracuda as the next shark.

## 3. Red Trench PvP rules (MB_PvPServer, MB_PvPClient)
- **Too small to fight:**
  - A shark can't bite one **3 or more stages smaller**. The toast reads "Too small to fight! Hunt sharks nearer your size".
  - Tested with bots: Megalodon → Barracuda = "small"; Megalodon → Hammerhead = "ok".
- **Eaten by a player = drop one stage:**
  - The victim goes back to the start of that shark's bar (EXP = its threshold), with size reset. Then a toast: "You dropped to X! Refill its bar to evolve again".
  - Bots never take a stage, and a Yellow Fish has nothing to lose.
  - This replaces the owner's 11 Nov "eaten costs nothing", but only for player kills in the opt-in Red Trench (Ant's rule).
  - **Not tested in Play:** it needs 2 real players (Studio's Team Test with 2 clients). The code was compile-checked and the logic read through.

## Next (Ant systems still to copy, in order)
1. **MUTATE:** done 24 Nov, see [[2026-11-24 MEGA BITE - MUTATE (DNA, rolls, pity, stars, slots, packs)]].
   - DNA currency, roll 1 token / 120 DNA, x5 rolls;
   - pity: Epic+ at 25, Legendary+ at 100;
   - stars for duplicates, mutation slots (1, +1 at Fossil II, +1 by pass);
   - roll packs at 35 / 149 / 399 R$.
   - This would replace or merge MEGA BITE's per-evolution mutation cards.
2. A **TOP** leaderboard button.
3. **Lost Eggs → "Lost Teeth"** collectibles (20 hidden, +DNA each).
4. **Breeds** as Fossilize cosmetics.
5. **Pets.**
