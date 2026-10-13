---
date: 2026-10-13
tags: [gymarc, feature]
status: planned
---
# GYM ARC - NPC Rivals

Back to [[00 GYM ARC Home|GYM ARC Home]].

Planned (new features prompt, task 6): one named rival NPC per gym with a challenge to beat. Not built yet.

## How it works (as the prompt asks)
- **One rival per gym:** reuse Dante if he fits, plus 2 more with simple original looks and names. They train on machines in their gym like the regulars.
- **Challenge card:** talk to a rival (prompt) to see it. Beat his record on a specific lift, or beat him at arm wrestling for one of them. Numbers in Config, rising per gym in unlock order.
- **Reward:** coins, a title ("Beat Dante", etc.), and a pointer toward the next gym. Gyms already unlock by Growth Spurt, so the rival may become an extra goal instead (to be decided and written down).
- **Reactions:** a short kid-friendly line on a win or loss ("Not bad, rookie." / "Come back stronger."). No insults.
- **Size:** must use the fixed NPC size rules (one source of truth; no shrinking or growing when you get close or while they train).

## Where it lives
- Not built. Would reuse `Server/GymGoerService` / `Server/NpcService` and a new Config table.

## Related
[[GYM ARC - NPC Regulars and Gym Cat]], [[GYM ARC - Arm Wrestling]], [[GYM ARC - Titles]], [[GYM ARC - Town and Gyms]]

## Screenshots
![[GYM ARC/Screenshots/giant_dante_shirtless.jpg]]
