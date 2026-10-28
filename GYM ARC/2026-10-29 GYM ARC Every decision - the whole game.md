---
date: 2026-10-29
tags: [gymarc, plan, decisions]
status: decided (owner asked Claude to decide everything, 29 Oct)
---
# GYM ARC: every decision, the whole game

Back to [[00 GYM ARC Home|GYM ARC Home]] · Ladder + schedule: [[2026-10-29 GYM ARC Master plan - one ladder]]

Owner, 29 Oct: "use ALL the research since the start and decide what to do for everything in the game: current, future, past, features, removal, add, change, music, sounds, VFX, everything."
Built from: the Roblox Playbook (rules, making games better, craft deep dive, updates/storefront/analytics, 24 research notes), [[Playbook notes - Top games art study (Oct 2026)]], [[Playbook notes - Costly mistakes of big games]], [[2026-10-29 GYM ARC Why players stop grinding - research]], [[2026-10-29 GYM ARC Abilities - research]], [[2026-10-29 GYM ARC Gym genre research]], [[2026-10-29 GYM ARC Hall of Fame - good or bad]], [[2026-10-29 GYM ARC Systems review - training, economy, money, trainers]], and the GYM ARC feature notes.

**Legend:** KEEP = leave as is · CHANGE = rework · ADD = new · HIDE = keep in the game but out of the way · REMOVE = take out (nothing a player owns is ever lost) · LATER = after January.

---

## 0. The rules every decision follows
1. **One sentence:** "Lift to grow taller, from 4 feet to 8 feet, and enter the Hall of Fame." Height is our hook; nobody else in the gym genre has it.
2. **Every feature must** make you taller/stronger, let you USE strength, or let you SHOW IT OFF. Otherwise it's hidden or cut.
3. **First 5 minutes = train → grow → next goal.** About half of new players leave before the first Growth Spurt; that's the #1 problem.
4. **3-4 new things per ladder step.** No floods, no empty stretches.
5. **Never take away:** no wiping, no weakening owned items, no moving old goals further (Fisch, PS99, Grow a Garden).
6. **No paid power that wins competitions; no paying for nothing (MAX BOOST).**
7. **Weekly small update every Saturday 15:00 UTC (21:30 Myanmar).** Measure after every update; undo with Configs if numbers drop.
8. **Kids first:** clothed, calm wording, no fake timers, filtered text, no links in game, Reduced Motion respected.
9. **Phones first:** cheap Android, ~1,000 draw calls, ~300 particles on screen, 60 FPS target.
10. **Original only:** no real brands, people, music with lyrics or other games' IP.

---

## 1. Core training loop
| Item | Decision | Why |
|---|---|---|
| Tap reps on machines, dumbbells, weight tiers, MAX button | KEEP | Simple, mobile-friendly, the genre standard |
| Weighty rep feel, clanks, REP punch, bar shake, coin fly | KEEP | "Feedback on every action" is done and good |
| 18 muscles in 6 groups, "Needs LEGS", Train next, Body Map | KEEP + CHANGE: make the BALANCED +10% bonus visible ("BALANCED x1.1" chip) | Turns the chore into a reward |
| ~10 hidden multipliers + caps (x5, +400% trainers, x8 coins) | CHANGE: one **GAINS** number with 4 parts (Body, Trainers, Boosts, Gear); raise caps per stage instead of a wall | Kids can't read 10 layers; caps waste boosts |
| MAX BOOST wasting boosts/purchases | CHANGE: "MAXED: no effect right now" on items/offers; no Robux offer when maxed | Paying for nothing kills trust |
| Stamina pacing, recovering, shake button, treadmills (max stamina) | KEEP | Tuned 21 Oct; fine |
| Free auto reps at 40% / Auto Rep pass 100% | KEEP | Fair, standard |
| PUMPED / BIG REP | KEEP | Good "juice" moments |
| Muscle of the Day, rush hour, workout together +10% | KEEP (quiet) | Small daily reasons; social nudge |
| EXP numbers "+1.2K" | KEEP | Big numbers feel good (genre) |

