---
date: 2026-10-13
tags: [gymarc, config]
status: current
---
# GYM ARC - Config values

Back to [[00 GYM ARC Home|GYM ARC Home]]

Every number you can tune lives in a Config module in Studio: `ReplicatedStorage > Shared > Config`. The backup copies
are in the repo at `C:\Users\kaung\ClaudeOne\src\ReplicatedStorage\Shared\Config\<Name>.luau`. Change a number in
Studio, play-test, then save the place. Very long data lists (machine tiers, titles, body stage mesh sizes) are only
summarised here; open the file for the full list.

Tip: after changing gains, tiers, stamina or Growth Spurt numbers, the pacing test (`tests/pacing`) has to be re-run so
the Growth Spurt goals still match the target play times.

## Config/Stamina
File: `Config/Stamina.luau`. See also [[GYM ARC - Stamina and Treadmills]].

| Setting | Value | What it does |
|---|---|---|
| Max | 100 | Starting max stamina |
| Cardio.MetersPerPoint | 40 | Metres run on a treadmill per +1 max stamina |
| Cardio.MaxBonus | 150 | Most extra max stamina running can give (so max 250) |
| RegenPerSecond | 20 | Stamina refilled per second |
| RegenDelay | 2 s | Wait after a rep before refilling starts |
| Recovery.StretchMat | 2.5x | Refill speed on the stretch mats |
| Recovery.Cardio | 1.6x | Refill speed on treadmills / cardio |
| Recovery.Sauna | 3.5x | Refill speed in the beach sauna |
| Shake.Cost | 25 coins | Price of one Energy Shake |
| Shake.MaxCarry | 20 | Most shakes you can carry |
| Shake.GainsBoost | 1.5x | Gains while a shake is active (+50%) |
| Shake.Duration | 30 s | How long one shake lasts |
| Shake.MaxDuration | 90 s | Most time stacked from drinking several |
| Shake.Flavors | 6 flavors | Chocolate, Strawberry, Vanilla, Banana, Cookies and Cream, Mint (cosmetic) |
| Cat.Name | "Plates" | The gym cat's name |
| Cat.Refill | 10 | Stamina from petting the cat |
| Cat.Cooldown | 30 s | Per player, between pets |

## Config/Gains
File: `Config/Gains.luau`. Formula: base EXP x weight tier x genetics x frame/body x Growth Spurt bonus x boosts x
Muscle of the Day x diminishing.

| Setting | Value | What it does |
|---|---|---|
| BaseXp | 34 | Base EXP per rep (tuned so the first Growth Spurt is about 8 min) |
| MaxMultiplier | 5 | Cap on all stacked multipliers together |
| DiminishLevel | 50 | A muscle at this level grows at half speed |
| BalancedBonus | 1.1x | Bonus when all 6 groups are close together |
| BalancedSpread | 10 levels | "Close together" means within this many levels |
| BalancedMinLevel | 5 | Groups must be at least this level for the bonus |
| RepCooldown | 0.4 s | Fastest the server accepts two reps |
| MaxRepsPerSecond | 1.35 | Long-run rep rate limit (anti-cheat) |
| RepBurst | 3 | Extra reps allowed in a burst (lag) |
| AutoRepGap | 0.8 s | Rest between automatic reps |
| Pump.TapsToFill | 16 | Taps to fill the PUMP meter |
| Pump.TapsPerSecond | 8 | Most taps per second that count |
| Pump.DrainDelay | 0.8 s | Wait before the meter drains |
| Pump.DrainPerSecond | 12% | Meter lost per second when not tapping |
| Pump.Duration | 8 s | How long PUMPED lasts |
| Pump.Multiplier | 2x | Gains while PUMPED (outside the 5x cap) |
| Pump.Speed | 0.75x | Rep animation time while PUMPED |
| BigRep.Chance | 1 in 12 | Chance a rep is a BIG REP |
| BigRep.Multiplier | 3x | BIG REP gains (outside the 5x cap) |

## Config/Muscles
File: `Config/Muscles.luau`. 18 muscles in 6 groups (Chest 2, Shoulders 3, Back 4, Arms 3, Legs 4, Core 2).

