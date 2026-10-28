---
date: 2026-10-29
tags: [gymarc, review, economy, monetization, trainers]
status: proposal
---
# Systems review: training, economy, monetization, trainers, genetics

Back to [[00 GYM ARC Home|GYM ARC Home]] · Plan: [[2026-10-29 GYM ARC Master plan - one ladder]] · Lessons: [[Playbook notes - Costly mistakes of big games]]

Read on 29 Oct from the vault: Gains and EXP, Stamina, Machines, Economy and Daily Rewards, Pump Shop, Boosts Inventory, Monetization, Personal Trainers, Genetics, Titles, and the 23 / 26 / 28 Oct progress notes.

## 1. Training and progress
**Now:** gains per rep = weight tier × genetics × frame/body × spurt/alter bonus × boosts × Muscle of the Day × diminishing; all capped at x5 (+1 per alter tier); PUMPED, BIG REP and Hall of Fame stars outside the cap; trainers have their own +400% cap; gear +5/+10%; coin boosts capped x8. Stamina pacing by spurt; free auto reps at 40%, Auto Rep pass at 100%.
**Problems:**
- **Too many hidden layers and caps.** A kid can't tell why they're getting what they get. Worse: when the cap is hit (MAX BOOST), extra boosts, trainers and Robux supplements do **nothing**. Paying for something that does nothing is the fastest way to lose trust (Grow a Garden "rewards not worth it", PS99 backlash).
- **"Needs LEGS" chores:** 6 groups must all reach the goal, and diminishing returns make the top group crawl. Good for variety, but it's the main "grind" feeling.
**Fixes:**
1. **One GAINS number** on the HUD/Stats ("GAINS x3.4") with a simple breakdown: BODY (spurts/alters/genetics), TRAINERS, BOOSTS, GEAR. Four buckets, not ten.
2. **Never waste a boost or a purchase:** if a boost/supplement/pass wouldn't add anything because of the cap, the button says "MAXED: no effect right now" and the Robux offer doesn't show. Long term: raise the cap per stage instead of a hard wall.
3. Keep "Train next" + Body Map red groups (already); add "BALANCED +10%" more visibly so switching machines feels rewarded, not forced.

## 2. Economy (coins)
**Now:** one currency (good). Rewards = "minutes of coins at your stage" (good: rewards never become worthless). Sinks: trainer rolls (main, endless), gear (Basic 750 / Pro 4,000 only; Elite/Champion off sale), coin supplements at Coach Dex, DNA tokens (25,000, +10% per token per week), STYLE colours (5,000-120,000), trainer snacks.
**Problems:**
- **Mid-game coin hole:** after the Pro belt/wraps (4,000) there's nothing to save for except rolls and cosmetics. "What do I buy next?" has no clear answer between Spurt 3 and Alter 15.
- Coins don't help the ladder (height/alters), so grinding coins feels separate from growing.
**Fixes:**
1. **Gear ladder back on sale for coins, tied to gyms:** Basic (Starter) → Pro (Pro Gym) → Elite (Powerlifting Gym) → Champion (Golden Era Gym) → Legend (Hall of Fame). Each new gym = a new thing to save for. Elite/Champion owners keep theirs.
2. **Show the next purchase on the Progression Road** ("Next: Elite Belt 25,000 · you 18,400").
3. Keep DNA tokens and STYLE as long-term sinks (fine as they are).

