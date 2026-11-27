# GYM ARC: Christmas VFX pass, reviewed to 9+/10

28 Nov 2026. The owner said: "almost everything uses VFX and the entire game is almost driven by it", "keep looping like asking gemini and chatgpt until they say its perfect, above 9/10 rating", and "do everything, stop asking me". It follows [[2026-11-27 GYM ARC - Christmas panel to 9 of 10 (review loop)]].

## Scores (strict, against Pet Sim 99, Bee Swarm and TDS)

| Round | ChatGPT | Gemini |
|---|---|---|
| 1 | 8.7 | 7.4 |
| 2 | 8.9 | 8.6 |
| 3 | **9.2** ("Pass. No further VFX changes required") | **9.1** |

Sheets: [[Screenshots/xmas_panel/vfx_round1.jpg]], [[Screenshots/xmas_panel/vfx_round2.jpg]], [[Screenshots/xmas_panel/vfx_round3.jpg]].

## What's in the game

The new module is `ReplicatedStorage.Shared.VFX.XmasFX`. It runs on the client only and cleans up after itself. With Reduced Motion on, it shows the glow only.

| Moment | How often | Effects | Length | Sound |
|---|---|---|---|---|
| Tap a ready present | each day | small burst on the tile | 0.3 s | Click |
| Present reveal | each day | Anticipation: dark scrim, shake with rising ticks, a 0.1 s squash. Impact: white flash and Burst(tier), where Common/Rare get 1 ring, Epic 2, and Legendary 3 plus a gold wash and 5 big glints. Then the reward pops, the rarity shows in a pill, the name slams in, canes fly into the counter after the name lands (the scrim lifts so the counter bump shows), and "TAP TO CONTINUE" appears. | 2.6 s (4 s on big days) | Whoosh, ticks, drum roll on big days, HofBoom, LevelUp, Thump, Fanfare |
| Ready presents | always while the calendar is open | two staggered twinkles per tile, plus the wobble | loop | none |
| Shop buy | rare | the card bursts and pops, then the unlock showcase: scrim 0.18, stacked glow, the item at 250 px with a wobble, "<RARITY> UNLOCKED!" and the name, a tap hint | 2.2 s, or tap to skip | LevelUp, plus Fanfare (Legendary) or a title sting (Epic) |
| Canes earned elsewhere | often | canes fly into the counter and it bumps | 0.6 s | a tick |

- The reveal and showcase draw above the HUD, tutorial hints and toasts: DisplayOrder 84 and 85.
- Both screens scale with the screen height. Checked on the Galaxy A06 in Device Simulator.
- The sparkle sprite is rbxassetid://122841645096125. Source: [[Assets/xmas_art/sparkle_white.png]], made by `Scripts/make_sparkle.py`.

## Kept on purpose
- **No sunburst rays or star shockwave**, though ChatGPT asked for them (owner rule). The legendary glints do that job instead.
- **The trophy icon stays** for the 4 calendar unlocks: the CHRISTMAS SPIRIT title, the SNOW LIFTER and FROSTBITE TITAN alters, and the GOLD SANTA HAT. Those alters have no in-game look yet: their ids exist only in Config/Advent. Both reviewers accepted that once told why.
- **The toast size stays.** The showcase now carries the moment.

## Saved
- Saved to Team Create on 28 Nov (version 2048), after RestoreTemplates(), with FreshPlayer = true and TestTutorialStep and AdventTestDay cleared. **Not published.**
- TestChristmas = true was already set on Workspace and was left as it was.

## Follow-ups
- **The calendar unlocks grant nothing visible yet:** AlterSnowLifter, AlterFrostbiteTitan, HatSanta and TitleChristmas. Make them real in game, then give each its own cut-out art in the reveal.
- **The thin white speed streaks** from the tutorial's auto-walk (GuidePath, GoToFade DisplayOrder 90) can draw over a reveal if both happen at once.
- **Studio's Device Simulator was left on the Galaxy A06.** Switch it back to PC in Studio's device menu.
- **Not checked:** sound balance by ear, real-phone frame rate.

Lessons are in the `roblox-vfx-reveal` skill, section 4c, synced to Brain/Skills.
