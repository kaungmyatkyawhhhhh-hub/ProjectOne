---
tags: [mega-bite, plan]
date: 2026-11-14
status: plan only, nothing built
---
# MEGA BITE - Build plan from the evolution-game research (14 Nov 2026)

Source: [[Research/Evolution games 14Nov/00 Comparison and takeaways]] (7 games played). Studio was not connected while this was
written, so the "already built" column comes from the vault notes; check each in Studio before building on it.
House rules kept: everything <= 449 R$, **no paid random items**, nothing bought helps in fights, cartoon eating, own art only,
phone first, kid sims before and after, nothing published without the owner.

## 1. The action list against what MEGA BITE already has
| # | From the research | MEGA BITE today | Gap |
|---|---|---|---|
| 1 | First evolution in < 60 s | Clownfish at ~34 s (impatient-kid sim) | none |
| 2 | One next step + trail to food | NEXT UP card, EAT! marker, ground arrows, sea current + rings | none |
| 3 | A named move per evolution | an ability per shark + its name on the evolve hit | small: key hint the first time |
| 4 | Server events on a timer with a countdown pill | Frenzy bait ball every 60 s, golden fish, hunters, Kraken Saturday | **no event rotation, no "next event" pill, no arrows** |
| 5 | Soft death | chomped = back to the Safe Reef, nothing lost; 5 s spawn shield (planned) | check the shield is really in |
| 6 | Ladder with locked silhouettes | Shark Index SHARKS tab with tier bands | none |
| 7 | Index = character select | not built | **"Play as" any grown shark** |
| 8 | "Hour 1 -> Hour 100" thumbnail, face icon | not made | **icon + 3 thumbnails** |
| 9 | Fair monetization | 7 passes <= 449, skins, x2, VIP | none (keep it this way) |
| 10 | Calm, consistent UI | UI v6 | none |
| + | Daily streak, playtime gifts, daily quests | not built (listed as open in the home note) | **biggest gap** |
| + | Card pick every half evolution (Evolve a Cell) | "earned mutations, never sold" decided 9 Nov, not built | **mutation cards** |
| + | REVENGE marker, real fact per species | not built | small |

## 2. Build order
Why this order: the ad rule says the second $100 only if **D1 >= ~10%** and **playtime >= ~15 min**. Phase A is the D1 lever,
Phase B the playtime lever. Page art (E) matters most right before launch.

### Phase A - reasons to come back (about 1 session)
- **A1 Daily streak (7 days):** a GIFTS button on the HUD with a red dot; days pay EXP boosts (x2 for 10 min), Fossil-free items
  and on day 7 a gift-only skin (earned, never sold). Miss a day = start over (Evolve a Cell, Ant Evolution, Primeval Earth).
- **A2 Playtime gifts:** 3 / 8 / 15 / 25 / 40 min in the same window, progress bars, "next gift in 1:44". The 15-min gift lands on
  the playtime target.
- **A3 Daily quests:** 3 a day (easy / medium / hard) + a "finish all 3" bonus, beside the NEXT UP chain (not replacing it).
  Reset at 00:00 UTC with a countdown.
- Where: new `MB_Rewards` (server, inside the existing save), client window in the UI v6 white slab style, own icons and sounds.
- Not doing: "skip the timer for Robux" (Primeval Earth), rewards for group joins or likes (owner rule).
- Check: impatient-kid sim with day-2 returns, phone sizes, `MB_FreshPlayer` run, save/load twice.

### Phase B - timed server events (about 1 session)
- **B1 Event pill** top centre: "NEXT: FEEDING FRENZY 3:12", then the live event name with a gold/red style and time left.
- **B2 Rotation every 5-7 min** across what already exists: big Feeding Frenzy (x2 for 60 s), Golden Fish Rush (3 golden fish),
  Lighthouse Lamp, Gold Rush for all (40 s), plus Kraken Saturday staying on its own clock.