## 3. Monetization
**Now:** ~25+ things for sale: passes 2x EXP 249, 2x Coins 149, VIP 299 (deal 209), Aura Pack 199, Auto Rep 249, Extra Trainer 99, 4th Trainer; products: coin packs 25/99/249 (scale by stage), Shake Bundle 49, Endless Stamina 49, DNA 99 / x3 249, Quest Reroll 19, Starter Pack 49 (Active Projects says 79: check), 4 Robux supplements 25/99, 6 alter variants 149-299.
**Problems:**
- **Paid power vs. caps** (see 1): Robux supplements and 2x EXP can be wasted at MAX BOOST.
- **Paid random outcomes:** DNA tokens buy a genetics reroll (random grades that change power) and coin packs buy coins that buy trainer rolls. Odds are shown (good), but Roblox also requires respecting `PolicyService` (`ArePaidRandomItemsRestricted`) so players in some countries can't pay Robux for random results. Check this is done for DNA and for rolls paid with purchased coins.
- **Trainer slots (28 Oct):** slots 3-4 used to be free (first alter); now only passes give them. If any existing player lost a free slot, that's the "taking away" mistake (Fisch, PS99). Existing players must keep what they had.
- **Choice overload:** 25+ items, many tiny (19-49 R$). Kids skim; a clear, small store sells better.
**Fixes:**
1. **Store front = 6 heroes:** Starter Pack, Auto Rep, 2x EXP, VIP, Extra Trainer, one cosmetic (alter variant of the week). The rest one tab deeper.
2. **Cosmetics are the future money:** alter variants, Hall of Fame looks (star auras, Legend Form colours), statue frames. Fair, no P2W, and they fit the "show it off" rule. Add one new variant with each weekly update.
3. **Fairness checks (prompt):** PolicyService for paid random, "MAXED" instead of selling useless boosts, existing players keep free trainer slots, Starter Pack price consistent everywhere, competitions keep divisions by stage so paid boosts don't win shows against small players.
4. Reality check: with ~10-20 players online, the store isn't the bottleneck; retention is. Don't add more products until D1 ~10%.

## 4. Trainers
**Now:** 8 trainers, one per rarity (Sam 42%, Nia 30%, Lou 18%, Rex 7%, Duke 2.2%, Volta 0.6%, The Shadow 0.16%, Atlas 0.04%); coin rolls only; pity stages (Legendary in 50 → Mythic in 100 → Secret in 150); levels 1-20 (+10%); evolutions 3 → 1 (BASE x1 ... LIMITLESS x2); boosts up to Atlas +75% BASE, +165% at LIMITLESS LV 20; trainer cap +400%; 2 slots (+2 by passes); snacks; Best Equip; auto-delete.
**Problems:**
- **Only 8 to collect.** Top sims have dozens to hundreds (Gym Star "100s of pets", Arm Wrestle Sim 2,500+). After the first few rolls there's no "new one" to chase, only duplicates.
- **Evolution goals are invisible/impossible:** LIMITLESS = 81 copies of the same trainer (81 Atlases ≈ 200,000 rolls). Players can't see a reachable next goal.
- **Luck beats work:** one lucky Atlas (+75% EXP and coins) outweighs hours of training. Fine for excitement, but it weakens the "I grew by training" feeling.
- Rarity names changed over time (Eternal tier gone, Volta now Legendary): check every board, odds panel and the notes say the same thing.
**Fixes:**
1. **A trainer pool per gym** (like eggs per zone): Starter Agency (the 4 coaches), Beach / Pro / Powerlifting / Golden Era / Hall of Fame agencies each add 3-5 new trainers with that gym's theme. Each new gym = new trainers to chase = a new desire on the ladder. Old trainers stay.
2. **Duplicates always useful:** evolutions need fewer copies at higher stages (e.g. 3, 3, 2, 2) or duplicates can be fed for trainer EXP, so pulling a duplicate never feels like nothing.
3. **Trainer index in the Collection book** (Champion/collection plan): owned / not owned / stages reached, rewards for completing a gym's set.
4. Keep: coins only, odds always shown, pity stages, no server spam.

## 5. Genetics, titles, small systems
- **Genetics:** fine as a later layer (now at Spurt 4 in the plan). Grades D 0.75x to S 1.5x per group is a big swing; keep the free first reroll, odds panel, and PolicyService for Robux tokens.
- **Titles:** good free collection; fold into the Collection book. Never sold (keep).
- **Posing shows / Strongman Showdown / arm wrestling / court:** keep divisions by stage so small players can win something; rewards should be visible (titles, auras, statue time), coins as bonus.
- **Spotting, playtime gifts, offline coins, rush hour, re-racking:** small, fine, quiet.

## Proposed order (fits the weekly plan)
| When | What |
|---|---|
| With prompt 95 (before Sat) | Fairness checks: existing players keep free trainer slots; Starter Pack price consistent |
| With 91 (7 Nov) | One GAINS number + "MAXED: no effect" on boosts/offers |
| With 96/98 (14-21 Nov) | Gear ladder tied to gyms (Elite at Powerlifting, Champion at Golden Era) |
| With 92 (28 Nov) | Trainer pools per gym start (Beach + Pro agencies) |
| Dec | Store front of 6, a cosmetic each week, PolicyService audit, duplicates always useful |
