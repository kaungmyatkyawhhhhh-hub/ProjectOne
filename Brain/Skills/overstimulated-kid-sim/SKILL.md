---
name: "overstimulated-kid-sim"
description: "Use when a Roblox game's screen may get too busy: simulate kids overloaded by stacked pop-ups, cards, flashes and sounds, find missed messages and collisions, and fix until nothing piles up."
---

# Overstimulated-kid simulation

The owner's method (13 Nov 2026, Stomp Evolution), next to the impatient-kid, quality-nerd and debate-kids sims. The other sims reward "something new every few seconds", so a game tuned only by them tends to fire everything at once: on 13 Nov a boss kill showed DEFEATED + an evolve card + AREA UNLOCKED + a Coin Rain banner together, the combo counter sat on the card picker's Later button, and the talent hand opened over the evolve card. A kid misses the important thing, or feels swamped and taps everything away.

Research (vault): `Roblox Playbook\Research notes\2026-11-13 Research - Overstimulated kids (UI overload, stacked popups).md`.
- Visual working memory roughly doubles from age 5 to 10, reaching the adult level of about 3-4 items.
- Pop-ups capture attention away from the goal.
- Notifications that fire together overlap into an unreadable pile; the fix is a priority queue.
- Keep flashes under 3 per second.

Read the vault's Brain and the game's notes first.

## 1. Read the LIVE build: every thing that can appear on screen
From Studio (MCP: grep the client scripts for ScreenGuis, cards, toasts, banners, stickers, flashes, shakes, sound plays), list each emitter:
- name and trigger: evolve, area unlock, power-up hand, quest done, event start, boss kill, reward, golden, combo, daily, shop offer, etc.;
- screen region (centre card / top banner / toast stack / corner / full modal) and the size;
- how long it stays, and whether it waits for anything (cutscene, other cards);
- weight:
  - modal window or full card = 2
  - big centre card = 1.5
  - banner = 1
  - toast = 0.5
  - flash or shake = 1 for 0.3 s
  - sound sting = 0.5
- whether it blocks controls, or sits where the phone joystick and jump button are;
- KEY or not: a KEY message is one the kid must notice (evolve, new area, boss beaten, what to do next).

Then fire the real chains in Play with a Studio-only dev hook (e.g. a player attribute that sets Mass) and screenshot the busiest moments: an evolve that also unlocks an area, a boss kill that pays enough to evolve, a power-up during an event.

## 2. The kid model (Python)
- Take the event timeline from the impatient-kid / grinder sim on the same live numbers (first 10 min and a mid-game 10 min), so the triggers happen when they really would.
- Turn each trigger into the UI elements it shows (step 1), with their times and regions.
- Attention slots by age:
  - 5-6 y = 2
  - 7-9 y = 3
  - 10-12 y = 3.5
- Reading speed (estimate): about 1.5 words/s at age 7, about 3 at age 10.
- Run 2,000 kids per version with a spread of ages and of reading speeds.
- TELLS, each counted:
  - OVERLOAD: the summed weight on screen is over the kid's slots for 0.5 s or more;
  - MISSED: a KEY message is covered by another element, shown during an overload, or gone before the kid could read it;
  - COLLISION: two elements in the same region at once, or an element on a button the kid needs;
  - BLOCKED: a modal is open while the game expects action (a boss, a timed event);
  - NOISE: more than 3 sound stings in 2 s;
  - FLASH: more than 3 flashes in 1 s (photosensitivity guideline: always a hard fail).
- Report:
  - overload seconds per 10 min;
  - % of KEY messages missed, per message type;
  - the top 5 collisions by name, e.g. "bosskill card x evolve card";
  - the worst 3 moments as timelines.

## 3. Iterate
Change ONE thing per version, cumulative, and re-run. Fixes that worked or are standard:
- **One centre queue with priorities:** a cutscene first, then evolve, area unlock, boss and reward. Each card waits for the one before it (or the server delays the payout so its evolve comes after the cards).
- **Merge:** several toasts of the same kind become one ("+3 QUESTS").
- **Demote:** minor news becomes a toast or a badge, not a card.
- **Hide** small HUD pop-ups (combo counters, hints) while a window or cutscene is open.
- **Delay** modals that need a choice (talent hands, shop offers) until the screen is calm.
- **Minimum reading time** for KEY text: words / reading speed + 0.5 s.
- **Cap stings:** one big sound per moment; the others duck.
- **Keep clear** of the phone joystick (bottom-left) and jump button (bottom-right).

**Goal:**
- 0% KEY messages missed for 7-year-olds;
- under ~5 s of overload per 10 min;
- no flash failures;
- no collisions with buttons.

Also re-run the impatient-kid sim after the fixes: spacing things out must not create dead time (one big card at a time is fine; long empty gaps are not).

## 4. Deliver
- A vault note in the game's folder: how the kid works, the emitter table, the version table (overload s/10 min, % KEY missed, top collisions), the before/after screenshots of the worst moment, and what changed in Studio.
- Copy the sim code to the game's `Calc` folder.
- Build the fixes in Studio, test the worst chains in Play with the dev hook, and save. Don't publish (the owner does).
- Be honest that it's a model built on estimated weights and reading speeds. The real check is watching a kid play (or a screen recording) and seeing what they notice.