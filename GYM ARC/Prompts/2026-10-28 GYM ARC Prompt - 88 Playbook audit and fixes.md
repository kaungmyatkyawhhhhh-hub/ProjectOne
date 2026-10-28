---
date: 2026-10-28
tags: [gymarc, prompt]
status: todo
---
# 88 Playbook audit and fixes (only what's NOT done yet)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Rules: [[Roblox Playbook - Rules for every game]]

Run AFTER the Hall of Fame work (80-87) is stable; don't break Saturday's launch. Checked against the vault on 28 Oct so it doesn't repeat finished work.

**Already done, don't redo:** loading SKIP at 5 s + world load capped (83); trainer odds board + genetics "View odds" (23 Oct, 27 Oct); crew name/tag filtering; Store prices read from Roblox with fallbacks; Starter Pack popup calmer (every 15 min, max 3 a session); codes (RELEASE, GYMARC, HALLOFFAME, STRONGMAN) and the Admin console; onboarding + FirstGrowthSpurt funnels; performance passes (NPC culling, LOD, streaming LowMemory, remodel of 10,852 parts into meshes, only 5 lights cast shadows, plate labels, mirror, body rewrites); placeholder button audit (28 Oct); soft shutdown (13 Oct). Hall of Fame cutscenes stay unskippable (owner's choice).

```text
GYM ARC: Playbook fixes, only the items below (the rest is already done, see the list at the top of this note). Follow CLAUDE.md. Only the GYM ARC Studio.
READ: "Roblox Playbook\Roblox Playbook - Rules for every game.md". For details SEARCH inside the Playbook guides (don't read them whole).

1) CAMERA.FOCUS: since mid-2025 lighting/shadow/material detail follows Camera.Focus. In every scripted camera (roll cutscenes, Hall of Fame soul cutscenes and ceremony, menu flyover, genetics 3D stage, any other Scriptable camera) set Camera.Focus every frame to what the camera looks at. Before/after screenshots of one cutscene.

2) REDUCED MOTION: when GuiService.ReducedMotionEnabled is on, turn off screen shake and big flashes everywhere (roll reveals, Hall of Fame, rank ups, level ups) and use fades instead of big camera moves. Cutscenes still play (owner wants HoF unskippable), just calmer.

3) STARTER PACK WORDING: keep the real 24 h window, but remove the ticking "ENDS IN 23:59:15" countdown and the crossed-out "250 R$" from the popup and card (Roblox bans false time pressure and fake sales; kids' wording must be calm). Use "NEW PLAYER PACK - only in your first day" and show what's inside. Same check for the VIP 30% OFF card (a real one-time deal is fine; no fake "was" price unless VIP is really sold at 299).

4) LIVE SWITCHES WITH ROBLOX CONFIGS: move the launch switches (Hall of Fame on/off, loading badge, events, double-XP weekends, new codes if useful) to Roblox Experience Configs (ConfigService) so I can flip them in Creator Hub without republishing (live in 15-60 s). Keep the current Config modules as the default values. Tell me step by step how to flip one in Creator Hub.

5) SERVER RESTART: check the soft shutdown uses Roblox's "Restart only outdated servers" + ServerRestartScheduled: show an in-game countdown ("Update in 2:00 - your progress is saved") and save everyone before the restart. Fix if not.

6) ANALYTICS: add what's missing: LogEconomyEvent for coins and DNA tokens (every source and sink, with transaction types), LogProgressionEvent for Growth Spurts, Alters and Hall of Fame stars, and a few custom events (shop opened, offer shown / bought, trainer roll, code redeemed). Server only, once per real action. List the event names in a note.

7) QUICK RULE CHECKS (fix if found): any text mentioning Discord / socials / links in the game; any player-typed text not filtered (besides crews: pet/trainer names, signs, profile text if any); any random thing bought with Robux (or with items bought with Robux) without an odds panel; any Robux price hard-coded with no live price.

TEST: 2-player Studio test, no console errors, phone-size screenshots of the Starter Pack card, one cutscene, the restart countdown. Progress note with what changed.

OWNER TO DO (write these as plain steps at the end of your report):
- Creator Hub > GYM ARC > Audience Reach / Maturity questionnaire: fill it fully (aim Minimal/Mild), ID + 2-Step Verification, start the Kids and Select trial.
- 3-5 different thumbnails + Thumbnail Personalization on (keep 7+ days), add a gameplay video.
- Genre (Simulation), set once (locks 3 months).
- Experience Event for the Hall of Fame launch (Notify Me) + an Update Announcement under 60 characters.
- Phone test: FPS and memory in the hub, the gyms and the Hall.
```
