# Research - Sound skills for Claude (9 Nov 2026)

Owner: "so we need sound skill for u right, lets find it" (for the MEGA BITE shark animations).

| Found | What it is | Verdict |
|---|---|---|
| Owner's claude.ai skills / plugin directory | nothing for game SFX (only music generators, a web-UI sound pack, social-media tools) | none fit |
| zeveck/audiogen | ElevenLabs API: SFX, voice, music. Paid plan = commercial rights; free tier needs attribution | best AI option, but needs a paid ElevenLabs plan + the owner's API key |
| noizai sound-fx | Noiz text-to-sound API, cost and output licence not stated | skip (licence unclear) |
| popey game-audio | guidance only (mixing, ducking, categories) | the vault research already covers this |
| akillness game-sounds | sounds for the coding agent itself, not for games | not relevant |
| pyfxr / jfxr | sfxr-style synthesis libraries (code-made retro/UI sounds) | use for UI pops, bubbles, whooshes |
| Roblox Studio MCP `search_asset` (assetType Audio) | searches Creator Store audio from Claude | main source: licensed Roblox/partner SFX, free |

Decided: our own skill **roblox-game-sounds** (proposed 9 Nov): Creator Store audio via Studio first, own synthesis/CC0 second, ElevenLabs only after the owner approves a paid plan. Layering, variation, phone loudness (-16 to -18 LUFS), animation markers, a Sounds module.

Sources: skillsmp.com/skills/zeveck-audiogen-claude-skills-audiogen-skill-md, tessl.io/registry/skills/github/popey/claude-code-skills/game-audio, openskillindex.com/skills/noizai-skills-sound-fx, skills.sh/akillness/jeo-skills/game-sounds, pyfxr.readthedocs.io


## Update (owner 9 Nov, 15:07): "we can upload our own sounds too ... not elevenlabs lets use fish audio"
- Main source = **Fish Audio** sound effects, made in the web app (fish.audio/sound-effects) in the owner's Chrome. Its API and MCP (api.fish.audio/mcp, 47 tools) only cover speech, voices, images, video and Story Studio, with no sound-effect tool (docs checked 9 Nov). Paid plans include full commercial rights; confirm the owner's plan.
- We upload our OWN processed audio to the game's group. Creator Store audio is only a reference or stand-in. ElevenLabs is dropped.
- The skill roblox-game-sounds is updated to match.
Sources: https://fish.audio/sound-effects/ , https://docs.fish.audio/overview/mcp/tools.md , https://docs.fish.audio/overview/platform


## Fish Audio test (9 Nov, 15:17), checked in the app
- The owner's team is on the **Free plan**: 8,000 credits a month (7,944 left before the test).
- **One sound-effect generation costs 5,000 credits** whatever the length (1-60 s), steps (25-50) or guidance. One generation gives one take.
  - So the Free plan = 1 sound a month.
  - Plus ($5.5/mo billed yearly in the 9 Nov 50%-off offer, about $66 for the first year) = 250,000 credits, about 50 sound takes a month.
  - Pro ($37.5/mo yearly offer) = 2M credits.
- Commercial rights are only on paid plans, so free-plan takes are for testing only.
- Test take: "Cartoon shark bite ... CHOMP with a sharp teeth click ... bubbles ..." at 1.0 s. Measured result:
  - quiet (peak -26 dBFS);
  - flat noise for 0.45 s, with no transient spike (no real "chomp" hit);
  - energy 1-5 kHz.
  - Raw file: `MEGA BITE/Audio/raw/fish_bite_take1.wav`.
- Code-made chomps for comparison: `MEGA BITE/Audio/mb_bite_synth_v1-3.wav` (`synth.py`). Each has three layers: a teeth click, a falling jaw thump with crunch, and a low-passed bubble tail, at -15 LUFS. Comparison file: `MEGA BITE/Audio/bite_compare.mp3`.
- Plan: make the high-repeat sounds (bite, swim, dart, bubbles, UI) in code, and keep Fish Audio for a few signature sounds once there's a paid plan.
