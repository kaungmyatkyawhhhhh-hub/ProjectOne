---
date: 2026-10-09
tags: [gymarc, feature]
status: done
---
# GYM ARC - Machine Signs

Back to [[00 GYM ARC Home|GYM ARC Home]].

A floating glass diamond above the nearest machine that tells you what it trains and how to use it.

## How it works
- **Only the nearest machine within 12 studs** shows the sign.
- **The diamond:** a square slab turned 45 degrees, dark tinted matte glass (no reflections since 9 Oct) with a thin glowing white border, gently bobbing and turning toward the camera.
- **Inside:** a white body icon with the main muscle in red, the muscle's name and its share in red (for example "53%").
- **Above:** the machine name in big bold white.
- **Below, the prompt:** a small square key ("E" on PC, the gamepad button, a tap button on touch) and "OCCUPY", or "UNLOCK · 45 COINS" when your next weight can be bought. Prompts reach 10 studs.
- **Floor outline:** a glowing white rectangle around the machine, brighter while you stand inside it.
- **Locked machines:** a lock + "Growth Spurt N".
- **From 12 to 60 studs:** only a bouncing yellow "!" + "NEW" over machines you never used.
- Hidden while you are on a machine; the diamond also hides when the camera is very close. 0.2 s fades.

## Where it lives
- `MachineSignsClient`, `Shared/UI/BodyFigure`, `Server/MachineService` (prompts), save field `machinesUsed`
- Studio hook `TestSignCamera`

## Related
[[GYM ARC - Machines]], [[GYM ARC - Machine HUD]], [[GYM ARC - Tutorial]]

## Screenshots
![[GYM ARC/Screenshots/sign_diamond_flat_bench_side.jpg]]
![[GYM ARC/Screenshots/sign_angle_below.jpg]]
![[GYM ARC/Screenshots/gym_middle_only_bangs.jpg]]