## 2. Progression (full table in the master plan)
| Item | Decision |
|---|---|
| Growth Spurts 4'0" → 6'0" (~1 h total) | KEEP pacing; Future You card shows the next body; 3-4 unlocks per spurt |
| Body Alters 1-15 | CHANGE: alter ready = full MASS MONSTER; body never shrinks; +0.8" every alter; smooth curve (Alter 1 ≈ last spurt); flat goals in a tier; a reward every alter; "Fully grown → TRANSFORM" moment (prompt 96) |
| Alter skins tiers 1-3 | KEEP; review Stone skins on max bodies (fur look) |
| Alters 16-20 (Gem) | ADD in January; 21-30 later |
| Hall of Fame at Alter 15 | KEEP + fixes (run 2 x2 EXP from Spurt 3, peak height kept, no cheater statues, analytics); preview at Alter 10; Plan B (no reset) if entered players quit (prompt 95) |
| 2nd+ Hall of Fame (star 2, 3...) | ADD a STAR TRACK: each run faster (8 h → 3 h → ... → 1 h floor), something visible every star, pick 1 of 3 star perks from star 2, star-only trainers/gear/champions, fastest-run board, Alters 16+ open after 15 so entering is a free choice (prompt 101) |
| Champion Ladder (rivals + legends) | ADD (prompt 92) |
| Strongman Feats | ADD 3 first (Power Jump, Ground Stomp, Iron Grip Throw), 3 more as alter rewards (prompt 93) |
| Strength objects ("NEEDS X STRENGTH") + server crown | ADD (prompt 93) |
| Skill tree (upgrades, aura, gear, feats branches) | ADD at Spurt 3 (prompt 94) |
| Progression Road + Future You | ADD (prompt 91) |
| Collection book (trainers, auras, titles, alters, champions) | ADD in January |

## 3. First minutes: loading, menu, tutorial
| Item | Decision | Why |
|---|---|---|
| Loading screen with SKIP at 5 s, world load capped | KEEP | Playbook rule |
| Cinematic menu + PLAY | KEEP, but PLAY must be first thing tappable in <2 s | Every second before play bleeds players |
| Tutorial | CHANGE: only train → grow → next goal; remove the skate tip; Dante "this could be you" moment (no longer total) | Funnel: half leave before the first spurt |
| First spurt ~4 min, 2x new player boost, first-rep reward, 750 coins | KEEP | Already tuned |
| Genetics on join | KEEP OFF (start x1.00); genetics opens at Spurt 4 | Less to understand in minute 1 |
| Popups in the first 5 min (shop, offers, starter pack) | KEEP OFF | Playbook: no offers in the tutorial |
| **Default look: shirtless** | CHANGE: **new players start in the white tank top** (MINE / shirtless stays a choice) | Owner's account was hit once over a muscle-body image; thumbnails/video show clothed bodies; Kids & Select rating; looks like our thumbnails |

## 4. Economy (coins)
| Item | Decision |
|---|---|
| One currency, rewards = "minutes of coins at your stage" | KEEP |
| Offline coins 2%/min up to 8 h, login calendar, daily quests, playtime gifts, re-racking, spotting | KEEP |
| Gear: only Basic/Pro on sale | CHANGE: **gear ladder by gym**: Basic (Starter) → Pro (Pro Gym) → Elite (Powerlifting) → Champion (Golden Era) → Legend (Hall of Fame); owners of Elite/Champion keep them |
| Coin supplements at Coach Dex, Robux specials at Pump Shop | CHANGE with prompt 97 (3 boost kinds) |
| STYLE colours (5k-120k), DNA tokens (25k, +10%/week), trainer snacks | KEEP as long-term sinks |
| Next purchase shown on the Road ("Elite Belt 25,000 · you 18,400") | ADD |
| Trading between players | NOT NOW (dupes/scams risk, Fisch had to switch it off); LATER only with server-side anti-dupe |

