---
date: 2026-10-28
tags: [gymarc, prompt, video]
status: todo (after 88)
---
# 89 Video recording mode (for the game page video)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Why: [[Roblox Playbook - Updates, storefront and analytics]] (real gameplay video autoplays in Recommended For You, up to +39% playtime from that row)

Roblox rules for game-page videos: **real, current gameplay only**. No trailer edits, no voiceover, no promo text on top. So the video must be recorded from the real game, not made by AI.

```text
GYM ARC: build a Studio-only RECORDING MODE so the owner can record a clean gameplay video for the game page. Follow CLAUDE.md. Only the GYM ARC Studio. Nothing here may run in the live game (Studio + owner-only, behind a Workspace attribute RecordingMode).

1) Recording mode (Workspace attribute RecordingMode = true, Studio test only):
- Give the test player a strong showcase save (big body near 7'0", a nice alter skin, a Legendary trainer following, an aura) WITHOUT touching real player data.
- Hide only debug stuff (test labels, admin text). Keep the normal HUD (it's real gameplay).
- A small owner-only hotkey panel: 1-6 teleports to the 6 shots below; R starts/stops a smooth recording camera for that shot.
2) The 6 shots (each 4-6 s, smooth camera, real gameplay happening):
  1. Bench press in the Pro Gym: reps with plate clanks, +EXP numbers, coins flying.
  2. Growth Spurt moment: the character grows taller (the best "transformation" shot).
  3. Trainer roll: the Legendary reveal cutscene.
  4. Body Alter: the skin changing (Gold or Chrome).
  5. Strongman Yard: lifting the Atlas stone / tire.
  6. Hall of Fame: the statues and gold lights, ending on the HALL OF FAME sign.
- Each shot: Camera.Focus set every frame, no camera shake, 16:9.
3) Tell me exactly how to record: Studio Play (not Run), set graphics to the highest, Roblox window 1920x1080, press Win+Alt+R (Windows Game Bar) or use OBS, press 1..6 and R for each shot, stop. Where the files are saved.
4) Test it once yourself with screenshots of each shot's first frame. Progress note.
```

## Owner steps after recording
1. Record with **Win+Alt+R** (Windows Game Bar, saves to Videos\Captures) or OBS, 1920x1080.
2. Send the clips to Claude (attach them in the chat). Claude cuts them into one 15-30 s video (best moment first, no text, no voiceover, game sound only), sized for upload.
3. Creator Hub > GYM ARC > Places/Experience > Thumbnails > add video (3 video uploads a month), put it first.
