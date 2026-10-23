---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Puffy inner tube shorts

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The gym shorts looked like a puffy inner tube around the thighs.
- **Cause:** The shorts' color layer was drawn about 1.7x too big: a mesh part scales by its own original mesh size, and the layer was given another part's size.
- **Fix:** Each part is sized from its own mesh size; shorts are matte and hug the thighs.
- **Commit:** 9cf1167

![[GYM ARC/Screenshots/shorts_front.png]]
