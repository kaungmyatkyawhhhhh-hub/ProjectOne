---
date: 2026-10-28
tags: [speedarc, prompt]
status: todo
---
# 6 Look, sound and launch check (M6)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

```text
SPEED ARC milestone M6: make it look and sound premium, then check everything before the soft launch. Follow CLAUDE.md (Quick Rules). Never touch GYM ARC.
READ (only these): "SPEED ARC - Lighting.md", "SPEED ARC - VFX.md", "SPEED ARC - Audio (SFX and Music).md" (all three, they're short); GDD section 24; "SPEED ARC - Lessons from GYM ARC.md" sections 2 and 10.

1) LOOK PASS (every area: Hub, City Park, Stadium)
- Lighting preset per area from the Lighting note (sky, Atmosphere, ColorCorrection, light Bloom), applied when you arrive. Neon for glow, < 20 lights per area, no prop shadows.
- Walk every area from the player's view at phone size. Fix anything that looks plain, empty, placeholder, floating, flickering (z-fighting) or default plastic. The flat green fields from prompt 1 need detail: grass colour variation, paths, flower beds, small props from the kit.
- VFX from the VFX note that aren't in yet: rank-up shockwave, race start dust, overtake swoosh, finish confetti + slow-mo for the winner, podium spotlights, coin fly to the counter, button shine sweep.

2) SOUND PASS
- Music for every area + race music with a FINAL STRETCH swell (list library candidates, I pick the IDs).
- Every sound in Config/Sounds with measured loudness (PlaybackLoudness method) so nothing is louder than the rest. SoundGroups + Music/SFX sliders in Settings.
- Play 10 minutes with eyes closed: list and fix anything flat, annoying, too loud or missing.

3) LOADING SCREEN + MAIN MENU
- Loading screen: logo, a moving progress bar with changing steps, tips that change every 3 s, preload meshes/textures/sounds and build every window once behind it. SKIP after 5 s, loading continues in the background.
- Main menu: a slow camera fly over the hub, logo, PLAY, music starting quietly.

4) SETTINGS: music, SFX, low graphics (fewer effects), reduced motion, codes.

5) PERFORMANCE CHECK
- Per area: parts, lights, draw calls, triangles, particles in a full 8-runner race.
- A 60 min server soak test with bots (memory must stay flat). Check every "player left" path (no tables growing, connections disconnected, characters destroyed).
- Tell me how to test on my phone (F9) and what numbers to send you.

6) LAUNCH CHECK
- Run the pacing sim again (all of M1-M5) and show the table: first race, first win, Silver, Go Pro 1, 2, 3.
- Play the first 15 minutes as a fresh player on phone size one last time, with the time of each step.
- A list of everything I must do before publishing: game name, description (short, simple), icon + thumbnails (I make them), genre, age rating questionnaire, passes/products IDs, group ownership, codes, notification strings, social links.

TEST + REPORT
- Before/after screenshots of each area at phone size, the sound list with loudness, the performance table, the soak test result, the launch to-do list for me. Progress note.
```
