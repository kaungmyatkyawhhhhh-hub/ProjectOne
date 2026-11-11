---
date: 2026-11-10
tags: [megabite, food-fish, eating, exp, evolve, build, phone-test]
status: built in the Mega Bite place, shown to the owner
---
# MEGA BITE: phone test + food fish + the eating loop (build step 2, 10 Nov)

Owner (12:11): "can u test for phone for me and then do the next step".

## Phone test (Studio device emulator, driven with computer use)
- iPhone 17 Pro and Samsung Galaxy S25 Ultra: the HUD fits, nothing overlaps, the Roblox top bar sits above the counters.
- Touch: the floating thumbstick appears under the thumb and swims; a drag on the right turns the camera; a tap on DART fires it (server saw DartAt); swimming to the vent finished the quest.
- **Found + fixed:** (1) the old dev display sharks' "Control shark" prompts took phone taps and opened a dev key panel over the HUD: workspace.MB_ImportTest moved to ServerStorage.MB_ShowcaseSharks_old, MB_SharkControl + MB_SharkKeys disabled. (2) Swim-through plants (tag MB_Soft, 232 parts) now fade out when they are between the camera and the shark, so leaves never cover the view.

## Food fish (batch 1): 4 species, own models
- ChatGPT model sheets (prompts: [[2026-11-10 MEGA BITE - Prompt - Food fish sheets batch 1 (ChatGPT)]]) -> `Art/FoodFish/<Species>/`.
- New generic generator `Art/FoodFish/fishgen_v1.py` (+ render.py, export.py): body ring-loft from the traced side profile + top-view width, fins as thick plates traced from the sheet (roots pushed into the body), pectorals hinged out from the flank, eye domes oriented to the head surface + shine, puffer spikes as cones at the sheet's spike blobs. Colours = the sheet itself as one 1024 texture atlas (side view for flanks, top view for the back, painted fins/eyes removed by inpainting), so stripes and spots match the design. Rig: Root + Spine0..3 (tail wag in code).
- 1.2-2.2K tris each. Assets (group 33151111): Sardine 98959086021218, Damsel ("Sunny Damsel", original) 71757009227523, Puffer 91386019328291, Mackerel 132543124090049. In ReplicatedStorage.MegaBite.Fish (scaled 0.01: FBX is in cm).

## The eating loop (GameConfig.Fish)
- MB_FishServer: fish are server DATA (no parts): 37 schools (Sardine 9x7, Damsel 14x2, Puffer 9x1, Mackerel 5x5 in the Open Sea ring 300-380), wander, flee from sharks that can eat them, respawn 6 s after being eaten. Streamed to each player 6x/s (fish within 170 studs, 10 bytes each).
- MB_FishClient: pooled models, smoothed, tail wag on the bones; the nearest 18 get an outline: green = edible (<= 0.8x your length), white = your size, red = bigger. Eat on contact with your mouth (predicted, server validates reach + size + 0.22 s cooldown), bubble pop + gulp, Bite clip for everyone.
- EXP: Safe Reef bites go straight to EXP (Sardine/Damsel 1, Puffer 2, Mackerel 3); Open Sea bites x2 go into CARRYING (30) and bank at the vent (BANKED toast + ding + gold VFX). Every 8 bites SIZE +4% (max +60%). EXP past the next evolve = evolve on the spot (model swap + Evolve VFX + sound + "You are a PIRANHA!").
- Tested in Play: eating (EXP 0 -> 2, NEXT bar), bank -> EXP 30 -> evolved to Piranha, FRENZY unlocked. No errors.

## Next
Predators + DART dodge (red glow before the lunge, "ESCAPED!"), the Fish Index + more species (shrimp, squid, tuna, golden fish), quests chain, then a phone test on the owner's real phone.

## Owner changes (10 Nov, 14:48)
- Outlines: green = you CAN eat it, red = you can't, white ONLY when a fish is exactly your size (within 5%, GameConfig.Fish.SameTol). Before, white meant 'up to 1.15x your size' and looked edible.
- Camera aims 0.3 x body length in front of the middle (toward the eyes): GameConfig.Camera.AimForward.
