---
date: 2026-11-11
tags: [megabite, build, quests, onboarding, sound]
status: built in Studio, compile-checked + quest logic unit-tested WITHOUT Play (as the prompt asked). Not published. Owner tests.
---
# MEGA BITE: watch-study changes built (11 Nov, ~04:10-04:40)

Back to [[00 MEGA BITE Home]]. Prompt: [[2026-11-11 MEGA BITE - Prompt - Watch-study changes (first quest, welcome school, evolve sounds)]]. Research: [[Roblox Playbook/Research notes/2026-11-11 Watch study - Titan Simulator clips + Venom sound measured (YouTube in the browser)]].

## The six
1. **First quest = "Eat 5 fish to GROW"** (reward 3). The vent quest moved to just before the Open Sea: "Find the BANK VENT" (reward 6). New order: eat5, eat10, index3, piranha, vent, open, bank20, escape, barra.
   - **Saved BY ID now**, not by position: new saved fields `QuestId` (current id; `r<n>` = the n-th repeatable) and `QuestsDone` (finished ids). `QuestIndex` is only a cache.
   - Old saves are converted with `C.QuestsLegacyOrder`: everything before their old position counts as done, the old current quest is kept wherever it moved, and anyone past the start gets "Eat 5" marked done.
   - Unknown or already-done id → the first unfinished quest. After every quest, the next one is the first unfinished quest from the TOP, so a moved quest never makes anyone skip another (found while testing: an old player on the vent would have skipped eat10 / index3 / piranha forever).
   - Unit test (mock saves, the shipped code): 10 cases all right (brand new → eat5; old on vent → vent, then eat10; old on index3 → index3; old repeat 2 → r2; unknown → first unfinished …).
2. **Welcome school** (`MB_FishServer`): a NEW player's shark (Minnow, 0 EXP) gets the nearest Minnow-sized reef school (Shrimp / Sardine / Damsel / Puffer) moved `C.Fish.WelcomeAhead = 25` studs in front of the spawn at spawn height, held `C.Fish.WelcomeHold = 8` s (or until eaten). Never for a player with EXP.
3. **Evolve sting only for evolve + Fossilize.** Golden fish caught → BankDing (`MB_FishClient`); store purchase → BuySuccess (`MB_StoreUI`); taking the crown → BankDing (`MB_SharkTags`); also the crown bounty from step 6 → BankDing (`MB_PvPClient`). Kept: the evolve handler (`MB_FishClient`) and Fossilize (`MB_HUD`).
4. **Second hit on EVERY evolve** (`MB_HUD`): the celebration got an optional second beat; `C.EvolveAbilityDelay = 1.0` s after the celebration really starts, "NEW ABILITY: FRENZY!" (etc.) punches in with SizeUp + a glint + a buzz. Timed from the celebration's own start, so the queue (crown bounty + evolve) still shows both. Celebrations with a second hit stay up 2.6 s instead of 1.9. (Before: Piranha only, a late toast that the celebration hid.)
5. **Size = pitch** (`MB_Sounds`): `C.SoundPitch = {1,1,1,1,0.92,0.85,0.78}` × the random jitter, for `C.SoundPitchFamilies` = Bite, Gulp, EatPop, DartWhoosh, Swish, HurtBonk only. `S.Play(name, parent, evo)`: the evolution passed in, else the shark the sound sits on (its model's `Evo` attribute: players, PvP bots, and now predators: `MB_PredatorClient` sets it from the model key), else the local player's Evo for 2D sounds. UI / bank / evolve / ability sounds never pitched.
6. **"Big Jaws" → "Big Chomper"** (`C.Predators.Types.GreatWhite.name`); every pop reads the name from config, no other copy.

## Checked
- All 12 touched scripts compile (`loadstring`), config values read back right. No Play, no publish.
- Two mistakes of mine caught and fixed during the edit: a comment typed inside the golden-fish toast string, and a comment that commented out the rest of the predator's config line.
