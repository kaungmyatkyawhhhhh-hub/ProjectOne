---
date: 2026-11-12
tags: [gymarc, progress, bugs, performance, ui]
status: in Studio, NOT published. Tested on a TEST save (FreshPlayer, never saves). 0 re-entrancy / task.defer errors.
---
# GYM ARC: UI re-entrancy loops fixed at the root (12 Nov)

Prompt: "REMAINING UI LOOPS (FPS 36). Maintenance fix only." Follows [[2026-11-10 GYM ARC - Like-ratio fixes built (part 1 + part 2)]].
Every change has a "(12 Nov" comment in the script.

## Error report (V1844, last day)
| Count | Error |
|---|---|
| 5,902 | AbsoluteSizeChanged re-entrancy at `Kit` 1433 (`queue`, the text-fit fallback) |
| 1,403 | TextBoundsChanged re-entrancy at `MachineHud` 299 (`fitNeeds`) |
| 857 | SizeChanged re-entrancy at `MachineHud` 447 (`placeUnderTopbar`) |
| 789 | AbsoluteSizeChanged re-entrancy at `Kit` 307 (`Kit.Fit`) |
| 184 | "Maximum re-entrancy depth (80) exceeded calling task.defer" |

## Root cause
The handlers didn't call themselves, but the chain still re-entered. Some handlers wrote Size / AutomaticSize / Position inside the size event of the same object or an ancestor:
- **RightColumn:** the column's AbsoluteSize handler wrote the drawer's Size and AutomaticSize (its parent).
- **MachineHud:** the loop ran fitNeeds (TextBounds) → panel.Size → placeUnderTopbar (SizeChanged) → panel scale → labels refit → TextBounds again.
- **BodyMap:** the panel wrote holder.Size (its parent).
- **Kit labels:** every label kept an AbsoluteSize listener, so every cascade reached thousands of them (that's why `queue` topped the report).
- **task.defer chains:** Kit.OnTopbar and the screen-change handlers chained defers.

## Fix: measure in the event, write later
- **New `Shared.UI.Layout`:**
  - `Layout.Dirty(fn)`: handlers only mark their layout dirty. Every dirty layout runs once per frame in one `RunService.PreRender` step, which starts at depth 0, so nothing can re-enter.
  - `Layout.Set(obj, prop, value)`: writes only when the value really changed (1 px / 0.001 tolerance).
  - `Layout.OnViewport(fn)`: the ONE camera ViewportSize listener (and Studio's TestPhoneSize), debounced 0.2 s.
- **Kit 1433 (fallback `queue`):** the AbsoluteSize listener is removed. The check runs when the Text changes, when the screen size changes, or when TextFits turns false. A TextFits change only marks the label dirty; the listener is dropped once the label is scaled. A label not laid out yet is checked again a few times.
- **Kit 307 (`Kit.Fit`):** the same rule. No AbsoluteSize listener; it refits on Text and screen-size changes, in the layout step.
- **Kit.OnTopbar:** uses Layout.Dirty, no chained task.defer. The modal's fitHeight follows the screen, not root.AbsoluteSize.
- **MachineHud:**
  - fitNeeds just marks dirty (the 10 Nov busy guard is gone);
  - fitNow writes with Layout.Set;
  - placeUnderTopbar comes from the top bar inset + the viewport only, and no longer listens to the panel's own SizeChanged;
  - screen changes go through Layout.OnViewport.
- **The others:**
  - **RightColumn:** column size → Layout.Dirty; Layout writes use the 1 px tolerance; pickCard uses the layout step instead of task.defer.
  - **SideMenu:** the root AbsoluteSize listener is gone; screen size and scale go through the layout step.
  - **MenuClient, BodyMapClient, DailyClient, RunCardsClient, ResultCard:** every size / text-bounds reaction now writes in the layout step.
- **Checked, no change needed:** HudBottom and TopBar have no size listeners. Theme (button Size → gradient colour), ReadyGlow and OverheadTitle write other objects, not their own size.

## Test (TEST save, Studio, phone emulation via TestPhoneSize)
Run: 3 min training on the Flat Bench (6 taps/s), a window opening every 12 s, switching every 30 s between iPhone SE (667x375) and a big tablet (1366x1024). Then off the machine, every window opened and closed (Shop, Quests, Stats, Trainers, Inventory, Settings, Road, Star Track, Boosts, Plate Forge, Needs, Codes, Profile, Muscles). The before run is the same test with the old code put back for the measurement.

| | Before (old code) | After |
|---|---|---|
| Re-entrancy / task.defer errors | 0 | **0** (2 runs) |
| Script errors | 0 | 0 |
| FPS phone size (avg / 1% low) | 56.9 / 31.1 | 56.1 / 25.8 (final run 55.8 / 22.2) |
| FPS tablet size (avg / 1% low) | 56.8 / 23.4 | 56.6 / 21.9 (final run 56.9 / 23.0) |

Script time (ScriptProfiler, self time, ms per second):

| Script | Before | After |
|---|---|---|
| Shared.UI.Kit | 1.45 | **0.60** (+ Layout 0.33) |
| Kit fallback fit + queue | 0.85 | gone from the top list |
| Shared.UI.MachineHud | 0.53 | 0.51 |
| Shared.UI.SideMenu | 0.76 | 0.69 |
| All Shared.UI modules | 8.81 | 8.50 |
| All HUD (Shared.UI + PlayerScripts) | 44.0 | 43.2 |

**Read this honestly:**
- Studio on the PC did NOT reproduce the live flood: the old code also gave 0 errors in the same test. The live errors need real phones (slower frames, bigger Text Size setting) and long sessions.
- So the proof is structural: no handler writes inside its own size event any more. The real check is the error report 2-3 days after publishing.
- Studio FPS is capped near 60 on the PC. The 1% lows move ±5 run to run (noise), so they don't measure the phone FPS. The ~36 FPS has to be re-read on a real phone.
- The biggest HUD costs left are not loops: MachineClient 4.6, GuidePath 2.8 (renderDots), StarterPackClient 2.1, MachineSignsClient 3.0, WorldLodClient 3.1 ms/s. These are the next FPS targets.

## Found, not fixed (not part of this fix)
- Progression Road cards: "REACH GROWTH SPURT 2/3/4" runs past the card edge. Those pills' labels are AutomaticSize X, which the fallback never touched (the same before this fix).

## Backups
- `ServerStorage._Backups_12Nov_UIFix_After` (the fixed sources, StringValues). The temporary test script `_UITest12Nov` is deleted.

## Owner: next
1. File > Save.
2. Test on a phone (train a few minutes, open the windows, check the HUD).
3. Publish.
4. Watch the error report for 2-3 days: these five errors should be ~0.