- **B3 Off-screen arrows** with the event's name at the screen edge, and a big title that types in letter by letter + its own sting.
- **B4 APEX HOUR** (Red Trench only, keeps PvP rules): the crown holder gets a boss HP bar seen by everyone in the Trench; bites
  on them pay a shared bounty (Evolve a Cell's Colossus, but earned, never a paid role).
- Where: new `MB_Events` server/client; reuse `MB_FishServer` (`_G.MB_GoldenAt`), `MB_LandmarkUses`, `MB_PvPServer` crown.
- Check: overstimulated-kid sim (pill + toasts + title must not stack with windows), 2-player Trench test.

### Phase C - mutation cards (about 1-2 sessions)
- At the half-way EXP of every evolution: 3 cards slide up (keys 1 / 2 / 3, tap on phones), pick one. Cards are small perks:
  longer DART, faster cruise, magnet for EXP stars, ink cloud when hit, +1 bite on big fish, faster heal, glow outline (show-off).
- Rarity by chance but **free and earned only**; one rare card at most per evolution. Kept until Fossilize, shown in the Index.
- No paid reroll (Evolve a Cell's R$19 reroll is a paid random item = against the rule).
- **Owner 14 Nov: no card spam after a Fossilize.** A Fossilized shark re-evolves fast (EXP x2, x2.5 ...), so cards could pop every
  few seconds. Rules: cards you already picked in an earlier run are KEPT through Fossilize (no re-pick for the same evolution);
  new card picks only for evolutions you have not picked a card for yet, or one pick per Fossil tier; never more than one card
  screen per ~2 min (extra picks wait in a small "CARD READY" badge you open when you want); never during a cutscene/fight.
- Card art: one ChatGPT sheet of card frames + 12 perk icons (art pipeline), owner approves the sheet first.
- Check: quality-nerd sim (do the cards look hand-made?), balance pass with the EXP curve in `Calc/exptune.py`.

### Phase D - small steals (about half a session)
- **D1 Play as:** in the Shark Index, a PLAY AS button on any grown shark (play a Clownfish with a new friend). Size, HP and EXP
  follow that form; you can switch back any time in the Safe Reef. Needs the owner's OK (it touches PvP fairness).
- **D2 REVENGE marker** over whoever ate you in the Red Trench for 60 s, small bonus if you bite them back (Ant Evolution).
- **D3 Real fact line** on the hero card of every shark and fish ("Megalodon lived 23 to 3.6 million years ago") - parents like it.
- **D4 First-use key hint** under a new ability ("Q - HAMMER RAM") until it is used once.
- **D5 Check** the 5 s spawn shield and that no predator homes near the Safe Reef spawn.

### Phase E - game page (before launch, with the roblox-icon-thumbnail skill)
- Icon: one big cartoon shark face (our approved Megalodon/Leviathan render), high contrast on blue.
- Thumbnails: "HOUR 1 -> HOUR 100" (Minnow -> Leviathan underwater), "EAT & EVOLVE" ladder of all sharks, the Kraken fight.
- A countdown version of the icon for update days ("12 HOURS"), title tag in brackets for events.
- Check: test at real sizes in the Roblox app search grid next to Ant Evolution and My Dino Life.

## 3. Owner decisions before building
1. Daily streak day-7 reward: a gift-only skin (my pick) or a big EXP boost?
2. "Play as" smaller sharks: yes / no (fairness in the Trench: it would be locked there).
3. A one-time Starter Pack (<= R$99, EXP boost + a skin, no random items): yes / no. Every top game has one; it is the only
   new paid item in this plan.

## 4. Not doing (seen in the research, against our rules or bad for kids)
Permanent Robux shelf on the gameplay screen, limited-stock packs with counters, paid gacha / rerolls, paid revives / hatch-now /
skip timers, rewards for joining the group or liking, 4 popups on join, debug text on screen.
