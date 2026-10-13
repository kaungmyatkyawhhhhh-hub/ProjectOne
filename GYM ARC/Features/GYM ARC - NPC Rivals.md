---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - NPC Rivals

Back to [[00 GYM ARC Home|GYM ARC Home]].

One named rival per gym, each with a challenge to beat. Built 13 Oct (new features run, task 6).

## How it works
- **The rivals** (original characters, numbers rising in the order the gyms open):
  - **Benny**, starter gym: a full set of 10 on the Flat Bench heavier than 95 lb. Reward 150 coins and the "Beat Benny" title (Uncommon).
  - **Coral**, beach gym: win an arm wrestling match against her. Reward 300 coins and "Beat Coral" (Rare).
  - **Dante**, pro gym (the 8'0" giant regular): a full set on the Squat Rack heavier than 315 lb. Reward 600 coins and "Beat Dante" (Epic).
- **They train like the regulars:** they walk between their gym's machines, lift, drink water and chat. A small "RIVAL" tag sits over each one.
- **Challenge card:** walk up and press **Challenge**. The rival stops and turns to you. The card shows his line, the challenge, his record next to your best, and the reward (title plate in its rarity color). Press **I'M IN** to start the challenge, or **LATER**.
- **Beating him:** a lift counts on any copy of that machine in town. For Coral, sit at any arm wrestling table: she is in the opponent list as "Rival" once you accepted (also for rematches).
- **Reactions:** a set at or under his record, or a lost match, gets a kind line in a bubble over his head ("Close one! Come back stronger."). A win shows a small win card at the bottom (fades after 7 seconds) with his line ("Not bad, rookie. Not bad at all!"), the coins, the title and the next rival.
- **Choice written down:** gyms already open by Growth Spurt (beach at 1, pro at 2), so a rival never opens a gym. Rivals are an extra goal, and the win card points to the next one ("Next rival: Coral at the beach gym (opens at Growth Spurt 1).").
- **Size:** one source. Benny and Coral are built from their look in Config (`Rivals.BuildSpec`), and Coral's arm wrestling copy uses the same spec. Their size never changes after that (checked: the same while you stand next to them and while they train).
- **Phones:** a compact card (no quote line, tighter spacing) that fits a landscape phone.

## Where it lives
- `Config/Rivals` (rivals, challenges, rewards, lines), `Server/RivalService`, `RivalClient`.
- Builder `tools/builders/Rivals` puts Benny and Coral in Workspace.NPCs. Run it again after the NPCs or BeachNPCs builders: those clear every NPC with a Gym attribute.
- Saved per player in `data.rivals` (accepted / beaten) and the stats beatBenny, beatCoral, beatDante (the titles read these).
- Studio test switch: `TestRivalBeat` = a rival's id wins his challenge for every player.

## Known issues
- Tested solo only (2-player tests can't be run from here).

## Related
[[GYM ARC - NPC Regulars and Gym Cat]], [[GYM ARC - Arm Wrestling]], [[GYM ARC - Titles]], [[GYM ARC - Town and Gyms]], [[GYM ARC - Bug - Tutorial path target nil]]

## Screenshots
![[GYM ARC/Screenshots/rival_card_benny.jpg]]
![[GYM ARC/Screenshots/rival_card_coral.jpg]]
![[GYM ARC/Screenshots/rival_card_dante.jpg]]
![[GYM ARC/Screenshots/rival_win_benny.jpg]]
![[GYM ARC/Screenshots/rival_card_phone_layout.jpg]]

## RIVAL tag (14 Oct)
The small RIVAL tag over a rival only shows while you have accepted his challenge.
