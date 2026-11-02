---
date: 2026-11-03
tags: [galaxy, analytics, phone, ui, progress, overnight]
status: built and tested in Studio; not published
---
# Galaxy Incremental - overnight part 5: analytics + phone readability (3 Nov, Claude Code)

From the overnight run (part 5). Screenshots: `Progress\screens\overnight\p5-*`.

## Analytics (all server side, once per real action)
| What | Event | Value / field |
|---|---|---|
| Tutorial steps 1-7 | onboarding funnel (`LogOnboardingFunnelStepEvent`) | step 1-7 |
| Supernova n | custom `Supernova` | value = the Supernova number, field 1 = shards |
| Ring-2 buy | custom `Ring2Buy` (new) | value = the level bought, field 1 = node id |
| Code redeemed | custom `CodeRedeemed` | field 1 = the code |
| Potion used | custom `PotionUsed` | field 1 = Stardust / Comets |
| Pass prompt shown / bought | custom `PassPromptShown` / `PassBought` | field 1 = X2Stardust |
| Session 5 / 15 / 30 min | custom `SessionMinutes` (new) | value = 5, 15, 30 (once each per session) |

- **Every event name is fixed.** The ids go in the custom fields, not in the names, so Roblox's event-name limit stays small: 8 names.
- They show in Creator Hub > Analytics > Custom events.

## Phone readability (667x375)
**How I checked:** a Studio script measured every visible text's real size on the phone frame (font size x every UIScale above it) and listed everything under 12 px.

| Window | Before (smallest row text) | After |
|---|---|---|
| UPGRADES rows (descriptions) | **6.2 px** | **12 px** (2 lines at size 20) |
| Supernova card (KEEP / RESET lines) | ~9 px | all >= 12 px |
| Guide book lines | 11.2 px | ~12 px |
| Codes, Store, Settings | ~11 px | all >= 12 px |
| HUD hint line / "+x/s" | 10.7 / 8 px | 12 / 12 px |
| Tree window (TREE + INFO) | 9-11 px | 11-12 px |

**How (phones only; the desktop look stays the approved v12 one):**
- **One phone check in the kit:** `Kit.phone()` (a screen under 500 px tall, or Studio's `TestPhone`) and `Kit.ps(desktop, phone)` for sizes.
- **UPGRADES rows** (also the island boards on a phone, same code):
  - descriptions wrap onto 2 lines at size 20;
  - the name moves up and the "1/s > 2/s" chip moves down to make room;
  - LV, the locked-button captions and the tab captions are bigger.
- **Windows on a phone use more of the screen:** the glow's margin is no longer reserved, and the smaller windows (Codes, Store, Settings, Guide, Supernova card) may grow to 0.85 where they fit.
- **The Supernova card's long line is shorter:** "Wait to earn 2x first: 24 shards (+41%)".
- **The hotbar's key letters (U F T G E Q) are hidden on phones** (no keyboard).

**Still under 12 px (short captions, kept on purpose):**
- In UPGRADES: "ESSENCE" under the chip number (8.4), the locked tabs' "SUPERNOVA 3" / "100K SHARDS" (10.2), and the "UNLOCK MOON" button caption (10.8).
- In the tree window: "NEXT UPDATE" / "SUPERNOVA 1" under locked tiles (11).
- These are short words in fixed spots. Making them bigger needs a new phone layout for those windows. **Your call** (open question in the overnight summary).

## Tested
- Every window opened on the phone frame and measured.
- Settings → CODES opens Codes (Settings closes).
- The Supernova card on a phone (shot p5-02), the UPGRADES window (p5-01).
- No errors.

## Code
- **Changed:**
  - UIKit: `Kit.phone`, `Kit.ps`
  - UpgradesPanel, IslandBoardsUI: phone sizes
  - GalaxyHUD: phone sizes, window room, no key letters on phones
  - GalaxyGuide / Codes / Store / Settings / Supernova / Potions: phone sizes and scale
  - GalaxyEconService: Ring2Buy, SessionMinutes
- **Vault copies:** `Code\friends-test\`.
