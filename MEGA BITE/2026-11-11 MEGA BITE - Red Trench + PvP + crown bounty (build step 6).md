---
date: 2026-11-11
tags: [megabite, build, pvp, red-trench, crown, bounty]
status: built in Studio (not published), play-tested with Studio test bots (1 player). Needs a real 2-player / phone test.
---
# MEGA BITE: the Red Trench, PvP and the crown bounty (build step 6, 11 Nov ~04:00-04:50, autopilot)

Back to [[00 MEGA BITE Home]]. Rules come from the research, not invented: [[2026-11-09 MEGA BITE - Full research report]] (rows "x1/x2/x4", "10 s shield...", "Server crown"), [[2026-11-09 MEGA BITE - Notes - PvP fairness and Roblox rules]] (the 8-point fairness kit), [[2026-11-11 MEGA BITE - Prompt - Titan Simulator steals (body growth, size tag, crown)]] ("everyone who bit the crown shark in the last 10 s shares the bounty"). Look: [[2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]].

## The place
- A gate in the NORTH wall (3 border rocks moved aside to frame it): two rock pillars, a rock beam with red neon trim, a hanging sign "RED TRENCH / PVP · x4 EXP · FAIR FIGHT" (LuckiestGuy). Visible from the spawn = a landmark that pulls kids there.
- Corridor (56 studs half-width) sloping down → a deep basin (370 wide, to z = -860) with rock walls from our border kit, 7 glowing red vents (embers + bubbles + red light), floor boulders. `workspace.MB_Map.RedTrench`.
- As you swim in, the water turns red-violet (Atmosphere + colour correction blend with depth), the minimap shows the Trench in red.
- Own food: Tuna, Squid, Mackerel, Puffer schools that live only in the basin; food there is worth x4 (Reef x1, Open Sea x2). No bank vent inside (risk!).

## The rules (all in `C.Trench`, GameConfig)
| Rule | Value |
|---|---|
| PvP only past the gate | yes, nowhere else |
| Spawn shield on entry | 5 s, ends early if you bite; shielded sharks glow cyan |
| HP | 100 × 1.55^(evo-1) (Minnow 100 … Megalodon ~1,390) |
| Bite damage | max HP × 0.3 × 1.45^(attacker tier - victim tier), clamped 10-50% → equal sharks 4 bites, 2 tiers up 2 bites, never 1 bite, never more than 10 |
| Bite | on contact (like eating fish), 0.75 s cooldown, server checks zone + reach |
| Regen | after 6 s without a hit, 8% HP / s |
| Eaten | Minnow / Piranha / Barracuda lose NOTHING; bigger keep 25% of the bag; respawn at the reef |
| Reward | the dropped bag + base (30 × 2.1^(tier-1)) SPLIT between everyone who bit in the last 10 s, straight to EXP |
| Anti-bully | no EXP for eating a shark 2+ tiers smaller; 60 s before you can hurt the same shark again; 3 rewarded eats per pair per 30 min |
| Combat tag | 10 s after biting / being bitten: leaving the Trench or quitting drops the bag (except the newbie tiers) |
| Crown bounty | 150 × 2.1^(tier-1), split between everyone who bit the crown shark in the last 10 s, straight to EXP; everyone sees who took it |
| Paid items | change nothing here (HP + damage use the evolution only) |

## On screen
- First time in: a dark reveal card (RNG-Battlegrounds style): darkness + letterbox bars, a soft red flare, "RED TRENCH" in chrome-white GothamBlack, "PVP ZONE · x4 EXP", "Fair fight: nothing bought works here · Small sharks lose nothing". Later entries: a short banner.
- HP bar top-centre (only in the Trench or while hurt): red fill + a white damage trail that drains after, a jolt on each hit, SHIELD / FIGHT countdown chips.
- Hits: "-34" numbers (gold when it's your bite), bite pop VFX + sound, small HP bars over hurt sharks; when YOU are hit: red edge pulse, camera shake (Settings respected), buzz.
- EATEN! card (kind words for small sharks), "ATE X! +N EXP · shared x3", "Too small to count", "Fled a fight - bag dropped", CROWN BOUNTY! celebration. Celebrations now QUEUE (a bounty that evolves you shows both).
- Minimap: the Trench in red + a crown marker on the biggest shark (pinned to the rim when far).

## Tests (Studio, solo + test bots via ServerStorage.MB_PvPDev, Studio only)
- Minnow vs Piranha bot: 5 bites, reward 213 (150 dropped + 63 base). ✔
- Crowned Barracuda bot: 8 bites, bounty 661 to EXP, CROWN BOUNTY + evolve celebrations both shown (after the queue fix). ✔
- Great White bot vs me (Minnow): 2 bites, EATEN! "Small sharks lose nothing", respawn at the reef, nothing lost. ✔
- Real client bites through the server reach check: a same-size bot eaten in ~3 s; my shield ended when I bit. ✔
- Fixed on the way: PvP rewards overflowed the bag (495/30) → now EXP; HP bar overlapped NEXT → top-centre; intro sunburst looked like a cartoon POW → soft flare on darkness.
- **Old bug found + fixed:** `MB_FishClient` called `myShark()` before it existed, so every eaten fish threw an error and the "+N" floater + eat sounds never played. Forward-declared; verified clean.

## Not done yet / next
- A REAL 2-player test (Studio "Start" with 2 players, or 2 phones) - bots don't swim back.
- Sea mines and the squid boss (map plan) - later.
- Report hint in the Trench (research point 8), teaming split is done, "avoid" matchmaking later.
