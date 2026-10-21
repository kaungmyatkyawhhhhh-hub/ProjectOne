---
date: 2026-10-22
tags: [gymarc, prompt]
status: todo
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
- Side menu buttons (SHOP, STATS, MUSCLES, INVENTORY, GENETICS, POSES, CREW, TRAINERS) are always visible. If the feature isn't unlocked yet, the button is dimmed (~50%), its icon greyed, with a small gold padlock badge in the corner.
- Tapping a locked button: a small shake + a "locked" click sound, and a toast pops up (same style as the locked-title tooltip: dark tile, gold outline, lock icon, stroked title, clean italic line, auto-hides after ~3 s). It tells WHEN it unlocks and teases WHAT's inside, so players want it. Example lines (edit in config):
  - TRAINERS: "LOCKED · Unlocks at Growth Spurt 2" / "Real coaches who train you while you train. Some are legendary..."
  - CREW: "LOCKED · Unlocks at Growth Spurt 1" / "Team up, win shows together, climb the crew board."
  - POSES: "LOCKED · Unlocks at Growth Spurt 1" / "Hit the stage. Flex in front of the whole server."
  - GENETICS: "LOCKED · Unlocks at LVL 5" / "Your DNA is hiding something. Find out what you were born for."
  - INVENTORY: "LOCKED · Unlocks in a few minutes" / "Boosts, gear and secret drops go here."
  - SHOP: "LOCKED · Unlocks at Growth Spurt 1" / "Rare stuff. Only for lifters who make it."
  Always show the real unlock condition (from the unlock table), plus a progress hint when it helps: "Growth Spurt 1 · 54% there".
- When it unlocks: the padlock breaks open (small pop + sparkle sound), the button brightens with the gold NEW glow, and the unlock guide from sections 1-2 starts.
- Same rule for locked tabs inside menus (e.g. Alters before 7'0"): padlock + teaser toast.

4) ANALYTICS
Log per guide: shown, completed, skipped, timed out. Also log taps on locked buttons (which button, player level), to see what players are curious about.

Test: a fresh save through Growth Spurt 1 and 2 (Beach Gym, posing shows, trainers), and a 7'0" save getting its first alter. Phone screenshots of one UI guide and one world guide. Short progress note in the vault.
```
