---
date: 2026-10-23
tags: [gymarc, prompt, ui]
status: done
---
# Rounded corners on the tier backgrounds

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Next-evolution button in MY TRAINERS: the background picture has square corners that stick out past the rounded outline.
- Give the picture the same rounded corners as the button: put a UICorner on the ImageLabel itself (radius = the button's corner radius minus the outline thickness), or wrap the picture + VFX in a CanvasGroup with a UICorner so everything inside is clipped.
- The UIStroke outline sits exactly on the edge of the rounded picture: no gap, no corners poking out, same thickness all the way round.
- Check every place the tier backgrounds are used (trainer tiles, detail card, evolutions chart, the reveal cards, mini tiles in the NEEDS line) and fix the same problem there.
- Also remove the "EVOLVE!" tag (still showing here).
TEST: close-up screenshots of the button and a trainer tile corner. Short note in the vault.
```
