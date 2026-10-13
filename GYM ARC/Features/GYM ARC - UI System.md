---
date: 2026-10-07
tags: [gymarc, feature]
status: done
---
# GYM ARC - UI System

Back to [[00 GYM ARC Home|GYM ARC Home]].

The "clean minimal" look used by every screen, the colored side menu tiles and the top bar pills.

## How it works
- **Theme:** one shared Theme module is the source of truth; no hardcoded colors or fonts anywhere else. All UI is built in code (StarterGui is empty).
- **Panels:** dark see-through (#0E0E10 at 55%), thin white border, soft drop shadow, 10px corners.
- **Fonts:** Oswald Bold for headings, numbers and buttons (UPPERCASE); Nunito for body text. Never Montserrat or Gotham. Fredoka One only on side menu tile labels.
- **Color only means something:** bumper plate colors for weight tiers, grades and rarity (white, green, yellow, blue, red, black). Soft red #FF8A8A for "needs work". Gold for big moments.
- **Crisp text:** at least 14px, whole sizes, no UIScale on screens, no CanvasGroup fades.
- **Buttons:** at least 44px tall; press shrinks to 0.95 with a soft click.
- **Side menu tiles (UI v7):** a 2-column grid of colored square tiles on the left (68px on PC, 60px on phones): Stats, Muscles, Titles, Genetics, Poses, Crew, Wardrobe. Bounce on hover and press, a white dot when something is new, an arrow tab slides them out like a drawer. On phones they hang under the coins pill, folded by default.
- **Top bar pills:** coins on the left; Quests, Daily Reward and Settings on the right (icon only on phones). Hidden on the menu, while training and behind full-width panels.
- **Notifications:** small, in a corner, fade out. No big pop-ups, no emojis.
- **Phones:** landscape only; tested with the Studio phone layout hook.

## Where it lives
- `Shared/UI/Theme`, `Shared/UI/UIFonts`, `Shared/UI/SideMenu`, `Shared/UI/TopBar`, `Shared/UI/RightColumn`, `Shared/UI/Notify`, `Shared/UI/Icons`, `Shared/UI/UIBus`
- `Config/HudIcons` (tile colors, icons, optional image ids)

## Known issues
- Phone layouts only checked in Studio, not on a real device.

## Planned change
- Monetization prompt: a "Shop" button on the HUD with tabs Passes, Coins, Boosts, Auras; the Wardrobe tile hidden behind a flag.
- New features prompt: a Quests button on the side bar for daily quests, small boost timer icons on the HUD.

## Related
[[GYM ARC - Machine HUD]], [[GYM ARC - Settings]], [[GYM ARC - Stats and Muscles Panel]]

## Screenshots
![[GYM ARC/Screenshots/ui_v7_hud_pc.png]]
![[GYM ARC/Screenshots/ui_v7_phone_hud_fixed.png]]
![[GYM ARC/Screenshots/fonts_after_muscles.png]]