## 5. Monetization
| Item | Decision | Why |
|---|---|---|
| Passes: 2x EXP 249, 2x Coins 149, VIP 299 (deal 209), Aura Pack 199, Auto Rep 249, Extra Trainer 99, 4th Trainer | KEEP prices | Inside the genre range; first pass under 400 |
| Store front | CHANGE: **6 heroes** (Starter Pack, Auto Rep, 2x EXP, VIP, Extra Trainer, cosmetic of the week); everything else one tab deeper | 25+ tiny items = choice overload |
| Starter Pack | KEEP; one price everywhere (notes say both 49 and 79: fix) | Consistency |
| Coin packs (scaled, 10/30/60 min), Shake Bundle, Endless Stamina, Quest Reroll | KEEP; hidden when MAXED would waste them | Fairness |
| DNA tokens (99 / x3 249) | KEEP + **PolicyService** check (paid random results blocked where required) | Roblox rule on paid random items |
| Trainer rolls paid with bought coins | KEEP coins-only rolls + odds + pity; PolicyService check | Same rule |
| Trainer slots (2 free, 3rd/4th paid since 28 Oct) | CHANGE: anyone who had a free 3rd slot keeps it | Never take away |
| Alter variants (149-299) | KEEP + ADD **one new cosmetic each update** (variants, Hall of Fame looks, star auras, statue frames) | Fair money; fits "show it off" |
| Server Boost, Gene Lock, Iron Lungs, Fast Recovery, Shake Fridge (old config, off) | REMOVE from config | Dead items confuse the next Claude Code |
| More products | NOT until D1 ~10% | Retention is the bottleneck, not the store |
| Ads (brother) | $20-50 test after 7 Nov; scale only if D1 ~10% and 5-min ~45% | Playbook; Break A Bed lesson |

## 6. Trainers
| Item | Decision |
|---|---|
| 8 trainers, coin rolls, odds shown, pity stages, levels 1-20, evolutions, snacks, Best Equip, auto-delete | KEEP |
| Only 8 to collect | ADD **a trainer pool per gym** (Beach, Pro, Powerlifting, Golden Era, Hall of Fame: 3-5 each) from January; old trainers stay |
| 81 copies for LIMITLESS | CHANGE: fewer copies at higher stages (3, 3, 2, 2) or feed duplicates for EXP so a duplicate is never "nothing" |
| Rarity names changed over time | CHANGE: one source of truth; boards, odds panel and notes must match |
| Trainers following (1-4 shown, see-through near camera, LOD) | KEEP |
| Server announcements for rolls | KEEP OFF (beam only) |

## 7. Boosts, gear, auras, looks, genetics, titles
| Item | Decision |
|---|---|
| 6+ boost kinds | CHANGE: **3 kinds** (Stamina, Gains, Luck), owned items converted at equal or better value (prompt 97) |
| Gear: belt + wraps with % per body half | KEEP + gear ladder by gym (above) |
| Auras (13; earned, coins, passes) | CHANGE: **Aura Altar** (coin spins, odds, pity, ~24 auras in 5 rarities with coin multipliers x1.05-x2), earned **signature** auras (alters, champions, stars), much STRONGER visuals by rarity, walking at 50%+ power (prompt 102, [[2026-10-29 GYM ARC Auras rework]]) |
| Looks (tank tops 12 colours, name/title colours, alter tints, variants) | KEEP (no stats) |
| Wardrobe tops (old fits) | KEEP OFF (already off) |
| Apparel at Pump Shop | KEEP OFF |
| Genetics (D-S grades, frames, body types, DNA rerolls, odds panel) | KEEP, opens at Spurt 4 |
| Titles (Title Book, rarities, never sold) | KEEP; fold into the Collection book in January |
| Undiscovered "???" tiles + discovered counts | KEEP (curiosity works) |
| Membership card (Bronze-Diamond by reps) | KEEP quiet on the profile |
| Codes (window, console-added) | KEEP; one new code per update + in the Update Announcement |

