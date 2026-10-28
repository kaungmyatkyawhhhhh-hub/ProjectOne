---
date: 2026-10-29
tags: [gymarc, prompt, retention, onboarding]
status: todo (7 Nov, with 104 and 108)
---
# 106 First 3 minutes

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plan: [[2026-10-29 GYM ARC The whole game plan (research loop)]] · Research: [[Playbook notes - Whole-game research (Oct 2026)]] (Roblox counts quits under 60 s and 61-180 s against us; about half our new players leave before the first Growth Spurt)

```text
GYM ARC: make the first 3 minutes fast, clear and rewarding. Follow CLAUDE.md and "Roblox Playbook - Rules for every game". Only the GYM ARC Studio. Read first: Tutorial, Growth Spurts, Analytics, Unlock Guides, Loading Screen and Menu, Game Feel. Never undo my manual Studio changes. The tutorial changes only affect players who haven't finished it; a player saved mid-tutorial moves to the matching new step. Also fix any menu/loading text that promises "8 feet" → "7 feet" (7'0" is the real top today).

0) BEFORE: report today's numbers from the onboarding funnel + FirstGrowthSpurt funnel (players per step, last 14 days) and the real median minutes to the first Growth Spurt (custom event FirstGrowthSpurt).
1) FIRST GROWTH SPURT IN ~2 MIN: lower the first goal so a real new player (who has the new-player 2x boost) reaches it in about 2 minutes (now ~4-5). Players already mid-run never get a HIGHER goal than they have now. Spurt 2 about 5 minutes. Re-tune later spurts so the total time to 6'0" stays about the same (~1 h). Prove it with tests/pacing (table before/after) and re-run the Hall of Fame run-2 pacing from prompt 95 (it starts at Spurt 3, so these changes move it).
2) WELCOME BONUS (endowed progress): a new player's Growth Spurt bar starts 20% filled, labelled "WELCOME BONUS" for 5 s. Check the first-rep reward still fires in the first 15 s.
3) TUTORIAL = 4 STEPS: (a) walk to the Flat Bench (glowing beam on the floor), (b) lift (bouncing arrow on the rep button, no text wall), (c) "watch your bar" (the Growth Spurt bar pulses once), (d) GROW (the button glows when ready). Everything else becomes a just-in-time tip: shake tip the first time stamina is low, Stats tip right after Spurt 1, Coach Dex after Spurt 1, skate guide at Spurt 2 (remove the skate tutorial step here; 91 runs a week later). Coach Dex lines: max one short sentence.
4) TIMED HINTS: if a new player does nothing for 10 s during the tutorial, the beam/arrow pulses again and Dex says one short line. Never more than once per 10 s.
5) MINUTE ONE IS CLEAN: during the tutorial the HUD shows only the Growth Spurt card, Future You (when 91 lands) and coins. PLAY on the menu is tappable within 2 s of the menu appearing. No offers, no daily calendar popup, no playtime toast until the first Growth Spurt is done (they wait, they're not lost).
6) MOMENT OF JOY: the first Growth Spurt plays the existing transformation, then one line "Next: BEACH GYM" with a GO TO button. Keep it short (tap to continue after ~1 s). After it, everything that waited comes ONE PER MINUTE in this order: daily calendar, playtime gift, tips, (later) the notification opt-in from 107. Never two popups at once.
7) ANALYTICS: leave the old onboarding funnel as it is (history) and log a NEW funnel "Onboarding_v2" for the new steps (otherwise the dashboard shows fake drop-offs at the removed steps); custom event "Hint_Shown" with the step in a custom field; keep FirstGrowthSpurt minutes.
7b) SWITCH: Config/Experience Config FastStart_Enabled (false = old tutorial and old first goal), so it can be undone live. Write before/after in the progress note so I can compare next Sunday.
TEST: 3 fresh players in Studio (phone size): time to first rep, time to first Growth Spurt, hint after 10 s idle, no popups before Spurt 1. Screenshots. Progress note + update Tutorial, Growth Spurts and Analytics notes.
```

## Added 29 Oct from the playtest ([[2026-10-29 GYM ARC Playtest - first 6 minutes]])
```text
8) NEVER INTERRUPT THE BAR: no tutorial step may make the player STOP a machine or open a menu while the first Growth Spurt bar is filling (today it stops them at 50% and 83%).
9) SPURT BAR ON THE MACHINE: a slim Growth Spurt progress bar on the machine HUD (the right column collapses there today, so the goal is invisible while lifting).
10) SEE YOUR BODY: the machine cameras (flat bench first) frame the lifter's upper body, not the plates.
11) QUIET UI IN MINUTE ONE: max one line of text on screen; no 2-page Coach Dex dialogs; hide every locked left-menu tile except the next unlock; your own title tag hides near machines (it covers OCCUPY).
12) STATS: no floating giant numbers over the world for new players; the Stats tip comes after Spurt 1 and shows the 6 group bars.
13) READY TO GROW = ONE MESSAGE: while a Growth Spurt is ready, mute PR / weight-unlocked / personal-best toasts; only one TAP TO GROW (today 3 buttons + 6 messages).
14) CLEAN TRANSFORMATION: during the Growth Spurt moment hide machine signs, ProximityPrompts, trainers and over-head tags.
15) AFTER THE TUTORIAL: the SKIP pill disappears (bug: it stays); quests window, free trainer roll, DEAL badge, FREE 1,000, INVITE, CODES wait until after Spurt 1 and come one per minute; the first session's quests point at the Growth Spurt (not "run 1 km").
16) MENU: the line under the logo says "Lift to grow taller." and the menu flyover camera never passes through walls.
```
