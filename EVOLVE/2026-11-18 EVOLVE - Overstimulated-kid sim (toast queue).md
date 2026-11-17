# EVOLVE: overstimulated-kid sim, 18 Nov 2026

I ran the `overstimulated-kid-sim` skill on the live build after the Develuper UI kit went in. The sim code is `Calc/overstim_sim.py`. Run it with `python -I overstim_sim.py`; it checks its own queue model on start.

## How the kid works
- **Ages:** 5–12, spread evenly.
- **Attention slots:**

  | Age | Slots |
  |---|---|
  | 5–6 | 2 |
  | 7–9 | 3 |
  | 10–12 | 3.5 |

- **Reading speed:** about 0.5 × age − 2 words per second, ±20% per kid. That is about 1.5 words/s at age 7 and about 3 at age 10.
- **Timeline:** 400 kids per version, on the real server numbers:
  - life 45 s × 0.9^Aging, never under 8 s, plus 3.5 s to respawn;
  - mutation 30%, illness 15% (Fruit diet);
  - the kid buys the cheapest upgrade whenever they can afford it.
- **Windows:** each kid opens a window about every 50 s and keeps it open for 5–15 s.
- **Missed:** a KEY toast (evolve, era, badge, purchase, asteroid) counts as missed when any of these happens:
  - it plays while a window covers it;
  - it is on screen for less time than the kid needs to read it;
  - the queue cap drops it.

## Emitter table (live build)

| Emitter | Trigger | Region | Stays | Weight | KEY |
|---|---|---|---|---|---|
| Toast "Your child evolved into X!" | life end + new species | top centre, 380×52 | 3.5 s | 0.5 | yes |
| Toast "Your people entered the X Age!" | first life as Modern Human, then each new era | top centre | 3 s | 0.5 | yes |
| Toast "Badge! X (+N DNA)" | badge reached | top centre | 3 s | 0.5 | yes |
| Toast "Thank you! …" | Robux purchase | top centre | 3 s | 0.5 | yes |
| Toast "An asteroid wiped out…" + Explosion | rebirth | top centre + world | 3.5 s | 0.5 + 1 | yes |
| Toast "Mutation!" / "Caught …" / "… was not passed on" | random, at each life end | top centre | 2.2 s | 0.5 | no |
| Toast "Generation N is born" | every life end without an evolve | top centre | 2.2 s | 0.5 | no |
| Death + respawn | every life end | world | ~3.5 s | 1 | no |
| Shop / Diet / Index window | kid taps | centre, 560×300 | while open | 2 | — |

There is no sound in the UI, so the noise count was 0. The only flash is the rebirth explosion, so the flash count was 0.

## Version table (V1–V5 build on each other)

| Version | Overload s / 10 min | KEY missed, all ages (early / mid) | KEY missed, age 7 (early / mid) | Toasts on a button, per kid |
|---|---|---|---|---|
| V0 live | 0 | 47% / 51% | 46% / 65% | 33 / 47 |
| V1 news waits while a window is open; a toast cut off by a window comes back afterwards | 0 | 31% / 40% | 31% / 60% | 33 / 47 |
| V2 + KEY toasts stay words / 1.2 + 0.5 s (the slowest 7-year-old) | 0 | 16% / 21% | **0% / 0%** | 33 / 47 |
| V3 + "Generation N" only shows when nothing else happened that life | 0 | 16% / 21% | 0% / 0% | 28 / 36 |
| V4 + the queue cap drops the lowest priority, not the newest | 0 | 16% / 21% | 0% / 0% | 28 / 36 |
| V5 + the toast moves from y 104 to y 120, below the menu buttons | 0 | 16% / 21% | 0% / 0% | **0** |

What the table shows:
- **The game never overloads.** It only ever shows one toast at a time.
- **The real problem was missed news.**
  - Badges and eras played behind an open Shop window, which sits above the toasts (DisplayOrder 20 vs 15).
  - Holds of 2.2–3.5 s were too short for a 7-year-old reading "Your child evolved into Australopithecus!".
- **The 16–21% still missed are ages 5–6.** Those kids read too slowly for any toast. A sound and icon for the big moments would reach them; that is not built yet.
- **V4 changed nothing in the sim.** The queue never passed 6 in normal play. It stays in because the live cap removed the *newest* line before sorting, which could drop an evolve.

## Screenshots
- Before: `Calc/overstim_before_badge_behind_shop.jpg`. The badge toast is playing hidden behind the Shop.
- Before: `Calc/overstim_before_toast_on_button.jpg`. The toast's corner sits on the Index button.
- After: `Calc/overstim_after_toast.jpg`. The toast sits at y 120, clear of the buttons.

## What changed in Studio
All changes are in `StarterPlayerScripts.EvolutionUI`; the vault copy is `Assets/UI art/scripts/EvolutionUI_develuper.luau`.

- **Windows pause news.** `news.pause()` runs on window open and `news.resume` on close; the resume is deferred so switching windows doesn't flash a toast.
- **Cut toasts come back.** A toast that was showing when a window opened slides out and goes back in the queue.
- **KEY holds are longer.** Toasts with priority ≥ 7 stay max(style hold, words / 1.2 + 0.5) s.
- **The routine line is skipped when there's bigger news.** "Generation N is born" doesn't show when the same life had other news.
- **The queue sorts before trimming to 6.**
- **The toast moved from y 104 to y 120.**

**Play test:**
1. Fired the worst chain (era + mutation + badge).
2. Clicked Shop while the badge toast was showing: the toast slid away.
3. Closed the Shop: the evolve toast came back first.
4. The console showed no errors.

## Honest limits
- This is a model. The weights, reading speeds and window habits are estimates, and the timeline uses fixed placeholder lines ("Mutation! Sharp Mind").
- **Not built:**
  - **Purchases while the Shop is open:** a "Thank you!" toast now waits until the Shop closes. The card turning "Owned" is the feedback in the meantime.
  - **The impatient-kid re-check** has not been run. The longer holds mean more time per toast, and at 8 s lives the queue could lag behind the game late in a run.
- The real check is a screen recording of a kid playing.
