---
date: 2026-11-12
tags: [gymarc, data, likes, lag, prompt]
---
# GYM ARC: like ratio 69% → 67% in one day (12 Nov check)

Owner: "the game went from 69% to 67% like ratio again in one day".

## What the data says (Creator Hub + game page, 12 Nov ~13:20 MMT)
- **Votes:** 191 likes / 93 dislikes = **284 votes total**, so ~3 dislikes move the ratio 1%. 69 → 67 = about 6 more dislikes than likes in a day, out of ~5,000 new players. That's noise, not a trend.
- **Since the fixes (V1844, live 11 Nov 00:18):**

  | Metric | Change |
  |---|---|
  | Errors (last day) | 23,843, **−72%** |
  | Day 1 retention | **+21.5%** (7-day avg 6.98%, +34.8%) |
  | Avg playtime | **13.4 min (+44.6%)** |
  | Daily revenue | **+77%** |
  | New users | −21% (less traffic, not the fixes) |

- **Still bad:**
  - **client frame rate 36 FPS (−7.4%)**;
  - new re-entrancy loops in V1844: **5,902× Kit line 1433 `queue` (AbsoluteSizeChanged)**, 1,403× MachineHud `fitNeeds` line 299, 857× MachineHud `placeUnderTopbar` line 447 (SizeChanged), 789× Kit line 307 anonymous (AbsoluteSizeChanged), 184× task.defer.
  - The 10 Nov fix guarded each handler, but some OTHER handler on the same objects still changes sizes inside size events, and the error names whichever handler is at depth 80.

## Decision
- Don't change the game because of the ratio. The real numbers went UP.
- Fix the remaining loops (FPS = the main dislike reason left).
- Judge the like ratio over a week, not a day.

```text
GYM ARC – REMAINING UI LOOPS (FPS 36). Maintenance fix only. Do NOT publish. TEST save.
Error report (V1844, last day):
- 5,902x "Maximum event re-entrancy depth exceeded for Object.AbsoluteSizeChanged when calling queue on line 1433 in ReplicatedStorage.Shared.UI.Kit"
- 1,403x the same for Object.TextBoundsChanged when calling fitNeeds on line 299 in ReplicatedStorage.Shared.UI.MachineHud
- 857x the same for Object.SizeChanged when calling placeUnderTopbar on line 447 in ReplicatedStorage.Shared.UI.MachineHud
- 789x the same for Object.AbsoluteSizeChanged when calling anonymous function on line 307 in ReplicatedStorage.Shared.UI.Kit
- 184x "Maximum re-entrancy depth (80) exceeded calling task.defer"
The 10 Nov guards stop each handler from re-running itself, but the event still re-enters: some handler writes Size / Position / TextSize / AutomaticSize INSIDE a size or text-bounds event of the same object (or its parent), which fires the event again.
Fix at the root:
1. Find every GetPropertyChangedSignal("AbsoluteSize" / "Size" / "TextBounds") and every .Changed in Shared.UI (Kit, MachineHud, RightColumn, HudBottom, TopBar, SideMenu) and the HUD scripts.
2. A handler must NEVER write a property that fires the event it listens to, on the same object or an ancestor. Measure in the event, write later: collect into one "layout dirty" flag and apply all writes once per frame in a single RunService.Heartbeat (or PreRender) step, and only when the value really changed (compare, with a 1 px tolerance).
3. Kit line 1433 (`queue`, the text-fit fallback): drop the AbsoluteSize listener. Re-check fit only when Text changes and when the screen size changes (one global camera ViewportSize listener, debounced 0.2 s).
4. MachineHud placeUnderTopbar (447): compute from the topbar inset + viewport only; never react to the panel's own SizeChanged.
5. Kit line 307: same rule.
Test: Play on phone emulation (iPhone SE size + a big tablet), train 3 minutes, open/close every window, rotate between 2 sizes. ZERO re-entrancy / task.defer errors in Output. Report the script time (MicroProfiler or Developer Console > ScriptProfiler) before / after for the HUD scripts and the FPS on a phone-size emulation.
```
