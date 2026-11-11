---
date: 2026-11-03
tags: [galaxy, prompt, alpha, supernova]
status: todo (Claude Code)
---
# Galaxy Incremental - next: ALPHA part 1 = the SUPERNOVA (3 Nov)
Why first: friends test build, map, island boards (pass 3) and lighting are done (progress notes 2-3 Nov). The alpha (Sat 14 Nov) needs the first reset; today a player can reach "SUPERNOVA READY" with nothing to press. Everything after it (shards, ring 2, Star tier, rank, Star Surge) hangs on it.
Then: ALPHA 2 = full tutorial 1-7 + guide book (G) + sounds; ALPHA 3 = codes + Boost Potions, players-near-you board, x2 Stardust pass, alpha badge + [ALPHA] title, funnel.

```text
GALAXY INCREMENTAL (P&L Studios XP, never GYM ARC): ALPHA PART 1 - THE SUPERNOVA. Read: Celestial Incremental\2026-11-01 Supernova Incremental - Full game design (sections 1, 2, 5, 7) + VFX plan (SUPERNOVA rows, 5 WOAH moments, anime tricks, limits) + 2026-11-02 Design additions. Numbers from the design; anything not priced -> calc in Calc\ first, PROPOSED in the note.
1) RULES (EconConfig): ready when stardust EARNED this run >= 1M. Shards = floor(10*sqrt(earned/1e6)) (+20% if Supernova Readiness). Resets: stardust, bodies, ring 1 nodes. Keeps: shards, Supernova count, rank, Essence, tutorial, island tier pieces stay but the star system shrinks back to the rock and regrows. Save version bump with a safe migration.
2) BUTTON: when ready, a big gold SUPERNOVA button on the HUD (pulsing glow, not the icon) + the INFO board shows SUPERNOVA with the shard amount + the Core beam turns gold. Tap -> a confirm card in the v12 style: YOU GET n SHARDS / KEEP / RESET, "next Supernova gives more if you wait" with the shards at +x% more earned. Never auto-pops.
3) CINEMATIC (VFX plan): ~5 s first time, ~2 s after (skip button after the first): your system's bodies pull into your star, it swells and pulses, music cuts, 1 white flash (Reduced Motion: none), 2 shockwave rings across all islands (server-wide), hand-drawn "SUPERNOVA!" stamp, shards fly into a new SHARDS counter on the HUD, rank lands over your head (SPARK at 1...), a new nebula patch stays in the sky. Others see the burst over your island. Star Surge +5% (already built).
4) SHARDS: a SHARDS counter on the HUD (next to Stardust). Spend in RING 2 on the Constellation Tree board + window: STELLAR branch for the alpha: Starfire (all x1.5, 5 levels), STAR tier unlock (Supernova 1), Binary Star (Supernova 3), Heavy Elements; price them with the rule "sensible build ~ x(1 + 0.1 * shards earned)" (calc). Other branches show as "?" / locked with their unlock text.
5) STAR body tier unlocks at Supernova 1 (row on BODIES board, planet in the system).
6) Tutorial steps 5-7 from the design (goal bar SUPERNOVA 0% -> 100% on the HUD, step 6 the button, step 7 buy Starfire) + funnel logging.
7) Pace check: real-time test from a fresh save (TestFreshSave) to the first Supernova: target 10-15 min; second run should feel ~2x faster. Report the times.
8) Screenshots: button ready, confirm card, 4 frames of the cinematic, after (rank, shards, empty system), ring 2 on the tree board, phone. Progress note.
```
