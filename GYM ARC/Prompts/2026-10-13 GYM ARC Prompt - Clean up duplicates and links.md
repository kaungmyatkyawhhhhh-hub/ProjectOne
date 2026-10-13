---
date: 2026-10-13
tags: [gymarc, prompt]
status: done
---
# 2026-10-13 GYM ARC Prompt - Clean up duplicates and links

Back to [[00 GYM ARC Home|GYM ARC Home]]. Saved exactly as sent:

CLEAN UP THE GYM ARC NOTES IN MY OBSIDIAN VAULT (C:\ObsidianOne\Claude+Obsidian)
Only touch GYM ARC notes. Never touch my other games' notes.

1. Find duplicates and broken links
   - List every GYM ARC note, and every [[wikilink]] in GYM ARC notes that points to a note that doesn't exist (these show as grey dots in the graph).
   - Group notes that cover the same topic, e.g. "Muscles and Bodies" / "Bodies and muscles", "Stamina" / "Stamina and Treadmills", "Monetization" / "Monetization products", "Daily Quests" / "Quests and Muscle of the Day", "Energy Shakes" / shakes in Economy, etc.

2. Merge
   - For each group keep ONE note with a clear name. Prefer the older note's name if it already existed before today.
   - Move all useful content from the duplicates into it (don't lose anything; if two notes disagree, keep the newer info and put the old line under a "History" heading).
   - Add the other names as aliases in the kept note's frontmatter (aliases: [...]) so old links still resolve.
   - Delete the duplicate notes only after their content is merged. If you can't delete files, move them into "GYM ARC/_to_delete/" and tell me.

3. Fix every link
   - Update every [[link]] in GYM ARC notes to point at the exact kept note name. Afterwards there must be zero links to notes that don't exist.

4. Prevent it next time (add to CLAUDE.md)
   - Before creating a GYM ARC note, search the vault for an existing note on that topic (names AND aliases). If one exists, update it instead of creating a new one.
   - Only link to note names that exist (or create the note at the same time). Copy names exactly.
   - Keep a "GYM ARC - Index" list in 00 GYM ARC Home with every note name, and use it as the source of truth for names.

5. Report: list the merges (kept note <- merged notes), the links you fixed, and the final note count.
