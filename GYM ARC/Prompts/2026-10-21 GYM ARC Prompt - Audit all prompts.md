---
date: 2026-10-21
tags: [gymarc, prompt]
status: in progress
---
# Audit all prompts

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Go through every prompt note in the vault folder "GYM ARC\Prompts\" (all of them, oldest to newest).
For each one, check whether it's actually done: look at its "status:" line, the vault Progress notes, PROGRESS.md, and the game itself in Studio. Don't trust "status: todo" or "done" alone; check that the work really exists.

First, give me a short table: prompt number, name, DONE / PARTLY DONE / NOT DONE, and for partly done what's missing. Then wait for my OK.

After I say OK, do the NOT DONE and PARTLY DONE ones one at a time, in number order, with these rules:
- Skip prompts marked "status: cancelled" (prompt 26 is cancelled; prompt 32 replaced it).
- If two prompts disagree, the newer one wins, and inside a prompt the "OWNER UPDATE" / "latest" parts win.
- For UI, match the mockups the prompts point to (Downloads\gym_arc_ui_mockups_current\, gym_arc_agency_ui\*_v5.png, agency_final.png, gym_arc_alters\ui_tier1\mockups.png).
- Never undo my own manual Studio changes.
- After each prompt: set its "status:" line to done, write a short progress note, then go to the next.
- Stop and tell me whenever I need to import files, upload images, or do something in Creator Hub.
- Follow the CLAUDE.md Speed rules.
```

## Owner's order (21 Oct, after the audit)
```text
OK, with these changes to the order:
1-5 as you said (lift screams, NPC test, performance leftovers, town music + treadmill sounds, prompt 9 chest meshes).
Then: 29 (trainer lag, first because players are lagging), 32 (restore starter gym, because 27 and 31 put the Trainer Agency and Coach Dex in it), 28 (UI cleanup, 31 builds on its inventory tabs), 27, 31, 22, 12, 30, 33.
15 and 35 when I've imported the files.
Also confirm prompts 34 (trainer outfits + gear meshes) and 25 (new trainers) are really DONE. 34 was still in progress last time I looked. If not done, do 34 right after 33 (it needs the gear meshes in Downloads\gym_arc_gear_meshes\).
```
