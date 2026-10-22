---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# Coach dialog spacing

Back to [[00 GYM ARC Home|GYM ARC Home]]

Done together with [[2026-10-23 GYM ARC Prompt - 53a Tutorial restyle|52]] and [[2026-10-23 GYM ARC Prompt - 53 Tutorial and toast cleanup|53]].

```text
Tutorial Coach Dex dialog + GO TO button: everything is squeezed together. Fix the spacing (do this with prompt 53 if it isn't done yet).
- GAP: at least 12 px between the GO TO button and the dialog, and between the dialog and the left nav. Nothing touches.
- GO TO button: smaller (normal ChunkyButton height, about 30% of the screen width on phones), centred above the dialog.
- DIALOG SIZE: max ~55% of the screen width, centred at the bottom, clear of the left nav on every screen size. Less tall: fit the text, then 12 px padding.
- INSIDE PADDING: 12-14 px everywhere. Portrait, text and reward pill each have their own space:
  - Portrait on the left, a bit smaller, with its gold frame. Use the REAL Coach Dex portrait picture (the one used in tutorial2.png), not the blurry 3D render.
  - "COACH DEX" name in gold chunky font.
  - The line in the second font (Inter Bold, sentence case, white), 1.2 line height. Not all caps chunky text; it's too dense to read.
  - The "+50" coin pill at the top-right, never overlapping the text (the text wraps before it).
  - "Tap to continue (1/2)" small and grey at the bottom-right, with space above it.
- Same fix for the unlock guide dialogs (they share this box).
TEST: phone (667x375) and desktop screenshots of the first tutorial step. Short note in the vault.
```
