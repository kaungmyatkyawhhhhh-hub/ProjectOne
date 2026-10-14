---
date: 2026-10-15
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Bug: clothes vanish behind glass

**What happened:** looking through a window or the pro gym glass wall, everyone's clothes disappeared.

**Cause:** Roblox's Glass material hides see-through things behind it. The clothed body pieces are very slightly see-through (so skin shows through the gaps in a shirt image), so the glass hid them.

**Fix (15 Oct):** the 56 see-through glass parts (windows, glass doors, the pro gym glass wall, jars, bottles) use SmoothPlastic with a little shine instead of Glass. Mirrors stay Glass.

![[GYM ARC/Screenshots/lowpoly_glass_fixed.jpg]]
