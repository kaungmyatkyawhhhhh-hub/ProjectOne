---
tags: [gym-arc, onboarding, tutorial, cutscenes, sims]
date: 2026-11-26
build: v1914
---
# GYM ARC: tutorial + cutscene redesign ("the tutorial is boring", 26 Nov)

Owner (26 Nov, 00:32): "i feel like the tutorial is boring" + "and also the intro cutscene and cutscenes too". Then "ok sure do ur suggestion": give the taps back, make every cutscene one short shot, research first, then sim. Built into the Christmas brief as **Phase 2d**: [[2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec)]].

## What the live tutorial really does (v1914, seen in the 26 Nov bug-hunt runs)
- **It plays itself.** A test player who never touched the screen went from PLAY to Benny, won, and trained at the beach:
  - autoGo walks you to every machine (16 Nov, 23 Nov);
  - autoLeave ends every set (12 Nov);
  - the PUMP bar fills and pumps by itself while any tutorial step is left (owner, 3 Nov);
  - the reps kept counting with no input;
  - GO TRAIN presses itself until Growth Spurt 1 is ready (autoTrain, 18 Nov);
  - Benny's first match is an auto win ("the tutorial's auto push", ArmWrestleService).
- **Cutscenes:** intro 18.1 s, GROW 6 s, Benny story 5 s, Coral story ~8 s (estimate), none skippable the first time. Benny and Coral stand behind the player's own body when their scene starts.
- The autos were added for good reasons: walking and tours were dead time and the funnel lost players there (12 and 18 Nov notes). The redesign keeps the dead-time cuts and gives back only the fun part: **the taps**.

## Research (vault first, then the web)
- Vault [[2026-11-01 Research - Do cutscenes help, what makes a good one]]:
  - good cutscenes are earned, star the player, last 2-6 s, are skippable, end on a question;
  - CHI 2024 (1,699 players): feedback tied to the player's OWN success raised motivation; bigger effects alone lowered it;
  - Roblox practice: first-join intro ≤ 10-15 s and skippable; never unskippable beyond a ≤ 3 s reward beat.
- Vault [[Playbook notes - Onboarding, retention and live ops]] (Roblox docs): teach through the world (highlights, trails); show timed hints only to stuck players; long prescriptive tutorials, text walls and fixed sequences that restrict choice are named drop-off causes.
- Web, 26 Nov:
  - Roblox docs: end onboarding on a deliberate moment of delight; let players get to the core action in seconds.
  - Apple, Onboarding for Games: give players an active role during onboarding and let self-directed play start as soon as possible; teach in short tutorials at the moment they matter.
  - Tap Simulator REBORN / RE:Heads, Please! guides: their first quest is "tap 5 times", with an animated hand pointing at the button.
  - CHI 2012 (Andersen et al., 45,000 players): tutorials barely changed engagement in simple games whose mechanics can be found by trying. A simulator's core action (tap REP) is learned by doing, not by being shown.
  - "Playing with agency" (Abertay thesis): more say over your own pace and effort tested as a retention lever (IKEA effect).
  - Player studies (Waterloo, CHI 2025): players want onboarding that keeps their agency and active learning.

