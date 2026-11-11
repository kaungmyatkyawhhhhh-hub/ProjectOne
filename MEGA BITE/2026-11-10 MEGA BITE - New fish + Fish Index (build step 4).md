---
date: 2026-11-10
tags: [megabite, food-fish, fish-index, golden-fish, build]
status: built in the Mega Bite place (Studio), waiting for the owner's test
---
# MEGA BITE: 4 new fish + the Fish Index (build step 4, 10 Nov)

Owner (16:42): "go" (after "what is the next step").

## The new fish (own models, sheet method, all HIGH QUALITY gates by eye: side/top/front/3-4 renders vs the sheet)
| Fish | Zone | Length | EXP | Who can eat it | Special | Asset |
|---|---|---|---|---|---|---|
| Coral Shrimp | Safe Reef (10 schools x6) | 2.5 | 1 | Minnow + | eyes on stalks, 2 antennae, 5 legs | 92054038888938 |
| Lavender Squid | Open Sea (6 x3) | 6 | 4 | Piranha + | **ink cloud + dash** when a shark that can eat it gets close (4 s cooldown) | 94293317590232 |
| Yellowfin Tuna | Open Sea (4 x4) | 12 | 8 | Barracuda + | fast (16), flees early | 113145251884789 |
| Golden Treasure Fish | anywhere, ONE at a time | 4.5 | 25 (straight to EXP, never carried) | Minnow + | gold light + sparkles; first after 40 s, then every 2 min, lives 70 s; "A GOLDEN FISH appeared!" / "<name> caught the GOLDEN FISH!" for the whole server | 102276867690115 |
- Sheets: `Art/FoodFish/<Fish>/<Fish>_sheet_chatgpt.png`, prompts: [[2026-11-10 MEGA BITE - Prompt - Food fish sheets batch 2 (ChatGPT)]]; FBX next to them; check renders `<Fish>_check.png`.
- Generator `Art/FoodFish/fishgen_v2.py` (from v1) learned: squid arms as 8 tapered tubes + 2 club tentacles (the loft is mantle+head only), lateral fins traced from the TOP view, stalk eyes + antennae (shrimp), a painted stripe touching a fin is split off (tuna gold line vs the pectoral), small painted marks stay paint (pec_min), a head crest becomes a plate (golden star), and the background is bled with the nearest fish colour BEFORE inpainting (fixed magenta/black smears).

## Fish Index
- HUD: an INDEX button (blue, book icon, "3/8") next to STORE. Panel: 8 cards, 4x2, spinning 3D model + name + zone + EXP; species you haven't eaten = dark silhouette, "???" and "Eat at: PIRANHA" (the smallest shark that can eat it).
- First bite of a new species: "NEW FISH! CORAL SHRIMP (3/8 in your INDEX)". Every 3 new species: "INDEX PAGE 1 COMPLETE! +10 EXP" (GameConfig.Fish.Index).
- Saved per session only (player attribute `Index`): there is NO DataStore in the game yet (EXP/Evo aren't saved either); saving comes with the data step.

## Also fixed
- Open-sea schools picked targets straight across the map and wandered through the Safe Reef: they now wander ALONG the ring and are kept out of the reef (same bug the predators had).

## Checked in Play (Studio)
Shrimp/Squid/Tuna schools render; eating a Shrimp/Sardine filled the Index (1, 2, 3 -> page +10 EXP); squid inked 6x when chased (Piranha) and was caught on the 3rd try; the golden fish spawned at 40 s with the toast, sparkles + light, was eaten for +25 EXP and announced; Index panel screenshots (2/8 and 8/8); no console errors.

## Next
Step 5: the quest chain (one quest at a time, ~45 s each: "Eat 5 shrimp", "Bank 30 EXP", "Escape a barracuda" (uses `Escapes`), "Catch a squid", ...). Later: DataStore saving.
- (18:05) Owner: "should we not put a cooldown on eating because its less satisfying rn". Removed the 0.22 s bite cooldown: every fish your mouth touches is eaten (client + server). Anti-cheat is now a token bucket instead (12 bites at once, refills 8/s; GameConfig.Fish.BiteBurst/BiteRefill). The Bite clip no longer restarts on every fish in a chain (keeps chomping), one gulp sound per chomp-run + a pop per fish. Tested: 5 of a 6-shrimp school eaten in one fast pass; no errors.
