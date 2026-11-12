---
tags: [brain, method]
created: 2026-11-09
---
# Debate kids simulation

**Owner's words:** "use the debate kids method. simulate multiple group of kids arguing over which roblox game to play. find the objections they have to yours and improve the game until everyone agrees to play ur game" (9 Nov)
**Use when:** a new game or a big update: "would a group of friends pick ours?", "what will kids object to?"; before building the launch scope and before ads. Goes with [[Kid focus group (ChatGPT)]] (ChatGPT plays kids in words; this is the numbers version) and the [[Impatient kid simulation]] / [[Quality-nerd kid simulation]].
**Skill:** debate-kids-sim (proposed 9 Nov)

## Steps
1. Pick the rivals kids would really choose instead: the top live games (Rowatcher / GGRecon / Rolimons) + the closest games in the genre. Score each 0-10 on the same traits (first minute, depth, social, PvP thrill, PvP safety, fair money, looks, cute/funny, scary, players online, updates, phone, easy, new, original, collect, show-off, theme).
2. Define ~10 kid types: what each argues for (weights) and a deal-breaker with the line he says ("it's pay to win", "nobody plays it, it's dead", "it's too scary"...).
3. Run ~3,000 friend groups of 3-5 kids, each with our game + 3 random rivals. Friends play the best game NOBODY vetoes.
4. Calibrate: big rivals should land at roughly 20-60% "everyone agrees", a dying game near 0%. Fix the model before judging our game.
5. Report "everyone agrees", "1st pick" and the top objections (with the kids' words). Fix the biggest objection with ONE concrete feature per version (cumulative).
6. Robustness: move every score of our game ±1 at random; any objection that comes back = a score sitting on a deal-breaker: add margin there. Test a small launch crowd separately.
7. Goal: 100% agree, robust to ±1, and say clearly which objections need marketing, not design.

## Tools
- Python; reference code `MEGA BITE/Calc/debatekids.py`.

## Output
- A game note with the version table, example debates, the plan changes; code + results in the game's `Calc`.

## Used on
- 2026-11-09 MEGA BITE: 18% → 100% agree (robust), 90% 1st pick, 8 fixes; the risk left: a small launch crowd (60%) → [[2026-11-09 MEGA BITE - Debate kids simulation]]

- 2026-11-13 GYM ARC (live game, build v1882): 4% → 100% agree (robust), 93% 1st pick with 6 design fixes + a launch push; five objections tied (pay to win, lag, dead, play together, no PvP); the crowd (56 players) is the one design can't fix → [[GYM ARC/2026-11-13 GYM ARC - Debate kids simulation]]

## Learned
- First calibration was wrong: old hit games were vetoed as "copies". Keep "original" (not a copy) apart from "new".
- The robustness check found two fragile scores the first 100% hid (PvP thrill, players online).
- 2026-11-11 Stomp Evolution: 9% → 100% agree (robust), 93% 1st pick; biggest fixes: first minute, hand-made look, fighting at launch; small launch crowd still 59% → [[TITAN ARC/2026-11-11 Stomp Evolution - Three kid simulations (impatient, quality nerd, debate)]]
- Learned 11 Nov: feed the other two sims' version-A results into our starting scores (first_min, looks), so the debate starts from the plan as it really is. A score sitting exactly on a deal-breaker shows no veto but is fragile: lift it anyway.
- Learned 13 Nov (live game): give half the groups a gym-only slate (kids who already want the genre) and half the big hits; report both. For a LIVE game, take the starting scores from real evidence (critic review, funnel, owner's like/dislike reports) and check live player counts of rivals first.