## The redesign (each part is a config value or a small change)
1. **YOUR taps lift.** No auto reps and no auto pump in the tutorial. The PUMP bar fills from your own reps and pumps itself when full, so pumping is still never a lesson (owner's 3 Nov rule).
2. **Hand hint.** If no tap for 3 s, the REP button pulses and an animated hand taps it (once per step).
3. **Juice on every tutorial rep:**
   - every 2nd rep the trained muscle visibly swells (the existing pump flash);
   - "+EXP" pops rise from the muscle;
   - a combo "x5!" and "x10!";
   - the clank pitch climbs a little per rep.
4. **PICK YOUR NEXT MUSCLE.** After the bench, the Squat Rack, Crunch Bench and Pull-Up Bar glow with big icons (leg / abs / back). Tap one and you dash there in 2 s. The other two glow until done, in any order.
5. **Dash, don't walk.** autoGo stays (walking is dead time) but it's a 2 s dash with speed lines and a whoosh.
6. **YOU tap GROW.** The READY card's GROW button pulses; the transform is 4 s and ends on you flexing + the tease of what's next.
7. **Short, skippable story shots:**
   - Benny 4 s with a 3-word caption ("You? Beat ME?");
   - Coral 4 s, ≤ 3 words;
   - every cutscene can be skipped by a tap after 1 s, the first view included; skipping still gives everything;
   - the camera shows the NPC's face, never behind your body (Phase 2b).
8. **Beat Benny yourself.** No auto push.
   - Winnable at 2 taps a second.
   - If you tap slower than 1 a second for 3 s, "BENNY IS TIRED!" and his push weakens, so every kid still wins, by tapping.
   - The TAP button pulses with the hand if no tap for 2 s.
9. **Intro 5 s, one shot:** the gym, a push-in on YOU, Benny's 3-word taunt, control. Skippable after 1 s.
10. **GO TRAIN (until Growth Spurt 1):** the button presses itself only if you haven't pressed it for 5 s.

## Impatient-kid sim (`GYM ARC\Calc\tutorialsim_gymarc.py`)
Same kid as the impatient sim, plus OWN vs AUTO:
- a reward you caused counts fully; one that happened by itself counts AUTO_PAY of it;
- AUTO_PAY can't be read from the funnel, so it's tested at 0.35 / 0.65 / 1.0;
- the time the game plays itself is calibrated to the live funnel: live = 79% past 60 s, 49% past 3 min (funnel ~85 / ~62; the old sim gave 90 / 54).

| Version (cumulative) | 60 s | 2 min | 3 min | 5 min |
|---|---|---|---|---|
| A live v1914 | 79% | 70% | 49% | 49% |
| B Phase 2b only (8 s intro, Benny card opens, GROW on READY) | 99% | 94% | 89% | 89% |
| C + your taps lift (no auto reps / pump) | 99% | 88% | 88% | 88% |
| D + hand hint after 3 s | 99% | 88% | 88% | 88% |
| E + juice every 2nd rep | 99% | 90% | 90% | 90% |
| F + pick your next muscle, 2 s dash | 99% | 88% | 88% | 88% |
| G + you tap GROW (4 s), Benny / Coral 4 s, skip after 1 s | 99% | 95% | 95% | 95% |
| H + you tap to beat Benny (he tires if you're slow) | 99% | 96% | 96% | 96% |
| **I + intro 5 s, one shot** | **100%** | **96%** | **96%** | **96%** |

Sensitivity:
| Test | Live (3 min) | New tutorial (3 min) |
|---|---|---|
| AUTO_PAY 0.35 | 35% | 97% |
| AUTO_PAY 0.65 | 49% | 97% |
| AUTO_PAY 1.0 | 50% | 97% |
| Patience 7 s | 20% | 85% |
| Patience 11 s | 49% | 97% |
| Patience 16 s | 70% | 99% |

What the model says, honestly:
- **The biggest gains come from shorter, skippable cutscenes and doing the Benny match yourself (G, H)**, on top of Phase 2b.
- **Giving back the taps (C) costs ~1 point in this model**: a kid has to realise he should tap, and the auto version never asks. The juice (E) wins it back.
- The model can't measure how much more FUN doing is than watching (that's AUTO_PAY). The owner's own feeling ("boring") and the research both say doing wins. So the taps go in, and the funnel decides.
- If the published game has Roblox Experiments set up: A/B the tutorial (auto vs taps), 50/50, on step 04 "first rep" → step "Growth Spurt 1" → Benny beaten.

## Rules kept
- No manual PUMP lesson (owner, 3 Nov).
- Can't skip the TUTORIAL before Growth Spurt 1 (owner, 31 Oct). Skipping a cutscene is not skipping the tutorial.
- Saved step numbers never move (Config/Onboarding comment): new behaviour lives in the existing steps, IDs stay.
- Mobile: the hand and the glow never sit under the joystick / jump button; text ≥ 14 px.
