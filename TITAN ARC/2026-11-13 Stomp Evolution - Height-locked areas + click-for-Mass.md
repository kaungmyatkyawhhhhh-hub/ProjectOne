# Stomp Evolution - Height-locked areas + click-for-Mass (13 Nov 2026, 11:13-11:30)

Saved as v126.

## Areas (owner: "make areas and the areas need a certain height to unlock")
| Area | Unlocks at | Wall |
|---|---|---|
| Starter Park | open | none |
| Suburbs | 2.4 m (Stone) | x = 230 |
| Downtown | 4.5 m (Magma) | x = 700, up to the Crown plateau |
| Harbour + Skyline | 8 m (Storm) | west river bank, x = 884 |
| Titan District | 13 m (Crystal) | z = 250 on the east bank |
| Crown Core | 21 m (Star) | a ring around the plateau |

- **Best height:** unlocks use your best height ever (`BestH`, saved as `best`), so Awaken never locks you out again.
- **Gate heights:** each gate sits below the cheapest landmark or big prop of its area.
- **Walls:** drawn on each client, only for areas still locked. Each one is a ForceField wall plus:
  - a tinted see-through curtain;
  - a neon base strip and neon posts every 60 studs;
  - kit lock signs every 160 studs ("SUBURBS / NEED 2.40 m").
- **Bumping a wall:** shows a toast "NEED x TO ENTER ...".
- **Unlocking:** the wall sinks into the ground and an "AREA UNLOCKED!" card appears after the evolve card.
- **Server check (`SE_Areas`):** anyone inside a locked area is pulled back to their last allowed spot.
- **Kept out of locked areas:** the guide arrow, quest targets, the golden keeper and Gold Rush never point at props behind a locked wall.
- **Config:** `C.Areas`, `C.AreaAt(pos)`, `C.AreaNeed(id)`.

## Clicks give Mass, props give coins (owner: "like titan simulator")
- Every click pays `C.BareMass` = 0.8 x the Mass of the biggest prop you can smash, whether or not it hits a prop. Stomp Power, Ground Pound, events and index stars all multiply it.
- Props give only coins: golden props give x25 coins, plus the NEW! and star bonuses.
- Clicks give no coins (`C.BareCoins` = 0).
- Test: 10 clicks gave +24 Mass and 0 coins (with one Ground Pound); a Bin gave +1.6 Mass from the click and 12 coins (including the NEW! bonus).
- Quest 1 now reads "Smash 5 things for COINS"; the golden toast reads "x25 COINS!".

## Owner question: "why are my boots the only transformed ones"
That's by design: STARTER is boots only (the staged transformation from the Venom study). BRAWLER at 1.9 m is the first full set.

## To re-check
Re-run the impatient-kid sim with clicks giving Mass, because the first-evolve timing has changed.
