---
date: 2026-10-14
tags: [gymarc, prompt]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: loading screen, declutter the HUD, Genetics on mobile (14 Oct)

```text
1. LOADING SCREEN: rebuild it to match Downloads\gym_arc_ui_final\00_loading.png (same kit as the rest):
   - logo.png image instead of typed "GYM ARC"; gray "Everyone starts tiny." under it
   - Tip in a dark graphite tile with a small gold "TIP" tag (no yellow "TIP:" text)
   - Step text "LOADING PLAYERS" in the heavy italic font (GothamBlack), percent in gold on the right, a thick metallic red bar in a dark track, small page dots under it (gold = current tip)
   - SKIP = quiet dark button top-right
   - Same dark blurred art background + character on the right

2. TOO MUCH UI ON SCREEN (declutter the HUD):
   - STAMINA must be at the very BOTTOM center of the screen (anchored to the bottom, 10px above the edge) and smaller: max 300px wide, slim bar. Never in the middle.
   - Right side shows only ONE card at a time, priority: (1) TAP TO GROW when ready, (2) Coach quest when it's ready to turn in, (3) Today's quest. The others are hidden; the player sees all quests in the Quests panel.
   - "MAX HEIGHT 7'0"" card: remove it. Max height only shows as the height chip in the top bar ("7'0" MAX" in gold).
   - Zone messages ("Stretching area. Stamina refills faster here.") show once when you enter, as a small pill under the top bar, and fade after 3 s. No permanent banners.
   - Hide the duplicate "Quests" pill in the top bar (Quests is already in the left menu) OR remove the Quests tile from the left menu; keep only one.
   - Left menu: 8 tiles max, collapses with "<" and auto-collapses while lifting or when any panel is open.
   - Floating name tags/billboards over machines only show when you're close (MaxDistance ~25 studs).
   - Rule: the center of the screen and the area around the character stay clear. Max 3 HUD groups visible: top bar, left menu, one right card + bottom stamina.
Screenshot before/after on phone size, commit, update PROGRESS.md and Obsidian.

GENETICS SCREEN IS BROKEN ON MOBILE (see my screenshot: labels overlap "ShoulBacArmLegChestCore", multipliers overlap "x1.5x1.5…", KEEP button and "DNA tokens" are cut off at the right edge, everything is spread across the whole screen).

Rebuild the Genetics reveal as ONE centered panel in the final black + gold kit (same as the Store), max 600px wide on phone, with UIScale so it always fits 844x390 and smaller:
- Header row: "GENETICS" title left, DNA token count chip right (inside the panel, never off-screen).
- Left column: OVERALL label + the big result word ("BLESSED") in the gold gradient heavy italic font, with "View odds" as a small gray link under it.
- Right column: a clean 2-column grid of the 6 muscle groups, one row each: group name (full word: Shoulders, Back, Arms, Legs, Chest, Core) + grade plate (S/A/B/C in the small gold-plate style, or its color) + multiplier "x1.5". Use UIGridLayout/UIListLayout with fixed row heights so nothing can overlap. Text uses TextScaled off, fixed sizes, TextTruncate for long words.
- Under that: Frame and Body as two small chips side by side (wrap to 2 lines if needed, never overflow).
- Bottom row inside the panel: REROLL · 1 DNA TOKEN (quiet dark button) and KEEP (red CTA, the only bright button). Both fully inside the panel, min 44px tall.
- Background: keep the gym visible around the panel with the soft dark blur only behind the panel. Hide the HUD while this screen is open.
- Test on phone 844x390, a small phone 667x375, tablet and PC: nothing cut off, nothing overlapping. Screenshot each, commit, update PROGRESS.md and Obsidian.
```
