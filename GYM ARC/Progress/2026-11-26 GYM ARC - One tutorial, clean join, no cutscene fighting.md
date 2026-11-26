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

## Pass 4 (v1962): time to read, Benny's muscles, audible clicks
- First tutorial step (GoBench, autoGo) now waits until Coach Dex's dialog closes (max 10 s) + 0.8 s before dashing to the bench. Before: dash 1.4 s after "Welcome!". Tested: dialog at 0.07 s after the intro, dash at 9.93 s.
- IntroCutscene `dressMuscles(model)`: the cutscene Benny copy gets `MuscleRig.new(model,{static=false,keepBody=true,style})` + `rig:Snap(Decode(MuscleG))` (MuscleClient only dresses NPCs in the world, so copies were skinny). Used in Play() and PlayShort(). Checked on the shove frame: bulky arms.
- Button sounds (TDS-style tick on every click): Config/Sounds Click 0.1 -> 0.5 (basePitch 1.12), TabTick 0.05 -> 0.3, Select 0.08 -> 0.35. Click was there but under the music (0.1 x UI group 0.55). Levels measured, not heard.

## Pass 5 (v1964): clicks you can hear, a real muscle picker
- Owner: "clicks cant hear". The click clip 9114212934 itself peaks at 5/1000 PlaybackLoudness: silent at any volume. Click, Select, TabTick and DialogNext now use Roblox's "UI Bright Click" 15675059323 (peak 212 raw, 103 in game at Click 0.35 x UI 0.55). RepTick keeps the old soft tick.
- Owner: the PICK YOUR NEXT MUSCLE icons were the same as the Run Cards, and the frame, background and buttons looked like placeholders. New ChatGPT art (one chat, the boost icon sheet as style reference), `Assets/pick_muscle_2026-11-26/`:

| piece | id |
|---|---|
| icon_legs (squat, thighs glow orange) | 102184921421552 |
| icon_abs (crunch, six-pack glows gold, clothed) | 122240811217104 |
| icon_back (pull-up from behind, back glows purple) | 74633281653190 |
| panel (gold rim, bolts, diamond plate, chevron header) | 132824241363420 |
| button (gold pill) | 76159087926069 |
| card_legs / card_abs / card_back | 113982329234903 / 86459323226447 / 137939004459369 |

- TutorialClient: the panel is the image at its own aspect (560x427 at UIScale 0.86, pops in with Back easing), each choice is one ImageButton (card + hero + gold pill with dark italic word, Theme.BindPress). First card sheet came back with sunburst rays: redone with "NO sunburst", green key.
- Checked on PC in Play (screenshot). Not checked: phone size, the real path to the picker (needs a full bench set).

## Pass 6 (v1969): the muscle picker in the modern style, no ChatGPT art, no viewports
- Owner on v1964: "this is very bad. study modern GUI's", then "the pictures that chatgpt made look very AI generated and not modern GUI looking", "dont use view port frame for anything", "ill try to make pictures with chatgpt myself".
- Studied: our TDS lobby frames (store, towers), the TDS research note, two web searches. Modern = no frame, the world blurred, dark glass + bright art, one solid colour per card, the card is the button.
- TutorialClient PICK YOUR NEXT MUSCLE now: no panel; `PickBlur` (Lighting BlurEffect, Kit.BlurSize, 0.12 s in / 0.1 s out) and Kit.HudAside while it shows; white "PICK YOUR NEXT MUSCLE" header with a rule line sized to the title; "Auto-picks in Ns" countdown; three solid cards (legs red, abs gold, back purple; 148x188, 8 px corners, light edge, dark bottom fade) with the word and the machine name; hover lights the edge, a pick snaps a gold outline; cards slide in 50 ms apart.
- Card pictures: `PICK[id].image` in TutorialClient (empty now; the owner makes them). The Art ImageLabel is 160x190, bottom 30 px above the card bottom, so a picture can break out of the top.
- Tried and removed the same day: ChatGPT frame/card/button sheet (v1964) and a live 3D preview (owner: no ViewportFrames). The ChatGPT files stay in `Assets/pick_muscle_2026-11-26/` but are unused.
- ViewportFrames still in the game (to swap for pictures when the owner has them): TitanPreview (Titan Serum), AdventClient (gift boxes), MirrorClient, PlateForgeUI, PumpShopClient (plates), TrainerPortrait, CoachDialog / CoachPortrait.
- Checked on PC in Play (screenshot). Not checked: phone size.

