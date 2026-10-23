---
date: 2026-10-14
tags: [gymarc, prompt]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: top bar with TopbarPlus (14 Oct)
Replaces the earlier custom top bar request (lining our own chips up with Roblox's buttons).

```text
TOP BAR: switch to TopbarPlus (by ForeverHD) instead of our custom top bar chips.
Docs: https://devforum.roblox.com/t/topbarplus-v340-construct-topbar-icons-with-ease-customise-them-with-themes-dropdowns-captions-labels-and-more/1017485 (and the docs site linked there: 1foreverhd.github.io/TopbarPlus).

1. Install
   - Get the official TopbarPlus v3 (latest 3.x) from ForeverHD's GitHub releases or the official Creator Store model (creator: ForeverHD; check it's the real one, no extra scripts/viruses). Put the "Icon" module in ReplicatedStorage (e.g. ReplicatedStorage.Packages.Icon). Don't edit the package's source so we can update it later.
2. Replace our top bar with TopbarPlus icons (LocalScript in StarterPlayerScripts):
   - Left side (after Roblox's buttons): Coins (coin image + live number label), Height ("7'0"" + "MAX" when capped), Level ("LVL 60" label; caption shows EXP progress).
   - Right side (:align("Right")): Daily (calendar icon + notice dot via :notify() when claimable), Quests (icon + notice count), Settings (gear, opens our Settings panel).
   - Use icon:setImage / :setLabel / :setCaption / :notify / :bindEvent("selected"/"deselected") or :oneClick() to open our existing panels. Update labels live when values change.
   - Keep TopbarPlus' default Roblox-style theme (it matches Roblox's buttons). Only change the coin/gold accent color if it still looks native.
3. Remove our old custom top bar ScreenGui and every hardcoded top offset that depended on it. Things that sat under the top bar (quest card, zone messages, Posing Competition card) now start at GuiService.TopbarInset.Max.Y + 8.
4. Mobile: if there isn't room, let TopbarPlus overflow into its dropdown/overflow menu (built in) instead of shrinking or overlapping. Hide Height first.
5. Test phone 844x390, small phone 667x375, PC, and with Roblox chat/menu open: our icons are exactly the same height and line as Roblox's buttons. Screenshot, commit, update PROGRESS.md and Obsidian (credit TopbarPlus in a Credits note).
```
