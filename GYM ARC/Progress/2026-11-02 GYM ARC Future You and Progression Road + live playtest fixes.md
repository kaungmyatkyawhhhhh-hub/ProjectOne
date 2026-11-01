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

## Intro cutscene fixes (2 Nov, owner feedback, Studio)
- **Black screen on a real first join:** MenuClient's HUD fade-in (a frame after PLAY) faded in every screen's pieces, the cutscene's black cover too. Screens marked `NoHudFade` are skipped now; the cutscene also waits for the menu's camera swoop to finish.
- **Couldn't turn the camera after it:** the menu's swoop finished mid-scene and kept the camera; and cleanup now always restores the camera, even if it already ran. Tested: CameraType Custom, the arrow keys turn it, the tutorial starts.
- **Outlined "EVERYONE STARTS TINY" stuck on screen:** text faded but its outline didn't; text + outline fade together now. The bottom line "...Everyone starts tiny." (a repeat) is now "A membership... I could get strong too."
- **Centre titles:** FredokaOne, white with a soft silver gradient, dark outline (owner tried serif, said it looked bad).
- **Poster blocked by a pole / opening shot blocked:** the canopy post and the street-side props in front of the cameras removed from `ReplicatedStorage.IntroSet` only (the real town keeps them).
- **Crying pose:** hands to the face, head down (it read as a flex).
- **Sound on everything + better music** (all licensed or Roblox built-in): street bed APM "Leaving the City" -> tension sting when Benny comes -> his footsteps (Roblox's own, heavier) and yours -> grunt + whoosh + hit + your gasp on the shove -> body fall thud (+ low layer, dust) -> sad piano APM "Reflection" + PSE boy sniffles while you cry -> PSE evil laugh on "Go home, punk" -> glass door as he goes in -> APM "Brave" rises at the poster (+ shimmer), getting up, deep breath, fist -> title boom. Only the music group is muted meanwhile (the game's SFX stay audible); everything fades out after. The intro music no longer plays twice. Tested: every licensed sound loaded and played.
- **Removed NPCs (owner):** no errors; 17 NPCs at run time.
- Screenshots: `GYM ARC/Screenshots/road/intro_1..4`.
- **More owner feedback on the intro (2 Nov, later):**
  - Sounds were too quiet (the game's own clips come out near silent there): the cutscene now has its own sound channel at full volume and its own licensed clips: PSE whoosh + grunt + hand/body thud + gasp on the shove, PSE "Body Fall Concrete 2" + low thud on the fall, PSE boy sniffles x3 (volume 6, the piano dips under each), evil laugh, glass door, APM thump/boom. Footsteps (Roblox's built-in) at volume 2 / 2.6 (Benny heavier). Tested: all load and play at the right beats.
  - Centre titles: FredokaOne, pure white (no gradient), bigger (66).
  - Holes at elbows / knees: softer bends in the cry, laugh and fist poses (R15 opens gaps at sharp bends).
  - Street props in front of the opening camera and the canopy post in front of the poster removed from the set.
- **Tutorial: leave the machine mid-reps -> the way back (owner, 2 Nov):** on the bench steps (first rep, 8 reps) and the squat step (5 reps), getting off the machine brings back the gold path, the marker + arrow and GO TO FLAT BENCH / SQUAT RACK, with the line "Get back on the Flat Bench and finish your reps!". They hide again once you're back on it. (TutorialClient `repsHome`.) Tested on the bench (screenshot `tutorial_back_to_bench.jpg`).
- **"This is your max potential" scene removed (owner, 2 Nov):** it no longer plays after the tutorial. The code stays (Studio test: Workspace `TestPotential`).

