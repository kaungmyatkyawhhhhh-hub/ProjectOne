---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# 39 Unlock guides (mini tutorials for new features)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
When a player unlocks something new, guide them to it the same way the tutorial does. Read "GYM ARC\2026-10-20 GYM ARC Gameplay plan.md" (section "Introduce features slowly") and "GYM ARC\Features\GYM ARC - Tutorial.md" first. Follow CLAUDE.md Speed rules. Mobile first. Reuse the tutorial pieces (Coach Dex dialog, GuidePath gold path, glowing outline, gold marker + arrow, teleporting GO TO button). Don't build a second system.

1) WHAT TRIGGERS A GUIDE
Every unlock in the plan's unlock table, plus:
- Growth Spurt ready, first time (and a short reminder each later time).
- Body Alter ready (first alter, and every new alter tier).
- New heavier weight tier, first time only.
- New gym unlocked (Beach, Pro, Garage...).
- New feature unlocks: posing shows, crews, trainers / Trainer Agency, inventory and boosts, daily rewards, arm wrestling, spotting, auras, PUMP SHOP sections.

2) HOW A GUIDE LOOKS (1-3 short steps, like the tutorial)
- Coach Dex dialog at the bottom (same box as the tutorial): one line about what's new and why it's good, e.g. "You can GROWTH SPURT! Grow taller and unlock the Beach Gym." "Tap to continue (1/2)".
- Then point at it:
  - A UI thing (button, tab): the button gets the gold glow + bouncing gold arrow (like "TAP STOP"), and the rest of the screen dims slightly. The guide finishes when they tap it.
  - A place in the world (new gym, Trainer Agency, posing stage, new machine): gold GuidePath + gold marker with the name over the target, and a gold "GO TO ..." button that TELEPORTS them there.
- The new button also gets the gold "NEW" glow until it's tapped once (from the plan).
- A small reward on finishing the first-time guides (e.g. +25 coins), shown as the gold "+25" pill.

3) RULES
- Never interrupt: no guide while the player is on a machine, in a posing show, rolling trainers or in another menu. It waits and starts when they're free (Growth Spurt / Alter ready can show the big popup right away; the guide comes after).
- One guide at a time; queue the rest, at least ~30 s apart. Max one big unlock guide per minute.
- Every guide has a small SKIP pill and a timeout (finishes by itself after ~40 s) so nobody gets stuck.
- Each guide plays ONCE per player (saved). Existing players who already have the feature don't get it (no spam after this update), except a one-time "What's new" for features they've never opened.
- Settings: "Show tips" toggle (on by default) turns all guides off.
- All texts and steps in one config (like Config/Onboarding), so the owner can edit lines.

5) LOCKED MENU BUTTONS (owner, 22 Oct; this REPLACES "hide the button until it unlocks" from the gameplay plan)
- Side menu buttons (SHOP, STATS, MUSCLES, INVENTORY, GENETICS, POSES, CREW, TRAINERS) are always visible. Use the EARLIER left-nav tile style (owner, 22 Oct): dark graphite tile with faint hex mesh, thin gold inner outline, thick dark bottom edge, GOLD line icons (all the same gold), white chunky labels with a dark stroke. Same 8 buttons as now: SHOP, STATS, MUSCLES, INVENTORY, GENETICS, POSES, CREW, TRAINERS.
  If the feature isn't unlocked yet: the tile darker (~50-60% brightness), the gold outline turns grey, a GREY padlock in place of the icon (same size), the label grey but readable. Mockup: Downloads\gym_arc_ui_style_match\real\left_nav_badges.png.
- Button badges (left nav and other menu buttons/tabs), ONE badge per tile at a time, priority LOCKED > NEW > NOTIFICATION. Badges stay inside the tile (clip to its rounded corners); tile size never changes:
  - NEW: a small gold "NEW" tag (dark text) inside the tile's top-right corner. Stays until the button is tapped once.
  - NOTIFICATION: the small red chip with a white "!" inside the top-right corner (as now). Gentle pulse. Replaces the old red dot.
- Tapping a locked button: a small shake + a "locked" click sound, and a toast pops up (same style as the locked-title tooltip: dark tile, gold outline, lock icon, stroked title, clean italic line, auto-hides after ~3 s). It tells WHEN it unlocks and teases WHAT's inside, so players want it. Example lines (edit in config). Tone: plain, short, like a gym friend talking to a kid. Say what it is and why it's fun. No slogans, no "legend", no "secret", no dramatic "...":
  - TRAINERS: "LOCKED · Unlocks at Growth Spurt 2" / "Hire a coach who lifts with you. Some are really rare."
  - CREW: "LOCKED · Unlocks at Growth Spurt 1" / "Make a crew with your friends and win shows together."
  - POSES: "LOCKED · Unlocks at Growth Spurt 1" / "Get on stage and flex in front of everyone."
  - GENETICS: "LOCKED · Unlocks at LVL 5" / "See which muscles grow fastest for you."
  - INVENTORY: "LOCKED · Unlocks in a few minutes" / "Your shakes and boosts go here."
  - SHOP: "LOCKED · Unlocks at Growth Spurt 1" / "Spend your coins on boosts and gear."
  Always show the real unlock condition (from the unlock table), plus a progress hint when it helps: "Growth Spurt 1 · 54% there".
- When it unlocks: the padlock breaks open (small pop + sparkle sound), the button brightens with the gold NEW glow, and the unlock guide from sections 1-2 starts.
- Same rule for EVERY tab inside menus. Nothing appears later out of nowhere: all tabs and sub-tabs exist from the first time the menu opens, the not-yet-unlocked ones are locked (dimmed + padlock + teaser toast on tap).
  - Inventory: ITEMS · GEAR · AURAS · LOOKS (and Looks > ALTERS · TITLES) are all visible from the start. Locked example lines: GEAR "Unlocks at Growth Spurt 2 · Belts, wraps and straps. Each one makes a lift stronger." AURAS "Unlocks at Growth Spurt 3 · A glow around your body. Each aura gives a small bonus." ALTERS "Unlocks at 7'0\" · Change your skin once you hit max height."
  - Same for Store tabs, Stats/Muscles tabs and any other menu with tabs.
  - A locked tab can't be opened; it never opens an empty page.
  - The menu opens on the first UNLOCKED tab.

4) ANALYTICS
Log per guide: shown, completed, skipped, timed out. Also log taps on locked buttons (which button, player level), to see what players are curious about.

Test: a fresh save through Growth Spurt 1 and 2 (Beach Gym, posing shows, trainers), and a 7'0" save getting its first alter. Phone screenshots of one UI guide and one world guide. Short progress note in the vault.
```

## Done (checked 22 Oct)
The owner's update to section 5 (earlier tile style, badges, locked tabs) is exactly prompt 39b, done: [[2026-10-22 GYM ARC Unlock guides]].
