# MEGA BITE - Titan steals built (body growth, size tags, crown) - 11 Nov 2026

Built from [[2026-11-11 MEGA BITE - Prompt - Titan Simulator steals (body growth, size tag, crown)]] (items 1-4), in the Mega Bite place with the free-ocean HUD v3. **Not playtested and not published** (owner tests on his phone). Checked without Play: every changed script compiles; an Edit-mode test scaled a Hammerhead built the way the server builds it (x1.089 then x1.2): mesh, bones and the root ball all scaled together, pivot unchanged.

## 1. The body really grows
- **Server-replicated scale** (cheaper than telling every client): MB_SwimServer `grow()` calls `Model:ScaleTo(BaseScale x SizeMult)` on the player's shark; scale, Weld C0s and bones replicate, so everyone sees it. 0.35 s in 5 steps: up to x1.06 overshoot, then settle. `Fx "Grow"` → a bubble ring (AbilityVFX.EatPop) for everyone + the SizeUp sound for the owner.
- Welds: the shark body is now joined to SwimRoot with **Weld (explicit C0)** instead of WeldConstraint, so ScaleTo scales the joint and it replicates.
- Model attributes: `Length`/`Height` = body as drawn now (camera, bite reach, nose ray, rock bounce, predator contact); `BaseLength`/`BaseHeight` (at SizeMult 1); `EatLength` = source model length (what you can eat / what can eat you: tied to the evolution, never to growth); `BaseScale`.
- MB_Swim: the controller's length/height follow the Length attribute live (camera distance + zoom limits + nose ray). Rock bounce already uses the root ball size (scales).
- **BonePlayer**: clip translations now scale with the model: it remembers the scale the clips were fitted at and refits when `Model:GetScale()` changes (checked every 0.25 s). Studs-based clips (ReefSharkClips) use the new `SrcScale` attribute on the source models in MegaBite.Sharks. (This also makes the scaled predators' translations correct.)
- Edible: `C.Fish.SizeUpAffectsEdible = false`; MB_FishServer (eat, flee, ink), MB_FishClient (outlines/padlocks), MB_PredatorServer (canEat), MB_PredatorClient all use EatLength for "who can eat whom".
- **Growth schedule**: SizeMult follows how far you are into your tier (EXP + carried): complete at `SizeUpAt = 0.8` of the EXP to the next evolution, in steps of `SizeUpStep = 0.02`, never shrinks; it also updates on bank/quest/Index EXP. Megalodon (no next tier) grows by bites (+0.02 per 8 bites).
- **Shrink bug fixed + decision**: with the real model lengths (Minnow 7, Piranha 9, Barracuda 16, **Reef Shark 16**, Hammerhead 22, Great White 28, Megalodon 40 studs) the spec's 0.6 caps would make evolving look smaller (and Barracuda/Reef Shark were the same length). So:
  - new `bodyScale` per evolution = a monotone body ladder x1.36 per tier: **7.0, 9.5, 12.9, 17.6, 24.0, 32.6, 44.3 studs** (Barracuda drawn 20% smaller, the others 6-16% bigger). Looks only; eating uses the source length.
  - `sizeUpMax` per evolution: **0.22** (Hammerhead **0.2** as specced: 4.5 x 1.2 = 5.4 = 0.9 x 6.0; Megalodon **0.6**). Biggest of each tier ≤ 0.9 x the next tier in HUD metres AND in studs.
  - The evolve resets SizeMult BEFORE the model swap (no flash of the old growth).

| Evolution | bodyScale | sizeUpMax | studs base → max | HUD m base → max |
|---|---|---|---|---|
| Minnow | 1.0 | 0.22 | 7.0 → 8.5 | 0.10 → 0.12 |
| Piranha | 1.058 | 0.22 | 9.5 → 11.6 | 0.30 → 0.37 |
| Barracuda | 0.809 | 0.22 | 12.9 → 15.8 | 1.2 → 1.46 |
| Reef Shark | 1.101 | 0.22 | 17.6 → 21.5 | 2.5 → 3.05 |
| Hammerhead | 1.089 | 0.2 | 24.0 → 28.7 | 4.5 → 5.4 |
| Great White | 1.163 | 0.22 | 32.6 → 39.7 | 6.0 → 7.3 |
| Megalodon | 1.107 | 0.6 | 44.3 → 70.8 | 18 → 28.8 |

## 2. Size tag over every OTHER shark (MB_SharkTags, new)
Crown (if they hold it) / display name / [badge] "4.5 m · HAMMERHEAD". Badge by shape: up chevron on coral = bigger than you, down chevron on kelp = smaller, "=" on white = within 5%. Studs-sized (10 x 3.4) so it shrinks with distance, MaxDistance 140, AlwaysOnTop off, max 12 nearest (checked once a second). Content updates only on Evo/SizeMult/Crown/Height signals (and when YOU grow). `C.SizeTag` in GameConfig.

## 3+4. The crown (MB_CrownServer + ServerStorage.MB_Crown, new)
Every 2 s with 2+ players: biggest = Evo, then SizeMult, then EXP; moves only after 6 s strictly bigger and at most every 20 s (`C.Crown`). Player attribute `Crown` drives the tag crown and a crown on your own SIZE icon (HUD v3). One toast for everyone with the drawn Crown icon (the v3 toast now supports an icon): "<name> is the BIGGEST SHARK · 6.0 m" / "YOU are the BIGGEST SHARK!" + reused sounds (Evolve for you, BankDing for others). Hook: `require(ServerStorage.MB_Crown).Changed:Connect(function(newPlr, oldPlr) end)`. Analytics `Crown_Taken` (evo, size). No reward/bounty yet.

## Rules kept for later
- Red Trench: when the crown shark is beaten, everyone who bit it in the last 10 s shares the bounty.
- Launch gate: Fossilize tier 1 must exist before a public launch (the HUD says MAX at Megalodon).

## Owner phone test checklist
Grow a few steps (does the body visibly grow with a bubble pop? camera OK?), evolve (never looks smaller?), tail/fin animation at the biggest size, a second player for tags + crown.
