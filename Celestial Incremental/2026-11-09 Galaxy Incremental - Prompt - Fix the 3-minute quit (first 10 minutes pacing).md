---
date: 2026-11-09
tags: [galaxy, prompt, claude-code, pacing, retention, economy]
---
# Galaxy Incremental: fix the 3-minute quit (first 10 minutes pacing) (owner, 9 Nov)

Owner: "why the game feels so boring. most people have 3 mins of playtime".
Plan it should match: [[2026-11-05 Galaxy Incremental - Feel pass PLAN + numbers]] (a buy every ~6 s, something NEW every 10-20 s, first Supernova at 5:00).

## Diagnosis (from the owner's phone screenshots, 8 Nov)
- At about 2-3 minutes: **435 stardust, +7.2/s, LVL 2**, and the HUD goal says **"NEXT: ROCK ASTEROID - 4.22K"**. At 7.2/s that's a **~10-minute wait** with nothing big to aim for. Gas Giant unlock 5,120 = ~12 min. That is exactly where players quit.
- The plan had MOON at 1:21, PLANET at 2:08, GAS GIANT at 3:04, ROCK tier at 3:41 and income growing fast. The live game is far slower than the plan, so something in the built economy doesn't match `Calc\feel.py` (costs, income formula, or a multiplier missing).
- Perks cost XP (6 and 2) but XP is slow at LVL 2, so the PERKS tab doesn't fill the gap either.
- Empty servers: new players see no other islands, so nothing shows them what's ahead.
- The broken phone UI made the first sessions worse (fixed now).

```text
GALAXY INCREMENTAL – FIX THE 3-MINUTE QUIT. Most players leave at ~3 minutes. Do NOT playtest with players and do NOT publish: the owner tests. You MAY run the Calc bot (a simulation, not a playtest).

EVIDENCE: owner's phone at ~2-3 min on a fresh save: 435 stardust, +7.2/s, LVL 2, "NEXT: ROCK ASTEROID - 4.22K" (≈10 min of waiting). The approved plan (vault: "2026-11-05 Galaxy Incremental - Feel pass PLAN + numbers") says: a buy every ~6 s, MOON 1:21, PLANET 2:08, GAS GIANT 3:04, ROCK tier 3:41, first Supernova 5:00.

1. FIND THE GAP: read the LIVE GameConfig/economy code and run `Calc\feel.py` with the LIVE values (not the plan's). Print the fresh-save timeline (first 10 min: every purchase, every new thing, income/s each 30 s). Put it next to the plan's timeline and list every number that differs (costs, income formula, multipliers, XP rate, the HUD "NEXT" goal logic).

2. FIX IT TO THE PLAN: change the live values so the bot timeline matches the plan:
   - no gap over 20 s without an affordable buy in the first 10 min;
   - something NEW (body, tier, pad, level, perk) at least every 30 s for the first 5 min;
   - first Supernova at 4:30-5:30.
   Prefer fixing the bug/mismatch over inventing new numbers.

3. THE HUD "NEXT" GOAL must always show a goal reachable in under ~60 s (the next cheap buy or pad), never a 10-minute one. The big goal (Supernova progress bar) lives separately.

4. FIRST-SESSION HOOKS (small, no new systems):
   - XP: the first 5 levels come fast (LVL 2 by ~1:00, LVL 5 by ~3:30) so perks are affordable early, with a level-up pop + sound.
   - A free "2x Stardust for 5 min" playtime gift at 2:30 (the gift chip already exists), so the 3-minute moment gets a boost instead of a wall.
   - Supernova preview: from minute 1, a bar "SUPERNOVA 12%" with the star visibly growing, so new players see the big moment coming.

5. ANALYTICS (so we see where players leave next time): Funnel events for the onboarding (AnalyticsService:LogOnboardingFunnelStepEvent): 1 spawned, 2 first buy, 3 first pad, 4 Moon, 5 Planet, 6 LVL 5, 7 first perk, 8 Gas Giant, 9 first Supernova, 10 second Supernova.

Keep saves safe (never lower what players own). Put the new values in GameConfig.

REPORT (short): the LIVE vs PLAN difference table, what was wrong, the new bot timeline (first 10 min), the funnel steps added.
```
