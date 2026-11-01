---
date: 2026-11-01
tags: [gymarc, progress, retention, road]
status: in progress (Studio, not published)
---
# GYM ARC - Future You + Progression Road (prompt 91, items 1, 3, 4) - IN PROGRESS

Prompt: [[2026-10-29 GYM ARC Prompt - 91 Future You and Progression Road]]. Owner (1 Nov night): priority before Run Cards / Star Track / Gem alters; items 1, 3, 4 only (2 dropped, 6 = tutorial's job, 5 = one unlock table from what exists).

## Built in Studio so far (not published)
- `Config/Progression` = THE unlock map, built from the live configs (no hard-coded lists): START, Growth Spurts 1-6, Alters 1-15, HALL OF FAME, then COMING SOON per tier (Alters 16-20 Gem, 21-25 Elements, 26-30 Legend). Items: gyms + their bully (Story), menu/tab locks (Guides.Locks / TabLocks), posing shows + alter divisions, agencies (Trainers.Agencies[].open), 2nd trainer slot, Strongman Yard, Golden Era Gym, finale bully (Vince), alter auras, alter skins, Hall of Fame. Champion Ladder / Feats / Run Cards: no slots.
  - Today's map: Start: Arm wrestling, Starter Gym. Spurt 1 (4'4", +36%): Beach Gym [Benny], Poses, Crew, Trainer Agency, Genetics, Inventory, Local Show. Spurt 2: Gear, Regional Show. Spurt 3: Pro Gym [Coral], Auras. Spurt 4: 2nd trainer slot, National Show. Spurt 5: Powerlifting Gym [Dante], Pro Card Qualifier, Powerlifting Agency. Spurt 6 (6'0"): Body Alters, Universe Championship. Alter 1 Human division; 2 Strongman Yard [Hank]; 5 Peak Human aura; 6 Stone division; 8 Golden Era Gym [Magnus] + Golden Era Agency; 10 Stone Skin aura; 11 Metal division; 12 Beat Vince; 15 Forged aura + Hall of Fame. Hall of Fame: Hall of Fame Agency (star 3).
- `GrowthSpurts.UnlockText` (the "NEW:" line after a spurt) now reads the same map (old `GrowthSpurts.Unlocks` was stale: arm wrestling at Spurt 2, Pump Shop at 3).
- `Shared/UI/FutureYou`: NEXT YOU card under the GROWTH SPURT card (same holder, ProgressClient): your avatar thumbnail as a small grey "now" + a taller black silhouette with a gold rim, "NEXT YOU · 4'4"", "Beach Gym · Poses", "TAP FOR YOUR ROAD". Alter mode: silhouette in the alter's colours, "NEXT YOU · SHREDDED". Cheap: 4 flat images, redrawn only when data changes. Seen in the first seconds of a FreshPlayer join (screenshot taken).
- `StarterPlayerScripts/RoadClient`: "YOUR ROAD" window (Kit.Modal 770x290, the Pump Shop's tile + detail-strip layout): tiles with silhouette at that height, name, height + gains, item icons, YOU ARE HERE / NEXT tag, done tick, pill (YOU / REACHED / 13% / REACH GROWTH SPURT 2 / COMING SOON), gold road links, the next stop glows; strip: everything it opens (grey = not yet, "(beat Benny)"), progress bar + WHAT TO TRAIN. Tested at Spurt 0: works.
- Analytics: PlayerAction "RoadEvent" -> `Road_Opened`, `FutureYou_Tapped` (ActionService).
- Studio hook `TestAlter` (number): fresh test save at that alter.
- Fixed meanwhile: locked tiles' silhouettes showed real avatar colours (KeepColor added).

## Still to do
- Test on saves at Spurt 3, 6'0" (TestSpurts 6), Alter 8 (TestAlter 8) with TestPhoneSize 667x375; screenshots.
- Menu tile for the Road (9th tile may push the left menu to 3 columns on phones: check, else card-only).
- Item 4 audit: every locked thing says WHEN it unlocks.
- Feature note "GYM ARC - Progression Road".

## Also done tonight (owner requests, Studio)
- The automatic Roblox invite prompt after the first Growth Spurt (right after the "full potential" scene) removed (FriendClient). INVITE button + Crew invite stay.
- Invisible invite button fixed: Shared/UI/MiniOffer kept a faded card clickable when Hide() ran twice during its fade; now a hidden card never acts.
- Right drawer tab opens on a machine (RightColumn).
