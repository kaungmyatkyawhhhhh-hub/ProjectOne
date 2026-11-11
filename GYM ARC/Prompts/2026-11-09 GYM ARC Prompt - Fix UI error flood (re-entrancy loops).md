---
date: 2026-11-09
tags: [gymarc, prompt, claude-code, bug, autopilot, errors]
status: ready (written by the night shift, not run)
---
# GYM ARC: fix the UI error flood (re-entrancy loops) (night shift, 9 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Maintenance mode: [[2026-11-07 GYM ARC - Owner decision - stop development (autopilot)]] (fix real breakage only).

**Why:** Creator Hub → Error report, last 1 day (read 9 Nov, 07:20 MMT): **110,819 errors**. About 80% are UI layout loops that started with **place version V1783 (5 Nov, ~22:00)**, the same evening as the fonts-through-the-UI-kit work ([[2026-11-05 GYM ARC Prompt - Fonts through the UI kit (whole game)]]). A loop like this can freeze or lag a player's UI.

| count / day | error | first seen |
|---|---|---|
| 57,288 | Maximum re-entrancy depth (80) exceeded calling task.defer | V1783, 5 Nov |
| 12,085 | re-entrancy on AbsoluteSizeChanged, anonymous function line 1421, ReplicatedStorage.Shared.UI.Kit | V1783, 5 Nov |
| 6,091 | re-entrancy on TextBoundsChanged, `fitNeeds` line 295, ReplicatedStorage.Shared.UI.MachineHud | V1728, 4 Nov |
| 3,407 (+102) | The Parent property of PreferredTextCap is locked (parent NULL → Big / Label) | V1783 / V1820 |
| 1,486 | re-entrancy on SizeChanged, `placeUnderTopbar` line 432, MachineHud | V1728, 4 Nov |
| 886 | re-entrancy on AbsoluteSizeChanged, anonymous function line 307, Kit | V1783, 5 Nov |
| 6,180 | StatsLabelsClient:623: invalid argument #3 to 'clamp' (max < min) | V600, 21 Oct |

```text
GYM ARC – FIX THE UI ERROR FLOOD (maintenance mode: fix only, no new features, no visual changes).
Do NOT publish: the owner publishes. Studio: pick "GYM ARC" (placeId 80031260599632) by name.

Creator Hub error report, last 24 h: 110,819 errors. Fix these, in order:
1) "Maximum re-entrancy depth (80) exceeded calling task.defer" (57K/day, since V1783 = the fonts-through-the-UI-kit change, 5 Nov).
2) ReplicatedStorage.Shared.UI.Kit: AbsoluteSizeChanged handlers at line ~1421 and ~307 re-enter themselves (12K + 900/day).
3) ReplicatedStorage.Shared.UI.MachineHud: fitNeeds (line ~295, TextBoundsChanged) and placeUnderTopbar (line ~432, SizeChanged) re-enter themselves (6K + 1.5K/day).
4) "The Parent property of PreferredTextCap is locked, current parent: NULL" (3.5K/day): something re-parents a UITextSizeConstraint/cap that was already destroyed.
5) Players.<Player>.PlayerScripts.StatsLabelsClient:623: math.clamp with max < min (6K/day).

How (same for 1-3): a handler that changes Size / TextSize / font and so fires its own Changed event again. Fix by:
- a per-object "busy" guard (if busy then return), and only writing a property when the new value is really different (compare with a small tolerance);
- one deferred re-layout per frame per object (a dirty flag), never task.defer from inside the handler it triggers;
- for fit-text: compute the size once from TextService:GetTextSize / TextBounds, set it, and do not listen to TextBoundsChanged on the same label you resize.
For 4: check `cap.Parent ~= nil` / not destroyed before re-parenting, or create a fresh one.
For 5: if max < min, swap them or clamp max to min first (guard the input, don't change the look).

Keep every screen looking exactly the same (UI kit rule). Test on a phone emulator size and a PC size: open/close the main windows (Store, Pump Shop, Coach Dex, Physique, Trainers) and the machine HUD 10 times each; the Output must show 0 of these errors.

REPORT (5 lines): the cause of each loop, the files/lines changed, the test result (error count before/after in Output).
```

**Other findings (not urgent):** DataStore "request added to queue" 1,183/day (warning only, no data-loss errors seen); sound load rate limits (HTTP 429) ~500/day.
