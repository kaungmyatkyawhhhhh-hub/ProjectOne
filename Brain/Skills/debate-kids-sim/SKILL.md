---
name: "debate-kids-sim"
description: "Use for a new Roblox game or big update: simulate friend groups arguing over which game to play, find kids' objections to ours, and fix the game until every group agrees."
---

# Debate kids simulation

The owner's method (9 Nov 2026, MEGA BITE): "simulate multiple group of kids arguing over which roblox game to play. find the objections they have to yours and improve the game until everyone agrees to play ur game." Vault method note: `Brain\Methods\Debate kids simulation.md`. Reference code: vault `MEGA BITE\Calc\debatekids.py`; note "2026-11-09 MEGA BITE - Debate kids simulation". Read the vault's Brain and the game's notes first.

## 1. Rivals
- Pick the games kids would really choose instead: the current top live games (Rowatcher, GGRecon, Rolimons; look them up, they change) plus the closest games in the genre.
- Score each 0-10 on the same traits: first minute, depth, social, PvP thrill, PvP safety, fair money, looks, cute/funny, scary, players online, updates, phone, easy, new, original (not a copy), collect, show-off, theme fit. Our game too, from its notes and sims.

## 2. Kids
- ~10 kid types, each with weights (what they argue for) and a deal-breaker with the line they'd say: Grinder ("nothing to do after a day"), PvP sweat ("no real fighting"), Little sibling ("too scary", "big kids will eat me", "not cute"), Cheap-phone kid ("it lags"), Social kid ("we can't play TOGETHER"), Trend chaser ("nobody plays it, it's dead"), Quality nerd ("looks like AI slop", "a copy"), No-Robux kid ("pay to win"), Theme fan, Bored-fast kid ("boring at the start").

## 3. Run
- ~3,000 friend groups of 3-5 kids; each group gets our game + 3 random rivals.
- Friends only play a game NOBODY vetoes; among those, the best total score; if all are vetoed, the fewest vetoes.
- Calibrate first: big rivals should land at roughly 20-60% "everyone agrees", a dying game near 0%. If not, fix the model (e.g. keep "original" apart from "new": old hits aren't copies).

## 4. Iterate
- Report "everyone agrees" (no veto on ours), "1st pick", and the top objections in the kids' words.
- Fix the biggest objection with ONE concrete feature per version (cumulative), and say which feature raises which score.
- Robustness: move every score of our game ±1 at random (~60 tries); any objection that returns is a score on a deal-breaker: add margin.
- Test a small launch crowd separately and say clearly which objections need marketing, not design.
- Goal: 100% agree, robust to ±1.

## 5. Deliver
- Vault note: how it works, the version table, 2-3 example debates (before/after), the changes to the game plan.
- Update the game's home note and its Claude Code prompts with the new launch items. Code + results in the game's `Calc`.
- Be honest: it's a model of arguments (estimated scores); the real check is a friends test asking each kid what they'd play instead and why, then the onboarding funnel.