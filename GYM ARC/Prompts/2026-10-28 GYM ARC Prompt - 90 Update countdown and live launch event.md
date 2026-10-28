---
date: 2026-10-28
tags: [gymarc, prompt, liveops]
status: done
---
# 90 Update countdown and live launch event

Back to [[00 GYM ARC Home|GYM ARC Home]] · Playbook: [[Roblox Playbook - Updates, storefront and analytics]] (updates section)

**Done 28 Oct:** see [[2026-10-28 GYM ARC Update countdown and live launch event]] and [[GYM ARC - Live Update Events]]. Owner added: log the update in the in-game NEWS once the Hall of Fame switch is on (done).

Owner, 28 Oct: "there should be a cutscene during update and a countdown like the other big games." First use: the HALL OF FAME launch (Sat 31 Oct). Build it as a reusable system for every future update.

```text
GYM ARC: a reusable LIVE UPDATE EVENT system (countdown + a live cutscene that plays for everyone at the same moment + unlock), first used for the Hall of Fame launch. Follow CLAUDE.md and the Roblox Playbook rules. Only the GYM ARC Studio. Search "Roblox Playbook - Updates, storefront and analytics.md" for the updates section if needed.

KEY RULE: the update is published EARLY (hours before) with the new content hidden. Nothing is republished at launch time. The launch happens by a UTC timestamp (and can be moved by a Roblox Config switch), so it fires on every server at the same second, even if I'm asleep. Never restart servers at launch time.

1) EVENT CONFIG (one entry per update, in Config + a Roblox Experience Config override so I can change the time or cancel without republishing):
   name ("HALL OF FAME"), launchUtc (timestamp), countdownStartUtc (e.g. 24 h before), cutscene id, what it unlocks (feature switches), rewards for players online at launch (e.g. a "Launch Day" title + a small boost), enabled true/false.
   Use workspace:GetServerTimeNow() so every server and player is in sync.

2) BEFORE LAUNCH (hype, like big games):
   - A countdown board in the town plaza / in front of the Hall (big digital clock + "HALL OF FAME" + a covered / locked Hall with a glow and a sign "OPENS IN").
   - A small HUD countdown pill (kit style, not a placeholder) from 24 h before: "HALL OF FAME IN 3:12:05". Tapping it shows what's coming (3 short lines, no hype claims).
   - Last 10 minutes: the pill grows, music slowly builds, players are invited (button) to gather at the Hall (GO TO teleport). Last 10 seconds: big 10..1 numbers in the middle of the screen with a tick sound.
   - Players who join during the countdown see it right away (tutorial still first for brand-new players).

3) AT LAUNCH (the live moment, ~20-30 s, everyone in every server at once):
   - Lights dim, a rumble, the camera leaves the player and flies to the Hall: doors open / the cover drops, gold light beams, fireworks and confetti, crowd cheer, the HALL OF FAME title slams in, then the camera flies back to the player.
   - Client-side cutscene (cheap, pooled VFX, Camera.Focus set every frame, no camera shake / flashes when GuiService.ReducedMotionEnabled is on). Players on a machine or in a menu get pulled out safely first; nothing is lost.
   - After it: the switches turn on (Hall of Fame usable), a toast "HALL OF FAME IS OPEN", the launch reward is given to everyone online (server-side, once per player, saved).
   - Players who join AFTER launch: no forced cutscene; a short "NEW: HALL OF FAME" popup with a WATCH button that replays the cutscene, and a GO TO button.
   - Late servers / restarts: if a server starts after launchUtc, it's simply already launched.

4) REUSE: the system takes any event entry (next updates: winter, new gym...). Cutscene = a list of camera shots + effects in a module so each update can have its own.

5) SAFETY + TESTING:
   - Studio-only test switch (Workspace attribute TestLaunchIn = seconds) to run the whole countdown + cutscene in 60 s. Never active in the live game.
   - An admin command to start it now / move it / cancel it (server-checked, logged).
   - Test with 2-3 players in Studio: countdown in sync, cutscene plays at the same time for all, unlock works, launch reward given once, a player joining after launch gets the popup. Phone-size screenshots of the board, the HUD pill, the 10..1 and the cutscene. Check FPS during the cutscene.
   - Analytics: custom events LaunchEvent_Seen (online at launch), LaunchEvent_Replay, and how many players were online at launch.

6) TELL ME (plain steps):
   - What time to set for Saturday (I want it at 9:30 PM Myanmar time = 15:00 UTC, Sat 31 Oct) and how to change it in Creator Hub > Configs if I need to.
   - When to publish (a few hours before, then "Restart only outdated servers" with a delay well BEFORE the launch, never at launch time).
   - The game page: create an Experience Event for the same time (Notify Me), and an Update Announcement under 60 characters to send at launch.
```

## Notes
- Run order: finish Hall of Fame (80-87) → **90 (this)** before Saturday → 88 (Playbook fixes) → 89 (video recording mode).
- Update day runbook: publish early → restart outdated servers hours before → countdown runs by itself → live event at 15:00 UTC → send the Update Announcement → watch Error Report and players for 1-2 hours.