| Setting | Value | What it does |
|---|---|---|
| XP to next level | 20 + 2 x level | How much XP each level needs |
| FirstSpurtExp | 50,000 | EXP shown for a group's first Growth Spurt goal |
| FirstSpurtLevel | 15 | Must match Growth Spurt stage 1 level |
| ExpPerXp | about 98 | Converts internal XP to the big EXP numbers on screen |
| Look.AestheticAt | 2x goal | EXP (vs the goal) for the full aesthetic look |
| Look.MonsterAt | 5x goal | EXP for the full mass monster look |
| Look.Ease | 1.6 | Curve of the look growth |
| Look.DefaultMonsterG | 1.35 | Mass monster size if a muscle has no own value |
| Look.MonsterG | 1.32 to 2.91 | Mass monster size per muscle (biggest: Obliques 2.909, Traps 2.625) |
| Body (table) | per muscle | Where each muscle sits on the body (for stats dots, highlights, pump) |

## Config/GrowthSpurts
File: `Config/GrowthSpurts.luau`. See also [[GYM ARC - Growth Spurts]].

| Setting | Value | What it does |
|---|---|---|
| StartHeight | 48 in (4'0") | Height at Growth Spurt 0 |
| MaxHeightInches | 84 in (7'0") | Height cap; the spurt that reaches it is the last |
| Stage 1 | 4'6", level 15, x1.25 | Height, group level goal, permanent gains bonus |
| Stage 2 | 5'0", level 47, x1.5 | |
| Stage 3 | 5'6", level 72, x1.75 | |
| Stage 4 | 6'0", level 103, x2 | |
| Stage 5 | 6'6", level 135, x2.5 | |
| Stage 6 | 7'0", level 157, x3 | Last spurt (max height) |
| ExtraPerStage | +6 in, +18 levels, +0.5 bonus | Rule for stages past the table (height still capped) |
| Targets | 8, 15, 25, 35, 45 min | Target play time per spurt (pacing test tunes to these) |
| Level cap | none | Muscles keep growing; only diminishing returns slow them |
| MasteryOverGoal | 1.3 | 130% of the goal = the "Defied Genetics" mark |

## Config/Genetics
File: `Config/Genetics.luau`. See also [[GYM ARC - Genetics]].

| Setting | Value | What it does |
|---|---|---|
| Grade D | x0.75, 15% | Gains multiplier and roll chance per group |
| Grade C | x0.9, 25% | |
| Grade B | x1.0, 30% | |
| Grade A | x1.2, 20% | |
| Grade S | x1.5, 10% | |
| Frame Narrow | 25%, shoulders 0.9x, +10% Arms | Roll chance, shoulder width, bonus |
| Frame Average | 35%, shoulders 1.0x, +5% all | |
| Frame Wide | 25%, shoulders 1.1x, +10% Back and Legs | |
| Frame V-Taper | 15%, shoulders 1.2x, +10% Shoulders and Lats | |
| Body Lean | 33%, no bonus, detail shows at 0.8x | Abs/detail show earlier |
| Body Balanced | 34%, +5% all | |
| Body Stocky | 33%, +15% Legs, Back, Traps, detail at 1.25x | |
| Overall grade | nearest grade to the average | Shown on the player card |

## Config/Machines
File: `Config/Machines.luau`. See also [[GYM ARC - Machines]].

| Setting | Value | What it does |
|---|---|---|
| Tiers per machine | 12 | Weight steps from empty bar to max |
| Progression.gains | 1, 1.3, 1.65, 2.05, 2.5, 3, 3.6, 4.3, 5.1, 6, 7, 8.2 | Gains multiplier per tier |
| Progression.unlockLevel | 0, 3, 7, 12, 18, 25, 33, 42, 52, 64, 78, 95 | Main muscle level needed per tier |
| Progression.cost | 0, 5, 12, 25, 45, 70, 110, 160, 230, 320, 440, 600 | Coins to buy each tier (once) |
| Progression.coins | 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 8, 9 | Coins per rep at each tier |
| Plates | 55 red, 45 blue, 35 yellow, 25 green, 10 white, 5 steel | Plate colors and sizes |
| PlateGap / SleeveRoom | 0.02 / 1.55 studs | Plate spacing and room on the sleeve |
| Brand | "M WEIGHTS" | Printed on every plate |
| Tier sets | Barbell (45-315 lb), HeavyBarbell (45-455), Sled (45-455), Bodyweight (BW to +100), Cable (10-120), Treadmill (2-13 mph) | Which weights each kind of machine uses |
| Machines | 10 starter + treadmill, 11 pro, 1 seasonal (Sled Pull) | Each with main muscle, secondary shares, stamina cost 4-6 |
| Cardio.MetersPerMph | 2 | Distance per treadmill rep per mph |
| Cardio.KingMeters | 10,000 | Distance for the Cardio King title |
| Cardio.BeltScroll | 1.2 | Belt texture speed per mph |
| ClientCull.AnimateDistance | 80 studs | Other lifters only animate this close |
| ClientCull.PumpDistance | 30 studs | Pump swell only shows this close |
| GymUnlock | Starter 0, Beach 1, Pro 2, Seasonal 0 | Growth Spurt needed for each gym |
| GoalShare | 0.2 | A secondary below 20% doesn't count for the Growth Spurt goal |
| Spot type | hands: flat/incline bench, squat rack, overhead press; hype: the rest; none: treadmill | How spotters stand |

## Config/Spotting
File: `Config/Spotting.luau`. See also [[GYM ARC - Spotting]].

| Setting | Value | What it does |
|---|---|---|
| MaxSpotters | 5 | Spotters per lifter |
| RequestTimeout | 8 s | How long the request card stays |
| RequestCooldown | 3 s | Between two requests from one player |
| Range | 16 studs | How close to ask / how far before it ends |
| LeaveDistance | 3 studs | Moving this far from your spot stops spotting |
| Boost | 1.10, 1.20, 1.30, 1.40, 1.50 | Lifter's gains for 1-5 spotters |
| ClickBonus | +0.15 | Extra boost when all spotters are clicking |
| ClickRate | 3 taps/s | Speed needed to count as clicking |
| ClickWindow / ClickHold | 1 s / 1 s | Measuring window / stays on after stopping |
| MaxTapsPerSecond | 8 | Faster taps are ignored |
| EvenTaps / EvenSpread | 8 taps / 0.004 s | Perfectly even taps = auto-clicker, ignored |
| RewardEvery | 10 reps | Lifter reps per spotter payout |
| RewardCoins | 5 | Coins per payout |
| RewardClickingCoins | +3 | Extra coins when clicking at payout |

## Config/Economy
File: `Config/Economy.luau`.

| Setting | Value | What it does |
|---|---|---|
| Login.Coins | 25, 35, 50, 70, 90, 120, 300 | Login calendar coins for day 1..7 (13 Oct; replaced the Daily streak numbers) |
| Login.Day7DnaTokens | 1 | DNA tokens on day 7 (with the "Dedicated" title) |
| Offline.CoinsPerMinute | 0.5 | Offline coins rate |
| Offline.CapHours | 8 h | Offline cap (max 240 coins) |
| Offline.MinMinutes | 10 | Shorter breaks give nothing |
| Rerack.Coins | 5 | Coins per re-racked loose plate |
| Rerack.MaxLoose | 3 | Loose plates at once |
| Rerack.SpawnEvery | 90 s | Time between new loose plates |
| Rerack.Spots | 8 spots | Floor spots for loose plates |
| DnaTokenCost | 400 coins | DNA token price at the front desk |
| RushHour.EveryMinutes | 30 | Rush hour cycle |
| RushHour.LengthMinutes | 3 | Rush hour length |
| RushHour.Coins | 2x | Coins per rep during rush hour |

## Config/DailyQuests
File: `src/ReplicatedStorage/Shared/Config/DailyQuests.luau` (new 13 Oct)

| Setting | Value | What it does |
|---|---|---|
| PerDay | 3 | Quests a player gets each UTC day |
| BonusCoins | 150 | For claiming all of the day's quests |
| SwapsPerDay | 1 | Swaps a day (never into a quest that needs another player) |
| Pool | 12 quests | Each: text, type, count, coins (chest/leg/back reps 50, shoulder/arm/core reps 40, 100 reps, 3 groups, 1 km run, 2 spots, a posing entry, an arm wrestle win; 50-80 coins) |

## Config/Meals
File: `src/ReplicatedStorage/Shared/Config/Meals.luau` (new 13 Oct, [[GYM ARC - Energy Shakes]])

| Setting | Value | What it does |
|---|---|---|
| Items | Protein Shake 60 coins, gains x1.2, 300 s; Energy Smoothie 50, regen x1.5, 300 s; Chicken & Rice 90, gains x1.1 + regen x1.1, 600 s; Coconut Water 40, cardio x1.5, 300 s | Price, effect and time of each item (also its color and icon) |
| MaxStack | 3 | A boost holds at most 3 drinks' worth of time |
| Shops | SmoothieBar and StarterCart: Protein, Energy, Chicken & Rice; CoconutCart: Coconut Water, Energy Smoothie | What each stall sells |
| PromptDistance | 8 studs | How close you must be to order |
| DrinkSeconds | 2 s | How long the shaker stays in your hand |
| SaveEvery | 5 s | How often the time left is saved (paused while away) |

## Config/MuscleOfTheDay
File: `Config/MuscleOfTheDay.luau`.

| Setting | Value | What it does |
|---|---|---|
| Multiplier | 2x | Gains for the day's muscle group |
| Seed | 3 | Shifts which group starts the daily cycle (UTC day) |

## Config/Monetization
File: `Config/Monetization.luau`. All ids are empty, so the Store never shows. Full list in
[[GYM ARC - Monetization]].

| Setting | Value | What it does |
|---|---|---|
| Effects.DoubleGains | 2x | 2x Gains pass |
| Effects.IronLungsMax | 1.5x | Iron Lungs max stamina |
| Effects.FastRecovery | 1.5x | Fast Recovery refill speed |
| Effects.ShakeFridgeMinutes | 10 | Free shake every 10 min of play |
| Effects.VIPCoins | 1.1x | VIP coin bonus |
| Effects.ShakePackSize | 5 | Shakes in a Shake Pack |
| Effects.ServerBoostGains | 2x | Server Boost gains |
| Effects.ServerBoostMinutes | 30 | Server Boost length |
| StoreAfterMinutes | 5 | Store button waits for the tutorial + 5 min |

## Config/Social
File: `Config/Social.luau`.

| Setting | Value | What it does |
|---|---|---|
| Together.GainsBoost | 1.1x | Workout-together bonus |
| Together.Range | 30 studs | Distance between lifters for the bonus |
| ArmWrestle.TableSpot / ProTableSpot | (13.4, 0.1, -18.1) / (88, 0.1, -64) | Where the starter and pro gym tables stand (the builder uses them) |
| ArmWrestle.Muscles | Biceps, Forearms | Muscles whose look gives arm wrestling strength (13 Oct; was + Front Delts by level) |
| ArmWrestle.PushPerTap | 0.035 | Bar moved per tap at strength 1 (the bar goes -1..1) |
| ArmWrestle.StrengthBonus / StrengthLookCap | 0.5 / 1 | Up to +50% per tap at the full look, nothing more above it |
| ArmWrestle.MaxTapsPerSecond | 15 | Faster taps are ignored by the server |
| ArmWrestle.Countdown | 3 s | Countdown before a match |
| ArmWrestle.MaxTime | 8 s | Match time limit, then whoever is ahead wins |
| ArmWrestle.WinCoins / LoseCoins | 15 / 5 | Coins for beating a player / for everyone who finished |
| ArmWrestle.Xp | Win 40, Lose 20 | Biceps and Forearms XP each |
| ArmWrestle.Npcs | Rocco (easy, 0.9x, 5-7 taps/s, 8 coins), Tess (medium, 1.15x, 7.5-9.5, 15), Big Lou (hard, 1.35x, 9-10.5, 35, the King title) | NPC opponents |
| ArmWrestle.SeatedRootY | 1.6 | Seated height (the NPC sits like a player) |
| ArmWrestle.LiveAngle / PinAngle | 70 / 86 degrees | Arm swing / final slam angle |
| ArmWrestle.AnimateDistance | 70 studs | A table only animates this close to the camera |
| Crew.MaxMembers | 8 | Crew size |
| Crew.NameLength / TagLength | 3-20 / 2-4 letters | Crew name and tag length |
| Crew.CreateCost | 0 coins | Price to make a crew |
| Crew.Refresh | 120 s | Crew score update |

## Config/ShowOff
File: `Config/ShowOff.luau`.

| Setting | Value | What it does |
|---|---|---|
| Leaderboard.Refresh | 120 s | Wall leaderboard update |
| Leaderboard.Top | 5 | Rows per muscle group |
| Statue.Scale / Material / Color | 1, Marble, #C9C6BF | Statue of the strongest player |
| Emotes | 6 bodybuilding poses + High Five (+ Shake chug) | Pose list |
| PoseMaxSeconds | 45 s | A held pose lets go after this |
| PoseJudge.Delay / Margin | 0.9 s / 3 studs | Posing stage judging |
| HighFive.Range / Window | 7 studs / 2.5 s | High five distance and timing |
| Membership | Bronze 0, Silver 500, Gold 2,500, Platinum 10,000, Diamond 30,000 reps | Membership card tiers |

## Config/Quests
File: `Config/Quests.luau`. Coach Dex quests: a one-time chain of 12, then 6 repeatable quests in a loop.

| Setting | Value | What it does |
|---|---|---|
| Chain | 12 quests, rewards 10-200 coins (+ shakes, 1 DNA token) | First quests, in order |
| Repeatable | 6 quests, 30-60 coins | Loop after the chain |
| CoachName | "Coach Dex" | Quest giver |
| Prompt distance | 10 studs | Talk prompt range |

## Config/Leaderboards
File: `src/ReplicatedStorage/Shared/Config/Leaderboards.luau` (new 13 Oct, [[GYM ARC - Leaderboards and Statue]])

| Setting | Value | What it does |
|---|---|---|
| Refresh | 90 s | Time between saving values and reading the boards (60-120 keeps every server inside the DataStore limits) |
| FirstRefresh | 12 s | First read after a server starts |
| Top | 10 | Rows on a board |
| FetchCount | 100 | Entries read per board ("Your rank" is exact inside these) |
| StorePrefix | LB1_ | OrderedDataStore names (LB1_<board>, daily: LB1_RepsToday_<day>) |
| Boards | Biggest, Strongest, Tallest, RepsToday (daily), PosingWins, ArmWins | The six boards, in wall order |
| SizeScale | 100 | "Biggest" = average muscle look x this |

## Config/Legends
File: `Config/Legends.luau`.

| Setting | Value | What it does |
|---|---|---|
| Visit.EveryMinutes | 20-30 min | Gap between legend visits |
| Visit.StayMinutes | 3 min | How long a legend stays |
| Visit.FirstVisitSeconds | 120 s | First visit after a server starts (30 in Studio) |
| List | 8 legends | Lance Lats, Brody Pumpkins, Tank McFlex, Kyle Swole, Ricky Reps, Big Beefington, Tiny Tim Gains, Chad Gainsworth (each with a title and a 15-40 rep challenge) |
| Reward | 60 coins + 1 DNA token | Per finished legend challenge |

## Config/Seasons
File: `Config/Seasons.luau`.

| Setting | Value | What it does |
|---|---|---|
| Halloween Gym | 15 Oct - 2 Nov, 1.25x coins | Title "Pumpkin Spice Swole" after 200 reps |
| Winter Lifts | 10 Dec - 6 Jan, 1.25x coins | Title "Snow Plow"; Sled Pull machine appears |
| Summer Shred | 15 Jun - 31 Aug, 1.25x coins | Title "Beach Ready" |

## Config/Titles
File: `Config/Titles.luau`. About 21 base titles (1 Common, 5 Uncommon, 6 Rare, 5 Epic, 3 Legendary, 1 Secret) plus one
per legend and one per season added automatically. Each has a condition (reps, ratios between groups, height, genetics
grade, etc.). Three have a `badgeId` slot (empty): Aesthetics God, Skyscraper, Defied Genetics. See [[GYM ARC - Titles]].

## Config/Onboarding
File: `Config/Onboarding.luau`.

| Setting | Value | What it does |
|---|---|---|
| Steps | 9 | GoBench, FirstLift, Stamina (below 40% or 20 reps), Shake (1 free shake), GoSquat, SquatLift (3 reps), OpenStats, Coach, Goal (6 s) |
| Done | 100 | Saved step number when finished |
| Version | 2 | Bumped when steps are renumbered |

## Config/CoachNotes
File: `Config/CoachNotes.luau`. 19 coach one-liners for the machine HUD in 6 situations: first set (3), low stamina (3),
too light (3), unlock ready (2), maxed (2), general (6). Adding a line = adding text.

## Config/Cosmetics
File: `Config/Cosmetics.luau`. Bought with coins at Gear & Fits.

| Setting | Value | What it does |
|---|---|---|
| Slots | Fit, Waist, Head, Wrists, Hip, Board, Wheels | One item per slot |
| Belts | 120-200 coins (3) | Lifting belts |
| Headbands | 60-80 coins (3) | |
| Wrist wraps | 70-90 coins (3) | |
| Shakers | 100-120 coins (3) | |
| Skate decks | 80-150 coins (5) | |
| Skate wheels | 34 / 38 / 42 speed for 150 / 400 / 900 coins | Only gear that changes anything (normal speed 30) |
| Gym fits | 6 tops x 4 colors = 24 shirts, 150-400 coins | Gym tee 150, Stringer 200, Pump cover 300, Sleeveless hoodie 300, Compression 350, Cropped hoodie 400 |

## Config/Body
File: `Config/Body.luau`. See also [[GYM ARC - Muscles and Bodies]].

| Setting | Value | What it does |
|---|---|---|
| BundleId | 311 | Robloxian 2.0 body for everyone |
| Scales | BodyType 0, Proportion 0, Width 1, Depth 1, Head 1 | Same shape for all |
| Proportions | Stretch 1.08, Shrink 0.893 | Golden ratio legs vs torso |
| Widths.Skinny | shoulders 0.4, hips 0.2, arms 0.08, legs 0.06, depth 0.35 | Width growth with height for a beginner |
| Widths.Maxed | shoulders 1.15, hips 0.7, arms 0.5, legs 0.5, depth 0.45 | Full aesthetic look |
| Widths.MassMonster | shoulders 1.4, hips 1.2, arms 0.9, legs 0.9, depth 0.9, +12% muscle | Mass monster |
| Widths.ShouldersOverHips | 1.1 | Shoulders always wider than hips |
| ShortsColors | Black, Navy, Red, Gray, Teal | Game shorts (default Black) |
| Tops | Shirtless, Tank top, Sports top | Default Shirtless |
| CoveringAccessories | 7 types removed | T-shirt, shirt, pants, jacket, sweater, shorts, dress/skirt |

## Config/BodyStages
File: `Config/BodyStages.luau` (generated by `tools/gen_body_stages`). The static body meshes for other players, NPCs,
the statue and the mirror: 6 regions (torso, both upper arms, both thighs, waist), 7 stages each (waist 6), 62 meshes.

| Setting | Value | What it does |
|---|---|---|
| FadeTime | 0.3 s | Cross-fade between two stages |
| ImportTurn | 180 degrees | Undoes Studio's Import 3D turn |
| Regions | 62 mesh entries with sizes | Do not edit by hand (generated) |

## Config/LimbStages
File: `Config/LimbStages.luau` (generated by `tools/gen_limb_stages`). Forearms and calves for everyone: 4 limbs x 7
stages = 28 uploaded meshes (ids in [[GYM ARC - Assets]]).

| Setting | Value | What it does |
|---|---|---|
| FadeTime | 0.3 s | Cross-fade between stages |
| Stages | look 0, 0.2, 0.4, 0.6, 0.8, 1.0, monster | Calves monster at 1.875, forearms at 2 |

## Config/SkinStages
File: `Config/SkinStages.luau`. 5 skin textures (color, normal, roughness each; ids in [[GYM ARC - Assets]]).

| Setting | Value | What it does |
|---|---|---|
| At | 0, 0.5, 1, 1.5, 2 | Body look where each stage sits (0 = level 0, 1 = full look, 2 = mass monster) |
| Hysteresis | 0.03 | Stops flicker when the look sits on a switch point |

## Config/HudIcons
File: `Config/HudIcons.luau`. Tile and pill colors and icons. Every `image` field is empty (built-in white icons used).

| Setting | Value | What it does |
|---|---|---|
| Tiles | Stats #E2574C, Muscles #F0922E, Titles #E8C21C, Genetics #3FB8AF, Wardrobe #9B6BDF, Emotes #E96BA8, Crew #4C8DE0, Store #5BBE5B | Side menu tile border colors |
| DefaultAccent | #8A8F98 | Fallback tile color |
| MuscleGroups | Chest red, Shoulders orange, Back blue, Arms purple, Legs green, Core yellow | Machine sign and EXP popup chips |
| Pills | Coins, Quests, Daily, Settings | Top bar pills |

## Config/Sounds
File: `Config/Sounds.luau`. Every sound id, volume and pitch. Full list in [[GYM ARC - Music and Sounds]].

## Config/Poses
File: `Config/Poses.luau`. Where the body sits, lies or stands on each of the 21 machine poses (positions, seat heights,
which part carries the plates). Layout data, not gameplay tuning; edit only when a machine model moves.

## Config/Town
File: `Config/Town.luau`. The town layout in studs: walkable bounds (x -176..200, z -98..262), skate area, Main Street,
Beach Road, avenues, side streets, plaza, park, parking, sports court, smoothie bar, clothing store, beach, skate park,
beach gym, posing stage, boardwalks, sea, and 4 lawns with tree/flower counts. Used by the Town builder and the skate
rules.

## Config/PosingComp
File: `src/ReplicatedStorage/Shared/Config/PosingComp.luau` (new 13 Oct, [[GYM ARC - Posing Competition]])

| Setting | Value | What it does |
|---|---|---|
| Interval | 720 s | Time from one round's start to the next |
| FirstDelay | 180 s | Wait after a server starts before the first countdown |
| Countdown | 60 s | "Starts in" countdown before a round |
| MaxPlayers | 6 | Most contestants on the stage |
| MinPlayers / NpcFillTo | 2 / 3 | Fewer contestants than 2: NPCs fill up to 3 |
| StageMargin | 1 stud | Room around the stage that still counts as on it |
| Poses | Front double biceps, Lat spread, Most muscular | The three poses of a round |
| Intro | 4 s | Before the first pose |
| CueTime | 2.4 s | How long the ring takes to close |
| Perfect / Good | 0.2 s / 0.55 s | Tap windows either side of the ring closing |
| LateLimit | 1.2 s | A tap later than this is "Missed" (auto pose) |
| HoldTime | 3 s | From the ring closing to the judges' score |
| ScoreShow / Gap | 2.5 s / 1.5 s | Cards up / pause before the next pose |
| MaxPing | 0.3 s | Network delay forgiven on a tap |
| Timing values | Perfect 1, Good 0.6, Late 0.15, Missed 0 | Timing part of the score |
| HoldLost | 0.5 | Timing x this if the pose was let go early |
| Weights | Size 0.55, Balance 0.25, Timing 0.2 | Score of one pose |
| SizeFull | 1 | Average muscle look that counts as full size |
| BalanceZero | 0.25 | Smallest group / biggest group at or under this = no balance |
| VoteRange | 150 studs | Who gets the vote panel |
| VotePoints / VoteMax | 0.5 / 2 | Points per vote / most points from votes |
| PodiumTime | 10 s | Top 3 on the podium |
| Coins | 150 / 90 / 50 | 1st / 2nd / 3rd |
| EnterCoins | 10 | Everyone else who finished |
| Npcs | 5 bodybuilders | Name, skin, shorts color, share (how grown), skill (timing range) |

## Planned (not built yet)
From [[2026-10-13 GYM ARC Prompt - Monetization and hype]] and [[2026-10-13 GYM ARC Prompt - New features run]]:

| New table | Planned values |
|---|---|
| Config.Features.Wardrobe | false (hides the Wardrobe) |
| Config.Music | Tracks (empty), Areas: Town / StarterGym / ProGym / BeachGym, volume 0.35, 1.5 s cross-fade |
| Config.Screams | HeavyChance 0.35, Cooldown 2.5 s, Normal / Big sound lists |
| Config.Aura | Layer rules, particle caps, Colors (red, blue, purple, gold, green) |
| Config.PosingComp | Interval 12 min, MaxPlayers 6, score weights, vote bonus, coins |
| Daily quests + login streak | Quest pool, 7-day rewards, title "Dedicated" |
| Config.ArmWrestle | MaxTime 8 s, tap cap 15, 3 NPC levels, title "Arm Wrestling King" |
| Leaderboards | Refresh 60-120 s, top 10, 6 boards |
| Smoothie bar boosts | Protein Shake, Energy Shake, Chicken and Rice, Coconut Water: prices, strength, durations |
| Rivals | One per gym, record numbers per gym |
| Pets | Bonus default 0 |
| Config.DayNight | Length 20 min |
