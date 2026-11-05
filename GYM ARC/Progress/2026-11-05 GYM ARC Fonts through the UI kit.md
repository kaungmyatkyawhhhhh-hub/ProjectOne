---
date: 2026-11-05
tags: [gymarc, ui, fonts, progress]
---
# GYM ARC - Fonts through the UI kit (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · UI: [[GYM ARC - UI System]] · Same day: [[2026-11-05 GYM ARC Physique panel polish]]

In Studio only. **Not published.**

## Theme (one place: `Shared/UI/Theme` + `Shared/UI/UIFonts`)
| | Value |
|---|---|
| `Theme.Font.Display` | Montserrat Black Italic (Heavy, italic), all caps: titles, tabs, names, labels (the "PHYSIQUE" font) |
| `Theme.Font.Text` | Builder Sans Bold: descriptions |
| `Theme.Font.Number` | Builder Sans Bold: values, %, x1.32, prices, timers |
| `Theme.FontSize` (phone px; Kit.Root scales up on PC) | Title 30, Tab 15, Label 14, Body 14, Small 13, BigNumber 34, Value 24 (a card's number, added) |
| `Theme.TextColor` | Primary #FFFFFF, Secondary #D0D0D0 (`Colors.Muted` was #A39A9D), Positive #4BDB7A, Negative #FF5A5F, Grade = the grade ladder |
| Minimum | `Theme.MinTextSize` 13 (was 10); fit fallback never under `Theme.FitMinTextSize` 11 |
| Stroke | `Theme.TextStroke(label)`: thin dark UIStroke (~1.5 px) for display text over images |

- **Tabular digits:** Roblox has no fixed-width-digit setting (font features aren't exposed) and Builder Sans digits are proportional (1111 = 53 px, 8888 = 82 px at 40 px). So `Kit.Number` right-aligns numbers in fixed-width labels by default.
- **The cartoon font is gone:** LuckiestGuy (the old "Chunky", used for numbers, names, labels, buttons, badges, the side menu, the alter / growth moments, the loading screen) and FredokaOne (Hall of Fame, the intro cutscene). The old names now point at the roles (Chunky / Heading = Display, Body / BodyBold = Text).

## Kit helpers (read only from Theme)
- `Kit.Title` (Display, caps), `Kit.Label` (Display, caps, Secondary), `Kit.Body` (Text, Secondary), `Kit.Number` (Number, right-aligned). Sizes by role name (`TextSize = "Small"`), never a number.
- `Kit.Text` maps every old font name to a role, any dim grey to Secondary, and a size under 13 up to 13 (a fixed box shrinks to fit, max 13, never under 11).
- **Safety net for the whole game** (end of `Kit`): every label in the player's screen guis, including the ones a window still builds itself, is checked when it appears and when its words or box change:
  - fonts go to the three roles;
  - nothing is under 13 px;
  - text that doesn't fit its box scales down (TextScaled with max = its size, min 11);
  - no dim grey (except `Colors.Faint` for locked items).

## Migrated
- **Theme / Kit / UIFonts** (the roles; every Kit.Text and Theme.Text label in the game takes them at once).
- **27 hard-coded font lines** in 21 scripts switched to the roles:
  - Machine, Titles, Progress, StarterPack, Hall of Fame (5), Runway, Story, PlateForge, SideMenu.
  - Boosts / Gear panels, AlterPopup, AlterFX (2), GrowthFX (2), LaunchCinematic, GymReveal, TrainerStories.
  - IntroCutscene (3), LoadingScreen (2), PosingCompService, StrongmanService.
- **Dim grey text colours** in 6 scripts -> #D0D0D0: Titles, PumpShop, ActiveBoosts, Hall of Fame (4), Discovery, FutureYou.
- **Windows fully on the helpers** (no font / size / colour of their own):
  - Physique (StatsClient: both tabs, Lifts, the Growth Spurt moment).
  - Run Cards TALENT POWER.
- **Fits fixed after the bigger minimum:**
  - FutureYou card lines, Daily Quests text (2 lines), Inventory item names (2 lines), Pump Shop tile names (2 lines).
  - Physique: Lifts names (2 lines), MY BUILD (now an icon button like LABELS, it covered the figure's head), the multipliers (Value 24).
  - The boost row timers ("x4.5" in Number).
- **Still on the safety net:** 388 `TextSize = <number>` in 72 scripts. The biggest:
  - GeneticsClient 18, TrainerClient 18, DailyClient 17, MachineHud 15.
  - HallOfFame / HallChoice / PumpShop / Titles / Progress 13 each, RunCards 12, Crew 11, PlateForgeUI 11, AltersPanel 11.
  - These render by the rules already. Moving them to role names is the next passes, window by window.

## Exceptions (kept, on purpose)
- The GYM ARC logo and anything drawn in images; the Run Card and skin card faces (Merriweather serif); the plate prints "M WEIGHTS" + number (`PlateNumbersClient`, GothamBlack on the 3D plates); TopbarPlus.
- Allowed under 13 px (`AllowSmall`): the side menu's tile words under their icons (INVENTORY needs 9 px in the tile art), the BOOST word under the 25-unit HUD tile, badges / tags under 13 px tall (NEW, !, DEAL).

## Checked (Studio, temporary save; PC + phone at 844 x 390 via TestPhoneSize)
- Audit of every screen label after the pass (1,999 labels):
  - Fonts: Montserrat (Display) 1,640, Builder Sans 357, Merriweather 2 (card faces). LuckiestGuy / Fredoka / Gotham / Oswald / Nunito: **0**.
  - Not fitting: 32 before the fixes, **8 now**: DEAL tag, PLAY (italic overhang only), Trainers EVOLVE ALL / OFF / OFF, the skate hint, the Pump Shop "FULL + 60% REGEN" pill, MachineHud BEST WEIGHT. These are the next small fixes.
- Screens looked at:
  - HUD, Physique (both tabs), Pump Shop, Run Cards MY BUILD, Shop, Inventory, Trainers, Genetics, Quests.
  - The coach popup, a story chapter title, the main menu.
- Not done:
  - Hall of Fame / Plate Forge windows open (the story cutscene took the screen).
  - Nameplates / billboards (world scale, only the font rule applies).
  - Other languages (the game isn't localized).
  - A real phone.

Before / after (all in `GYM ARC/Screenshots/2026-11-05_fonts/`):
![[GYM ARC/Screenshots/2026-11-05_fonts/before_physique_genes_phone.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/after_physique_genes_pc.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/before_physique_muscles_phone.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/after_physique_muscles_pc.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/before_hud_pc.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/after_hud_pc.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/before_pumpshop_phone.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/after_pumpshop_phone.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/before_runcards_build_phone.jpg]]
![[GYM ARC/Screenshots/2026-11-05_fonts/after_runcards_build_phone.jpg]]
