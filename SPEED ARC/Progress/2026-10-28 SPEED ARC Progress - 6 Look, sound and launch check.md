---
date: 2026-10-28
tags: [speedarc, progress]
prompt: "[[2026-10-28 SPEED ARC Prompt - 6 Look, sound and launch check]]"
---
# Progress 6 - Look, sound and launch check (M6)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Done overnight without questions (owner asleep). Your to-do list for launch: [[SPEED ARC - Launch Checklist]].

## 1. Look pass
- **Lighting:** each area's preset (Lighting note) is applied when you arrive: Hub 16:30, Park 09:00, Stadium golden hour 17:30. Only the area you're in has lights on. Lights: Hub 0, Park 0, Stadium 4 (floodlights, no shadows) + 3 winner spotlights for 3 s after a win.
- **Hub fields** (were flat green): grass colour patches, two gravel paths with edging, 10 flower beds, bushes along the hedges, benches, path lamps and a drinking fountain. Hub 751 -> 915 parts.
- **Blender hero props** (`blender/areas_kit.py`, previews in `Screenshots/models/areas/`): Park_Fountain (5.6K tris, landmark), Park_FoodCart (2.4K), Park_Gazebo (1.9K), Stadium_FloodTower (2.0K). The builders use them once you import them; the part builds stay as the fallback.
- **New VFX:** dust burst from every runner at GO, a blue swoosh + sparks when you overtake, the win moment (gold flash, a short camera push-in "slow-mo", gold sparkles, 3 spotlights on the finish line), coins fly to the counter, a shine sweep across gold buttons every 3.5 s. Rank up already had the ground shockwave + sound.
- Your own name tag hides during races (it covered the track).
- Popups moved below the toast lane; windows sit a bit higher so their bottom fits a phone.

## 2. Sound pass
- Every clip measured (PlaybackLoudness method) and normalised per group:

| Clip | Used for | Loudness | Scale |
|---|---|---|---|
| 9114215780 | click / tab / join / denied / roll ticks | 8 | x3.0 (max) |
| 87061775498714 / 140594308250996 | footsteps | 14 / 17 | x3.0 |
| 9117720867 | lace pull | 9 | x3.0 |
| 75594243553477 | toast pop | 21 | x1.7 |
| 9120704978 | air whoosh, windows, jump | 35 | x1.0 (UI) / x2.6 (SFX) |
| 9120914426 | combo break, hurdle knock | 40 | x2.25 |
| 91609406292294 | ka-ching | 51 | x1.8 |
| 9113849583 | coin shower | 55 | x1.6 |
| 72827234719643 | shoe squeak | 62 | x1.5 |
| 9125648149 | combo up, rank up | 69 | x1.3 |
| 139825402019264 | coins | 70 | x1.3 |
| 9126228631 | wind, trail equip, arrive | 77 | x1.2 |
| 4944424481 | starting gun | 86 | x1.05 |
| 1841800152 | fanfare | 91 | x1.0 |
| 9126229255 | boost | 94 | x0.96 |
| 9120974378 | crowd murmur / stadium bed | 96 | x1.15 |
| 9120975307 | crowd burst | 128 | x0.86 |
| 9120975204 | crowd cheer / finish | 148 | x0.74 |
| 91072655090313 | countdown beep | 150 | x0.6 |
| 132574644259001 | sparkle chord, reveals | 153 | x0.59 |
| Music: Hub 1846273376 / Park 1846810919 / Stadium 128683938011405 / Race 1842057947 | | 83 / 157 / 132 / 111 | x1.33 / x0.7 / x0.83 / x0.99 |

- **SoundGroups + Settings:** MUSIC and SOUNDS sliders (10% steps), saved.
- **FINAL STRETCH swell** on the race music; menu music starts quietly.
- **Ambience:** Hub birds (9112831284), Park birds + distant dogs (9116969962), Stadium crowd bed.
- **"Eyes closed" check:** honest note - I can't hear. I went through every moment in the code instead and added sound where it was missing (overtake, coins flying). The loudness numbers above are measured, not guessed. Please do the real 10-minute listen.
- **Music candidates for you to pick** (Creator Store, free, licensed library):
  - Hub (friendly, upbeat): current 1846273376; also "Last Look Back, A" 1848116769 (APM)
  - Race (fast, driving): current 1842057947; also "Battleground" 9048541013 (APM), "Sands of Thunder" 122226145348588 (DistroKid)
  - Stadium crowd: "Stadium Crowd 2" 9119562527 (Pro Sound Effects) as a richer bed than the current one