## Intro cutscene v2 (owner, 2 Nov: "build all of them", from [[2026-11-02 Become a Gladiator - loading screen and intro cutscene]])
Studio, not published. ~47 s, can't be skipped (`Story.Skippable = false`; the Playbook says skippable after ~1 s: owner's call).
1. EVERYONE STARTS TINY (street shot), you walk up.
2. **Benny walks in carrying his barbell on his shoulders** (a carry pose: hands on the bar; a low tracking shot first), blocks the door: "Where do you think YOU'RE going, twig? Lift THIS first." and drops it in front of you (owner: a bar lying outside a gym made no sense, so it's his).
3. **You try to lift it:** bent over the bar, straining (shaking, sweat drops), it comes up a little, drops: **"CLANK!"** (comic word) + metal clank; Benny laughs.
4. The shove + fall (as before), 5. you cry, he laughs (as before).
6. **At the door he turns back:** "Wanna beat me? Get strong first. I'll be waiting, twig." (the goal), then goes in.
7. The poster: "A membership... I could get strong too."
8. **The vision:** riser + gold flash -> your **max-size future self** (the server builds it: MirrorService "IntroPotential", the same body as the removed full-potential scene) flexing over a **knocked-out Benny**, turning gold light rays, a warm gold tint, sparkles, choir + crowd cheer: "One day, **YOU'LL** be the big one." (YOU'LL in gold). White flash back.
9. Fist, "I'll show him." -> PROVE HIM WRONG.
10. **Flyover of the real town:** white flash, from the beach up to above the town; each gym pops up in order with a gold light beam: GYM 1 STARTER GYM (YOU ARE HERE), GYM 2 BEACH GYM (BEAT BENNY), GYM 3 PRO GYM (BEAT CORAL · x1.1 GAINS), GYM 4 POWERLIFTING GYM (BEAT DANTE · x1.2), GYM 5 STRONGMAN YARD (BEAT HANK), GYM 6 GOLDEN ERA GYM (BEAT MAGNUS · x1.2), THE END GOAL HALL OF FAME (THE TOP). Gains read from the configs. Then **BECOME THE STRONGEST IN TOWN**.
11. **The camera drops behind you**, the letterbox slides away, the tutorial's gold path is already on the floor.
- Fixes on the way: Benny's held poses were undone by his walk animation (poses are now applied again after the animations each frame); "always on top" billboards don't draw here (the CLANK word and labels aren't). Cleanup bug found and fixed (the set copy was left in the sky).
- Tested: full run 46.7 s, no errors, camera / body / tutorial back, nothing left over. Studio test switch: Workspace `TestIntroHold` = a beat name (carry, block, lift, clank, door, vision, fist, labels, title, drop) pauses the scene there.
- Not done: a phone-size check of the flyover labels; Benny's carry is a held pose on top of his walk (not a real animation asset).
- Screenshots: `GYM ARC/Screenshots/road/intro2_1..8`.

## Tutorial arrow only in the Starter Gym (owner, 2 Nov)
"the tutorial is pointing at the flat bench in the members gym": while the tutorial runs (`onboarding.tutorialStep` < Done), `Shared/GoTo.Find` only picks machines inside the Starter Gym (Workspace.Gym), for the gold path and the GO TO teleport. Tested: the path goes into the Starter Gym (`intro2_8_after.jpg`). Old saves (no step = done) aren't affected.
- **SKIP on the intro (owner, 2 Nov: "if gladiator one has a skip button too, add a skip button"):** checked the Become a Gladiator! frames: its "Skip >>" shows from the cutscene's first frame (not on the loading or black screen), bottom right on the black bar, until you get control. Ours does the same: the game's SKIP pill look (Shared/UI/SkipPill: Quiet, 64 x 28, chrome), bottom right on the lower bar, ~0.3 s after the picture fades in; one tap = fade to black (0.3 s), the scene stops, the tutorial starts (seen once, like watching it). Captions narrowed so they never run under it. Tested: tap -> cutscene gone, camera / body back, no sounds left, no errors, gold path to the Starter Gym bench. The other story cutscenes stay unskippable (`Story.Skippable = false`). Screenshot `intro2_9_skip_pill.jpg`.

## Benny's chapter scene right after Growth Spurt 1 (owner, 2 Nov)
- "show the CHAPTER 1 - BENNY THE NEW KID cutscene instantly after finishing the growth spurt 1 cutscene": `GrowthFX.Finished` (new) -> StoryClient starts the bully's call-out shot the moment the spurt cutscene ends (0.4 s, while its gold tint fades): no 6 s tutorial gap, no waiting for a free screen; the story is held at once so guides / Coach Dex / offers queue behind it. Works for any bully whose requirement is a Growth Spurt (Benny 1, Coral 3, Dante 5).
- "dont let benny say the two spoken lines": no lines before (or after) the shot any more; the shot shows his last line ("The Beach Gym is my turf. Beat me at arm wrestling, or stay a nobody."). Same for every call-out.
- Tested (fresh save, TestMuscleShare): StoryScene appeared as the spurt cutscene ended, no captions before it. Screenshot `chapter1_right_after_spurt.jpg`.

## Arm wrestling: strength decides, HOLD instead of TAP, no auto clicker (owner, 2 Nov)
"for the arm wrestling (the 1v1 with player and rocco and others one) make it so that it also uses strength and no auto clicker":
- **No tapping:** HOLD the button (or anywhere, or Space / A) = you push with all your strength; let go = 25% (`HoldOffShare`). Letting go 4+ times in a second (`MaxLetGos`) counts as letting go: an auto clicker pushes at 25%. The button says HOLD! / hold to push. Same for the bully matches (same screen); the bully card / lose toast say "hold on".
- **Rocco, Tess, Big Lou have their own strength** (they used to be a share of yours, so your strength didn't matter): Rocco = a fresh player x0.9, Tess = Growth Spurt 2 x0.95, Big Lou = Growth Spurt 5 x0.95 (Config/Social NPC `spurts`). PvP: strength vs strength.
- Tested (fresh save, Starter Gym table): holding vs Rocco WON; not holding vs Rocco LOST; holding vs Big Lou LOST; simulated auto clicker (20 clicks/s) vs Rocco LOST; holding vs Rocco WON. No errors.
- Not checked: the HOLD button by eye on a phone (in the test it sat under the tutorial's Coach Dex box, as the old TAP button did for a player still in the tutorial).
