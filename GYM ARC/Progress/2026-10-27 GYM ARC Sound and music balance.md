---
date: 2026-10-27
tags: [gymarc, progress]
status: done
---
# Sound and music balance (prompt 73)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 73 Sound and music]].

See [[GYM ARC - Music and Sounds]] (Balance pass). Tested in play: the starter track at 0.56 and the Pro track at 0.85 (their gains), back within 5 s resumes, a later visit plays the next track. No errors.

How to measure a track (Studio play test, client): put a Sound with the id in a SoundGroup at volume 0, jump TimePosition to 15/35/55/75% of TimeLength, read PlaybackLoudness every 0.1 s for ~2.5 s at each point; gain = 180 / average.
