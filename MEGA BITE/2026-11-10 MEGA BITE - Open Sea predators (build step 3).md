---
date: 2026-11-10
tags: [megabite, predators, build, open-sea]
status: built in the Mega Bite place (Studio), waiting for the owner's test
---
# MEGA BITE: Open Sea predators (build step 3, 10 Nov)

Owner (15:56): "ok now next step, the movement is good". Built to the spec in [[2026-11-09 MEGA BITE - EXP curve tuning + slice prompt]] item 6 + the map sim (red outline warns, DART dodges) + the art style guide (red = danger, cartoon, no blood).

## What's in the place
| Piece | Where | What it does |
|---|---|---|
| GameConfig.Predators | ReplicatedStorage.MegaBite.GameConfig | every number below (types, ring, chase, catch, keep, safe time) |
| MB_PredatorServer | ServerScriptService | predators are server DATA (no parts), 20 Hz AI, 10 Hz snapshots (18 bytes each) over `Remotes.PredSnap` (Unreliable); catch/escape/dodge logic; Studio-only test hook `ServerStorage.MB_PredDev` |
| MB_PredatorClient | StarterPlayerScripts | renders the approved shark models (smoothed + predicted, BonePlayer Swim/Dart/Bite + turn bend), red outline / red glow, red screen edge + "!" pointer, the big pops |

## The predators (reusing the approved, HIGH QUALITY shark models; no new art)
| Name | Model | Length | Count | Hunts (your length ≤ 0.8x) |
|---|---|---|---|---|
| Hunter Barracuda | Barracuda x1.0 | 16 | 3 | Minnow, Piranha |
| Reef Prowler | Reef Shark x1.4 | 22.4 | 2 | up to Barracuda / Reef Shark |
| Big Jaws | Great White x1.25 | 35 | 1 | up to Hammerhead / Great White |
They patrol ALONG the Open Sea ring (r 306-340, y 8-40), never enter the Safe Reef, stay clear of the border mesas, and swim AWAY from sharks big enough to eat them. Megalodon is never hunted.

## How a hunt plays
1. **Spotted** (in the Open Sea, within 55/65/75 studs): toast "HUNTER BARRACUDA is hunting you!" + predator sting; a soft red screen edge; a red "!" at the screen edge points to it when it's off-screen; it gets a red outline.
2. **Chase** at 90% of YOUR top speed: holding full speed slowly gets you away.
3. **Red glow** (wind-up 1.4-1.6 s): it slows, lines up, glows pulsing red, the screen edge pulses harder, sting + "DART to dodge!" (first 3 times).
4. **Lunge** (60-70 studs/s for ~0.5 s, Dart clip + whoosh). DART's invulnerable window = **DODGED!**. Minnow/Piranha: a lunge that connects only catches 30% of the time, otherwise **SO CLOSE!**. Then a 2.6-3.5 s cooldown and it tries again.
5. **ESCAPED!** (big green pop): you got back to the Safe Reef, got far enough away, or it gave up (11-12 s). Counts `Escapes` on the player (for the quest chain).
6. **CHOMPED!** (cartoon: white flash, bonk + bubbles, Bite clip, no blood): back to the Safe Reef spawn with 3 s of protection. Carried EXP: kept in full below Reef Shark, 25% kept from Reef Shark up. Banked EXP is never lost.

## Checked in Play (Studio)
- AI loop: patrol → hunt → wind-up → lunge → miss/catch → cooldown → re-lunge; catches respawn you at the reef; ESCAPED fires when you reach the reef/get away.
- DART dodge: 3/3 lunges dodged with the invulnerable window ("DODGED!").
- Models face their swim direction (head·velocity = 1.00), red outline + glow show, pops sit above the HUD (screenshots), no console errors.
- Fixes found while testing: patrol goals went across the reef (pinned on the reef edge) → goals now walk along the ring; border mesas trapped them → band max 342 + an unstuck rule.

## Next
Owner test (PC + phone): is the red glow readable, is the chase too easy/hard. Then: predator dots on the minimap (?), more food species (shrimp, squid, tuna, golden fish), the Fish Index, the quest chain (uses `Escapes`).
- (16:45) Owner: "the predators are sideways". The shark FBX templates have a Z-up pivot, and the client built its turn from the pivot axes; it now builds from the WORLD head direction + world up (like MB_SwimServer does for players). Checked: every predator body-up Y = 0.97-1.00, Big Jaws upright in a screenshot.
- (16:55) Owner: "too easy to dodge, I didn't even have to dart". Retuned: chase speed = your top x 1.08 (or its own top if higher), so you can NOT outswim it: DART or reach the Safe Reef. Wind-up glow 1.4/1.5/1.6 → 1.0/1.1/1.2 s, lunge faster + longer (72/76/82 studs/s, 0.55-0.65 s) and it tracks you during the lunge, leads your movement more, bigger mouth reach, cooldown between lunges 1.8-2.5 s, gives up after 16 s (was 11-12), Minnow/Piranha catch chance 30% → 60%. Tested as Minnow holding W away: caught within ~2 s, 2/2. With a DART timed to the glow: DODGED!, then caught on the next lunge when I didn't dart again.
