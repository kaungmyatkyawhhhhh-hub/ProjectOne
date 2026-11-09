---
date: 2026-11-09
tags: [galaxy, status, night-shift]
---
# Galaxy Incremental: status of the 7 Nov prompts + what to run next (night shift, 9 Nov)

Read: the two newest Claude Code reports, [[2026-11-07 Galaxy Incremental - Launch-day fixes]] and [[2026-11-07 Galaxy Incremental - Phone HUD, tycoon pad, rank tag (live fixes)]], plus the hotfix note.

## The 7 Nov list
| item | status | where |
|---|---|---|
| Phone HUD | DONE (UIAudit clean on Android, SE, 14 Pro, iPad, PC) | Phone HUD report §3 |
| STAR DAIS pad arrow | DONE (arrow now above the pad, points down). AlwaysOnTop NOT on (Studio can't screenshot it) | Launch-day §2A |
| Remove the extra pads (UPGRADE / +BODY / UNLOCK) | DONE; the island NextPad is the step-on tycoon button | Phone HUD report §1-2 |
| Overhead rank tag | DONE (studs-sized, own tag hidden; 2-client test passed) | §4 + hotfix note |
| Tutorial arrow / trail | DONE (ends 6 studs in front of the board). Steps 1-20 not walked one by one | §5 |
| Plaza boards | DONE (lamps, FREE REWARDS kept at your spot, 60 studs) | §7 |
| HUD art wiring | DONE. GROUP chip art (116787686626945) failed to load on 7 Nov; the later pre-publish check says all HUD images load | §6 + hotfix note |
| Fall-through hotfix | DONE + 2-client test passed (0 deaths) | [[2026-11-07 Galaxy Incremental - HOTFIX - players fall through their island]] |

## Still open from those reports (owner's call)
1. **Workspace.StreamingIntegrityMode = PauseOutsideLoadedArea**: scripts can't set it; you set it in Studio Properties before a publish. Not checked if done.
2. **Sector 2 gate walk-around**: a player-size character can walk round the locked gate. The fix is written in the plaza note (a second Barrier door across the Sector 2 bridge).
3. Not tested by ear: the music picks. Also 4 music tracks fail to load live (see below).

## Prompts written but no Claude Code report yet (run them in this order)
1. [[2026-11-09 Galaxy Incremental - Prompt - Fix the 3-minute quit (first 10 minutes pacing)]]: the biggest problem (playtime 3.5 min).
2. [[2026-11-08 Galaxy Incremental - Prompt - Windows fit phone + board scroll wheel only]].
3. [[2026-11-09 Galaxy Incremental - Prompt - Space movement (speed + low-gravity jump)]].

**2 notes for the Space movement prompt** (facts from the reports, so Claude Code doesn't redo work):
- Part 3 (void safety) is **already built** by the hotfix (void rescue at 40 studs, through `GalaxyMapService.toIsland` with RequestStreamAroundAsync). Paste this line under the prompt: `Part 3: a void rescue already exists in GalaxyMapService (hotfix, 7 Nov). Reuse it; only add the edge rails and the fade + whoosh.`
- The step-on pad is a position check every 0.25 s (feet on the disc), not Touched. Higher jumps don't break it.

## Live errors (Creator Hub, last 1 day, V210): 24 total, nothing breaking
- 4 music tracks skipped (didn't load: moderated or gone): 1847078335 Get Going B, 1836702723 Uplighter, 1839889971 Back to the Scoreboard, 1844486984 Saturday Special. The game skips them, but the playlist is shorter.
- 5x "Failed to load object. PBR textures may not be visible".
- 2x DataStore queue warning, 1 animation, 1 sound NetFail.
