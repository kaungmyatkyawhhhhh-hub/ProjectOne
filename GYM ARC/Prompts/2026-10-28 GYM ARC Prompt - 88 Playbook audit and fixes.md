---
date: 2026-10-28
tags: [gymarc, prompt]
status: todo
---
# 88 Playbook audit and fixes

Back to [[00 GYM ARC Home|GYM ARC Home]] · Rules: [[Roblox Playbook - Rules for every game]]

Owner, 28 Oct: "store all of this research so GYM ARC can read it and fix the things right now." Run this AFTER the Hall of Fame work (80-87) is stable, and don't break Saturday's launch.

```text
GYM ARC: audit the game against the Roblox Playbook and fix what's wrong. Follow CLAUDE.md. Only the GYM ARC Studio.
READ: "Roblox Playbook\Roblox Playbook - Rules for every game.md" fully. For details, SEARCH inside the 3 Playbook guides (don't read them whole).

STEP 1 - AUDIT FIRST (no changes yet). Go through every rule (sections 1-10) and check GYM ARC in code + Studio. Write a table in GYM ARC\Progress\ "Playbook audit": rule, PASS / FAIL / OWNER TO DO, what you found, how big the fix is. Must check at least:
- Odds: every paid or Robux-bought random thing (trainer rolls, eggs, DNA, any luck boost) shows exact % odds before buying; luck boosts show their effect; PolicyService restrictions respected.
- No fake timers/sales that reset (Starter Pack timer must be real), calm offer wording for kids.
- Text filtering: crew names/tags and any other player-typed text filtered on the server with TextService, again when loaded.
- No links/"check our socials" text anywhere in the game.
- Prices: every shown Robux price read from GetProductInfo/MarketplaceService, nothing hard-coded. Developer products granted only in ProcessReceipt, saved before confirming, never twice.
- Cutscenes and scripted cameras (roll cutscenes, Hall of Fame ceremony, menu flyover): Camera.Focus set every frame; all skippable; nothing depends on watching to the end; camera shake/flash off when GuiService.ReducedMotionEnabled.
- Reduced Motion and settings: Music / SFX sliders exist; screen shake and flashes respect Reduced Motion.
- Performance: parts, lights (only area lights on, no prop shadows), Glass, partly transparent parts, textures over 512 px, SurfaceGuis without MaxDistance, per-frame loops over many objects, particles over budget, Highlights count.
- Data: session lock, save on leave/shutdown/purchase, retries; every RemoteEvent checked on the server (types, math.isfinite, rate limits).
- Analytics: onboarding funnel steps, plus economy events (LogEconomyEvent for coins sources/sinks), progression events (growth spurts, alters, Hall of Fame stars), and a few custom events. List what's missing.
- Live ops: is there a Config (ConfigService) switch for new content / events? Is the Hall of Fame behind a switch? Is there a server-restart countdown (ServerRestartScheduled) and a safe save on restart? Admin commands: server-checked permissions, logged, test switches can't run in the live game.
- UI: any placeholder buttons (plain coded rectangles) left; anything breaking the UI kit.
- First session: time to first action, first reward, first growth spurt; anything stacked on tutorial hints.

STEP 2 - FIX the safe FAILs yourself (rules, filtering, odds panels, prices from Roblox, Camera.Focus, Reduced Motion, analytics events, Config switches, restart countdown, small performance fixes). Each fix: test (2-player Studio test, no console errors, phone-size screenshot). Don't change the economy numbers, the UI kit look or anything the owner made by hand.
STEP 3 - Big items (bigger performance work, anything that changes gameplay): don't do them, list them with a suggested prompt each.
STEP 4 - OWNER TO DO list in plain steps (Creator Hub: maturity questionnaire, Kids and Select / Audience Reach, ID + 2-Step Verification, custom thumbnails + Thumbnail Personalization, genre, Experience Event for the Hall of Fame launch, Update Announcement text under 60 characters).
Report: the audit table, what you fixed, what's left. File > Save to Roblox.
```
