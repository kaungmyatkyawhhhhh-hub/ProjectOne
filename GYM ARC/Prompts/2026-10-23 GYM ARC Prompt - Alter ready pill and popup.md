---
date: 2026-10-23
tags: [gymarc, prompt, ui]
status: done
---
# Alter ready: pill and popup

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Alter ready: two fixes.

1) HUD NEXT ALTER pill when the alter is READY
- Right now it turns into a different, golden chunky "ALTER NOW" button. Keep it the SAME pill as while progressing: same size, same position, the alter's background art filling the whole card with the dark gradient, the same gold outline and fonts.
- Only the text changes: "PUMPED READY" in the alter's colour (stroked) on the first line, and "TAP TO ALTER" in small white text under it. The % is replaced by a small gold "!" chip.
- To show it's ready: the outline glows and pulses gently in the alter's colour, and the art drifts a bit faster. No gold button, no extra text behind it.
- Tapping it opens the BODY ALTER READY popup.

2) BODY ALTER READY popup (match exactly)
- Panel 15% narrower than now, same height or less, centred. Keep the red theme, rings and heartbeat line.
- Remove the flex-arm icon in the top-left.
- Text, top to bottom: "BODY ALTER READY" (as now), the big "PUMPED" title (as now), "ALTER 1" small white text, then "x1.15 GAINS" as a stroked gold pill. Remove the old "Alter 1 · gains x1.15" line.
- ALTER button: red vertical gradient with a faint heartbeat-line texture inside, 3 px dark outline, 6 px darker bottom edge, a soft red glow around it, white stroked chunky text "ALTER >".
- LATER button: dark graphite, the same 3 px dark outline and 6 px darker bottom edge, white stroked "LATER". Same height as ALTER.
- Both buttons press down into their bottom edge when tapped (prompt 37 ChunkyButton).
- Every alter's popup uses this layout with its own colour/theme.
TEST: phone + desktop screenshots of the HUD pill while progressing and when ready, and the popup. Short note in the vault.
```
