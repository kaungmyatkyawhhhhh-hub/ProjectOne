---
tags: [brain, skills]
updated: 2026-11-14
---
# Skills index (Brain/Skills)
Back to [[00 BRAIN]]. Each folder holds the CURRENT copy of one of the owner's Claude skills (`<name>/SKILL.md` + any helper files).

**RULE (owner, 13 Nov 2026):** whenever a skill is created or updated, copy the new SKILL.md (and its files) into `Brain/Skills/<name>/` in the same turn and update this index. The vault is the brain; a skill that lives only in Claude is lost knowledge.

| Skill | Use it when |
|---|---|
| [[Skills/dead-game-method/SKILL\|dead-game-method]] | Use for new Roblox game ideas or features: research shut-down multiplayer games with passionate fans, why they were loved and died, and reinvent the mechanics as original Roblox concepts. |
| [[Skills/debate-kids-sim/SKILL\|debate-kids-sim]] | Use for a new Roblox game or big update: simulate friend groups arguing over which game to play, find kids' objections to ours, and fix the game until every group agrees. |
| [[Skills/impatient-kid-sim/SKILL\|impatient-kid-sim]] | Use when checking or fixing a Roblox game's first minutes: simulate impatient kids on the live economy, find dead time, and iterate changes until they stay. |
| [[Skills/kid-focus-group/SKILL\|kid-focus-group]] | Use when deciding what goes into a Roblox game update or new game: ChatGPT role-plays groups of kids, Claude pitches the live game and fixes objections until all vote for it. |
| [[Skills/overstimulated-kid-sim/SKILL\|overstimulated-kid-sim]] | Use when a Roblox game's screen may get too busy: simulate kids overloaded by stacked pop-ups, cards, flashes and sounds, find missed messages and collisions, and fix until nothing piles up. |
| [[Skills/pro-video-editing/SKILL\|pro-video-editing]] | Use for any video Claude edits or builds in code (shop ads, game edits, launch/motion-graphics videos, trend re-edits, collage trend edits). Beat grid first, real assets only (no placeholder UI), layered sound design, measured checks, critique loop. |
| [[Skills/quality-nerd-kid-sim/SKILL\|quality-nerd-kid-sim]] | Use when a Roblox map, world or UI will be judged by eye or might look cheap / AI-made: simulate a picky kid counting cheap tells vs wow moments and iterate until it looks hand-made. |
| [[Skills/roblox-3d-model-from-sheet/SKILL\|roblox-3d-model-from-sheet]] | Use when making a 3D model (shark, fish, creature, prop) for a Roblox game in the owner's Blender: ChatGPT design sheet first, then trace, check face landmarks and look, then export. |
| [[Skills/roblox-chatgpt-art-pipeline/SKILL\|roblox-chatgpt-art-pipeline]] | Use when making Roblox game art (icons, UI frames, decals, textures, VFX, flipbooks): Claude writes one-try ChatGPT prompts, runs them in Chrome, then cuts, cleans and uploads. |
| [[Skills/roblox-game-sounds/SKILL\|roblox-game-sounds]] | Use when a Roblox game needs sound effects for actions, animations, abilities, UI or ambience: generate our own in Fish Audio (owner's Chrome), process them in Python, upload them to Roblox, and wire them in. |
| [[Skills/roblox-game-video-pipeline/SKILL\|roblox-game-video-pipeline]] | Use when making a Roblox game video (TikTok/Shorts or the Roblox game-page video), or re-editing a trend video into a shop ad: record, cut on the beat, animate in Remotion, sound-design, check, deliver fast. |
| [[Skills/roblox-ui-pro/SKILL\|roblox-ui-pro]] | Use for ANY Roblox UI work: building, fixing, restyling or reviewing a HUD, shop, inventory, index, settings, popup, reward screen or menu. Correct ScreenGui setup (respawn, safe areas, phone/tablet/console, touch and gamepad), concrete design numbers, a house-style UI kit, AI-slop checks, and a Studio MCP loop that audits (`scripts/ui_audit.luau`) and screenshots the UI on real device sizes until it passes. Pairs with the art method in [[Best UI method (skill draft)]]. |
| [[Skills/roblox-icon-thumbnail/SKILL\|roblox-icon-thumbnail]] | Use when making or judging a Roblox game icon, thumbnail or logo: research what kids click, render the real avatar, one-try ChatGPT prompts, add the logo in code, and test at real sizes. |
| [[Skills/ytdlp-video-watch/SKILL\|ytdlp-video-watch]] | Use when the user shares a TikTok/YouTube/Shorts/Reels link or video to watch, break down or research: watch it in the browser (no download) or download with yt-dlp, extract frames, sound hits and transcript, then analyze. |
| play-roblox | (vault-only tool, not a synced Claude skill) |

## Log
- 2026-11-14: added roblox-ui-pro (SKILL.md + references/, scripts/ui_audit.luau, assets/UIKitStarter.luau). Built from gamedev-skills roblox-ui, afrxo's design numbers and izzyfrm's anti-slop list, then updated the same day with the Develuper UI video lessons (depth text, edge highlight, fade-slide, shop layout) and the MEGA BITE phone-audit lessons (tap floor, the game's own touch controls, tap areas on slim chips). Later on 14 Nov: the audit got smarter (24 px targets on mouse, CanvasGroup clipping, full-screen dims, plates that are siblings), plus the Studio-only bus hook for opening windows in tests, the mid-Play device sweep, and "phone windows are wide and short".
- 2026-11-13: added overstimulated-kid-sim; refreshed all 12 others from the live skills (pro-video-editing, roblox-chatgpt-art-pipeline, roblox-icon-thumbnail and ytdlp-video-watch had changed since the last copy).
