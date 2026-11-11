---
date: 2026-11-03
tags: [research, thumbnails, ctr, qptr, discovery]
---
# Research: how to make high-CTR Roblox thumbnails (3 Nov 2026)

Owner: "research on how to make high CTR thumbnails on roblox". Builds on [[Playbook notes - Thumbnails]] (28 Oct) and [[2026-10-30 Icon and thumbnail testing]]. Reliability: Roblox staff/docs = high; experienced devs on DevForum = medium; tool-vendor blogs = low (no data, sell a product).

## What Roblox itself says / has measured (high)
- Thumbnail personalization (several thumbnails, Roblox picks per player): average **+8.5% qPTR**, some games **+50%**. Keep several active, a DIVERSE set, test new ones with each major update, then leave them **at least 7 days**. (DevForum staff posts, Nov 2024 / Feb 2025; 2025 Discovery roadmap)
- Make variants VISIBLY different: different gameplay, characters, place, player motivation (competition / creativity / social). Similar ones can't be told apart by the system.
- Show NEW content/features/events; no clickbait or misleading images (Roblox lowers visibility of misleading thumbnails; players who feel tricked leave -> qPTR falls).
- **Since 16 Mar 2026 Search shows the FIRST 16:9 image of the details-page gallery** (not the icon). So gallery image #1 = your search thumbnail. Icons (1:1) still show in Charts / Continue.
- Since 19 Oct 2026 a custom thumbnail is required for any Home recommendation.
- Gameplay video in Recommended plays on hover/scroll-stop: up to +39% playtime from RFY; Standout video tests +47% quality plays (from earlier notes).
- No official CTR numbers per design choice exist.

## The funnel (medium, experienced dev on DevForum)
qPTR = impression CTR x details-page CTR x share who play 5 min.
- Impression CTR (Analytics > Acquisition > New User Funnel): aim **>= 5%**.
- Details page -> Play: aim **>= 70%** (gallery, video, first line of description).
- Then 5-minute retention: bugs / confusion in the first minutes kill qPTR even with a great thumbnail.
- Example: 20% x 35% x 50% = 3.5% qPTR. One dev reports ~3.2% qPTR for his best thumbnail.

## What critics on DevForum point out (medium)
- Thumbnail looks AI / more realistic than the game -> players leave at once (hurts qPTR).
- Too clean / static: add motion (speed lines, effects), action, exaggerated faces.
- Two thumbnails of the same scene waste a slot.

## Design rules (low-medium: vendor blogs + YouTube practice, no hard data)
1. ONE focal subject, big (fills half the image); few large things, not many small ones.
2. Strong contrast: subject brighter/more saturated than the background; outline / rim light / glow to separate it; simple or blurred background.
3. Action + emotion: an action pose, an exaggerated face. YouTube top creators mostly use HAPPY or SURPRISED faces (Kapwing/NeoMam analysis; counts only, no CTR data).
4. Show the core fantasy + progression in one glance: small vs giant, common vs legendary, before vs after.
5. Curiosity: partly hidden thing, "???", a gate, something huge off-frame.
6. Text: 0-3 words, huge, bold, outlined; readable on a phone; never in the bottom ~20% (player count overlay).
7. Must look like the real game (same art style), no fake UI, no "FREE", no Robux claims.
8. Check at phone size (~300 px wide): if you can't tell what it is, simplify.

## What this means for our games
- GYM ARC: gallery image #1 = the best 7 FT! thumbnail (it is the search image now). Run 4-5 visibly different ones (growth/size, Hall of Fame/status, arm wrestling/competition, crew/social, Gem update/new content). Keep the giant clothed and Roblox-styled. Check New User Funnel CTR (>=5%) and details CTR (>=70%) before changing art; fix the freezing first (5-min retention).
- Galaxy Incremental: before/after island (bare rock vs glowing system) = the tycoon progression shot; the Supernova blast = action; the dark galaxy "light it up" = curiosity. Real game style (low-poly), first gallery image the strongest.

Sources: devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689 ; /t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233 ; /t/search-results-will-now-show-169-thumbnails/4525356 ; /t/roblox's-2025-discovery-roadmap.../3557533 ; /t/how-can-i-improve-my-horrible-play-through-rate/3524823 ; /t/qualified-play-through-rate-best/3751740 ; qptr.io/blog/roblox-thumbnail-tips (vendor) ; tubefilter.com 2024/10/24 Kapwing emotion study.
