---
tags: [brain, method, gate]
created: 2026-11-09
---
# Launch gate (before ANY public launch or big update)

**Why:** Galaxy launched broken on phones (overlapping HUD, windows off screen, players falling into the void) and got 5 likes / 8 dislikes. A boring game makes kids leave; a BROKEN game makes them dislike. Lessons: [[Roblox Playbook/Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]].

## Must pass (all)
- [ ] Someone other than the owner plays 10 min on a real PHONE, fresh account.
- [ ] 2-player test on 2 devices, with streaming on (nobody falls through anything).
- [ ] [[Impatient kid simulation]]: 100% past 60 s at median patience.
- [ ] Something to do every ~3 s in the first 30 s; no wait over ~20 s in the first 10 min.
- [ ] Phone UI audit: no overlaps, nothing off screen, text ≥ 14 px, safe insets, the jump button never over a button.
- [ ] Lighting: the play space is bright; music is upbeat.
- [ ] No placeholder-looking UI.
- [ ] UIAudit clean: only palette-token colours, max 3 component families (counter / button / tile), no floating text, no screen-space giant arrows, on 3 phone sizes.
- [ ] Movement feel pass on a phone (speed, turning, jump/swim); no falling through or clipping; streaming-safe teleports.
- [ ] Lighting per zone checked on a phone at min AND max graphics with the HUD on: nothing blown out behind the HUD, the ground has mid-tones.
- [ ] Like prompt only after the first big moment, no reward.
- [ ] No Test switches on in Workspace; File > Save done.
- [ ] Title without [ALPHA]-style tags unless it's a real limited test.
