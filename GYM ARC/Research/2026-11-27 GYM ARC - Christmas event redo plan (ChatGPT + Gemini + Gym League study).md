---
tags: [gym-arc, christmas-update, research, plan]
date: 2026-11-27
---
# GYM ARC: Christmas event redo plan

**Why we're redoing it:** the owner looked at the event in game and said "i dont think u know how to make the christmas event". What we built is a pile of reward systems, not an event: a lumpy tree, a plain red chair against the wall, floating labels, and a gym that looks the same as normal.

**Sources:**
- ChatGPT and Gemini, given the same brief. Gemini's raw answer is in `xmas_ai_answers/gemini_2026-11-27.txt`; ChatGPT's is summarised below and lives in the "Christmas Event Redesign" chat.
- Two Gym League Christmas videos watched as frame grids (sound not studied):
  - rNNsT_5HGkw "NEW CHRISTMAS UPDATE IN ROBLOX GYM LEAGUE"
  - 0MD92yhUnJ4 "Absolute Zero Body Alter And Buff Santa Trainer", 93K views

Earlier build notes: [[2026-11-26 GYM ARC - Christmas Phase 1 + 2 (advent, canes, free gift)]], [[2026-11-26 GYM ARC - Christmas Phase 2f 2c 3 5 6 (events, chair, launch)]].

## What Gym League does (our closest competitor), from the frames
- **A separate snowy Christmas gym.** A popup announces "End of Year Event … teleport to the Christmas Event GYM" with a big green Teleport button. The gym is an outdoor village:
  - snow and gingerbread houses;
  - warm string lights on fences;
  - giant candy canes;
  - a big lit tree in the middle;
  - gym machines out in the snow.
- **Timed minigames with a banner countdown:**
  - "Snow Launch will load in 8 seconds", a snowball-throw distance contest;
  - "King of the Snow", hold the hill;
  - "Yeti Hide and Seek, starting in 38 seconds";
  - a round timer ("Time left 03:31").
- **Quests:** a quest NPC with "Choose your quest": EASY Train (use machines) or HARD Kill (yetis). The quests window has Daily and Weekly lists.
- **Rewards:**
  - Snowflakes as the event currency, and an event store with mystery items;
  - a "Potential Rewards" gift that shows real odds (Snowflakes 100%, Candy Cane 50%, Gingerbread 30%, Protein Ham 20%, Swole St. Beard 0.5%);
  - limited gears;
  - hidden crystals to find for a title.
- **The want-it items:**
  - "Swole St. Nick", a buff Santa trainer in the Gym Store;
  - "Absolute Zero", an icy body alter shown locked in the store.
- **Codes** posted on social media ("Holidayseasons").

## What ChatGPT and Gemini agree on
1. **Change the whole gym, not one corner.** Warm string lights on walls and ceiling, garlands and wreaths, red/white/gold "peppermint" weight plates, snow outside the windows, a festive arch at the entrance, a banner, festive music and bells.
2. **Build one event place you can see from spawn.** An outdoor Winter Training Yard reached through an opening in the brick wall framed with garland and an arch. No teleport or loading screen. It holds:
   - a real landmark tree (about 1.5x a big player, gold star, ornaments, presents);
   - the event activity;
   - a shop stall;
   - a pedestal showing the top reward.
3. **One Christmas-only activity that uses REP.**
   - ChatGPT: **MEGA GIFT LIFT.** Every 10 minutes, everyone in the yard taps LIFT and a giant present in a steel rig rises. A shared bar fills, the present bursts open with ribbons and canes, and everyone who helped gets paid. Every rep counts the same (new players help as much as veterans), the target scales with the number of players, and one player alone can still finish.
   - Gemini: "Santa's heavy lifting". Reps fill a Festive Pump bar, then you carry a crate to the sleigh and the sleigh fills up.
   - Both turn reps into something you can see happening.
4. **Rewards kids can wear or become, bought with Candy Canes at the shop:**
   - Santa hat (cheap, first session);
   - Candy Cane dumbbells skin;
   - a Gingerbread alter;
   - **Frost Titan**, the signature icy alter, on a rotating pedestal next to the shop so kids see it and want it (Gym League's Absolute Zero is the same idea).
   - ChatGPT's prices: 40 / 100 / 200 / 750 canes, aiming for about 100–120 canes per active hour.
5. **Cut the noise:**
   - Gift Rush and the AFK chair go.
   - Protein Drop and the falling presents become the Mega Gift Lift's payout.
   - The "CHRISTMAS ALTERS n/150" chip goes.
   - The 10 s cutscene becomes a 3 s reveal.
6. **Keep:**
   - the advent calendar, as secondary;
   - Candy Canes, plus the +1 per 60 reps as background income;
   - the free welcome gift;
   - the kill switch.
7. **Calendar (ChatGPT):** don't freeze missed days. Kids miss days around Christmas, so let them claim missed days later. Days 29 Dec – 7 Jan are catch-up.

## Merged plan (recommended): "Christmas Strongman"
**The idea:** you're strong enough to lift Christmas itself.

| # | What | Days |
|---|---|---|
| 1 | Whole-gym makeover: lights, garland, wreaths, peppermint plates, snow outside the windows, an entrance arch, a banner, music. Lighting stays bright and warm (house rule: never dark). | 1 |
| 2 | Winter Training Yard behind an opening in the gym wall: snow ground, fence, pines, mountains behind, the landmark tree, a shop stall, the Frost Titan pedestal, the lift rig. | 1.5 |
| 3 | MEGA GIFT LIFT: every 10 min a real server countdown banner, a 30 s join window, up to 60 s of lifting with REP and a shared bar, the present rises and bursts, rewards paid once per round on the server, safe if a player leaves mid-round. | 2 |
| 4 | Candy Cane shop: hat, cane dumbbells, Gingerbread alter, Frost Titan (made from the existing alter rigs). One CHRISTMAS window with two tabs: Rewards and Calendar. | 1.5 |
| 5 | Remove the chair, Gift Rush, the n/150 chip and the long cutscene. Fold Protein Drop and the gift drops into the lift payout. Missed calendar days stay claimable. | 0.5 |
| 6 | Polish and test: sound, particles, phone performance, save and duplicate checks. | 1.5 |

**If time runs out:** cut the cane dumbbells first, then put the lift inside the gym instead of the yard.

**How to judge it:** show it to kids without explaining. If they talk about lifting the giant present with friends and wanting Frost Titan, it works. If they only talk about claiming gifts, it failed.
