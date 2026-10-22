---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 52 Tutorial restyle

Back to [[00 GYM ARC Home|GYM ARC Home]]

Feature: [[GYM ARC - Tutorial]]. Follows [[2026-10-22 GYM ARC Prompt - 40 Apply all new UI|prompt 40]] (not done there) and the prompt 37 components.

```text
The tutorial still uses the old UI. Restyle it to match the new UI (prompt 40 said to, it wasn't done). Mockups: C:\Users\kaung\Downloads\gym_arc_ui_style_match\real\tutorial.png and tutorial2.png (current look: Downloads\gym_arc_ui_current\tutorial.png, tutorial2.png). Use the prompt 37 components. Mobile first. Don't change the tutorial steps or rewards, only the look.
- COACH DEX DIALOG: dark graphite box with the hex texture, thin gold outline, thick dark bottom edge. His real portrait on the left (the newer Coach Dex picture). Text in white chunky stroked font, "COACH DEX" name tag in gold. "Tap to continue (1/2)" small and grey bottom-right. Reward as a gold "+50" coin pill.
- TARGETS: a gold marker with the name over the target in the world + the gold GuidePath. For a UI button: the rest of the screen dims, the button gets the gold glow and a bouncing gold arrow.
- GO TO button: chunky gold ChunkyButton ("GO TO FLAT BENCH"), teleports (fade + whoosh, 3 s cooldown).
- SKIP: small dark pill top-right "SKIP" (shows after 5 s, tap twice: first tap turns it gold "TAP AGAIN TO SKIP").
- Top band step line: same dark pill style, white chunky text.
- While the tutorial runs, hide the non-tutorial UI (quests, machine labels, boost popups), as in prompt 40.
- The unlock guides (prompt 39) use the same dialog, marker, arrow and buttons, so they get the new look automatically. Check one.
TEST: phone screenshots of each step next to the mockups (save in Screenshots\ui_v3\tutorial). Short progress note in the vault.
```
