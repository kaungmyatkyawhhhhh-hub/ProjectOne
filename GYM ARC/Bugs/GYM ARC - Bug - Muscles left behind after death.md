---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Muscles left behind after death

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** When a character died, its muscle meshes could stay behind or the muscle loader could lock up.
- **Cause:** Muscles were not removed with the character, and the mesh allocator kept budget for pieces that failed.
- **Fix:** Muscles are removed on death, the loader is protected, failing pieces free their budget, thigh shorts rebuild after a body swap.
- **Commit:** ba327e0
