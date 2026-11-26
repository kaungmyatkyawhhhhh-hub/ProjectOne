---
tags: [gym-arc, ui, tutorial, onboarding]
date: 2026-11-26
build: Studio save v1950 (saved, NOT published)
---
# GYM ARC: one tutorial, clean join, no cutscene fighting

Owner asked:
- "the tutorial is getting interrupted by the old system and new system mixing up together, if new system is getting added, remove the old system";
- "for some buttons/labels in the same position, only the main one shows";
- "some labels / buttons keep fighting to get on cutscenes";
- "these look very placeholder" (the PICK YOUR NEXT MUSCLE panel);
- "when players first join, all the GUI load 1 by 1 for a millisecond ... thinking it's some sort of virus".

## Found (fresh-player run, logged + video)
- HUD (top pills, left tiles, GROWTH SPURT card, NEW TITLE toast) popped in over the menu and during the intro.
- Old guides (SpurtReady, BeachGym, Trainers, TrainerAgency ...) fired on top of the new tutorial / NEXT GOAL card.
- The band and the coach box said the same line; "Pick your next muscle!" band over the panel's own title.
- QUEST DONE toasts mid-tutorial; NEXT YOU card next to the coach.
- Right column showed only the top card; side-menu footers 5/7/8 rotated in one spot.

## Removed / changed
| What | Now |
|---|---|
| Config/Guides | SpurtReady, SpurtReadyAgain, AlterReady, AlterTier, BeachGym, ProGym, PowerliftingGym, TrainerAgency, Trainers, HeavierWeight dropped (the tutorial + NEXT GOAL card lead these) |
| GoalCoachClient, TutorialExtrasClient | retired: moved to ServerStorage._Retired, disabled |
| TutorialClient | no band while the coach box carries the step; no band on the pick screen |
| DailyClient / QuestClient | no QUEST DONE toast during the tutorial |
| ProgressClient | NEXT YOU card off during the quiet start |
| UI/SideMenu | RotatingFooters = {} (all footers show) |
| UI/RightColumn | "< 1/3 >" pager under the card when several want to show; a new top card resets to it |
| TutorialClient pick panel | each choice = the muscle art (RunCards.Art.Types Legs / Core / Back) + a gold button |
| NEW ReplicatedFirst.GuiGuard | holds HUD-type ScreenGuis off while loading, over the menu, until a new player's intro ends, and during any cutscene (IntroCutscene, GrowthTransform, GymReveal, AlterTransform, LaunchCinematic, RollCinematic, TrainerStory, Potential; Story* while the camera is scripted). Remembers what their scripts asked for and gives it back after. |

Guard rules learned: never hold windows (Kit.Modals): the loading screen pre-draws every window behind itself, and a window closing itself while held is invisible (Enabled was already false), so it reopened afterwards. Check once per frame before drawing, not on ChildAdded. Fades / overlays with DisplayOrder 85+ are left alone.

## Checked in Play
Join video: loading → menu → intro with no HUD on screen, HUD comes in once after the intro. Pick panel art, pager (1/2, arrows), no new errors.
Not checked: the growth-spurt / alter / gym-reveal cutscenes with the guard (covered by name), phone size.

## Pass 2 (v1956, saved, NOT published): the HUD eases in
Owner: "there is still the overstimulating GUI's loading in a millisecond at the start".

A frame-by-frame log from the first client frame (a test LocalScript in ReplicatedFirst, removed afterwards) showed:
- the loading and menu stretch is clean: windows pre-draw only under the loading screen;
- the moment the hold ended (the Play shot / the intro over), about 20 HUD ScreenGuis switched on in ONE frame: top bar, side menu, right cards, hotbar, toasts. That snap was the "millisecond" pop.

Fix in `ReplicatedFirst.GuiGuard`: when the hold ends, the HUD eases in by area:
- the top bar and side menu at 0 s;
- the right column at 0.1 s;
- the boosts at 0.16 s;
- TalentBar at 0.2 s;
- the bottom bar and hotbar at 0.24 s;
- everything else at 0.34 s.

Each one fades up over 0.28 s with `Theme.FadeWindow`. The parts in `Kit.HudAsideParts` also glide in from their edge (Back easing, 0.32 s). If a gui's own script changes Enabled while it waits, the gui is handed back to the script.

Checked in Play (returning player: menu → PLAY → town shot): the HUD fades in by area, with no one-frame pop. Not checked: phone size; a fresh player after the intro (same code path).
