---
date: 2026-10-23
tags: [gymarc, prompt, ui]
status: done
---
# A real soft glow for "ready" (next-evolution button)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Next-evolution button glow (when the player can evolve): right now it's just 2 outlines with different transparency. Replace it with a real soft glow:
- Remove the extra UIStroke outlines used for the glow (keep only the button's own outline).
- Behind the button, add ONE soft glow image: a blurred rounded-rectangle glow texture (white, very soft edges, 9-slice so it fits the button shape), tinted with the tier colour, about 20-24 px bigger than the button on every side. If there's no glow texture yet, make one (a white rounded rect with a heavy Gaussian blur, transparent PNG) and list it for upload.
- Animate it: transparency breathes between ~0.35 and ~0.7 and the size grows ~6 px, on a 1.6 s loop (TweenService, sine in/out).
- On top of the outline: a bright highlight that travels slowly around the border (UIGradient on the UIStroke, rotating, ~3 s per lap), in a lighter tint of the tier colour.
- The glow sits behind the button and never covers the text. Off when the player can't evolve. Reduced Motion: glow stays, no pulsing.
- Use the same glow component for other "ready" things later (alter ready pill, claim buttons).
TEST: a short clip or 2 screenshots (glow at its smallest and biggest). Short note in the vault.
```
