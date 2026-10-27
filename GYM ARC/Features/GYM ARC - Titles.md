---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Titles

Back to [[00 GYM ARC Home|GYM ARC Home]].

Collectible titles earned by playing. You keep them forever and wear one above your head.

## How it works
- **Earning:** never bought. Conditions compare muscle groups (ratios) with a minimum level, or count activity, height, genetics and social things.
- **Rarity colors** (bumper plate colors): Common white, Uncommon green, Rare yellow, Epic blue, Legendary red, Secret black.
- **Categories and examples:**
  - Activity: Beginner Gains, Gym Rat, Cardio King (10 km run)
  - Trend: Lock In, Glow Up
  - Physique: Skipped Leg Day, Chicken Legs, Boulder Shoulders, Greek Statue, Aesthetics God
  - Growth Spurt: Late Bloomer, Skyscraper
  - Genetics: Genetic Freak, Hard Gainer, Defied Genetics
  - Social: Spotter, Gym Buddy, Iron Grip
  - Legend titles (one per legend) and seasonal titles
  - Secret: No Days Off
- **Title Book:** opened from the Titles tile; locked titles show as "???" in their rarity color.
- **Overhead title:** Oswald text in the rarity color with a thin dark outline and a tiny plate disc, sized in studs, visible to about 60 studs. Legendary titles get a slow shine. Your own title is smaller and see-through so it never blocks your view.
- **Badges:** the biggest titles are meant to link to Roblox badges.
- **Arm Wrestling King** (Epic, added 13 Oct): beat Big Lou, the hardest arm wrestling NPC ([[GYM ARC - Arm Wrestling]]).
- **Dedicated** (Rare, added 13 Oct): claim all 7 days of the login calendar in a row ([[GYM ARC - Economy and Daily Rewards]]).
- **Posing Champion** (Epic, added 13 Oct): win a posing competition ([[GYM ARC - Posing Competition]]).

## The full list now (checked 19 Oct)
Owner, 19 Oct: the three rival titles were raised one rarity each: Beat Benny Uncommon -> **Rare**, Beat Coral Rare -> **Epic**, Beat Dante Epic -> **Legendary**. Nothing else in the titles changed.

| Title | Rarity | Category | How to unlock |
|---|---|---|---|
| Beginner Gains | Common | Activity | Do your first rep |
| Gym Rat | Uncommon | Activity | 1,000 reps |
| Cardio King | Rare | Activity | Run 10 km on the treadmill |
| Dedicated | Rare | Activity | Claim all 7 days of the login calendar in a row |
| Lock In | Rare | Trend | 50 reps in one set |
| Glow Up | Epic | Trend | Every muscle to level 25 (shown as EXP) |
| Skipped Leg Day | Uncommon | Physique | Chest 2x your legs (level 15+) |
| Chicken Legs | Uncommon | Physique | Arms 2x your legs (level 15+) |
| Boulder Shoulders | Rare | Physique | Shoulders 1.5x your other groups (level 20+) |
| Greek Statue | Epic | Physique | All groups within 10% of each other, level 30+ |
| Aesthetics God | Legendary | Physique | Every muscle level 45+ (badge slot empty) |
| Late Bloomer | Rare | Growth Spurt | First Growth Spurt |
| Skyscraper | Legendary | Growth Spurt | Reach 7'0" (badge slot empty) |
| Genetic Freak | Epic | Genetics | Overall genetics S |
| Hard Gainer | Uncommon | Genetics | Overall genetics D |
| Defied Genetics | Legendary | Genetics | A D-grade group to 130% of the Growth Spurt goal (badge slot empty) |
| Spotter | Rare | Social | Spot others for 10 reps |
| Gym Buddy | Uncommon | Social | 100 reps while someone lifts nearby |
| Iron Grip | Rare | Social | Win 10 arm wrestling matches |
| Arm Wrestling King | Epic | Social | Beat Big Lou |
| Beat Benny | Rare | Social | Beat Benny on the flat bench |
| Beat Coral | Epic | Social | Beat Coral at arm wrestling |
| Beat Dante | Legendary | Social | Beat Dante on the squat rack |
| Posing Champion | Epic | Social | Win a posing competition |
| No Days Off | Secret | Secret | 500 reps in one visit |
| Legend titles | Epic | Legend | Finish that legend's challenge: Wingspan, Pumpkin Delts, Tank Mode, Certified Swole, Rep Machine, Beefcake, Small but Mighty, Gainsworth Approved |
| Season titles | Epic | Seasonal | Lift during the event: Pumpkin Spice Swole, Snow Plow, Beach Ready |

- **How they unlock:** the server checks the conditions (`Titles.Check`) and saves earned ones in the player's save as `titles.owned` (title id -> time earned); the worn one is `titles.equipped`.
- **Where they show:** above the head (`OverheadTitleClient`), in the INVENTORY window's Titles tab (`TitlesClient`, the side menu's INVENTORY tile; locked ones as "???"), and a red dot on the tile for new ones.

## Where it lives
- `Config/Titles`
- `Server/TitleService`, `TitlesClient`, `OverheadTitleClient`

## Known issues
- Badge ids for Aesthetics God, Skyscraper and Defied Genetics are not set yet (owner to create).

## Planned change
- New features prompt adds titles: "Posing Champion" (done 13 Oct), "Dedicated" (7-day streak, done 13 Oct), "Arm Wrestling King" (done 13 Oct), "Beat Benny", "Beat Coral" and "Beat Dante" (NPC rivals, done 13 Oct, [[GYM ARC - NPC Rivals]]).
- Monetization prompt: a VIP title for the VIP pass.

## Related
[[GYM ARC - Legend NPCs]], [[GYM ARC - Seasons and Events]], [[GYM ARC - Posing Competition]], [[GYM ARC - NPC Rivals]]

## Screenshots
![[GYM ARC/Screenshots/fonts_before_titles.png]]
![[GYM ARC/Screenshots/rank_tag_after_muscles.png]]

## Inventory window (14 Oct)
The Titles tile is now **INVENTORY** (backpack icon). Its window has three tabs, and it remembers the last one you used:
- **Titles:** the titles grid, as before (the old All / Owned filter is gone).
- **Auras:** the aura grid and the big card for the picked aura (see [[GYM ARC - Aura]]).
- **Items:** Energy Shakes (count + DRINK), DNA Tokens (count + "Use in Genetics", which opens the Genetics screen), and every boost running now with its timer (2x EXP, 2x Coins, VIP, Endless Stamina, Energy Shake, Server Boost, smoothie bar drinks).
The Store's Auras tab and the "new aura" message now open the Inventory.

## Boosts tab (21 Oct, prompt 14)
The Inventory has a **Boosts** tab first now (Boosts | Titles | Auras | Items): see [[GYM ARC - Boosts Inventory]]. The Items tab keeps DNA Tokens and the running boosts (the shakes moved to Boosts).

## Yard King (27 Oct)
**Yard King** (Epic, Social): win a Strongman Showdown (1st place, `stats.yardWins`). See [[GYM ARC - Strongman Yard]].

## Court King (27 Oct, prompt 70)
- Epic, Social: win 5 games of 1v1 basketball on the town court (`courtWins` >= 5). See [[GYM ARC - Court Competitions]].
