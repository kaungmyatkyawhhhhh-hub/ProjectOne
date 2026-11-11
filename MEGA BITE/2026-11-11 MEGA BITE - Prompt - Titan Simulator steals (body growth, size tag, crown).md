---
date: 2026-11-11
tags: [megabite, prompt, claude-code, dead-game-method, size, crown]
status: ready to send (not sent). Small: fits what build steps 1-4 already made.
---
# MEGA BITE: the Titan Simulator steals (body growth, size tag, crown) (11 Nov)

Research: [[2026-11-09 Research - Dead game method (shut-down multiplayer games as an idea library)]] section 6 (Titan Simulator, Roblox 2017: 91.7M visits, loved because **your body is the leaderboard**).
Back to [[00 MEGA BITE Home]].

**Checked in Studio first (11 Nov, Mega Bite place, edit mode, read only):**
- `MB_FishServer` raises `SizeMult` every `SizeUpEvery = 8` bites by `SizeUpStep = 0.04` up to `SizeUpMax = 0.6`, fires the "SizeUp" sound, and `MB_HUD` multiplies the SIZE number by it. **Nothing scales the shark's body.** The only `ScaleTo` in the game is for NPC predators (`MB_PredatorClient` line 34), which proves the approved models scale cleanly.
- **Bug:** Hammerhead 4.5 m x 1.6 = 7.2 m, then it evolves into a 6.0 m Great White. The SIZE number drops on an evolve (120 bites reach the cap, and Hammerhead → Great White needs 7,600 EXP, so every player will see it).
- No tag over other players, no "biggest in the server" marker. `UIKit` has a Crown icon (used only for VIP in the store).
- No PvP yet, so nothing here touches combat.

```text
MEGA BITE – 3 SMALL FEATURES FROM THE TITAN SIMULATOR RESEARCH ("your body is the leaderboard"). Do NOT playtest and do NOT publish: the owner tests on his phone. Phone first, UI kit v2 only (K.Counter / K.Text / K.Tile, the drawn ocean kit), every number in GameConfig, toasts follow the UX pass 1 rules (one at a time, never over the thumbstick or DART). Build ONLY what is listed; do not touch combat, the Store or the Fish Index.

1. THE BODY REALLY GROWS (today SizeMult only changes the HUD number)
   - When the server sets SizeMult, the player's shark model scales to baseScale x SizeMult. Use Model:ScaleTo the same way MB_PredatorClient already does for predators (same approved models, proven). Keep the base scale per evolution on the model as an attribute so it never drifts after many steps.
   - Tween it: 0.35 s ease-out with a small overshoot (x1.06 then settle), a short bubble ring from BiteVFX/AbilityVFX at the body, the existing "SizeUp" sound. Other players see the growth too (server-replicated scale or FireAllClients; pick the cheaper one and say which).
   - Everything that reads body length follows the new size: the chase camera distance, the bite reach (MB_SharkKeys uses BiteReach / mesh size), the rock-bounce radius in MB_Swim, the server speed checks (no false flags). Check the BonePlayer clips still look right at 1.6x (translation tracks must scale with the model).
   - What you can EAT does NOT change with SizeMult: fish locks stay tied to the evolution (the padlock badges say "Evolve to ..."). Add C.Fish.SizeUpAffectsEdible = false and keep the Eat check on the evolution's base length.
   - FIX THE SHRINK BUG: a full-grown Hammerhead shows 7.2 m and then evolves into a 6.0 m Great White. Replace the single SizeUpMax with a per-evolution cap so the biggest size of a tier is at most 0.9 x the next tier's size: add sizeUpMax to each row of C.Evolutions (Minnow 0.6, Piranha 0.6, Barracuda 0.6, Reef Shark 0.6, Hammerhead 0.2, Great White 0.6, Megalodon 0.6) and spread the steps so the cap is reached at about 80% of the EXP to the next evolution (not after 120 bites). On an evolve the model swap must never look smaller than the shark it replaces.

2. SIZE TAG OVER EVERY OTHER SHARK (the body is the leaderboard)
   - A BillboardGui above every OTHER player's shark (never your own): line 1 the display name, line 2 "4.5 m · HAMMERHEAD". UI kit text with the ink outline, studs-sized so it shrinks with distance, MaxDistance 140, hidden behind rocks (AlwaysOnTop false), max 12 visible, nearest first.
   - A small badge left of line 2 tells you bigger / smaller than YOU with a shape, not colour only: ▲ red-coral = bigger than you, ▼ kelp green = smaller, = white within 5% (same language as the fish outlines and the padlock/"=" badges).
   - Updates only when Evo or SizeMult changes (attribute signals), never per frame.

3. THE CROWN: BIGGEST SHARK IN THE SERVER
   - Server, every 2 s, only when 2+ players: the biggest = highest Evo, then highest SizeMult, then most total EXP. To stop flicker the crown only moves when someone has been strictly bigger for 6 s, and at most once every 20 s (C.Crown = {Check = 2, Hold = 6, MinGap = 20}).
   - The holder gets the UIKit Crown icon above the name on their tag, and their own SIZE counter on the HUD shows the same crown. A plr attribute "Crown" = true/false drives both.
   - When it changes hands: ONE toast for everyone, "👑 <name> is the BIGGEST SHARK · 6.0 m" (use the Crown icon image, not an emoji glyph, if the kit toast supports an icon), with a short fanfare from MB_Sounds (reuse an uploaded sound; do not add a new asset). The new holder's toast reads "👑 YOU are the BIGGEST SHARK".
   - No reward and no bounty yet (the Red Trench is not built). Leave a clearly named hook, Crown.Changed(newPlr, oldPlr), for the bounty later.
   - Analytics: Crown_Taken (evo, size).

REPORT (short): files changed, the new config rows, how the scale replicates, and anything in BonePlayer that needed a change.
```

## Rules for later (not in this prompt: the systems are not built yet)
- **Red Trench:** when the crown shark is beaten, everyone who bit it in the last 10 s shares the bounty. This is Titan Simulator's "team up against the giant" and it gives Schools a job.
- **Launch gate:** Titan Simulator ended at a hard cap. MEGA BITE's HUD reads "APEX: MEGALODON · MAX" today, so Fossilize tier 1 must exist before a public launch.
- **Prices:** Titan Simulator sold 2x power for 599 R$ and a PvP sword for 499 R$. Ours: 2x EXP stays ≤ 449 and nothing bought helps in a fight (already a rule).
