---
tags: [research, ui, hud, motion, sfx, vfx]
date: 2026-11-26
source: owner's own recording "Roblox 2026-11-26 13-23-32.mp4" (1920x1080, 60 fps, 89.6 s, stereo 48 kHz)
---
# Research: modern lobby HUD, window motion and UI SFX (Tower Defense Simulator lobby)

Owner: "this game's sfx & GUI & GUI SFX & Motion VFX animations are very good & this is what the modern HUD looks like now."
The game is a tower defense lobby ("TDS: Boot Camp" chapter, Minigunner/Scout towers), Halloween decor.

How I watched it:
- every frame at 2 fps (180 frames) plus 4 fps sheets;
- 12-30 fps close-ups of each animation (open, close, tab scroll, store, unit pick, achievement, skill tree, skill buy, hotbar shine);
- full-size stills.

The sound was **measured, not heard**: a spectrogram, sound starts lined up with clicks, and pitch and length of each sound. Images are in `2026-11-26 TDS lobby HUD study/`.

## What the video shows (timeline)
| t | what |
|---|---|
| 0-15 | lobby idle, walks to the HARDCORE elevator area; hovers the leaderboard |
| 15.6 | PLAY → mode window (Survival / Story / PvP / Arcade / Sandbox) |
| 18.5 / 19.5 | closes it, reopens it |
| 22-28 | sidebar tabs scroll the one long page to each section; opens Party (28) |
| 31.6 | STORE (Featured, Daily Items, Passes, Towers, Skins, Crates, Cosmetics) |
| 43.4 | ITEMS (towers grid, loadout, Emotes, Crates tabs); 49-52 picks Boomerang and Demoman, the 3D model shows on the right |
| 54-62 | INDEX (Enemies with a 3D preview, Achievements with progress bars + reward chips); claims one |
| 63.4 | achievement toast at the top centre |
| 64.5-79 | SKILLS: full-screen hex skill tree, buys Accelerator |
| 80-89 | QUESTS window, Missions Shop, back to Items |

## The HUD (01_lobby_hud.jpg)
**Layout:** nothing in the middle third except the character.
- **Left column:** STORE and ITEMS as wide pill buttons (coloured: red store, teal items); below them PARTY / QUESTS / INDEX / SKILLS as square icon tiles in a 2x2 grid. A big 3D-rendered icon breaks out of each tile's top-left; the label sits under it in white with a dark stroke. A red count badge goes on a corner (Index "1").
- **Currency:** under the buttons, as plain text: an icon, then "Coins" in white, then the amount in gold. Gems use a purple amount. No panel behind it.
- **Bottom centre:** one huge green PLAY button with a white rim. Beside it, the party avatar circle and a "+" circle.
- **Under PLAY:** the 5-slot loadout as character cards. Each card has a number tag at the top-left and a rarity-coloured frame (gold, red, blue).
- **Very bottom:** a thin full-width level bar: "Lv. 265" on the left, a segmented blue bar with "610 Exp" inside, the next level on the right.
- **Top right:** 5 square icon buttons (Claim! with a red "3" badge, Codes, Login 31, News, Settings), each a coloured 3D icon with a tiny label.
- **Under the top-right buttons:** the server leaderboard as a semi-transparent table, with no frame.
- **Right side:** the Quests tracker. It is a small dark title tab, then an exclamation icon, a grey quest name, a white description and a thin outlined progress bar.
- **Corner:** the build hash and version in the bottom-right, in tiny mono text.

