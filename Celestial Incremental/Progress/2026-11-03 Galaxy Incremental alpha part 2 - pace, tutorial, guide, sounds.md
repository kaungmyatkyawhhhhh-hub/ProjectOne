---
date: 2026-11-03
tags: [galaxy, alpha, progress, sound, guide]
status: built and tested in Studio; not published
---
# Galaxy Incremental - alpha part 2: pace, tutorial, guide book, sounds (3 Nov, Claude Code)

From [[2026-11-03 Galaxy Incremental - Prompt - ALPHA 2 (pace, tutorial, guide, sounds)]] + the owner's item 6 (music cut).
Place "Galaxy Incremental" (111654682859982, P&L Studios XP). GYM ARC was not touched.
Screenshots: `Progress\screens\2026-11-03-alpha2\` (01-17).

## 1. Pace
- **EconConfig:** Supernova need **2M** earned (was 1M); **Starfire x1.75** a level (was x1.5).
- The shards formula still uses 1M (`Econ.ShardBase`), so the first Supernova gives **14 shards** (as decided).
- **Bot test** (fresh save, real time, same bot as alpha 1: best-payback buys every 0.25 s, half the comets, ring 2 bought right after the Supernova):

| | Bot | Real player (x1.4) | Target |
|---|---|---|---|
| First Supernova | **6.8 min** (411 s, 14 shards) | **~9.6 min** | ~10 min |
| Second run | **3.8 min** (227 s) | ~5.3 min | ~2x faster |
| Speed-up | **1.81x** | | ~2x |

- **Decision:** kept both numbers. Run 1 hits the target. Run 2 is 1.8x, close to ~2x.
  - Raising Starfire to x2 would make 5 levels worth x32, far above the design rule (~x10 for 93 shards).
  - A second run with the tutorial (real clicks) reached Supernova at **392 s**: the same pace.

## 2. Tutorial 1-7 (fresh save, end to end)
| Step | Arrow on | Done how in the test |
|---|---|---|
| 1 Buy an asteroid | **the island's BODIES board** UPGRADE (arrow + ring; gold floor arrows while away) (shot 01) | the board's own buy request (see "not tested") |
| 2 FIRST LIGHT | hotbar U, then FREE in UPGRADES (02, 03) | real clicks |
| 3 First Moon | PLANETS tab, UNLOCK 80, then the Moon (04) | real clicks |
| 4 Tap the comet | the ringed tutorial comet (05) | the catch request (see "not tested") |
| 5 50% SUPERNOVA | the goal bar (06) | the buyer bot |
| 6 Go SUPERNOVA | the SUPERNOVA button (07); card (08), cinematic (09) | real clicks |
| 7 STARFIRE | T, then Starfire's UPGRADE (10) | real clicks |

- **+1 Essence each:** Essence 7 at the end.
- **The end:** TUTORIAL COMPLETE "7/7 ESSENCE 7" + "NEXT: STAR FORGE AT SUPERNOVA 3" (11).
  - The Star Forge on the plaza then glows gold for 20 s: a gold Highlight that pulses, plus a light (12).
  - **Fixed:** the message used to sit on top of the open TREE window. The windows now close first.
- **Funnel:** all 7 steps logged by AnalyticsService (Output: "LogOnboardingFunnelStepEvent fired" x7).
- **Fixed:** Starfire showed "x1.7 next". Multipliers now show 2 decimals ("x1.75").

## 3. Guide book (key G + hotbar G)
- **The window** (shots 14, 16, 17): the UPGRADES window's frame, now one kit piece (`Kit.window`), in violet.
  - Page list on the left: the UPGRADES category buttons.
  - The page on the right: a picture + its title + 3 short lines.
- **7 pages, in unlock order:**
  - STARDUST and ISLAND (from the start)
  - TREE (step 2)
  - COMETS and SUPERNOVA (step 4)
  - STAR SURGE and RANKS (Supernova 1)
- **Locked pages:** grey, "?" and a padlock; the page shows a big "?" and "Unlocks at: ...".
- **Red dots:** a red dot on every unlocked page you haven't opened, and on the hotbar's G while there is one (13). Opening a page clears its dot.
  - Which pages you've opened is saved (`GuideSeen`).
- **Pictures:** 7 screenshots of the real game taken in Studio (no AI art), 512x288, in `UI\guide\`.
- **The hotbar now has 6 keys:** U F T **G** E Q.
  - The G icon is a new Blender render in the same icon style (`Icons\rendered\icon_book.png`, `UI\galaxy_icons_extra.py` "book").
- **Phone:** tabs got short names (STARDUST, ISLAND, TREE...) and bigger text. The 3 lines share one size: 18, smaller only when a line is too long.

## 4. Sounds + music
- **Every id is in ONE config:** `ReplicatedStorage.Galaxy.Sounds` (vault `Code\friends-test\Sounds.lua`).
- **All sounds are Roblox's licensed Creator Store audio:** Roblox's own UI pack, Pro Sound Effects (licensed to Roblox), APM Music.
  - **Nothing for you to upload.**
  - Every id loads in the group game (checked in Play: all 14 loaded with their length).

| Sound | Asset |
|---|---|
| buy click | Roblox_UI_Bright_Click 15675059323 |
| tabs | Roblox_UI_Small_Click 15675032796 |
| buy (bodies) | Synth Sparkle Tone ... Ding 9126073001 |
| milestone x2 (+ TUTORIAL COMPLETE) | Roblox_UI_Tonal_Stinger 15675043410 |
| comet appear | Comet Trail Hissy Pass Bys 9113853873 |
| comet catch | Synth Sparkle Tone Burst 9126076030 |
| island piece pop (3D, at the piece) | Roblox_UI_Cute_Pop 15675055424 |
| Supernova wind-up | Time Warp Searing Build Up 9126102694 |
| Supernova boom | Time Warp Big Explosion Blast Boom 9126102254 |
| shards fly-in (pitch climbs per shard) | Electronic Blips Crystalline 9125530803 |
| UI open / close | Roblox_UI_Whoosh_01 15675024286 / Whoosh_02 15675028888 |
| error (can't afford) | Roblox GUI - Negative 17208353912 |
| **music loop** | APM "Ethereal Drone" 1837463526 (122 s, calm celestial synth) |

- **Volumes were balanced by measuring** each file's loudness in Studio (PlaybackLoudness), because I can't listen.
  - Some files were 10x quieter than others. The first milestone chime was almost silent, so I swapped it for the Tonal Stinger.
  - **Please listen once and tell me any sound you don't like:** it's one id to change.
- **Mixing:** two SoundGroups, Music and SFX.
  - Effects are pooled, and the frequent ones vary their pitch a little.
  - All effects are loaded in the background at join.
- **SETTINGS window (hotbar Q / key Q):** MUSIC + SOUND EFFECTS sliders (v12 style, a new kit piece `Kit.slider`), defaults 60% / 80%.
  - You hear the change while you drag (shot 15).
  - Saved in your save on release (tested: dragged MUSIC to 24%, the server stored 0.24).

## 5. Music cut in the Supernova (item 6)
Tested with a volume log through the cinematic (slow-mo x3):
- **Wind-up:** the music fades to silence in 0.3 s, and the riser starts.
- **Impact:** the boom.
- **Shards:** a blip per shard landing.
- **After the stamp has gone:** the music fades back in over 1.5 s.

## Tested
- 2 full fresh-save runs to Supernova 1 (bot), and 1 with the tutorial and sounds playing.
- Every new window on the phone frame 667x375.
- Output: no errors from the game. The only errors were my own test commands.

## Not tested / open
- **Taps on the 3D board screens and on a moving comet:** Studio's input tool can't do these. I sent the same requests the board / comet tap sends.
  - The board and comet taps themselves were tested in earlier sessions.
- **The sound mix:** measured, not heard. A real phone test is still to do.
- **On a phone the guide's lines are ~11 px:** readable but small. Overnight part 5 (phone readability) covers every window.

## Owner to-do
- **Images:** the 8 new images (book icon + 7 guide pictures) were uploaded from Studio as test copies.
  - Re-upload them to P&L Studios XP like the other UI images and swap the ids in `UIAssets` (`icon.book`, `guide.*`).
  - Files: `Icons\rendered\icon_book.png`, `UI\guide\guide_*.png`.
- File > Save when you're happy. **Don't publish yet:** the overnight parts come first.

## Code
- **New:**
  - `ReplicatedStorage.Galaxy.Sounds`
  - `StarterPlayerScripts.GalaxyGuide`
  - `StarterPlayerScripts.GalaxySettings`
- **Changed:**
  - EconConfig: pace, ShardBase
  - UIKit: sound player, music, `Kit.window`, `Kit.panel`, `Kit.redDot`, `Kit.slider`
  - GalaxyHUD: G and Q keys, side windows, body/milestone sounds, Forge glow, windows close at the end
  - GalaxySupernova: music cut + sounds
  - GalaxyMapClient: comet and piece sounds
  - GalaxyEconService: "Settings" and "GuideSeen" requests, both saved
  - IslandBoardsUI: x1.75 shown
  - UIAssets: book + guide ids
- **Vault copies:** `Code\friends-test\` and `Code\map\MapClient.lua`, checked identical to Studio.
