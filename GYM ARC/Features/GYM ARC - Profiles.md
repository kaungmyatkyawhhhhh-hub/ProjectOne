---
date: 2026-10-28
tags: [gymarc, feature]
status: built; own profile tested, the two-player parts not yet
---
# GYM ARC - Profiles

Back to [[00 GYM ARC Home|GYM ARC Home]]. Brief: [[2026-10-27 GYM ARC Prompt - 66 Hall of Fame, Profiles, Codes, Strongman at Alter 2]] (part 3).

## For players
- **Open:** tap another player (their body or the name over their head; not while lifting, in a window, on the menu, in the tutorial or the Hall of Fame ceremony). Your own: Settings > **Profile** (OPEN), or tap your card on the main menu.
- **The card** (the window style, scrolls):
  - headshot, name, the equipped title in its rarity colour, tags: ★N HALL OF FAME, the membership tier (Bronze..Diamond by lifetime reps), the crew tag
  - **VIEW STATUE** (only with a Hall of Fame statue): their statue stands on the Hall's middle stage for you for 60 s (yours comes back after); your own card: yours
  - stats: LVL, height, alter, lifetime reps, best lift (the heaviest plain lb tier lifted, with the machine), posing wins, Strongman wins, playtime
  - their 3 best trainers (BEST EQUIP order) as trainer tiles
  - collection: titles, auras, alter skins (x / y)
  - badges: BETA TESTER (the Roblox badge), event (Seasonal) titles, HALL OF FAMER, LEGEND
  - someone else's card: **ADD FRIEND** (Roblox's friend prompt; "Friends" when you already are), **INVITE TO CREW** (you're in a crew, they aren't), **CHALLENGE** (shows when they're within 40 studs)
- **A challenge:** the other player gets a card under the top bar "NAME challenges you to arm wrestling!" with ACCEPT / NO (15 s). ACCEPT: both are put on the stools of the nearest free arm wrestling table (within 150 studs of the one who asked); the match starts as usual.

## How it works
- `Config/Profiles`: tap range / time, challenge range / time, table range, statue seconds, badge categories.
- `ProfileService` (server): RemoteFunction **Profile** ("Get", userId) builds the card from the save (public info only, players in this server), kept 10 s; analytics `Profile_Opened` (0 = own, 1 = someone's). RemoteEvent **ProfileAction**: Challenge / Accept / ViewStatue (rate-limited, distances checked on the server).
- `ArmWrestleService.Challenge(a, b)`, `HallOfFameService.ShowFor(viewer, target)`, `CrewService.CrewOf(player)`.
- `ProfileClient` (window, tap picking, challenge card), `UIBus.OpenProfile`, Settings `openRow`, MenuClient card button (+ "Profile" allowed on the menu).

## Tested (28 Oct, Studio, one player)
Own card from Settings on the menu and from the menu card: every field filled (stats, trainer tile, collection 9/54 titles, 7/19 auras, 15/15 skins, BETA TESTER badge), buttons hidden on your own card, no errors. **Not tested (needs two players):** tapping someone, ADD FRIEND, INVITE TO CREW, CHALLENGE + ACCEPT, VIEW STATUE of someone else. Test with Studio's Test > Clients and Servers (2 players) or live with a friend.
![[GYM ARC/Screenshots/2026-10-28 Loading screen and codes/9 Profile card top.jpg]]
![[GYM ARC/Screenshots/2026-10-28 Loading screen and codes/10 Profile card bottom.jpg]]
