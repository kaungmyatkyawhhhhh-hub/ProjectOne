---
tags: [research, cutscene, camera, tds]
date: 2026-11-26
source: https://www.youtube.com/watch?v=cr0dXZYB1LY
---
# Research: TDS Solar Requiem cutscenes (the film look)

Owner: "these cutscene texts could look better if it was like TDS 2026 solar requiem cutscenes ... not just the cutscene texts, the literal entire cutscene".

**Source:** Tower Defense Simulator's 2026 Halloween event, *Solar Requiem*, by Paradoxum Games; a compilation of all its cutscenes, 17:45 long.
- Watched in Chrome: frames every 44 s, then every 1.5 s through one scene.
- The sound was not measured.
- Other compilations: [Nights 1-4](https://www.youtube.com/watch?v=rSszyN8j4z8), [Night 1](https://www.youtube.com/watch?v=GjlU-4DIJEE).

## What makes it look like a film
- **Letterbox bars** stay on the whole time, roughly 2.39:1. The scene opens on a black card: "PARADOXUM GAMES PRESENTS".
- **Subtitles:**
  - one small line at the bottom of the picture (about 2 % of the screen height);
  - the format is `Name: words`, with the name in that speaker's colour and the words in white with a thin dark outline;
  - no panel, no typing, no bounce, no big title text.
- **Shots:**
  - mostly tight close-ups of faces, hands and props;
  - low angles on the strong characters;
  - over-the-shoulder pairs for dialogue;
  - now and then a wide establishing shot.
- **Cuts:** a hard cut every 1.5-3 s. Each shot drifts slowly (a small push or arc). Action beats cut faster and add bright flashes.
- **Depth of field:** shallow. The speaker is sharp and the background is soft.
- **Grade:** one strong colour per scene (violet at night, warm orange in the desert), contrast up, a soft glow.
- Scenes end with a **dip to black**.

## Applied to GYM ARC (v1958, saved, NOT published)
- New `Shared/VFX/Cine`, shared by every story scene:
  - letterbox bars that slide in and out;
  - `scene:Say(name, colour, text)` for the film subtitle;
  - moods: warm, cold and dusk grades;
  - `scene:Focus(distance, radius)` for the depth of field;
  - `scene:Dip()` and `scene:Close()`.
- **New-player intro** (`IntroCutscene.PlayShort`, still 5 s for the funnel):
  1. the gym wide, drifting in;
  2. a low over-the-shoulder shot past you onto a copy of Benny (laugh pose), with "Benny: Go home, twig!" as a subtitle and his laugh;
  3. a reverse close-up of you from his side, the gym blurred;
  4. a dip to black: the copy is removed and the camera comes back behind you.

  Every camera position is checked against walls. The old big chunky caption is gone.
- **Story call-outs** (`StoryClient` shot):
  - the chunky name card is off;
  - the line is the film subtitle (bully name in red, the cold cliffhanger in blue);
  - the grade comes from the Cine moods;
  - the cut is a clean hard cut: no white flash, no shake.

**Checked in Play:** the fresh-player intro (video). Story call-outs: the script loads without errors, but no call-out shot was played in the test.

**Not done yet:** the other cinematics still have their old look: GrowthFX, GymReveal, AlterFX, TrainerStories, Launch and Roll. Phone size is not checked.

## Pass 2 (v1960, saved, NOT published): a 15 s intro with acting
Owner: "the tds one is so cinematic". Asked about the length, the owner picked **about 15 s** (the 5 s cap came from the funnel loss in the old 50 s intro).

- `Config/Onboarding.IntroCutsceneLength` = 15. This plays the existing SHORT cut of `IntroCutscene.Play`, the copy of the set far above the map, now in the film look:
  1. the street, with a small quiet title "EVERYONE STARTS TINY";
  2. Benny walks in carrying his bar, blocks the door and drops the bar ("Benny: Where do you think YOU'RE going, twig? Lift THIS first.");
  3. the shove and the fall ("Benny: Weak. Skinny. This gym is for REAL lifters.");
  4. the MEMBERSHIP poster ("You: A membership... I could get strong too.");
  5. the gold vision of future-you over a beaten Benny ("You: One day, YOU'LL be the big one.");
  6. a dip to black and a cut to behind you, with the tutorial path on the floor.
- The captions are now one film subtitle. The name and caption lines and the dark caption fade are gone.
- Depth of field follows each shot's subject, and the warm Cine grade is on for the whole scene.
- Some SHORT beats are trimmed: about 16.4 s measured.
- The vision's god rays are removed (house rule: no sunburst).
- The ending is a dip to black and a cut, no longer a swing through the sky from the set.

**Checked in Play** (fresh player, two videos): every beat above, no errors.

**Watch:** the Intro funnel (`Intro_Done` seconds / skipped) for drop-off against the 5 s version. **Not checked:** phone size.