## 8. Social and competition
| Item | Decision |
|---|---|
| Posing shows (divisions by height/alter tier), Local/Regional/National | KEEP; rewards visible (title/aura/statue time) + coins |
| Strongman Showdown | KEEP |
| Arm wrestling vs NPC | KEEP; ADD real-player challenge + weekly board in January |
| Spotting | KEEP |
| Crews (8 members, tags, top crews) | KEEP, opens at Spurt 5 |
| Leaderboards (6 boards + group board), statue | KEEP + server sanity checks so cheaters can't top boards or become statues |
| Profiles, photo mode, mirror before/after card | KEEP |
| Server crown (strongest in server) | ADD (prompt 93) |
| Friend boost, invites (both get rewards) | KEEP |
| Court competitions / basketball | HIDE until Alter 1 (side game) |

## 9. World
| Item | Decision |
|---|---|
| Town hub, Starter / Beach / Pro / Powerlifting gyms, Strongman Yard | KEEP |
| Golden Era Gym | ADD at Alter 8 (prompt 98) |
| Secret rooftop gym | ADD at Alter 7 with Power Jump (prompt 93) |
| Champion Arena | ADD in January (Alter 12) |
| Garage Gym (old plan) | REMOVE from the plan (no slot on the ladder) |
| NPC regulars, Dante, Coach Dex, Plates the cat | KEEP |
| Rivals + legends | CHANGE into the Champion Ladder |
| Skate park + skateboard | KEEP as movement fun; no guide before Spurt 2; ADD the missing roll/grind sounds |
| Day/night 20 min | KEEP |
| Hall of Fame building, statues | KEEP |
| Smoothie stands | KEEP REMOVED |

