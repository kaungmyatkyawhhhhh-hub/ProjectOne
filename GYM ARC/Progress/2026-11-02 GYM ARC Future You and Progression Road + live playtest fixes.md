---
date: 2026-11-02
tags: [gymarc, progress, retention, road, playtest-fixes]
status: built and tested in Studio, not published
---
# GYM ARC - Future You + Progression Road, and the live playtest fixes (1-2 Nov, Claude Code)

Prompt: [[2026-10-29 GYM ARC Prompt - 91 Future You and Progression Road]] (items 1, 3, 4; 2 dropped, 6 = the tutorial's job, 5 = one unlock table from what exists). Playtest: [[2026-11-02 GYM ARC live playtest - why players leave]]. Feature note: [[GYM ARC - Progression Road]]. **None of this touches saves** (only a Studio test switch in PlayerData). Owner publishes (target Wed 4 Nov).

## Part 1: Future You + Progression Road
- **`Config/Progression`**: the one unlock table, built from the live configs (gyms + bullies, Guides locks, shows, alter divisions, agencies, 2nd trainer slot, Strongman Yard, Golden Era Gym, Vince, alter auras and skins, Hall of Fame; alters 16-30 as COMING SOON per tier). No Champion Ladder / Feats / Run Cards.
- **NEXT YOU card** (`Shared/UI/FutureYou`) under the GROWTH SPURT card: you now (small, grey) + the next you (dark silhouette, gold rim; alter mode: the alter's colour rim), "NEXT YOU · 5'4"" / "NEXT YOU · MARBLE", the first thing that opens, TAP FOR YOUR ROAD. Shows in the first seconds of a fresh join. 4 flat images, redrawn only when the data changes.
- **YOUR ROAD window** (`RoadClient`, Kit.Modal, the Pump Shop's tile + strip layout): every stop with your silhouette at that height, height + gains, item icons, YOU ARE HERE / NEXT, ticks, % pill, locked "REACH ALTER 10"; the strip lists what opens (grey = not yet, "(beat Benny)") + a progress bar + WHAT TO TRAIN. Opens centred on the next stop.
- The Growth Spurt "NEW:" line reads the same table (the old list was stale).
- Analytics: `FutureYou_Tapped`, `Road_Opened`.
- Tested in Studio with the phone size (TestPhoneSize 667x375): fresh save (card in the first seconds), Spurt 3, Alter 8. Screenshots: `GYM ARC/Screenshots/road/`.
  ![[GYM ARC/Screenshots/road/road_spurt3_phone.jpg]]
  ![[GYM ARC/Screenshots/road/road_alter8_phone.jpg]]
- Fixed while testing: alter silhouettes showed the real avatar colours (an image tint multiplies); the card's line was too small on a phone (bigger, one item).
- **Not done:** a menu tile for the Road (a 9th tile pushes the left menu wider on phones, which the playtest already flagged as too crowded): the card is the way in for now. Item 4 audit: every lock found says when it opens (menu tiles + tabs: Guides toasts; gyms: "Beat X to unlock"; Strongman Yard / Golden Era plates; agencies' lockedText; court; alter skins in the Pump Shop); no gaps found.

## Part 2: fixes from the live playtest (Studio)
| Found live | Fix |
|---|---|
| Benny's "Arm wrestle" did nothing | The local copy of a bully's table kept the shared tables' sit prompt (the server never sees that table). Its prompts now open his card; the stools can't be sat on. Tested: E at the table opens Benny's card, ARM WRESTLE starts the match. |
| Coach Dex's box over the TAP button, the runway card over the bar during the match | The HUD steps away during a bully match (only the match screen and the story captions stay); his card and the runway invite are switched off first so they don't come back after. Tested (screenshot `benny_match_hud_clean.jpg`). |
| Invisible character, no movement, GO TRAIN dead after THE RUNWAY | Client: when the show ends the camera goes back to your body, controls on, body shown, the scripted walk stopped. Server: never left anchored; a safety net lets go of anyone still "RunwayLocked" when no show / invite is running. (Couldn't reproduce the exact live case in Studio.) |
| Runway invite every 2-3 min, over machines and story moments | At most once every 10 min; never on a machine, in a story moment, over Coach Dex, while the spurt is ready, or in the first minutes. |
| AUTO TRAIN opened Roblox's real-money prompt at once | **Changes the owner's 26 Oct choice:** it opens the Auto Rep card first (what it does + price + BUY). |
| "+750" chip read as paid now | The chip says "+750 AT THE END" (it's paid when the tutorial ends). |
| 35K EXP / 13% before any rep | It's the WELCOME BONUS (by design); Coach Dex's first line now says so. |
| Camera inside a machine sign / pumpkin after a GO TO teleport | The camera is pulled in front of anything between you and it, and sits closer (7 studs). (Machine signs can't be hit by any cast: their CanQuery is off.) |
| 5 things at once after Spurt 1 | Roblox's Favorite prompt moved to Growth Spurt 2 and waits for story moments. Coach Dex's come-back line waits for story moments, the machine, the post-spurt quiet time and some progress (no "0% of the way"). Tours wait for story moments. |
| Full-potential scene covered by other players and tags | Other players and every name tag are hidden on your screen for the scene (NPC bodies stay: the NPC culling owns them). |
| "NEXT: PRO GYM" while the Beach Gym is locked | The card says "NEXT: BEAT BENNY". Tested. |
| Dex "You can GROWTH SPURT!" after you grew | A TAP TO GROW guide never starts once the spurt isn't ready, and ends itself the moment you grow. |
| Other players' giant name tags while lifting | Their head tags hide within 9 studs of your camera, and within 12 studs of you while you're on a machine. |
| A tap after a dialog closed opened a stranger's profile | No profile from a tap within 0.8 s of a Coach Dex box closing. |
| Crunch Bench camera straight down | A lower side-on view for crunches. |
| "TAP TO..." cut on the PUMP pill | The label shrinks to fit ("TAP TO PUMP!"). |
| Invisible invite button / automatic invite prompt | Fixed earlier tonight (MiniOffer, FriendClient). |

Left as is (owner decisions or not bugs): the Starter Pack's always-on card (31 Oct) and its coin amount (it follows the coin rate: 29,600 earlier, 26,600 after the new-player boost ended, same formula everywhere); the Store's hero repeating the featured pass; the AURAS tab of earned auras (14 Oct); "7 feet" on the loading bar (= the Hall of Fame height). Left menu buttons (INVITE / CODES / FREE / PLUS) not moved: owner call.

## Testing notes
- No script errors in the play-tests. Studio's 3D view still draws flat grey (since the earlier crash): 3D looks (the potential scene, the match camera, the bench camera) are checked by values, not seen. **Restart Studio** before the next visual check.
- Studio test switch added: Workspace `TestAlter` (number) = a fresh test save at that alter.
- Owner: File > Save to Roblox, then publish.

## Next (owner's order)
108 save version -> Run Cards -> Star Track -> Alters 16-20 + looks (Sat 7 Nov). Effects on alters 1-15 can move to 14 Nov.

## Later on 2 Nov (owner requests, Studio, not published)
- **Story cutscenes can't be skipped** (`Story.Skippable = false`): bully call-outs, cliffhangers, his defeat. Tested with taps.
- **Benny's first-join cutscene** (`Shared/VFX/IntroCutscene`), replaces his old walk-up for new players (once per save, `Benny:intro`; `Benny:meet` marked too). Built on your screen only, 2600 studs above the map, on `ReplicatedStorage.IntroSet` (a copy of the gym front, street and plaza made in Studio: no players, no NPCs, no scripts) with a **STARTER GYM MEMBERSHIP / NOW OPEN / FREE FOR NEW MEMBERS / EVERYONE STARTS TINY** poster on the entrance wall. Copies of you and Benny act it out (~25 s, can't be skipped): EVERYONE STARTS TINY -> Benny blocks the door ("Where do you think YOU'RE going, twig?") -> shoves you, you fall ("Weak. Skinny. This gym is for REAL lifters.") -> you sit and cry (tears), he laughs ("Aww, gonna cry? Go home, punk.") -> he walks into the gym -> you see the poster ("...Everyone starts tiny.") and stand up -> fist, "I'll show him." -> PROVE HIM WRONG -> the tutorial starts. Tested: runs start to end, actors' feet on the street, camera / screens / your body back after, the tutorial starts at step 1, seen once. **Not yet looked at by eye** (Studio's 3D view was grey for most of the test): poses (shove, sit, cry, fist) need a visual check and maybe tuning.
- **Tutorial REP CARD:** on a "do N reps" step (the bench: 8 reps; the squat rack: 5) a card above the stamina bar: the machine, "2 / 8 REPS", a gold bar with one notch per rep that fills each rep (a small pop), and the step's line. So the tutorial never looks like it ended. Tested (screenshot `tutorial_rep_card_8.jpg`).
- **Leaderboard sorts by Strength:** the leaderstats Strength is a NumberValue again (it was text "2.3T" since 1 Nov, which Roblox can't sort). Most strength on top. Trade-off: Roblox shortens it itself, so past a trillion it reads "2,333B".
- Queued, not done yet: the "Train next" list per gym you're in (owner's screenshot), the broken faces on NPCs (4 screenshots).