**Style:**
- flat dark-glass panels (#1a1a1a at about 85%) with a 1-2 px light outline;
- rounded corners of about 6 px;
- bold sans font (Gotham/Montserrat-like), not cartoon;
- colour comes only from the art (renders, rarity frames, the green buy buttons).

That is the "modern" look: **dark neutral glass + bright 3D art + one strong action colour (green)**.

## Windows (02_store, 03_towers_detail, 04_skill_tree)
- **The world is blurred and darkened behind every window.** It is a camera blur, not a dark overlay. This is the single biggest "modern" tell.
- **The window has no frame.** Content floats on the blur:
  - a left vertical tab rail of 3D icons inside a dark pill;
  - section headers in white, each with a thin rule line after it ("Starter ————");
  - content cards in a grid.
- **Close button:** a red square with a white X, at the top right of the content.
- **Currency** repeats at the top right while a window is open, with blue "+" buttons.
- **Cards:**
  - the art fills the card;
  - the name is at the top and the rarity is on the second line in a rarity colour;
  - the price is at the bottom-left with a coin icon;
  - a green "Owned" ribbon tag breaks out of the left edge;
  - a red "New" tag sits on the top-left;
  - a green gift button sits bottom-right;
  - "Refreshes in 17:05:56" goes in a pill with a clock icon.
- **Rarity cards (towers):** a solid rarity background (yellow, red, grey, green, blue), the character render, the name at the bottom, and a small white corner triangle top-left. A green check means equipped; a red lock means locked. The selected card gets a 2 px yellow outline.
- **Detail panel on the right, no frame:**
  - a big name and the type;
  - a stats column (icon + number);
  - a blue "Skins ✎" chip;
  - the description;
  - a green price button;
  - the live 3D model of the tower, rotating.
- **One long page:** the sidebar tabs SCROLL the page to a section (smooth, about 0.3 s) instead of swapping panes. Sections load as you reach them.

## Motion (measured from 12-30 fps strips)
| Moment | What moves | Timing |
|---|---|---|
| Open a window (10, 12) | HUD fades out with a small slide toward its own edge (left column left, PLAY down) | ~0.1 s |
| | blur + darken ramp in | ~0.1-0.15 s |
| | content: top tab bar and side rail appear first; the cards then build top-left → bottom-right as empty dark tiles that grow from their corner, staggered ~40 ms each | ~0.5 s total |
| | text appears in the tiles, then the art images fade in last | — |
| Store open (12) | blur first, then ~0.4 s of just blur, then the whole page fades in (it loads while the blur covers it) | — |
| Items open | HUD out, blur, grid in | ~0.15 s (fast, already built) |
| Close (11) | content cut instantly (1 frame); the blur fades out over ~0.1 s while the HUD fades and slides back in | ~0.1 s |
| Tab click | the page scroll-tweens to the section; a section's cards build in as it arrives | — |
| Pick a card (13) | the yellow outline snaps on | 1 frame |
| | the detail panel rows appear one after another | ~30 ms each |
| | the 3D model pops in and idles | — |
| Hover | card brightens and grows ~3%; a small tooltip with the name above loadout slots ("Minigunner") | — |
| Hotbar cards (16) | a diagonal shine sweeps across each loadout card, staggered, looping every ~1.5-2 s (gold card strongest) | — |
| Achievement toast | one line of thin white text, top centre ("You have claimed the achievement …"); fades in, holds, fades out; no box | — |

**Skill tree intro (14):** the most "premium" moment in the video.
1. Hard cut to black.
2. A small spinning hex loader for ~0.2 s.
3. White hex silhouettes fly OUT from the centre to their slots (radial burst, ~0.25 s), with grey outer hexes drifting in at the edges.
4. Each hex then fills from white to its colour (purple/red first, then blue/green), ring by ring, ~60 ms per ring.
5. Locked "?" hexes fade in last. Faint 3D dice / d20 wireframes float in the background.

About 1 s in total.

**Skill buy (15):**
- coins pop and tick down with tiny coin particles at the counter;
- the bought hex flashes pure white;
- a white flash spreads to its neighbours (each neighbour flashes white in turn, with diagonal white streaks);
- the neighbours settle back to their colours, now upgraded;
- the tooltip numbers update (6.75% → 7.5%).

About 0.8 s in total.

## Sound (measured)
| Sound | Measurements |
|---|---|
| **Lobby music** | melodic loop, harmonics 250-1200 Hz. 0-22 s is an intro without drums; at ~22 s bass and drums come in (low end jumps ~10 dB). Bed about -30 dB RMS, so UI sounds sit 20 dB+ above it. |
| **Skill tree music** | music **cuts to silence** on the black frame (65.2 s), then a different track plays with heavier bass and twinkly chimes at 5-6 kHz (68-76 s). Lobby music comes back when you exit (~79.5 s). |
| **Click / open** (most buttons) | short bright tick, centre ~3 kHz, ~200 ms tail, peak -8 to -11 dB. Same sound for open, tab and close; quiet and consistent. |
| **Items open** (43.4 s) | louder (-4.8 dB) whoosh/tick |
| **Index grid clicks** (55-57 s) | crisper, higher (~3.8 kHz), 120 ms |
| **Achievement claim** (62.5 s) | the loudest sound in the video (-1.6 dB), very short (56 ms): a pop/cash hit |
| **Skill buy** (75.7 s) | punchy hit (-3.6 dB, 90 ms) plus a sparkle tail at ~4.3 kHz (76.2 s) |
| **Hover** | no sound found on hover; only clicks make sound |

No voice.

## What to take for our games (GYM ARC first)
1. **Blur the world behind windows** (BlurEffect Size ~16-24 in Lighting, plus a slight darken, tween 0.12 s in and 0.1 s out) instead of a dark modal box. Hide the HUD with a fade + 8-12 px slide toward its edge.
2. **Cascade the window's cards in.** Build them top-left → bottom-right, 30-40 ms apart, each growing from its corner (scale 0.9→1 + fade, 0.15 s Quad Out). Text first, art last.
3. **Close fast.** Cut the content instantly, fade the blur, slide the HUD back. Closing should never be slower than opening.
4. **Tabs scroll one long page** (sections with a white header + rule line) instead of swapping panes.
5. **Item cards:**
   - a solid rarity-colour background with the 3D render filling it;
   - a breakout "Owned"/"New" ribbon;
   - a coin + price bottom-left;
   - the selected card gets a yellow outline snap.
6. **A detail panel with a live 3D model** that rotates.
7. **A loop shine on the equipped cards in the hotbar**, a diagonal sweep every ~2 s, staggered.
8. **Our Growth Spurt / alter screens could use the skill-tree style reveal:**
   - cut to black;
   - pieces burst out from the centre as white silhouettes;
   - they fill with colour ring by ring.
   A buy flashes white and the flash spreads to neighbours.
9. **Sound:**
   - one soft ~3 kHz tick for every UI click (not a different sound per button);
   - a punchier hit + sparkle tail only for spending or claiming;
   - silence on cut-to-black, then a feature-specific music track;
   - nothing on hover.
10. **HUD layout:**
    - the left column is 2 wide action pills + a 2x2 icon grid;
    - currency is plain text under the buttons;
    - one big PLAY/action button at the bottom centre with the loadout cards under it;
    - a thin full-width level bar at the very bottom;
    - 5 small icon buttons at the top right (Claim, Codes, Login, News, Settings) with red count badges;
    - the quest tracker is a frameless text block on the right.

Not covered: the in-match HUD, phone layout, and the exact sounds (measured, not heard).

## Applied to GYM ARC (v1952, saved, NOT published)
Owner: "Yes, apply it" (points 1-3). All of it is in the kit, so every Kit.Modal window gets it.

| Point | Change |
|---|---|
| Blur | `Kit.BlurSize` 4 → 14; tweens in over 0.12 s and out over 0.1 s |
| HUD steps aside | `Kit.HudAside` runs when the first window opens and the last one closes. HudBottom, Hotbar, RightColumn, ActiveBoosts and TalentBar fade and slide 16-24 px toward their edge (0.1 s out, 0.14 s back). The left menu already folds by itself. |
| Cascade | `Theme.FadeWindow(root, true, time, cascade)`: grid cells and scrolling-list rows fade in top-left → bottom-right, 30 ms apart (at most 0.42 s), each growing from 0.92 through a temporary "CascadePop" UIScale. Cards with their own UIScale only fade. |
| Faster close | `Kit.CloseTime = 0.1` (opening stays 0.18) |

Also fixed: the right-column pager's right arrow. A Kit.Button's own list-laid icon doesn't draw its Rotation, so the icon is turned inside a holder frame.

**Checked in Play** (Inventory → Auras):
- the world blurs;
- hotbar, right column and boosts step aside;
- cards cascade in row by row;
- the X closes it, and the HUD and blur come back.

**Not checked:**
- phone size;
- windows with very long lists (the cascade caps at 0.42 s);
- the loop shine on hotbar cards and the skill-tree style reveal (points 7-8, not done).