## 3. Loading screen + main menu
- Loading: logo, a sliding progress bar with changing steps ("Painting the lanes..."), a new tip every 3 s, speed streaks moving. Preloads the hub meshes, textures, sounds and particles. **SKIP** after 5 s (loading continues). Every window (Locker, Coaches, Store) is built once behind it.
- Menu: the screen clears to a slow camera fly over the hub, the logo stays, one big PLAY, the HUD is hidden, music at 35%.

## 4. Settings
SETTINGS (CODES button): codes, MUSIC %, SOUNDS %, LOW GRAPHICS (Auto / On / Off), REDUCED MOTION (Off / On). Low graphics = no bloom / sun rays, half the particles. Reduced motion = no FOV swings or kicks, no win flash or camera push, fewer speed lines, no button shine. Saved in your data.

## 5. Performance
| Area | Parts | Lights | Draw calls | Triangles |
|---|---|---|---|---|
| Hub (idle at spawn) | 915 | 0 | 51 | 88K |
| Hub race (6 runners, the hub has 6 lanes) | | 0 | 59 | 75K |
| City Park (idle) | 292 | 0 | 54 | 83K |
| Big Stadium hurdles race (8 runners) | 443 | 4 | 77 | 181K |
- Particles in a full race: about 8 emitters/trails on at once, a few dozen particles (budget 300).
- Studio FPS is 60 (Studio limits itself; judge by the numbers above + your phone).
- **Player-left check:** went through every service. Fixed: the tutorial timing table, RACE THEM requests from a player who left, the friend cache and the leaderboard name cache (now capped), and characters of players who left are destroyed.
- **Soak test (60 min, Studio):** a race every 30 s with 8 runners (me + NPCs, auto-join) and Auto Train between races: **68 races**. Instance count **flat at 58,577** from minute 4 to minute 60. Memory went **down** (2,332 MB -> 1,239 MB; Studio counts itself in this number, so only the trend matters). No script errors.
- The soak found one real problem: leaderboard reads went over Roblox's budget with 1 player ("request was added to queue"). Fixed: reads now pace themselves to the budget (5 + 2 per player a minute).

## 6. Launch check
**Pacing sim (M1-M5, 60 runs):**
| Moment | Time |
|---|---|
| First race + first win (tutorial race) | ~1:00 |
| First shoes | 2.2 min |
| Silver | 5.0 min |
| Gold | 8.0 min |
| Go Pro 1 | 14.7 min (12.3 - 16.7) |
| Go Pro 2 | 49 min (42 - 59) |
| League 3 Champion (Go Pro 3 opens with Mountain Trail) | 110 min (101 - 119) |

**Fresh player, one last time** (real menu, no test switches):
| Step | Time after PLAY |
|---|---|
| Benji card + 2x boost | 0:00 |
| GO TO Sprint Lane | 0:04 |
| First tap (FIRST STEP!) | 0:07.5 |
| Combo hint done | 0:11 |
| Tutorial race won (gold medal) | 1:10 |
| First shoes | 1:17 |
| Silver + free coach roll | ~5:00 (bot sim) |
| Go Pro 1 | ~14.7 min (bot sim) |

**Launch to-do for you:** [[SPEED ARC - Launch Checklist]] (imports, group, passes, icons, notification strings, music, game page, age questionnaire, phone test).

## Not done / honest notes
- Phone-size screenshots: the Device Simulator wasn't on (I can't switch it from here). The layout was checked against a phone-sized canvas (844 x ~405 design pixels) by the numbers, and windows were moved up to fit. Please check on your phone.
- Real 2-player tests (friend boost, RACE THEM) still need two players.
- Music final picks are yours.

## New Studio test switches
`TestRaceRunners` (fill races to N runners), `TestAutoJoin` (everyone joins every race), `TestSoak` (logs server memory every 2 min into `SoakLog`).

## Screenshots
![[2026-10-28 p6 hub before.jpg]]
![[2026-10-28 p6 hub east after.jpg]]
![[2026-10-28 p6 loading.jpg]]
![[2026-10-28 p6 menu.jpg]]
![[2026-10-28 p6 settings.jpg]]
![[2026-10-28 p6 hub race.jpg]]
![[2026-10-28 p6 stadium race 8.jpg]]
