---
date: 2026-10-13
tags: [gymarc, feature]
status: in progress
---
# GYM ARC - UI System

Back to [[00 GYM ARC Home|GYM ARC Home]].

The owner's UI redesign (13 Oct): every screen rebuilt to the new mockups with image pieces. It replaces the older "clean minimal" look (kept below under History).

## How it works (UI v2, 13 Oct evening: Gym League style)
The dark image-piece redesign from earlier on 13 Oct is cancelled by the owner. The UI now follows the v2 mockups and style guide:
- **Look:** FredokaOne text, white with a black outline; Montserrat for descriptions. Buttons are glossy color gradients (green, red, gold, blue, gray, purple, orange, teal) with a darker bottom edge and a lighter border in their own color, like the left menu tiles. Panels are dark with rounded corners, tabs sit above them, the red X has a white border, and the game blurs behind an open menu.
- **Left menu:** the owner's OLD colored tiles stay (Shop gold first, Stats, Muscles, Titles, Genetics, Poses, Crew, Quests, Trainers; Wardrobe hidden while the Wardrobe feature is off). Same size and gap everywhere, a red number badge for news, a "<" tab that folds them away (remembered per player), and they fold away by themselves while you lift.
- **Top bar:** dark round pills: coins, height "6'4" / 7'0"", level on the left; Daily Reward, Quests and the settings gear on the right.
- **Right side:** the DAILY QUESTS card and the gold GROW tile (READY when you can grow).
- **Bottom:** a big blue stamina bar ("82/100") with the active boost icons and their timers above it.
- **Hints and toasts:** one hint at a time in a band at the top, gone after 4 seconds (Tutorial Hints in Settings turns them off); toasts stack under the top bar.
- **Machine HUD:** see [[GYM ARC - Machine HUD]]: the weight panel on the right, REP and PUMP bottom right, STOP TRAINING above the stamina bar.

- **Settings (mockup 10):** the gear in the top bar opens it; two columns of rows with a gold icon, the name and an ON / OFF button. Others' Sounds mutes other players' lift sounds, Low Graphics turns off shadows and glow effects on your device, Tutorial Hints turns the hints in the top band on or off.

## Where it lives (UI v2)
- `Shared/UI/Theme` (colors, gradients, fonts, panels, buttons), `Shared/UI/Kit` (buttons, bars, tabs, the menu window), `Shared/UI/SideMenu`, `TopBar`, `RightColumn`, `HudBottom`, `Notify`, `MachineHud`; tile colors and icons in `Config/HudIcons`; images and loading tips in `Config/UI`; feature switches in `Config/Features`.

## Earlier on 13 Oct (cancelled): dark image-piece redesign

- **Mockups are the source of truth:** 16 mockups at 844x390 (a landscape phone). Screens are built in the mockup's pixels inside a root that scales with the screen (the shorter side against 390, never wider than the 844px layout), so a phone, a tablet and a PC show the same layout.
- **Image pieces:** panels, cards, buttons, tabs, chips, bars, toggles, tags and badges are the owner's 9-slice images in the Myanmar Builders Club group (corners stay sharp at any size). Text, numbers and icons stay live on top. Icons are the owner's white line icons, tinted.
- **Colors:** dark warm panels (#141113), cards #1D191B, red #E4262F for main buttons, gold #F5B62F for coins and big moments, green #36C26B for claim / done, blue and purple for tags; grades and rarity keep the bumper plate colors.
- **Fonts:** Oswald (titles, buttons, tabs, numbers, UPPERCASE titles) and Montserrat (body text), as the redesign brief asks.
- **Buttons:** a darker bottom edge so they look pressable; pressing moves the content down 2px and the edge goes.
- **Windows:** dark see-through backdrop with a slight blur; open with a small scale-up and fade (0.18s).
- **Main HUD (mockup 01):** top center the coins (gold + opens the shop's coins tab, only while the shop exists), the LEVEL badge with an EXP bar (level = the average of the 18 muscle levels) and the height; menu tiles on the left (Quests shows a red count); on the right the daily quest card, boost chips with timers and the Growth Spurt card (tap it to grow when ready); small toasts at the bottom center.
- **Studio checks:** `TestPhoneSize` (for example 844, 390) shows the screens as that phone.

### Where it lived
- `Config/UI` (all 85 image ids), `Shared/UI/Pieces`, `Shared/UI/Kit` (the components), `Shared/UI/Theme`, `Shared/UI/TopBar`, `Shared/UI/SideMenu`, `Shared/UI/RightColumn`, `Shared/UI/Notify`; tile order, labels and icons in `Config/HudIcons`.

## History (before 13 Oct)
### Old look: how it worked
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
![[GYM ARC/Screenshots/ui_compare_00_foundation_login_streak.jpg]]
![[GYM ARC/Screenshots/ui_compare_01_main_hud_pc.jpg]]
![[GYM ARC/Screenshots/ui_compare_01_main_hud_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_02_machine_hud_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_01_main_hud_menu_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_02_machine_hud_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_10_settings_phone.jpg]]
