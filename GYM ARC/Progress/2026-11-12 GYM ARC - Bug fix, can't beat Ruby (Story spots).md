---
date: 2026-11-12
tags: [gymarc, bugfix, story]
---
# GYM ARC - Bug: can't beat Ruby (fixed, v1879)

Owner, 12 Nov 23:33: "theres bug rn, i cant beat ruby".

**Cause:** in `Config/Story`, `Story.Spots`, a comment was inserted mid-line after Flint's position:
`Flint = Vector3.new(...), -- (south side ...) Ruby = Vector3.new(...), Onyx = Vector3.new(...),`
Everything after `--` is a comment, so `Spots.Ruby` and `Spots.Onyx` were nil. StoryService's `near()` checks the player against the spot, so the server never showed Ruby's (or Onyx's) card or started the arm wrestle. Chapters 8 and 9 were unreachable.

**Fix:** the comment went onto its own line; Ruby and Onyx are back. Checked: the spots equal the NPCs' positions in the Gem Mine (192.8,-26,128 and 132.8,-26.4,140). Scanned every script for another mid-line comment hiding an assignment: none. Saved as v1879, not published.

**Lesson (2nd time this week, same as the CoachDialog AnchorPoint bug):** never append a `--` comment to a line that has more code after it. Put comments on their own line.
