---
date: 2026-11-02
tags: [gymarc, progress, ui, art]
status: done in Studio (not published)
---
Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-11-02 GYM ARC Prompt - Run card icons v5]] · Feature: [[GYM ARC - Run Cards]]

# Run card icons v5

## Where the old icons were used
- Searched every script, ImageLabel and Decal for the 10 old ids. They were in **one place only**: `ReplicatedStorage.Shared.Config.RunCards`, table `RunCards.Art.Types`. No UI script has a hard-coded id.
- The card hand, the keep window and MY BUILD's legacy cards read that table (`RunCardsClient`, `ART.Types[card.type]`).
- MY BUILD's rows used a kit glyph (dumbbell / sparkles / coin), and the tracker uses the kit "sparkles" icon. Neither used the old pictures.
- The odds window has only rarity tags, no type pictures.

## What changed
- **Ids:** the owner's uploads were not in Workspace or in the Myanmar Builders Club inventory (searched by name: gymarc_icon, shoulders, bicep; newest group images and decals), so I uploaded the 8 PNGs from `GYM ARC/Assets/icons_v5_runcards` with Studio's image upload. They are on the owner's account, which also owns the game, so they always load.

| Card type | File | New id |
|---|---|---|
| Chest | gymarc_icon_chest | 91440989366664 |
| Shoulders | gymarc_icon_shoulders | 134801909612812 |
| Back | gymarc_icon_back | 135324963479780 |
| Arms | gymarc_icon_bicep | 115090108614964 |
| Legs | gymarc_icon_legs | 95922603330447 |
| Core | gymarc_icon_abs | 111752824405672 |
| All Muscles | gymarc_icon_star | 134724855022220 |
| Coins Per Rep | gymarc_icon_coins | 124843647867791 |

- **No v5 icon:** Trainer Power and Stamina. They keep their drawn pictures (81769752416001, 120703350002828); nothing was reused for them.
- **MY BUILD rows** now show the type's card picture from the same table (34 px, zoomed on the middle 352 px of the 512 px image so the emblem reads at that size). A type with no picture would fall back to the kit glyph.
- Code: `Config/RunCards` (ids), `RunCardsClient.row` (MY BUILD picture).

## Tested (Studio Play, temporary data)
- Sent the client a test state (11 cards, 3 legacy, 2 picks waiting). The real save was not changed.
- **Loading:** every MY BUILD row picture and the legacy card art reported `IsLoaded = true`. All 8 new pictures also showed on real cards in the hand. No grey squares.
- PreloadAsync from the command bar reports "Failure" for every id, the old ones too, so that test doesn't work from the command bar.
- Hand: common and rare cards. Chest (Common), All Muscles (Rare), Coins (Common). Then Arms (Rare), Shoulders, Back. Then Core, Legs (Rare), Trainer Power.
- MY BUILD: all 10 rows plus the legacy cards (All Muscles Epic, Coins Common, Arms Rare).
- Tracker: "RUN CARDS · 2", unchanged (kit icon).
- Phone (844x390): MY BUILD with Kit's TestPhoneSize; the hand laid out in the same phone frame (test only).
- No game errors in the output.
- Small thing seen on the phone shot, not changed: "Tap a card to keep it" sits right under the raised middle card.

## Screenshots
`GYM ARC/Screenshots/runcard_icons_v5/`
- ![[GYM ARC/Screenshots/runcard_icons_v5/1_hand_common_rare_pc.jpg]]
- ![[GYM ARC/Screenshots/runcard_icons_v5/2_hand_arms_shoulders_back_pc.jpg]]
- ![[GYM ARC/Screenshots/runcard_icons_v5/3_hand_core_legs_trainers_pc.jpg]]
- ![[GYM ARC/Screenshots/runcard_icons_v5/4_my_build_pc.jpg]]
- ![[GYM ARC/Screenshots/runcard_icons_v5/5_my_build_lower_rows_pc.jpg]]
- ![[GYM ARC/Screenshots/runcard_icons_v5/6_tracker_pc.jpg]]
- ![[GYM ARC/Screenshots/runcard_icons_v5/7_my_build_phone.jpg]]
- ![[GYM ARC/Screenshots/runcard_icons_v5/8_hand_phone.jpg]]

## Owner to-do
- If you want them on Myanmar Builders Club: send me the 8 group ids and I'll swap them in the same table, then check they load.
- File > Save to Roblox + Download a Copy, then Publish.
