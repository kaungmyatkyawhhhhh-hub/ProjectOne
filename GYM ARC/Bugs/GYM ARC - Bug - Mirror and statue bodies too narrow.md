---
date: 2026-10-19
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

# GYM ARC - Bug - Mirror and statue bodies too narrow

Prompt: [[2026-10-19 GYM ARC Prompt - 3 Mirror statue width and duplicate crew tags]].

- **What happened:** the progress mirror's "Now" body and the strongest lifter statue had the muscles but not the body shape: too narrow next to the real player.
- **Cause:** the real body gets `BodyService.ApplyFrame` (genetics shoulder width + the widths that grow with height and muscle) before the golden ratio proportions; the mirror and statue rigs only got the proportions. The statue also always showed a generic fully grown body.
- **Fix:** both copies now use the same `BodyService.ApplyFrame` with the player's saved values, then the proportions, in the same order as the real body. The mirror's "Day one" stays the plain starting body. The statue reads the strongest player's save read-only (`PlayerData.Peek`; the posing champion's values are kept from when they won) and shows their own muscles; it rebuilds when their widths or muscles change.
- **Checked in play:** me, the mirror "Now" and the statue (as me, Studio switch `TestStatueMe`) all had the same widths (shoulders 1.386, waist 1.244) and the same muscle values.
- **Other copies:** photo mode and the posing stage use your real character, and the menu card is only a headshot, so nothing else copies a body. The quad fix reaches the statue through the stage meshes.
- **Seen, not changed:** the mirror rigs still wear your back accessory (a guitar showed on the card); the real character has it removed.

![[GYM ARC/Screenshots/mirror_statue/mirror_now_after.jpg]]
![[GYM ARC/Screenshots/mirror_statue/statue_me_after.jpg]]
