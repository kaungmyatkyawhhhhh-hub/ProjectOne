---
date: 2026-10-19
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

# GYM ARC - Bug - Two crews with the same tag

Prompt: [[2026-10-19 GYM ARC Prompt - 3 Mirror statue width and duplicate crew tags]].

- **What happened:** ARAQ313 and SRT313 both had the tag [SRT9].
- **Cause:** nothing checked that a crew name or tag was free.
- **Fix:** names and tags are unique, any capitals (`CrewNamesV1` DataStore, claimed with UpdateAsync when a crew is made: "That tag is already taken." / "That crew name is already taken."). A crew whose last member leaves is deleted: its record, its TOP CREWS score and its name and tag. A claim left by a deleted crew is taken over. Crews can't be renamed (there is no rename), so nothing to release there. A player was already only ever in one crew (joining needs leaving first).
- **The duplicate:** two different players (SRT313 by cort, made 14 Oct; ARAQ313 by mosa_ali, made 16 Oct). The older keeps [SRT9]; ARAQ313 is now [SRT1] and its leader gets a message the next time they join ("Another crew already had the tag SRT9, so your crew's tag is now SRT1."). All 9 crews' names and tags were claimed (`tools/crew_names_backfill.luau`); no other clash.
- **Not tested live:** making a crew in Studio needs a saving session; the claim code is new, so watch the first new crews.
