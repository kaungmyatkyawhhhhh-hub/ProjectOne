---
date: 2026-10-08
tags: [gymarc, feature]
status: done
---
# GYM ARC - Game Feel

Back to [[00 GYM ARC Home|GYM ARC Home]].

Everything that makes lifting feel satisfying: weighty motion, sounds, popups, the red training tint and the pump.

## How it works
- **Instant feedback:** the rep animation plays on the client at once; the server still checks and applies gains.
- **Weighty motion:** lowering about 0.6 s, pressing about 0.35 s, 0.1 s pause at the top. Heavier tiers are slower. Under 40% stamina the arms shake.
- **Sounds:** plate clank at lockout with random pitch (deeper on heavy tiers), a soft tick per rep, a short breath only on heavy tiers or low stamina. No grunts.
- **Gain popups:** one small "+12" per rep beside the chest (main muscle only), never stacked. Every 10 reps a "Set done · +[total] Chest" popup with a chime and chalk puff. Setting "Gain numbers: On / Minimal / Off".
- **EXP popups (8 Oct):** each rep a small popup per trained muscle with its group's color chip and real EXP ("+1.2K"): main bigger in warm red-orange, secondaries smaller in green, PUMPED / BIG REP gold. At most 8 at once. Setting "Show EXP popups".
- **Training tint (8 Oct):** while on a machine, every trained muscle is tinted red (main about 55%, secondaries about 30%), soft edges, both sides. Each rep a quick lighter red pulse. Same on NPCs and the mirror. Setting "Rep flash".
- **Pump:** the trained muscles swell slightly and settle (shown through the tint; parts are no longer resized).
- **Camera:** a tiny FOV punch on heavy tiers only.
- **Particles:** chalk puff from the hands when getting on, sweat drops under 25% stamina.
- **NEW PR banner:** a small banner (kept although PR popups were listed as cut).

## Where it lives
- `MachineClient` (gainPopup, `ExpPops`), `MuscleRig.SetTraining` / `MuscleRig.Flash`, `Config/HudIcons.MuscleGroups`, `Config/Sounds`
- Studio hooks `TestPopupSlow`, `TestFlashSlow`
- Sounds: see [[GYM ARC - Music and Sounds]]

## Known issues
- The warm rep flash on the body-map is hard to see on light skin under bright lights.

## Planned change
- **Monetization prompt:** grunts and **lift screams** become allowed (see [[GYM ARC - Music and Sounds]]), plus a layered [[GYM ARC - Aura]] while lifting.

## Related
[[GYM ARC - Machine HUD]], [[GYM ARC - Settings]], [[GYM ARC - Muscles and Bodies]], [[GYM ARC - Gains and EXP]]

## Screenshots
![[GYM ARC/Screenshots/exp_popups_flatbench.png]]
![[GYM ARC/Screenshots/training_tint_red_bench.jpg]]
![[GYM ARC/Screenshots/tint_npc_on_bench.png]]
![[GYM ARC/Screenshots/p1_pump-pumped_after.png]]
