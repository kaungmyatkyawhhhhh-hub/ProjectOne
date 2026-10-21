---
date: 2026-10-22
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Unlock Guides

Prompt: [[2026-10-22 GYM ARC Prompt - 39 Unlock guides]]. Progress: [[2026-10-22 GYM ARC Unlock guides]]. Related: [[GYM ARC - Tutorial]], [[2026-10-20 GYM ARC Gameplay plan]] ("Introduce features slowly").

## Look (22 Oct, prompt 39b)
- Tiles: graphite + faint hex mesh, thin gold inner outline, gold line icons, chunky white labels. Locked: darker, grey outline, grey padlock in place of the icon, grey label. One badge top-right: locked > gold NEW tag > red "!".
- Tabs (`Config/Guides.TabLocks`, `Kit.Tabs` tab.lock, `Kit.OpenTab`): Inventory GEAR (Spurt 2 or owning gear), AURAS (Spurt 3 or an aura / aura pass), Looks ALTERS (7'0"), Physique GENES (LVL 5 / Spurt 1).

## Locked menu tiles
- The side menu always shows all 8 tiles. A tile whose feature isn't open: dimmed, a small gold padlock. A tap: a small shake, a click, and a toast "LOCKED · Unlocks at Growth Spurt 2" with a teaser line (+ "Growth Spurt 1 · 54% there" when it's the next spurt). Taps are logged (`Locked_Tap_<tile>`, value = LVL).
- Other ways in (the Shop links, the Agency desk, Inventory / Genetics links) show the same toast while locked.
- When it opens: the padlock pops off with a sparkle sound, and a gold NEW tag + pulsing gold border stay until the tile is tapped once (saved).
- Today: SHOP, POSES, CREW at Growth Spurt 1; INVENTORY after ~60 reps (or Spurt 1); GENETICS at LVL 5 (or Spurt 1); TRAINERS at Growth Spurt 2. STATS and MUSCLES are open from the start.

## Guides
- Coach Dex's dialog (the tutorial's box, unchanged) with 1-3 lines and "Reward (coin) 25", then:
  - a menu tile / the Growth Spurt card: a gold glow on it and a bouncing gold arrow, the rest of the screen dims a little; done when it's tapped;
  - a place (Beach Gym, Pro Gym, posing stage, Trainer Agency, arm wrestling, PUMP SHOP): the gold path, a gold marker with its name and a gold GO TO button that teleports; done when the player is there.
- A first-time guide done pays its reward (+25 coins, checked on the server, once) with the gold "+25" pill.
- Rules: never on a machine, in a menu / window, a posing show, a trainer roll, the READY TO GROW / alter popup or the tutorial (they wait); one at a time, 30 s apart, a big one (a place / a reward) at most once a minute; a SKIP pill; done by itself after 40 s; each once per player (saved in `data.guides`). Existing players: whatever is already open counts as seen (no spam after the update).
- Settings "Show Tips" (was "Tutorial Hints") Off = no guides (the locks stay).
- Analytics: `Guide_shown_<id>`, `Guide_done_<id>`, `Guide_skip_<id>`, `Guide_timeout_<id>`.

## Config/Guides (the owner edits lines here)
- `Locks`: tile, need, when, tease. `List`: id, need, lines, tile / place, label, reward, big, every / after (reminders).
- Today's guides: Growth Spurt ready (first time + a short reminder each spurt), Body Alter ready (first + each new tier), heavier weight (first), Beach Gym, Shop, Poses, posing stage, Crew, Inventory, Genetics, spotting tip, Pro Gym, Trainers, Trainer Agency, arm wrestling, auras, PUMP SHOP.

## Where it lives
- `Config/Guides`, `StarterPlayerScripts/GuideClient`, `Shared/UI/CoachDialog` (moved out of TutorialClient), `Shared/UI/SideMenu` (SetLocked / SetNew / Button), `Shared/GoTo` (places), `ActionService` (Guide, LockedTap), `PlayerData` (SetGuideSeen, MarkOpenGuidesSeen), `Analytics.GuideEvent`.
