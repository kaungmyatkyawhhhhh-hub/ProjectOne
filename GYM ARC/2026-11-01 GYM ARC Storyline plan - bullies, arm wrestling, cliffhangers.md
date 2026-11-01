---
date: 2026-11-01
tags: [gymarc, plan, story]
status: built in Studio 1 Nov (not published)
---
# Storyline plan: the bullies (draft for the owner)
Owner (1 Nov): storyline instead of the plain 8'0" ending; starts with someone bullying the player (e.g. Dante); bullies are harsh; voice-overs; every chapter ends on a cliffhanger; the bullies arm wrestle you and beating one unlocks the next gym.

## Shape: one bully per gym, a chapter per gym
| Chapter | Gym it unlocks | Bully | Beat him when |
|---|---|---|---|
| 1 | Beach Gym | Benny (starter gym regular) | after Growth Spurt 1 |
| 2 | Pro Gym | Coral (beach) | Spurt 3 |
| 3 | Powerlifting Gym | Dante (pro gym boss, the main villain) | Spurt 5 |
| 4 | Strongman Yard | "Tank" (the yard's strongman, new) | Alter 2 |
| 5 | Golden Era Gym | "The Boss" (Dante's coach, new) | Alter ~5 |
| 6 | Hall of Fame | final rematch | Alter 15 |
Gym rule: Spurt requirement stays AND you must beat that gym's bully at arm wrestling (old players keep every gym they have).

## Chapter 1 beats (first 30 s and the tutorial end)
1. Spawn: Benny shoves the player off the bench. Voice: "Move, twig. This bench is for real lifters." Crowd laughs.
2. Coach Dex: "Ignore him. Train with me and you'll make him eat those words."
3. Tutorial runs as now.
4. End of tutorial: the "full potential" vision (8'0" you) - then Benny walks in: "Nice dream. Beat me at arm wrestling or stay a nobody." Arm wrestling starts at Spurt 1.
5. Win: Benny on the floor, the Beach Gym doors open. CLIFFHANGER: a shadow on the beach roof, a voice: "So Benny lost to the new kid... interesting." (Coral)

## Every chapter ends on a cliffhanger
- the next bully watching / a phone call from Dante / a locked door with a name on it / Coach Dex hiding something about Dante.

## Voice-overs (researched 1 Nov)
- Roblox AudioTextToSpeech (beta): 19 voices (English US/UK/AU male/female, retro, host), Pitch / Speed per line, all text filtered + audio moderated, free in beta, 300 chars a request, max 1 + 0.05 per 1,000 CCU requests a second (shared by the server) -> lines must be PRE-MADE as audio assets (GenerateSpeechAsset) or cached, not generated per player.
- Alternative: owner / friends record the lines (best quality, real actors).
- Note: TTS is AI-generated audio (the "no AI art" rule covers images; owner to decide).

## Harsh but allowed (Roblox Community Standards, kids' game)
- Yes: trash talk about being small / weak / new, shoves, laughing, taking the bench, "you'll never grow".
- No: swearing, slurs, real-world body-shaming (fat, ugly), threats of real harm, anything about family / race / gender. TTS filtering would block much of that anyway.

## Open questions
1. Bullies = the existing rivals (Benny, Coral, Dante) or new characters?
2. Voices: Roblox TTS or recorded by you?
3. Arm wrestle difficulty: can a player lose forever? (Suggest: lose = train more, rematch any time, gets easier with stronger forearms.)
4. Does the gym lock apply to players who already have those gyms? (Suggest: no, they keep them.)

(1 Nov, owner: "u forgot strongman yard": added as chapter 4, Strongman.UnlockAlter = 2.)

## UPDATE (owner, 1 Nov): the bully = the BIGGEST person in each gym
Checked in Studio (GymGoerService GYM_GIANTS, NPC_GROWTH; Workspace.NPCs by Gym):
| Chapter | Gym (bully's home) | Biggest there now | Unlocks |
|---|---|---|---|
| 1 | Starter Gym | nobody stands out (all regulars medium, 0.5 growth) -> make one the giant (Benny, ~6'6") | Beach Gym |
| 2 | Beach Gym | nobody stands out (0.6 growth) -> make one the giant (Coral, ~7'0") | Pro Gym |
| 3 | Pro Gym | Dante, 8'0" mass monster | Powerlifting Gym |
| 4 | Powerlifting Gym | Hank, 8'0" (Tank 7'10") | Strongman Yard |
| 5 | Strongman Yard | Magnus, 9'0" | Golden Era Gym |
| 6 | Golden Era Gym | nobody stands out (Vince / Dolores / Gina / Sal) -> make one the giant (Vince, ~9'6") | Hall of Fame |
Each bully bigger than the last: Hank 8'0" -> ~8'6" so he beats Dante; Coach Dex (7'6") is the mentor, not a bully.


## BUILT (1 Nov, Claude Code)
Built in Studio, not published: [[2026-11-01 GYM ARC Storyline built - bullies, arm wrestling, voices]]. Vince's chapter needs Alter 12 (a beat between the Golden Era at 8 and the Hall of Fame at 15). Voices: TTS for now; real recordings go in `Story.Recorded` ([[GYM ARC - Storyline voice lines to record]]).