## Pass 7 (v1972): picker to the owner's brief + Blender GFX start
- Muscle picker rebuilt to the brief: centred title, no rule line, ~40% less gap, no panel, exact 3:4 cards (radial light 75701970852689 + brushed grain 131298143741442, colour-matched 1.5px edge, bottom shade), art slot = top 78% (`PICK[id].image`, empty until the renders exist), big LEGS/ABS/BACK, small machine names, thin strokes.
- HUD: top HUD fades to 30%, stamina hidden, blur + 0.72 veil; all restored after the pick (checked in Play).
- Countdown: first tutorial pick 15 s (`Onboarding.FirstPickAfter`), later picks `AutoTrainAfter` (5 s); thin depleting bar + small "Auto-selecting in Ns"; a manual pick cancels it; one pick only (`pickClosing`).
- Cards: hover 1.04 + brighter edge, press 0.96, warm confirm edge, panel fades/slides out. Phone check: 844x390 and 667x375 fit (panel 312 / 280 px tall).
- GFX: default Bacon Hair R15 (Motorcycle Shirt 144076358, Dark Green Jeans 144076760, Smile 144075659, Pal Hair) posed in Studio on the real SquatRack / CrunchBench / PullUpBar with an FK + two-bone-IK poser (`Assets/pick_card_gfx/GFXPoser.luau`, recipes at the bottom). The game's own NPC poses were captured too (`poses_from_game.json`) but crunch/pull-up NPCs don't animate, so the hand-posed ones are better.
- Blocker: Studio's Export as glTF refuses Pal Hair (mesh 29938421 + texture 29938532, permission-locked) and one gym mesh (123480233606534); the place closed during the export. No Blender render exists yet. No asset ids for card art yet.

## Pass 8: LEGS card render (Blender)
- Studio saved v1980: the final GFXHero (Superhero body, Man Face head, Pal Hair, owner's shirt 10048957253 and shorts 14185753437) posed in the squat rack, scenes kept in ServerStorage._GFXExport.
- Studio's glTF export drops assets we don't own; the OBJ export keeps the geometry but scrambles the body UVs and drops clothing. Fix: take the real clothing templates from Studio's cache (rbx-storage), and box-project them onto each body part using the part frames from Studio (`pick_card_gfx/blender_uv_clothing.py` + `legs_part_cframes.json`). Arms read the shirt only, legs the pants only, torso both.
- Face: the owner picked face 33 from the cache sheet (`textures/face.png`).
- Render: Cycles 1536x2048, 192 samples, denoise, AgX, 80 mm, transparent film, key/fill/rim, shadow catcher with key-light shadows only. `LEGS_render_v1.png` (preview on blue and white: `LEGS_render_v1_preview.png`). Waiting for the owner's review before ABS and BACK.

## Pass 9: picker cards without pictures (saved v1983)
- Owner: "lets just do without picture, texts & details with designs only". The LEGS render (Pass 8) is parked, not wired in.
- TutorialClient PICK cards (168x224): machine name top-left, an AUTO chip on the card the countdown will pick, the big word, a rule, "TRAINS" and one row per muscle from Config.Machines muscles (name + a bar as long as its share: Squat = Quads 100 / Glutes 50 / Lower Back 30, Crunch = Abs 100 / Obliques 60, Pull-Up = Lats 100 / Biceps 50 / Rear Delts 40).
- Timer says which card it picks ("Auto-picks LEGS in 12s") and its bar takes that card's colour; on a pick the other cards dim; veil 0.72 -> 0.6; subtitle "Each machine trains different muscles".
- Checked in Play at PC size (screenshot); no script errors. Phone size not emulated (the panel is 344 pt tall in a ~400 pt phone root, so it fits on paper).

## Pass 10: picker hides everything else (saved v1985) + Gemini mockup
- Owner: "while that selection is showing up, hide all the other ui and dont let them show". TutorialClient `hideOtherUi`: every other ScreenGui/BillboardGui in PlayerGui, the Tutorial gui's other pieces and Roblox's chat/player list/backpack go off while the pick shows; anything that turns itself on meanwhile is turned off again; each one's own state comes back on close. Tested in Play (TestTutorialStep = 5, removed after): only Tutorial enabled during the pick, all HUD back after the auto-pick.
- Gemini enhance of the picker: `Assets/picker_gemini/picker_gemini_v1.png` (from `picker_v1985_ingame.jpg`). It kept the layout almost 1:1; differences: a small icon by TRAINS, a softer centre glow, slightly larger cards with a lighter glass edge.
