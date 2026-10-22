---
date: 2026-10-23
tags: [gymarc, progress, ui]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Chrome reset (title menu, left nav, main HUD)

Prompt: [[2026-10-23 GYM ARC Prompt - Chrome reset]]. Game commit 0034b67. The rule is now in CLAUDE.md.

## The rule
- **Chrome** (anything you read, navigate or buy) is quiet:
  - dark graphite, a thin dark outline, a 1 px top highlight, 10 px corners;
  - clean heavy italic labels (Montserrat Heavy Italic);
  - no hex, no diagonal shine, no stroked chunky text, no gold borders.
  - New `Theme.SetChrome(button)` turns any button into chrome.
- **Loud** (rarity colours, chunky stroked text, hex, glow) stays only on collectible tiles, roll reveals, evolutions and claim / equip / wear buttons.
- **Gold** is for numbers, progress and one highlighted element per screen.

## Title menu
- **PLAY:** the chunky stroked word on a deep red gradient, a dark outline and a 5 px darker bottom edge, no shine.
- **SHOP:** clean heavy italic dark words on metallic gold.
- **SETTINGS / NEWS:** clean italic white on dark graphite (the phone icon squares too).
- Same sizes and spacing. Logo, tagline, scene and player card unchanged (the card lost its gold inner line, like every HUD card).

## Left nav (the earlier tiles)
- **Tiles:** larger (58 px, was 54) with 10 px gaps, dark graphite, a thin dark outline, a 1 px top highlight. White line icons, clean italic labels, no hex.
- **Gold:** a gold outline only on the active tile (its window is open) or a notified one (a "!" or NEW).
- **Locked:** dimmed, a grey padlock in place of the icon, the label dimmed but readable.
- **Badges:** one per tile, a red "!" chip or the gold NEW tag in the top-right corner.
- **Phones:** the 2x4 grid still fits at 667x375.

## Main HUD
- **Top bar:** coins stay a top-bar icon, with the count in gold. LVL, DAILY and settings have clean italic labels, the LVL number in gold. The POSING SHOW pill is quiet too (white trophy, italic).
- **HUD cards** (Today's Quest, the Daily Reward card, toasts, the stamina bar, the machine controls): dark graphite with a thin dark outline. No gold inner line, clean italic titles; gold only on counts, percentages and bar fills.
- **NEXT alter / Growth Spurt card:**
  - dark graphite with the screen's one gold outline (the alter's blue / red edge and coloured base are gone); the percent is gold; the alter name keeps its own colour gradient;
  - TAP TO GROW / ALTER NOW (ready to claim) stays the loud gold button;
  - "Finish faster: Shake Bundle" is now small gold italic.
- **Hotbar:** unchanged (it keeps the old card style).
- **Tutorial pieces:** the step band, SKIP, GO TO (italic dark on gold) and the Coach Dex box (thin dark outline, gold italic name, portrait in a dark frame) follow the rule too.

## Hex mesh
- Cells ~18 px (were ~25).
- Window panels keep 5%, collectible tiles ~18%.
- **Removed from:** toasts, the boost info card, the streak days, the PUMP SHOP detail strip, the Agency pity bar and the MY TRAINERS bars. They're all inside a panel that has its own mesh, or are HUD chrome.

## Tested (Studio, temporary save)
- **Title menu** at 844x390.
- **HUD** at 844x390 and 667x375 as a finished-tutorial player at 7'0": NEXT: PUMPED with the one gold outline, gold coins and LVL, a notified Inventory tile.
- **New player** on desktop: locked tiles and the tutorial pieces.
- No errors; the game tests pass.

## Before / after
![[GYM ARC/Screenshots/chrome_reset/before_menu.jpg]]
![[GYM ARC/Screenshots/chrome_reset/menu_844.jpg]]
![[GYM ARC/Screenshots/chrome_reset/hud_844.jpg]]
![[GYM ARC/Screenshots/chrome_reset/hud_667.jpg]]
![[GYM ARC/Screenshots/chrome_reset/daily_streak_solid.jpg]]
![[GYM ARC/Screenshots/chrome_reset/new_player_locked_tiles_tutorial.jpg]]

## PLAY and SHOP follow-up ([[2026-10-23 GYM ARC Prompt - PLAY and SHOP buttons]])
- **PLAY and SHOP** are now the menu's "hero" buttons (`Hero` attribute, `Theme.HeroLip`): 14 px corners, a 3 px dark outline, a 6 px darker bottom edge, a 2 px pale line along the top edge, no glow or halo.
  - **PLAY:** a red gradient (bright to deep), heavy italic white ~44 px with a 2 px dark stroke; the play triangle is scaled up to match.
  - **SHOP:** a gold gradient, heavy italic dark ~28 px (no stroke on the dark words); the cart icon is sized to the words.
- **Unchanged:** SETTINGS and NEWS, and the sizes and spacing.
- **Checked** on desktop and at 667x375. Game commit after 0034b67.

![[GYM ARC/Screenshots/chrome_reset/menu_hero_desktop.jpg]]
![[GYM ARC/Screenshots/chrome_reset/menu_hero_667.jpg]]
