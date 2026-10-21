---
date: 2026-10-21
tags: [gymarc, prompt]
status: todo
---
# 29 Trainer followers cause lag

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The owner is lagging a lot because many trainers follow him (and other players). Fix performance. Follow CLAUDE.md Speed rules. Measure FPS and the top costs (MicroProfiler / ScriptProfiler) before and after, on a phone-size emulator with 4 players each having 3-4 trainers equipped.

1) FEWER VISIBLE FOLLOWERS
- Each player shows only ONE trainer following them in the world: their highest-rarity equipped trainer. The other equipped trainers still give their boosts, but don't spawn a body. Show them as small portrait icons next to the boosts display instead.
- Setting (in Settings): "Show other players' trainers": On (default) / Off. Low graphics = Off by default.

2) MAKE EACH FOLLOWER CHEAP
- Client-side only (each client renders followers; the server only stores who has what).
- No Humanoid physics: anchored model moved by CFrame lerp, updated at ~15 Hz (30 Hz for your own), no pathfinding, no collisions (CanCollide/CanTouch/CanQuery off).
- Low-poly stage meshes only; no EditableMesh for trainers.
- Animations: only for followers within 60 studs; further away, no animation (or don't render at all beyond 100 studs). Pause the look-at and idle logic when off-screen.
- Auras: max ~10 particles per follower, auras off beyond 40 studs, and off on low graphics.
- One shared update loop for all followers (not one script/loop per trainer).

3) CHECK FOR LEAKS
- Make sure followers are cleaned up when a player unequips, leaves, respawns or teleports (no duplicates piling up). Count the trainer models in the workspace before/after 10 equip/unequip cycles.

Report the FPS before/after and what was the biggest cost. Short progress note in the vault.
```
