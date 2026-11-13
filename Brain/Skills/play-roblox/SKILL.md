---
name: play-roblox
description: Play a Roblox game in the Roblox PLAYER on this Windows PC (not Studio) - see the game, walk, turn the camera, click buttons and 3D boards, open menus - with our own rbx.exe (real scan-code keys, holds, right-drag camera, game-only screenshots). Use for researching other games, playtesting live games, or any "play this Roblox game" task.
---

# play-roblox

The tool: `C:\Users\kaung\.claude\skills\play-roblox\rbx.exe` (source `rbx.cs` next to it; rebuild with
`C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /nologo /optimize /out:rbx.exe /r:System.Drawing.dll rbx.cs`).
Built 1 Nov 2026 because the public Windows computer-use MCP servers can't hold keys or turn a Roblox camera.

## Before you start
- The Roblox player must already be open in the game (RobloxPlayerBeta). The owner opens it.
- Every command focuses the Roblox window itself. While you play, the owner can't use the mouse/keyboard.
- NEVER press anything on a Robux purchase prompt. If a prompt with a Robux price appears: `key esc`, or click its Cancel / X. Don't open shop items.

## Commands (chain with `;` in ONE call, it's much faster)
| Command | What it does |
|---|---|
| `shot PATH [maxWidth]` | screenshot of the game only (default 1280 wide). Then `Read` the PNG. |
| `zoom X Y W H PATH` | full-detail crop of part of the LAST shot (read small labels) |
| `key K [ms]` | tap or hold a key (`key w 800` = walk 0.8 s). `w+a`, `w+space` = together |
| `down K` / `up K` | press / release separately (e.g. hold W while doing other things) |
| `click X Y [left/right] [ms]` | click at last-shot pixel X,Y |
| `move X Y` | move the mouse there (hover) |
| `turn DX [DY] [ms]` | right-drag camera (300 = ~90 degrees) |
| `scroll N` | wheel; +N = zoom in, -N = zoom out (also scrolls a list under the mouse) |
| `rel DX DY [ms]` | raw relative mouse move |
| `wait MS` | pause |
| `type TEXT` | type letters/digits/spaces |
| `release` | let go of every key/button (safety) |

Example (PowerShell): `& "C:\Users\kaung\.claude\skills\play-roblox\rbx.exe" "key w 600; wait 300; shot C:\...\a.png 1280"`

## How to play well (learned the hard way)
1. **Look first:** `shot`, Read it. Zoom out (`move 640 380; scroll -6`) to see more.
2. **Camera: arrow keys** (`key left 330` = ~90 degrees). W walks where the camera faces; A/D strafe. Turn first, then W in 0.5-1.5 s bursts, shot after each.
3. **Follow the game's guide arrow/beam:** turn until it points straight up the screen, then W.
4. **3D boards (screens in the world)** are clicked like a phone screen: stand ~8 studs in front, face them, zoom in, click their buttons. Floating labels in front can block clicks.
5. **Stuck / camera jammed against a wall:** `key s 800` and arrow keys; or the game's teleport menu back to spawn.
6. **Read tiny text with `zoom`**, not by guessing.
7. Log the real clock (`Get-Date`), not your own sense of time: it drifts badly.
8. A UI window: close with its X (top right). Scroll lists with the wheel over them.

## Game notes
Per-game controls live in the vault, e.g. `Celestial Incremental/Research/2026-11-01 Regrowth Incremental - play log and how to play.md` (HOW TO PLAY section). Read it before playing that game, and add what you learn.
