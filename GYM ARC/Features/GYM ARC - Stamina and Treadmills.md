---
date: 2026-10-08
tags: [gymarc, feature]
status: done
aliases: ["GYM ARC - Stamina"]
---
# GYM ARC - Stamina and Treadmills

Back to [[00 GYM ARC Home|GYM ARC Home]].

Every rep costs stamina, which refills on its own. Running on treadmills raises your max stamina.

## How it works
- **Stamina:** max 100 to start. Each rep costs 4-6 depending on the machine. Refills 20 per second, starting 2 s after the last rep.
- **Recovery stations:** refill faster while standing in them: stretching mat 2.5x, cardio area 1.6x, the beach sauna 3.5x. A small note appears when you step in.
- **Energy Shake:** refills instantly (see [[GYM ARC - Energy Shakes]]).
- **Gym cat:** petting Plates gives +10 stamina (30 s cooldown).
- **Low stamina feel:** under 40% the arms shake and the press slows; under 25% sweat drops; under 15% the bar turns soft red.
- **Treadmills (8 Oct):** 3 in the starter gym, 4 in the pro gym, all the premium model (chrome uprights, LED console with live speed / time / distance). Speeds 2-13 mph work like weight tiers. No stamina cost and no muscle EXP.
- **Max stamina from running:** every 40 m run adds +1 max stamina, up to +150.
- **Running animation:** a real running cycle with stride rate and size following the belt speed; the belt slats slide.
- **Cardio King** title at 10 km.

## Where it lives
- `Config/Stamina`, `Config/Machines` (Treadmill, `Machines.Cardio`)
- `Main` (stamina regen), `Server/StaminaService`, `Server/BoostService`, `MachineClient`
- Builders: `tools/builders/Sauna`, `GymKit` (treadmillPro)
- Numbers: [[GYM ARC - Config values]]

## Planned change
- Monetization prompt: an "Instant stamina refill" product (see [[GYM ARC - Monetization]]).
- New features prompt: a "Run 1 km on the treadmill" daily quest and Coconut Water (faster cardio distance) at the beach.

## Related
[[GYM ARC - Machines]], [[GYM ARC - Machine HUD]], [[GYM ARC - NPC Regulars and Gym Cat]]

## Screenshots
![[GYM ARC/Screenshots/treadmill_run_stride.jpg]]
![[GYM ARC/Screenshots/pro_gym_treadmill_working.png]]
![[GYM ARC/Screenshots/sauna-inside_after.png]]

## Stamina bar (14 Oct)
A slim bar at the very bottom center of the screen, 280 wide, 10 px above the edge.

## Stamina bar only while exercising (14 Oct)
- The stamina bar is hidden while you walk around. It fades in (0.2 s) when you get on a machine (lifting, the treadmill, Auto Lift) and fades out (0.4 s) about 1.5 s after you get off.
- When stamina jumps up while you're not on a machine (a shake, a refill), the bar shows for 3 s so you see it fill. The slow refill in the background stays hidden.
- The bar never moves, and the boost icons above it stay where they are.

![[GYM ARC/Screenshots/stamina_on_machine.jpg]]
