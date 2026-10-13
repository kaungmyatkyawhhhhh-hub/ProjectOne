---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Arm Wrestling

Back to [[00 GYM ARC Home|GYM ARC Home]].

A tapping duel at two tables (starter gym and pro gym). Bigger biceps and forearms push a bit harder, but tap speed decides most matches. Rebuilt 13 Oct (new features run, task 3).

## How it works
- **Tables:** one by the starter gym's front desk and one in the pro gym on the open floor in front of the cable machines. Each runs its own matches.
- **Sitting down:** the same sign and prompt as the machines: a glass diamond "ARM WRESTLING" with the biceps and forearms in red and "1 v 1", the key and OCCUPY, and the glowing floor outline.
- **Opponent:** two players = a match. Alone, you pick an NPC: Rocco (easy, 8 coins), Tess (medium, 15 coins) or Big Lou (hard, 35 coins), or wait for a player to sit down.
- **The match:** 3-2-1, then tap the big TAP button (or anywhere, Space, gamepad A) as fast as you can for up to 8 seconds. The bar shows who is winning (soft red when you're losing). Fill it to pin, or be ahead when time runs out. The server ignores taps faster than 15 a second (no auto-clickers).
- **Strength:** your biceps and forearms look adds up to +50% per tap at the full look, and no more after that, so tapping skill still matters.
- **Rewards:** coins for a win (15 vs a player, the NPC's coins vs an NPC), 5 for everyone who finished; a little Biceps and Forearms EXP for both (much less than a set on a machine). Beating Big Lou gives the title "Arm Wrestling King". Wins count for the "Win an arm wrestle" daily quest.
- **Animation:** both wrestlers lean in, elbows on the pads, hands locked; the arms swing with the bar and the winner slams the loser's hand down (a wooden thud), then pumps a fist.
- **Phones:** a narrower panel and a smaller TAP button, so the wrestlers stay in view.

## Where it lives
- `Config/Social` (ArmWrestle), `Server/ArmWrestleService`, `SocialClient` (panel), `ArmWrestleClient` (arms), `MachineSignsClient` (sign + OCCUPY)
- Tables: `Workspace.ArmWrestleTable` and `Workspace.ProGym.Feature_ArmWrestle.ArmWrestleTablePro` (builder `tools/builders/ArmWrestleTable`)
- Numbers: [[GYM ARC - Config values]]

## Not tested yet
- Two real players at one table.

## History
- Before 13 Oct: - **Table:** in the starter gym by the front desk. - **Match:** 3-second countdown, then both tap as fast as they can. The meter moves toward the winner; after 12 s whoever is ahead wins. - **Strength:** from Biceps, Forearms and Front Delts levels. At an average level of 40 your push doubles. - **Practice opponents:** sit alone for 8 s and a rookie sits down (Rocco, Tess, Big Lou), tapping 5-8 times a second at about your strength. - **Rewards:** 15 coins for a win, 5 for a loss, 8 for beating a rookie. Iron Grip title. - **Anti-autoclicker:** more than 14 taps a second are ignored. - **Animation (9 Oct):** both sit facing each other, elbows on the pads, hands clasped; the hands swing with the meter and shake; the winner slams the arm down and pumps a fist. Works between a 4'0" and a tall player. Only animates when someone is at the table and it is within 70 studs (cheap for slow devices).

## Related
[[GYM ARC - Titles]], [[GYM ARC - Quests and Muscle of the Day]], [[GYM ARC - Machine Signs]], [[GYM ARC - Bug - Pins against an NPC never counted]]

## Screenshots
![[GYM ARC/Screenshots/armwrestle_pick_opponent.jpg]]
![[GYM ARC/Screenshots/armwrestle_vs_npc_live_bar.jpg]]
![[GYM ARC/Screenshots/armwrestle_win_screen.jpg]]
![[GYM ARC/Screenshots/armwrestle_vs_npc_phone_layout.jpg]]
![[GYM ARC/Screenshots/armwrestle_sign_occupy.jpg]]
