---
date: 2026-11-03
tags: [gymarc, progress, hall-of-fame, gem]
status: built, tested in Play (Studio)
---
# GYM ARC Star Track built (3 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-10-29 GYM ARC Prompt - 101 Hall of Fame star track]] · Event: [[2026-11-01 GYM ARC GEM update launch event (7 Nov)]]

Everything stays locked until the GEM update (`LiveEvents.Unlocked("StarTrack")`, already in the Gem event's `unlocks`). At launch, LiveEventService re-checks titles, tags and auras for everyone online.

## What's in
1. **Star Track window** (`StarTrackClient`, `UIBus.OpenStarTrack`). Built like Your Road: one tile per star 1-15 in the tier colour, reward icons, EARNED ticks, YOU ARE HERE, NEXT with the gold glow. Tap a star to see its boosts and rewards in the strip. The right side shows **your fastest run this week** and your best ever.
   - Opened by a kit **Star Track** button on the Hall of Fame screen (left of the big star).
2. **Tier colours** (Config/HallOfFame `Tiers`, `TierOf`): bronze ★1, silver ★2-4, gold ★5-9, diamond ★10+.
   - Used on the over-head star tag, the statue plaque text and the niche light behind each statue.
3. **New titles:** Rising Star (★2), Golden Star (★5), Immortal (★15). HALL OF FAMER (★1) and LEGEND (★10) already existed.
4. **New auras** (unlock type `stars`): Silver Star (★2), Gold Star (★5), Diamond Star (★10). They reuse the frost, golden and galaxy effects and icons for now; new art can replace them later.
5. **Fastest run** (ActionService alter):
   - A starred run is timed once on the server, from entering the Hall to reaching Alter 15 again.
   - Runs under 30 min are refused and logged.
   - Saves `fame.lastRun`, `bestRun` and `weekBest`.
   - Analytics: `RunDone_<star>` (minutes).
6. **Weekly FASTEST RUN board** (Config/Leaderboards `FastestRun`, weekly = true):
   - Store `LB2_FastestRun_W<week>`, a new store every Monday 00:00 UTC.
   - Score = 10,000,000 − seconds, so the fastest run is first. It is shown as "1h 13m".
   - Only plausible saves count.
   - A gold-framed panel stands on the Hall's west wall, opposite the stars board. It is hidden until the update.

## Tested (Play, ★6 test save)
- Got RisingStar and GoldenStar.
- Silver and Gold auras earned; Diamond not (correct at ★6).
- The tag shows ★6 in gold.
- The window shows every tier correctly, and the board shows in the Hall.
- The weekly store key is right (Monday start).
- No script errors.
- **Not tested:** a real timed run (it needs a full run), and the board rows (DataStores were down in Studio).

## Not built yet (from prompt 101)
- **Run speed per star:** existing perks are unchanged. Needs pacing tests.
- **Legend Form colours** and the permanent **LEGENDS wall** at ★10.
- **Legacy cards:** the track says "Keep 1 Run Card". Showing the actual cards you kept is not built.
- **Fixed QoL star rewards:** auto-claim spurts, quick transform, start with feats.
- **Extra Legacy card** when entering from Alter 16+ (needs the Gem alters first).
- **Star-only content:** gear at ★4 and the champions ladder from ★6. **Needs the owner's OK before building.**

## Owner decisions (3 Nov, after the build)
1. **★4 star-only gear: YES, a look, not power.** A gold-star lifting belt + matching wraps that only ★4+ can equip, with the same stats as the best normal belt. Stars must be something you can SEE but must not break the economy or gear prices.
2. **Champions ladder from ★6: NO** (cancelled 1 Nov: the storyline, bullies + arm wrestling, now chapters 7-9 in the Gem Mine, already does that job). Instead ★6 gets something visible: a **star frame on the player's profile card** + their **Hall of Fame statue gets a gold base**.
3. **Correction:** the extra Legacy card is for entering the Hall of Fame from **Alter 20** (Diamond), not 16. Alter 15-19 = 1 star; Alter 20 = 2 stars + 1 extra Legacy card (decided 1 Nov).
4. **Order this week:**
   - GEM must-haves first: Alters 16-20 + looks, Gem Mine + chapters 7-9, countdown + auto unlock, HoF agency discovery.
   - Then: Legacy cards shown on the track, faster runs per star, QoL rewards (auto-claim Growth Spurts), the ★4 belt.
   - Legend Form colours + the ★10 LEGENDS wall can slip to 14 Nov.
   - **Nothing untested goes live on Saturday.**
