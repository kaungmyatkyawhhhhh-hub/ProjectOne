---
date: 2026-10-28
tags: [gymarc, progress]
status: owner to change one setting
---
# Lag spikes when things reappear (prompt 87)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-28 GYM ARC Prompt - 87 Lag spike when things reappear]]. Feature: [[GYM ARC - Performance]].

## How it was measured
- A frame-time logger in play (every frame over 100 ms, with what was added to / removed from the Workspace that frame), teleporting between the starter gym, beach gym, skate park, Powerlifting and the Pro gym, plus ScriptProfilerService.
- Studio on this PC: the spikes come exactly when a gym's machines stream back in: Pro leg press (838 parts) 272 ms, PL squat (484) 160 ms, beach deck (130) 119 ms, PL + starter machines (859) 135 ms. A phone is several times slower, so ~1 s: the owner's "1 fps".
- The ~100 ms hitches in the first minute after joining are the loading-screen preload still downloading (gone once it's done), not this.
- NPC muscles, area lights and NPC hiding: no spike in Studio when they come back.

## Cause
- The place's Workspace has **StreamOutBehavior = Opportunistic** (read from the 28 Oct backup GABACKUPHOF.rbxl: TargetRadius 256, MinRadius 64, IntegrityMode PauseOutsideLoadedArea). Opportunistic unloads everything past 256 studs even when the device has plenty of memory, so every walk away and back reloads whole gyms. Machines are Atomic models, so all their parts arrive in one frame. This came from the 14 Oct streaming advice in [[GYM ARC - Performance]].
- Scripts can't change the streaming settings; the owner changes them in Properties.

## Owner to do
- Studio: select **Workspace** > Properties > Streaming > **StreamOutBehavior = LowMemory**. Keep the rest. Things load once and stay; they only unload if a phone runs low on memory.

## Fixed in code (MachineClient)
- The beach rings' sway loop and the treadmill loop each walked every Machine (GetTagged + an attribute read on each) every frame. They now keep their own lists from the tag's added / removed signals. Profile over 3 s at the beach: ring loop 50-76 ms -> 4 ms; the treadmill loop no longer shows up.
- The ring sway also drops its saved ring positions when a ring part streams out, so the rings aren't moved from stale positions when they come back.
- Tested: rings still sway near the camera; no errors in the output.

## Console: set anyone's LVL
- (owner: "also make it so that i can change levels of any player too") `game.ServerStorage.Admin:Invoke("level", "<player or all>", 250)` (or `"lvl"`). New `PlayerData.AdminSetLevel`: LVL = levelBase + the average muscle level, so it moves `stats.levelBase` (muscles stay) and sets `stats.bestLevel` to the same number (the LEVEL / Strongest board follows, also when lowering). `info` shows LVL. `TopBarClient` now also refreshes on a `stats.levelBase` change (it only watched coins / muscles / spurts / alter). See [[GYM ARC - Admin console]].
- Tested: 5646 -> 250 -> 3 -> 120 -> 321, the top bar showed each at once; a non-number and an unknown player answered with a message; `"all"` works. No errors.
