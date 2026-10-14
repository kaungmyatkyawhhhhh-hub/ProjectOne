---
date: 2026-10-13
tags: [gymarc, feature, sounds]
status: done
aliases: ["GYM ARC - Sounds"]
---
# GYM ARC - Music and Sounds

Back to [[00 GYM ARC Home|GYM ARC Home]].

Background music per area and satisfying weight sounds. The owner picks every sound id; the full list of slots is below.

## How it works
- **Music:** low chill background tracks that loop; area music for the starter gym and the pro gym (different tracks). Volume slider in Settings.
- **Effects:** plate clank at lockout (pitch varies, deeper on heavy tiers), rep tick, soft breath on heavy reps, set chime, level up, title unlocked, tier unlocked, out of stamina, genetics reveal sounds, spotting sounds.
- **Rules today:** no grunts or screams; sounds are played through sound groups (Gameplay, UI, Music) with balanced volumes.
- **Sound ids (13 Oct):** at the owner's request Claude picked every placeholder and new slot, only from Roblox's licensed library (ProSoundEffects for effects, APM Music for music). Each is listed below; swap any id in `Config/Sounds`.
- **Area music:** Starter, Pro, Beach (APM "Happy Island") and Town (APM "Maypole Summer"); SettingsClient picks the area from where you stand.
- **Listen to these first (weak fits):** CrowdOoh (a crowd surge; no licensed "ooh" exists), RivalLose, DoorSlide (an elevator door), SkateGrind (a grind on concrete, not a rail).
- **Picked but not wired into the game yet:** SkateRoll, SkateGrind, DoorSlide, StorePurchase, MirrorOpen.

## Where it lives
- `Config/Sounds`, `Shared/Audio`, `SettingsClient`

