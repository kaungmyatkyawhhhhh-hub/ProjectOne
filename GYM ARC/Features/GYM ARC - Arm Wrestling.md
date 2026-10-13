---
date: 2026-10-09
tags: [gymarc, feature]
status: done
---
# GYM ARC - Arm Wrestling

Back to [[00 GYM ARC Home|GYM ARC Home]].

A tapping duel at the table by the front desk. Stronger arms push harder, but tap speed still matters.

## How it works
- **Table:** in the starter gym by the front desk.
- **Match:** 3-second countdown, then both tap as fast as they can. The meter moves toward the winner; after 12 s whoever is ahead wins.
- **Strength:** from Biceps, Forearms and Front Delts levels. At an average level of 40 your push doubles.
- **Practice opponents:** sit alone for 8 s and a rookie sits down (Rocco, Tess, Big Lou), tapping 5-8 times a second at about your strength.
- **Rewards:** 15 coins for a win, 5 for a loss, 8 for beating a rookie. Iron Grip title.
- **Anti-autoclicker:** more than 14 taps a second are ignored.
- **Animation (9 Oct):** both sit facing each other, elbows on the pads, hands clasped; the hands swing with the meter and shake; the winner slams the arm down and pumps a fist. Works between a 4'0" and a tall player. Only animates when someone is at the table and it is within 70 studs (cheap for slow devices).

## Where it lives
- `Config/Social` (ArmWrestle table)
- `Server/ArmWrestleService`, `ArmWrestleClient`, `SocialClient`

## Known issues
- Not yet tested against a second real player.

## Planned change
- **New features prompt, task 3:** 2 tables (starter and pro gym) using the machine Occupy flow; two players = match, alone = choose an NPC. Max time 8 s, a big tap button, a center bar, strength bonus capped so tapping skill matters. 3 NPC difficulty levels; beating the strongest gives "Arm Wrestling King". Small Forearms / Biceps EXP for both. Server cap 15 taps a second.
- Also: an "Arm Wrestling Wins" leaderboard, a "Win an arm wrestle" daily quest, and a scream on a win (monetization prompt).

## Related
[[GYM ARC - Machines]], [[GYM ARC - Leaderboards and Statue]], [[GYM ARC - NPC Rivals]], [[GYM ARC - Titles]]

## Screenshots
![[GYM ARC/Screenshots/armwrestle_live.jpg]]
![[GYM ARC/Screenshots/armwrestle_win_fistpump.jpg]]
![[GYM ARC/Screenshots/armwrestle_grip.jpg]]
