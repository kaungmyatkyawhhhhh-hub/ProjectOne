---
tags: [brain, skills]
updated: 2026-11-17
---
# Skills index (Brain/Skills)
Back to [[00 BRAIN]]. Whole plugins (firecrawl, caveman, headroom, ponytail) are in [[00 Plugins index]]. Each folder holds the CURRENT copy of one of the owner's Claude skills (`<name>/SKILL.md` + any helper files).

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
| [[Skills/roblox-game-lighting/SKILL\|roblox-game-lighting]] | Use for ANY Roblox lighting or 'make my game look better' work: Lighting, Atmosphere, Bloom, SunRays, ColorCorrection, DepthOfField, sky, time of day, zone/biome moods, underwater and night looks, retro player outlines (Highlight) and random surface textures. Tested presets with exact numbers (incl. the Develuper 'look 10x better' stylized day and MEGA BITE's reef), a backup-first apply script, a read-only lighting snapshot/audit and a look check. |
| [[Skills/roblox-game-sounds/SKILL\|roblox-game-sounds]] | Use when a Roblox game needs sound effects for actions, animations, abilities, UI or ambience: generate our own in Fish Audio (owner's Chrome), process them in Python, upload them to Roblox, and wire them in. |
| [[Skills/roblox-game-video-pipeline/SKILL\|roblox-game-video-pipeline]] | Use when making a Roblox game video (TikTok/Shorts or the Roblox game-page video), or re-editing a trend video into a shop ad: record, cut on the beat, animate in Remotion, sound-design, check, deliver fast. |
| [[Skills/roblox-organic-marketing/SKILL\|roblox-organic-marketing]] | Use to get players without (or before) paid ads: a readiness gate (game page, thumbnail squint test, no AI-slop look), our own TikTok clip formats, a measured game-rec creator campaign (`scripts/creator_stats.js`, shortlist, brief, one code per creator), cost per new player vs ads. The owner sends and pays. |
| [[Skills/roblox-ui-pro/SKILL\|roblox-ui-pro]] | Use for ANY Roblox UI work: building, fixing, restyling or reviewing a HUD, shop, inventory, index, settings, popup, reward screen or menu. Correct ScreenGui setup (respawn, safe areas, phone/tablet/console, touch and gamepad), concrete design numbers, a house-style UI kit, AI-slop checks, and a Studio MCP loop that audits (`scripts/ui_audit.luau`) and screenshots the UI on real device sizes until it passes. Pairs with the art method in [[Best UI method (skill draft)]]. |
| [[Skills/roblox-icon-thumbnail/SKILL\|roblox-icon-thumbnail]] | Use when making or judging a Roblox game icon, thumbnail or logo: research what kids click, render the real avatar, one-try ChatGPT prompts, add the logo in code, and test at real sizes. |
| [[Skills/roblox-vfx-reveal/SKILL\|roblox-vfx-reveal]] | Use for Roblox VFX and big moments: combat hit VFX (impact frames, shake, FOV punch, shockwave, debris, flash), RNG/egg rarity reveal ladders with a top-tier cutscene, and reward title cards. Tested client kit `scripts/VFXKit.luau`. |
| [[Skills/what-if-animation/SKILL\|what-if-animation]] | Make a 15-25 s "What If" stick-figure animated episode from one topic line: script, free Piper voice, storyboard, Remotion/SVG animation, free synthesised sound, master to -14 LUFS. |
| [[Skills/ytdlp-video-watch/SKILL\|ytdlp-video-watch]] | Use when the user shares a TikTok/YouTube/Shorts/Reels link or video to watch, break down or research: watch it in the browser (no download) or download with yt-dlp, extract frames, sound hits and transcript, then analyze. |
| [[Skills/play-roblox/SKILL\|play-roblox]] | Play a Roblox game in the Roblox PLAYER on this Windows PC (not Studio): see the game, walk, turn the camera, click buttons and 3D boards, open menus, with our own rbx.exe. Use for researching other games, playtesting live games, or any "play this Roblox game" task. (Local skill in `~/.claude/skills`, not a synced one.) |

## Log
- 2026-11-18: roblox-ui-pro, owner correction: the v3 Figma kit (earthy colours, leaf sprigs, dark panel) was rejected with "the design sucks". The new rule is to copy Develuper's "UI 10x" style 1:1: white panel, green title bar, red Close text, a big hero card first, saturated tier-colour cards, green price pills, halftone, shine and edge highlight. The recipe is in Research notes "2026-11-18 Watch study - Develuper UI 10x (1-to-1 recipe)".
- 2026-11-18 (night, latest): owner correction on the Livyatan T6 runes ("these details should be modelled instead of just slapping on a texture"). **roblox-3d-model-from-sheet** (vault copy only): runes, glyphs and glow markings are now MODELLED raised solid inlays (resampled outline, ray-cast, extruded proud + sunk with walls, one winding per glyph, gated closed and outward), never flat decals. Uploaded to Claude as v6 the same day (owner: "update it"); this v6 also carries step 1a, which the synced installed copy was still missing. Plugin copy and vault copy now match.
- 2026-11-18 (night, later): owner correction "chatgpt one looks too ai ... use figma but do it like how the tiktok developers use it". **roblox-ui-pro** (local + vault): the default is now hand-built Figma vectors with the Develuper depth recipe, studied from real top-game UIs; ChatGPT art is not for UI. **roblox-chatgpt-art-pipeline** (vault copy only): an "overruled" note on the 18 Nov UI lessons. The installed plugin copy needs a re-upload by the owner.
- 2026-11-18 (night): **roblox-ui-pro** (local + vault): 9-slicing painted art. A frame with a centred crest smears when 9-sliced, so draw it whole with Stretch; ask for corner-only ornaments; new uploads show blank for a few minutes during moderation. Learned while building the EVOLVE art UI (see `EVOLVE/2026-11-18 EVOLVE - UI art (ChatGPT sandstone set).md`).
- 2026-11-18 (late): **roblox-3d-model-from-sheet** step 1a now covers EVERY model, creatures included (owner: "cover them"): split the creature into body, head, jaws, teeth, eyes, each fin and the tail, label them, mark hinge points for moving parts, and make the exploded sheet in the same turn as the turnaround sheet. Uploaded to Claude as v5 the same day (plugin copy and vault copy now match).
- 2026-11-18 (later): owner corrections on the Evolution UI written into the skills (new core rule: corrections go into the skill):
  - **roblox-ui-pro** (local + vault): code-built UI still looks AI, so make the art outside Studio (ChatGPT art won an A/B against Figma); size text in phone points (1334x750 mock = 2x); shops are item cards with big art, not text rows.
  - **roblox-chatgpt-art-pipeline** (vault copy only; the installed plugin copy needs a re-upload): new 18 Nov lessons section (themed frames, corner-only ornaments, the 4 sheets that make a whole shop, phone-point mockups, reliable ChatGPT typing via execCommand).
- 2026-11-18: owner dropped the "nothing over 449 R$" rule. Removed from dead-game-method (vault copy; the installed plugin copy still says it until re-uploaded) and from [[K04 Monetization and economy]]. Same day: "no paid random items" changed to "paid random items allowed, odds must be shown" (dead-game-method vault copy, K01, K04).
- 2026-11-17 (night): roblox-vfx-reveal kit fix (owner's no-sunburst rule):
  - VFXKit: the spike `starburst` is replaced by `glowBurst` (soft camera-facing halo, light pulse, drifting motes); `starburst` stays as an alias. `reveal()` uses it.
  - `uiBurst` lost its rays: soft glow, one thin ring, random motes.
  - Tested in Studio Play (Evolution place). SKILL.md sections 1 (files), 4, 5, 6 and 7 updated. Local and vault copies match.
- 2026-11-17 (late): roblox-vfx-reveal updated from the 16 Nov TikTok search rounds ([[Brain/Training inbox]], creators' claims, unverified):
  - Section 1: small moments get timing + sound + a small reaction ("make simple actions satisfying").
  - Section 2: pool frequent effects instead of create/destroy.
  - New section 2b "Don't look AI-made": what reads as AI VFX and the fixes.
  - Section 7: post work-in-progress VFX clips too.
  - Section 6: `starburst` breaks the owner's no-sunburst rule (kit change still pending).
  - Local and vault copies match.
- 2026-11-17: full check of every installed skill against the vault.
  - The 5 local skills in `~/.claude/skills` (play-roblox, roblox-game-lighting, roblox-organic-marketing, roblox-ui-pro, roblox-vfx-reveal) match the vault exactly, file for file.
  - All synced skills are in the vault. **The vault is NEWER** for pro-video-editing, roblox-3d-model-from-sheet, roblox-chatgpt-art-pipeline, roblox-game-sounds, roblox-icon-thumbnail and ytdlp-video-watch. The installed copies date from 7–10 Nov, so the owner still needs to re-upload those 6 to Claude.
  - The play-roblox row now has its link and description.
  - Anthropic's built-in skills (docx, pdf, pptx, xlsx, docs, skill-creator and the others) are left out on purpose: they are not ours.
- 2026-11-16 (night): **New: roblox-organic-marketing**, from [[2026-11-16 Watch study - Organic Roblox marketing TikToks]].
  - SKILL.md: gate, own clips, game-rec creator campaign, measuring, owner rules.
  - `references/templates.md`.
  - `scripts/creator_stats.js`: tested on a live TikTok profile in the built-in browser; reads the median views of the last 12 posts and the bio contact.
- 2026-11-16 (later): roblox-vfx-reveal and roblox-ui-pro updated after putting them into MM Outfit Catalog ([[2026-11-16 VFX + design pass - from the watch study]]):
  - **VFXKit:** `uiBurst`, a `flash` peak and a `titleCard` centre added; a "store and shop moments" section (roll reveal, purchase celebration sized in px, celebrate only real purchases).
  - **roblox-ui-pro:**
    - new `assets/UIFx.luau` (oklch, edgeFade, drawn heart, icon swap);
    - an edgeFade re-parenting note;
    - the async page render-token trap.
- 2026-11-16: **New: what-if-animation**, from FreshStack's open-source What If skill (MIT, github.com/kelano86/what-if-animation). ElevenLabs was swapped for free tools: `scripts/voice.py` uses Piper TTS with Whisper word timing, and the new `scripts/synth.py` synthesises every sound effect and the music bed (sfx.py calls it). Both were tested on the copy-paste example. Setup: Node 18+, ffmpeg, Python with numpy, Pillow, piper-tts and faster-whisper; the studio needs `npm install`.
- 2026-11-16: from the 4-TikTok watch study ([[2026-11-16 Watch study - Claude Roblox VFX, exploded-diagram 3D, RNG reveal, UI design hacks]]) and the MM Outfit Catalog fix pass:
  - **New: roblox-vfx-reveal**, with VFXKit tested in Studio Play.
  - **roblox-ui-pro:**
    - nested radius = outer − padding (fixed);
    - alpha strokes, OKLCH palettes and the helper, OKLCH gradient keypoints;
    - icon weight = text weight, CanvasGroup edge fade, icon-swap crossfade, dark-mode lighter surfaces;
    - traps: UIGradient tints text, BuilderSans lacks ✕✓★♥, children cover the parent's text, ViewportFrame BackgroundColor3 blending.
  - **roblox-game-lighting:**
    - LightingStyle is not script-writable (pcall everything);
    - ViewportFrame studios against the 4–12 s light warm-up;
    - neutralise the look for true colours;
    - the impact-frame ColorCorrection rule.
  - **roblox-3d-model-from-sheet:** step 1a, the exploded-view sheet for hard-surface props.
  - **roblox-game-sounds:** `scripts/make_ui_sounds.py`, the group batch-upload flow, the pooled Sounds module.
  - The last two are the vault copies only. The installed plugin versions still need re-uploading by the owner.
- 2026-11-14: roblox-ui-pro updated with the Shop phone lessons (fit a scrolling window by width, one button instead of two, short phone wording, touch-sized carousel arrows, applyMode).
- 2026-11-14: added roblox-game-lighting, built from the Develuper lighting video (vkEXLmRAQgs; values read frame by frame off his Properties panel) plus a live Lighting API probe in Studio. It has SKILL.md, references/ (presets, lighting-api, look-check) and scripts/ (lighting_snapshot, apply_preset with backup/restore, random_textures, retro_highlight). All four scripts were tested in MEGA BITE Play.
- 2026-11-14: added roblox-ui-pro (SKILL.md + references/, scripts/ui_audit.luau, assets/UIKitStarter.luau). Built from gamedev-skills roblox-ui, afrxo's design numbers and izzyfrm's anti-slop list, then updated the same day with the Develuper UI video lessons (depth text, edge highlight, fade-slide, shop layout) and the MEGA BITE phone-audit lessons (tap floor, the game's own touch controls, tap areas on slim chips). Later on 14 Nov: the audit got smarter (24 px targets on mouse, CanvasGroup clipping, full-screen dims, plates that are siblings), plus the Studio-only bus hook for opening windows in tests, the mid-Play device sweep, and "phone windows are wide and short".
- 2026-11-13: added overstimulated-kid-sim; refreshed all 12 others from the live skills (pro-video-editing, roblox-chatgpt-art-pipeline, roblox-icon-thumbnail and ytdlp-video-watch had changed since the last copy).
