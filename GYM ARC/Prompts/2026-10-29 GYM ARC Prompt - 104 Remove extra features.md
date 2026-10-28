---
date: 2026-10-29
tags: [gymarc, prompt, simplify]
status: todo (7 Nov, with 91 and 103)
---
# 104 Remove extra features

Back to [[00 GYM ARC Home|GYM ARC Home]] · Cut list: [[2026-10-29 GYM ARC Every decision - the whole game]] (section 21b)

```text
GYM ARC: remove features the game doesn't need (owner: "the game has too many features"). Follow CLAUDE.md. Only the GYM ARC Studio. Never undo my manual Studio changes. Nothing a player OWNS is lost (titles, items, coins). Move removed models/scripts to ServerStorage._Removed_<name>_Nov (don't delete), so they can come back.

1) BASKETBALL COURT + court competitions: off (Config switch + court model to ServerStorage), no UI, guides, sounds, music, quests or titles that point to it. COURT KING owners keep the title.
2) RUSH HOUR (2x coins 3 min every 30 min): off, its pill and clock gone.
3) MEMBERSHIP CARD (Bronze-Diamond): off; show "Lifetime reps" as a plain stat on the profile instead.
4) STYLE > aura colours: stop selling (hide the rows); owners keep wearing theirs.
5) Check nothing else breaks: daily quests that mention removed things are swapped out, analytics events for removed features stop, no console errors.
6) List every removed thing and where it went in the progress note; update the feature notes (status: removed 7 Nov).
TEST: fresh save + an old save that used the court, owned a membership tier and aura colours. No errors, nothing owned lost. Phone screenshots of the HUD (fewer pills).
```