## 10. Bodies and characters
| Item | Decision |
|---|---|
| Live muscle meshes, stages for others, skin stages | KEEP |
| Never look smaller after an alter | CHANGE (prompt 96) |
| Default shirtless | CHANGE: white tank top for new players (section 3) |
| Trainers' looks (Duke, Volta, The Shadow, Atlas) | KEEP; keep them clothed in art/thumbnails (The Shadow fine, Atlas marble shorts OK) |
| Shirtless glowing-abs art in marketing | NEVER (other gym games do it; we don't) |

## 11. UI
| Item | Decision |
|---|---|
| Locked UI kit (graphite chrome, gold only on numbers/progress, real art, no placeholders) | KEEP; every new screen must use it |
| HUD | CHANGE: max 3 things on screen in minute 1 (Growth Spurt card, Future You, coins); one GAINS number |
| Locked tiles with "Unlocks at…" + teaser | KEEP; everything locked uses it |
| Progression Road screen | ADD (prompt 91) |
| Store front of 6 | CHANGE (prompt 99) |
| Phone layout, 44 px min tiles, no text smaller than HUD labels | KEEP as rule |
| Settings (volumes, popups, lifting voices, show tips, trainers near you) | KEEP + ADD "Screen shake" toggle if missing |

## 12. Music
| Item | Decision | Why |
|---|---|---|
| Licensed APM/library tracks per area (Starter, Pro, Beach, Town), balanced 27 Oct | KEEP licensed-only; **no lyrics** | Roblox video rules; copyright |
| "Hardtekk" playlist (old plan) | CHANGE: energetic but kid-friendly gym beats, not hard tekk; 1-3 loops per zone, 1-2 s crossfades, never restart on respawn | Kids' game; ear fatigue over long sessions |
| Moment music | ADD: short stingers for Growth Spurt, alter, Hall of Fame, champion beaten, launch countdown; duck music -4 to -6 dB during them | Rewards feel bigger |
| Mix | CHANGE gradually to the **Audio API mixer** (buses Music 0.4 / SFX 1.0 / UI 0.8 / Ambience 0.3 + compressor); mobile target about -16 LUFS | Playbook craft guide; Roblox recommends the Audio API |

## 13. Sound effects
| Item | Decision |
|---|---|
| Clanks with pitch variety, plate knocks, bar rattle, rep tick, set chime | KEEP (3-5 variants, ±4-6% pitch) |
| Lifting voices (soft grunts every 5th heavy rep + PR, toggle) | KEEP (owner found screams disturbing; screams stay removed) |
| UI sounds | CHANGE: one family in the music's key (tap click, open/close whoosh, two-note confirm, soft error thud, never a buzzer), no hover sounds on mobile |
| Coin sounds | CHANGE: combo pitch steps (pentatonic) + one "cash roll" for big payouts, 40-60 ms retrigger limit |
| Roll / reveal rarity ladder | KEEP + follow the ladder (pop → chime → arpeggio → whoosh + duck → silence then big stinger) |
| Skate roll/grind, door slide, store purchase, mirror (picked but not wired) | ADD (wire them) |
| Weak picks (CrowdOoh, RivalLose, DoorSlide, SkateGrind) | CHANGE after the owner listens |
| 3D only for world objects; UI/reward sounds 2D; ~30 spatial sources max | RULE |

## 14. VFX
| Item | Decision |
|---|---|
| Growth Spurt transformation (gold figure, 3 pushes, height count) | KEEP |
| Alter transformation, popups per alter theme | KEEP; tier 2-3 popups still need background art (owner imports) |
| Hall of Fame ceremony (calm reveal), soul cutscenes | KEEP (unskippable is owner's choice; respect Reduced Motion: no shake/flash) |
| Auras (3 layers, distance off) | KEEP within ~10-20 particles each |
| Feats (jump dust, stomp ring, throw debris) | ADD with pooled emitters, hit-stop 40-80 ms, shake 0.1-0.5 studs, Reduced Motion off |
| Budget | RULE: ~300 particles on screen, 100/s per emitter on mobile, one Highlight at a time, no white flashes faster than 3/s |
| VFX audit | ADD in the polish pass (prompt 100): count particles in the busiest scenes (posing show, showdown, Hall of Fame) on a phone |

## 15. Lighting, camera, cutscenes
| Item | Decision |
|---|---|
| Gym lighting pools, few shadow lights, night glow | KEEP |
| Camera.Focus every frame in scripted cameras | KEEP (done in 88) |
| Cutscenes skippable after ~1 s | KEEP rule; exceptions: Hall of Fame (owner) |
| Unlock scenes (Golden Era doors, Hall preview) | ADD, short (3-5 s), tap to skip |

## 16. Performance
| Item | Decision |
|---|---|
| NPC culling, LOD, streaming, meshes, 5 shadow lights | KEEP |
| Every update | RULE: FPS + memory check in the busiest place on phone size before Saturday |
| New gyms (Golden Era, rooftop, arena) | RULE: build to the same budget (draw calls, triangles ≤ the Pro Gym) |
| Mirror reflection | KEEP OFF (it cost 49 ms) |

## 17. Store page (Roblox)
| Item | Decision |
|---|---|
| Name `[🏋️STRONGMAN] GYM ARC 💪` | KEEP "GYM ARC" forever; change only the [TAG] per update (e.g. [🏆 HALL OF FAME], [⚡ FEATS]); max 1-2 emojis |
| Icon | CHANGE: the giant's confident face + flexed gold arm, flat bright blue, no text, clothed (height/face rule from the art study); event frame for events |
| Thumbnails | CHANGE: one template (tiny shocked player left, giant right breaking the top, one number/word, blue sky, gold glow); swap one thing per update; 3-5 in Thumbnail Personalization 7+ days |
| Gameplay video | KEEP the 30 s cut (first in the gallery); re-record after big visual updates |
| Description | CHANGE: first line = "Lift to grow taller, from 4 feet to 8 feet, and enter the Hall of Fame!" then how to play, features, codes |
| Genre / maturity / Kids & Select | DO (owner): Simulation genre, full questionnaire (Minimal/Mild), ID + 2-Step, Kids & Select trial |

## 18. Live ops and community
| Item | Decision |
|---|---|
| Saturday 15:00 UTC weekly update, live launch event system (prompt 90) | KEEP; use the countdown only for big updates (not every week) |
| Update Announcement (60 chars, 1 per 3 days) + Experience Event (Notify Me) | DO every update |
| Seasons: Halloween (ends 2 Nov), **Winter Lifts 10 Dec - 6 Jan** (Sled Pull), Summer Shred | KEEP; add one winter cosmetic + a winter code in the 12 Dec update |
| Codes per update | DO |
| Discord (empty) | KEEP but don't push it; no links in game (rule). Grow through the Roblox group (group rewards), Update Announcements and short gameplay clips (TikTok/YouTube Shorts using the video and thumbnails) |
| Admin console, configs, soft shutdown, restart outdated servers | KEEP |

## 19. Analytics
| Item | Decision |
|---|---|
| Onboarding funnel (15 steps) + first-spurt funnel | KEEP |
| Step funnel (Spurt 1-6, Alter 1-15) | ADD (prompts 88/96) |
| Economy + progression events, custom events (shop, offers, rolls, codes, Hall of Fame) | KEEP / ADD as listed in each prompt |
| Weekly routine (Sunday after the update) | D1, D7, 5-min retention, first-spurt %, step drops, session length, payer %, FPS/crashes. Fix ONE biggest leak per update |
| Targets | D1 4% → 8-10%, 5-min 33% → 45%+, first spurt reached by >60% |

## 20. Safety and policy
| Item | Decision |
|---|---|
| Text filter on every typed text | KEEP |
| No links / socials in game | KEEP |
| Odds before any paid/coin-bought random (trainers, genetics) + PolicyService | KEEP + audit (prompt 99) |
| No fake sales/timers, calm wording | KEEP |
| Clothed marketing art, no shirtless muscle images | RULE |
| Leaderboard / statue sanity checks | ADD (prompts 95, 99) |

## 21. Remove / hide list (nothing owned is lost)
- HIDE: basketball court (until Alter 1), skate guide (until Spurt 2), genetics/crews/auras/gear until their ladder step (existing players keep access).
- REMOVE: old dead monetization entries (Server Boost, Gene Lock, Iron Lungs, Fast Recovery, Shake Fridge), the Garage Gym from the plan, the skate tip from the tutorial, the screams (already), the 6 separate boost kinds (merged).
- KEEP REMOVED: smoothie stands, apparel shop, wardrobe tops, mirror reflection, roll server announcements, Skip Growth Cooldown.

## 22. Other games
- **SPEED ARC:** paused (owner, 29 Oct). Resume at prompts 12-13 only after GYM ARC's D1 reaches ~8%+.
- **MOW ARC:** on hold.

## 23. When (prompt queue)
**Updated 29 Oct:** the order now has decision gates; the current schedule is in [[2026-10-29 GYM ARC Master plan - one ladder]] and [[2026-10-29 GYM ARC Rescue plan - if the game is dying]]. The table below is the first version.
| Date (Sat) | Update | Prompt |
|---|---|---|
| before 31 Oct | Hall of Fame fixes + fairness checks (trainer slots kept, Starter Pack price) | 95 |
| 7 Nov | Future You, Progression Road, unlock map, short tutorial, basketball hidden, GAINS number + MAXED, tank top default | 91 |
| 14 Nov | Alter phase fix | 96 |
| 21 Nov | Golden Era Gym | 98 |
| 28 Nov | Champion Ladder | 92 |
| 5 Dec | Strongman Feats (3), strength objects, rooftop gym, crown | 93 |
| 12 Dec | Skill tree + Winter Lifts cosmetic + code | 94 |
| 19 Dec | Boosts merged into 3 | 97 |
| 26 Dec | Sound, music and VFX polish pass | 100 |
| 2 Jan | Economy and store pass (gear ladder, store front, trainer pools start, PolicyService audit, dead config cleanup) | 99 |
| when the first player reaches star 2, latest 28 Nov (with 92) | Hall of Fame star track | 101 |
| Jan | Gem alters 16-20, Champion Arena, Collection book, real-player arm wrestling | later |