## Planned change
- **Hardtekk music (monetization prompt, task 2):** replace the chill music with a hardtekk playlist slot `Config.Music.Tracks` (empty for the owner's ids), volume default 0.35, a music on / off toggle, optional per-area lists (Town, StarterGym, ProGym, BeachGym) with a 1.5 s cross-fade.
- **Lift screams (task 3):** grunts and screams become allowed. A 3D scream from the lifter on a heavy rep (at least 85% of max, 35% chance), always on the last rep of a set, on a new personal record (a big one), and on arm wrestling / posing competition wins. Slots `Config.Screams.Normal` / `Big` (random, never the same twice in a row), 2.5 s cooldown per player, a "Screams" toggle in Settings that mutes other players, a small camera shake for the screamer (off on low graphics).

## Related
[[GYM ARC - Game Feel]], [[GYM ARC - Settings]], [[GYM ARC - Monetization]]

## Every sound slot

Generated from `Config/Sounds` on 2026-10-13. PSE = ProSoundEffects, APM = APM Music.

| Slot | SoundId | What it's for |
|---|---|---|
| Clank | 9116750726, 9116751108 | Metal Plate Impact, Manhole Hit 1/2: plates at lockout |
| PlateKnock | 9116717455, 9116717780 | Metal Knocks on Metal Plate 1/4: plates jiggling on heavy reps |
| BarRattle | 9113757391 | Chain Hit Metal, Light Sliding: bar picked up / set down |
| PlateSlide | 9117681302 | Sliding Legs of Metal Tripod: plates on/off when the weight changes |
| FloorThud | 9113479635 | Body Falls on Carpet, low thuddy: rubber floor thud |
| Breath | 9113585730, 9113586280 | Breath Exhale 11/20: heavy tiers / low stamina only |
| RepTick | 9114212934 | Button click: soft tick on each rep |
| SetComplete | 9116163687 | Key Dings, light metal clinking: every 10 reps |
| GrowthSpurt | 9113421788 | Bell Rings, resonant: Growth Spurt moment |
| LevelUp | 9126073001 | PSE Synth Sparkle Bell Ding 4: a muscle levels up |
| Maxed | 9126073302 | PSE Synth Sparkle Bell Ding 2, a bit higher: a muscle hits its level cap |
| TitleUnlocked | 9116394876 | PSE Magic Glows Chiming Hits 2: a new title |
| TierUnlocked | 9116684733 | PSE Metal Impacts 1: heavier plates bought |
| OutOfStamina | 9117018751 | PSE Mouth Poof, burst of air: tapped with no stamina left (no voice) |
| PumpFull | 9126073011 | PSE Synth Sparkle Bell Ding 3: the PUMP meter fills, PUMPED starts |
| BigRep | 1837830196 | APM BOOM Deep Boom 02: a BIG REP |
| PersonalRecord | 9039636793 | APM Stargazing (sting c): NEW PR banner |
| Grew | 9125807054 | PSE Rising Whoosh Swooshing In 3: the 'you grew' moment |
| CrowdOoh | 9120974378 | PSE Wrestling Crowd 3, a crowd surge (there is no licensed 'ooh'): a pose hits |
| SpotPush | 9113885761 | PSE Computer Track Ball 57 click: every push; the pitch climbs with the combo |
| SpotBoostOn | 9126072698 | PSE Synth Sparkle Bell Ding 2: you start counting as clicking |
| SpotCombo | 9126073318 | PSE Synth Sparkle Bell Ding 1, higher: combo 10 / 25 / 50 / 100 |
| SpotAssist | 9113912086 | PSE Cooking Pot 29, light metal knock: the lifter's rep landed while you pushed |
| SpotPayout | 9119217702 | PSE Slot Machine 7, coins: spotting coins paid out |
| Click | 9114212934 | Button click: every button press |
| Whoosh | 9125715121 | Robe Swish, cloth flap: menus and panels opening |
| GeneticsClank | 9116750726 | Metal Plate Impact, Manhole Hit 1: each plate slamming on |
| GeneticsThud | 9119388384 | Distant Metal Booms, deep soft impact: overall plate |
| GeneticsThudLow | 9113479635 | Body Falls on Carpet: low layer under the overall plate |
| ChalkPuff | 9125964822 | Snow breaks into powder: S-grade chalk puff |
| GeneticsSpin | 9126228629 | PSE Whoosh Fast Camera In And Out 1: a plate spins in |
| GeneticsFlip | 9119239488 | PSE Small Pipe Wrench On Metal Pipe 7: the plate flips |
| GeneticsPop | 9117183955 | PSE Comic Pops (Pacifier 3): C / D small pop |
| GeneticsShimmer | 9116383749 | PSE Magical Wing Flutter 5: B gold shimmer |
| GeneticsBurst | 9116394545 | PSE Magic Glows Chiming Hits 1: A blue burst |
| GeneticsDrumRoll | 1840444182 | APM Drum Rolls (A): S build-up |
| GeneticsExplode | 1837830667 | APM BOOM Mid Boom 07: S explodes |
| GeneticsBlessed | 9039637427 | APM Full of Wonder (sting a): the BLESSED banner (2+ S) |
| PosingStart | 9042409054 | APM Day Of The Election Sting 2, fanfare: the round's countdown starts (server-wide) |
| PosingCue | 9113936601 | PSE Cordless Phone beep 8: the timing ring closes (tap now) |
| PosingScore | 9125574158 | PSE Gavel Hit Wood 4: the judges raise their cards |
| PosingWin | 9113137529 | PSE Applause Nightclub 1: the winner on the podium |
| QuestComplete | 1841173364 | APM In Toytown (a): a daily quest is done |
| QuestClaim | 9113849579 | PSE Coin Throws 1: quest reward claimed |
| StreakClaim | 9039566006 | APM Neon Nights (sting f): daily streak claimed |
| ArmCountdown | 9113939659 | PSE Cordless Phone beep 45: 3-2-1 |
| ArmGo | 9117264449 | PSE Referee Whistle 3: GO |
| ArmTap | 9113885617 | PSE Computer Track Ball 52 click: each tap |
| ArmSlam | 9119912410 | PSE Wood Table Impact 2: the winner slams |
| ShopBuy | 9113728049 | PSE Cash Register 2: bought at the smoothie bar |
| DrinkShake | 9114889936 | PSE Juice Box sip 6: drinking a shake |
| RivalWin | 1846248237 | APM Five Card Tricks 'Win': you beat a rival |
| RivalLose | 101507156781402 | APM Glissando down: lost to a rival |
| PetCheer | 9125994778 | PSE Squeaky Toy 12: your pet cheers a set |
| CameraShutter | 9113678227 | PSE Camera Shutter 1: photo mode |
| SkateRoll | 9125955674 | PSE Skateboard Constant Rolling 1 (a loop; not wired yet) |
| SkateGrind | 9125956838 | PSE Skateboard Tail Grinds 9 (not wired yet) |
| DoorSlide | 9114307558 | PSE Elevator Door, the closest licensed slide (not wired yet) |
| StorePurchase | 9126072697 | PSE Synth Sparkle Bell Ding 1: store purchase (not wired yet) |
| MirrorOpen | 9116395179 | PSE Magic Glows Chiming Hits 6: the mirror opens (not wired yet) |
| Music | 9043990443, 9043990341 | APM "Lovely Sunrise" C (underscore) and A (vinyl chillhop) |

## Treadmill sounds (14 Oct)
The treadmill never plays the lifting sounds (no plate clank, bar rattle, floor thud or plate slide). Two new slots, EMPTY for you to pick (silent until you add an id):
- TreadmillLoop: a quiet looping belt / running sound on the treadmill while someone runs; fades out in 0.3 s when they stop.
- TreadmillStep: a soft footstep on every stride (faster when running faster).
Also: pull-ups and dips with no plates (bodyweight) no longer clank.

## Your own music (14 Oct)
You replaced the music with your own tracks (in Studio: ReplicatedStorage > Shared > Config > Sounds).
- Music (the fallback list): 118959016267248, 131532099124744, 139266399633943, 86451874359343, 113417603188158, 1840007392 (volume 0.7).
- Every area now plays four songs in a row, then starts again (owner, 14 Oct: "multiple songs in each area"). Its own song first:
  - Starter gym: 86451874359343, 131532099124744, 139266399633943, 113417603188158
  - Pro gym: 118959016267248, 113417603188158, 139266399633943, 131532099124744
  - Beach: 1837324500, 139266399633943, 131532099124744, 86451874359343
  - Town: 1840007392, 113417603188158, 118959016267248, 131532099124744
- Tested: the starter gym went through all four songs in order and back to the first.

How to play several songs in one area: in `AreaMusic`, put more ids in that area's list, separated by commas, for example
`Starter = { 86451874359343, 131532099124744, 139266399633943 },`
They play one after another in that order, then start again from the first. When you walk into another area, its list starts from its first song. Save the place afterwards.

### Back to one song per area (14 Oct, your change in Studio)
You set every area back to a single song: Starter 86451874359343, Pro 118959016267248, Beach 1837324500, Town 1840007392. The four-songs-per-area lists above are no longer used. The backup copy matches your version. To play several songs in an area again, add more ids to its list (comma separated).

## Loading screen and menu music (14 Oct)
- MenuMusic: **118959016267248** (the owner's pick, the same track as the pro gym). Starts on the very first frame of the loading screen, keeps playing (one loop, never restarted) through the main menu, and fades out when you press Play; then the area music starts.
- To change it, change the id in two places: `Config/Sounds` (MenuMusic) and `ReplicatedFirst.LoadingScreen` (LOOK.Music), because the loading screen starts before the sound list loads.
