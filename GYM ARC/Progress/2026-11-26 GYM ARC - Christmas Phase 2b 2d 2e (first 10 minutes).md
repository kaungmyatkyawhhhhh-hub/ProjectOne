---
tags: [gym-arc, christmas-update, onboarding, progress]
date: 2026-11-26
build: Studio save v1928 (saved, NOT published)
---
# GYM ARC: Christmas brief Phase 2b / 2d / 2e, the first 10 minutes

Brief: [[2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec)]]. Plan: [[2026-11-26 GYM ARC - The 10-minute plan (minutes 3-10)]].
Tested in Studio Play as a fresh player (FreshPlayer), 4 runs, server + client logs, screenshots at PC size.

## Built
| Item | What it does now | Where |
|---|---|---|
| 2d your own taps | No auto reps and no auto pump in the tutorial. Each rep fills the pump (0.25 a rep). A hand icon taps REP after 3 s with no rep. "+EXP" pops over the muscle, "x5!" combos, and a gold flash every 2nd rep. The rep sound pitch rises. | MachineClient, MachineService, new TutorialTapsClient, Config/Onboarding knobs |
| 2d pick your next muscle | After the bench: a PICK YOUR NEXT MUSCLE panel (LEGS / ABS / BACK, kit buttons). The machines glow. It auto-picks after 5 s. The saved step numbers are unchanged (the pick only swaps which machine a step uses). The pick is saved in `settings.tutorialPick` (the server checks it). | TutorialClient, PlayerData.SetSettings |
| 2d dash travel | GO TO is a 2 s light dash (streaks, FOV kick), not a black fade. Gyms still fade. | GuidePath.Teleport opts.dash |
| 2d short intro | A 5 s Benny push-in shot, "Go home, twig!", skippable after 1 s. The HUD stays hidden for the whole shot. | IntroCutscene.PlayShort |
| 2d faster GROW | The transform is scaled to about 4 s. | GrowthFX |
| 2d Benny comes to you | After GROW, Benny walks up in front of you, the camera goes to him, and a "Big now? Prove it!" card has an ARM WRESTLE button (a tap anywhere counts too). Then a dash to his table and the match starts. | StoryClient, StoryService "Challenge" |
| 2d Benny can't be lost | The first match is won by your taps (a soft push, no surges). Stop tapping for 3 s and Benny tires: his push stops, taps count double, and the caption says "BENNY IS TIRED! TAP!". If time runs out, you win ("Benny gave up!"). | ArmWrestleService, StoryService |
| 2d short scenes | Story lines are 1 line each, max 4 s, tap to skip. | Config/Story |
| 2b calm HUD | The quiet start lasts until Growth Spurt 2. Before Growth Spurt 3 there's no NEW / "!" on the menu tiles, no paid offers or DEAL tag, no locked AUTO REP (pass) button, and no INVITE card. | UIBus, SideMenu, OfferClient, StarterPackClient, MachineHud, TutorialExtrasClient |
| 2b Benny auto card | At his table during BeatBenny, his card opens by itself after 0.6 s. | StoryClient |
| 2e GO TRAIN | "FULL! NEXT: <muscle>" plus STAY. In the first session it moves you to an unused machine after 3 s. | ProgressClient |
| 2e spurt steps | 25/50/75/90% milestones: coins, a body pulse, an FOV punch. | Config/GrowthSpurts, ProgressClient |
| 2e quests tour | No Quests tour in the first session. Instead one card, "DAY 1 STREAK: +750 · CLAIM", needs one tap. The tour never starts while the streak CLAIM is waiting. | DailyClient, TourClient |
| 2e playtime gifts | A gift every 2 min early (200c, a Shake, 300, 400, a roll...). They also pay during the tutorial, and the chip shows from the start. | Config/Playtime, PlaytimeService, PlaytimeClient |
| 2e no stamina wall | The first time stamina hits 0 (before Growth Spurt 3), a free Energy Shake goes into the hotbar with the tap hand on it (once per player). | StaminaService, TutorialTapsClient |
| 2e day sky | A first-session player keeps a 14:00 sky for 15 min, then it eases into the shared sky over 30 s. Checked: ClockTime 14 at the bench. | DayNightClient |

## The 4 bugs from the 10-minute plan
| Bug | Fix | Tested |
|---|---|---|
| CLAIM DAY 1 blocked by the quests tour | no tour in the first session; never while a streak CLAIM is waiting | code only (needs a 2nd session) |
| The tour's SKIP stays on screen | the watcher hides SKIP whenever no tour runs | code only |
| "Heavier weight open!" off a machine | HeavierWeight is `machineOnly`: saved as seen, never shown | no dialog seen in 4 runs |
| The GS1 READY card flashes again after GROW | the card stays muted until the Growth Spurt count changes; growNow returns while GrowthFX runs | checked: no re-flash in 2 runs |

## Bugs found in the play test and fixed
1. `StoryClient:1309` called `focusFace` before it existed, so Benny's card broke the scene → forward declared.
2. The tutorial's auto-dash to Benny's table fired during the GROW result and Benny's walk-in → no auto GO while a story scene or GrowthFX runs.
3. Benny never walked over: unanchoring him let his table pull him back → he slides in anchored with the walk animation. Checked: 7 studs in front of you.
4. The ARM WRESTLE tap was missed once → a tap anywhere counts.
5. The HUD (the Growth Spurt cards) switched back on over the intro shot → it's re-hidden every frame during the shot. Checked: nothing over the shot.
6. The intro used an unknown sound "Thud" → HofThump.
7. Idling in Benny's first match lost it → you win on time (see above).
8. The locked AUTO REP (PASS) button and the INVITE card showed before Growth Spurt 1 → hidden while calm.
9. `PlayerData.SetSettings` dropped `tutorialPick` → it's accepted and checked now (my first edit broke a line; fixed in the same run).

## Not done in this phase (carried)
- 2b.5 one queue for the top strip, 2b.6b icon + arrow on every tutorial line.
- 2b.8 the cheap-looking spots (trophy centrepiece, boards, palms, sign post, rack variants): map work, which needs the layout table → MapAudit process.
- 2b.2 auto GROW 1.5 s after READY: superseded by 2d.6 (you tap GROW yourself). An 8 s safety net remains. So the "GROW ≤ 2 s after READY" test no longer applies.
- Not seen in play yet: the DAY 1 streak card, the free shake (stamina never hit 0 in a tutorial run), and the BennyTired caption on screen. The code loads with 0 errors.

## Knobs (Config/Onboarding)
`BennyAutoOpenDelay 0.6, BennyCamFocus, GrowReadyGap 1.5, CalmHudUntilSpurt 2, CalmOffersUntilSpurt 3, TutorialAutoReps false, TutorialAutoPump false, TutorialPumpPerRep 0.25, TapHintDelay 3, AutoGoDash, AutoGoSeconds 2, GrowTransformSeconds 4, CutsceneSkipAfter 1, IntroCutsceneLength 5, AutoTrainAfter 5, ChoiceGroup, FirstSessionAutoNext 3, FirstSessionStaminaRefill, FirstSessionSeconds 900, FirstSessionQuestTour false`.

Time to Growth Spurt 1 in the test: about 2.5 min of tapping.
