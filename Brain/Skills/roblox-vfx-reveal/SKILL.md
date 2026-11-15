---
name: roblox-vfx-reveal
description: "Use for Roblox VFX and big-moment effects: combat hit VFX (impact frames, screen shake, FOV punch, shockwaves, debris, flashes), RNG/egg/gacha rarity reveals with escalating tiers and a final cutscene, and reward title cards. Gives a tested client VFX kit (scripts/VFXKit.luau), the tier-ladder design, timing numbers, and a Studio loop to screenshot each effect. Use it even when the user only says 'make hits feel better', 'add VFX', 'the roll is boring', 'make the legendary drop hype', or shows a TikTok of someone's VFX."
---

# Roblox VFX + rarity reveals

Big moments sell the game in play and in TikToks. The two most-watched Roblox dev clips in the 16 Nov watch study were both VFX: a Claude-made combat VFX clip (324K views, 8 s) and a Roll a Ball RNG reveal ladder (628K views). Research note: vault `Roblox Playbook\Research notes\2026-11-16 Watch study - Claude Roblox VFX, exploded-diagram 3D, RNG reveal, UI design hacks.md`.

| File | Use |
|---|---|
| `scripts/VFXKit.luau` | Copy into ReplicatedStorage. Client-only effects: `impactFrame`, `shake`, `fovPunch`, `flash`, `shockwave`, `starburst`, `debris`, `titleCard`, `heavyHit`, `Tiers`, `reveal`, plus `oklch` colours. Tested 16 Nov in Studio Play. |

## 1. Plan the moment first
Write one line per moment: **event | what the player must feel | length | who sees it (self / everyone) | how often**.
- **Frequent** (every hit, every common roll): ≤ 0.3 s, no screen flash, no shake above 0.3, and never block input.
- **Rare** (heavy hit, legendary+): 0.5–1.5 s, flash + shake + title card.
- **Rarest** (top tier, first-ever, boss kill): its own cutscene, 3–6 s, **skippable by tap after the first time**.

Repeating a big effect too often kills it. Budget it like currency.

## 2. Architecture (the rules)
- **The server decides, every client plays.** The server rolls or validates the hit, then fires a RemoteEvent (`VFX:FireAllClients("HeavyHit", attacker, victim)`) or `FireClient` for self-only reveals. VFX are built on the client (local parts in `workspace.ClientVFX`), so the server never replicates hundreds of parts.
- **Never trust the client** for the result. The client only shows what the server sent.
- **Everything cleans itself up** (`Debris:AddItem`, `task.delay`). A leaked ColorCorrection or Highlight is a stuck screen.
- Impact frames add their **own** named ColorCorrectionEffect and destroy it. Never edit the game's grade (see `roblox-game-lighting`).
- **Max 31 Highlights render at once**: impact frames only highlight the fighters, never every NPC.
- Honour `GuiService.ReducedMotionEnabled`: no shake, no FOV punch, flashes become ≤ 0.1 s fades. The kit does this.
- Shake runs at `RenderPriority.Camera + 1` (after the camera scripts), or the camera module overwrites it.

## 3. Combat hit recipe (the "pro dev" clip look)
Order matters. The hit lands on frame 0:
1. **Impact frame** (`impactFrame(models, "red"|"white"|"invert", 0.06–0.1)`): the world goes one flat colour, the fighters become black silhouettes with a white rim. It's built from ColorCorrection (Saturation −1, Contrast 1, tint) and AlwaysOnTop Highlights. Longer than ~0.15 s and it stops reading as a "frame". For a combo finisher, use two impact frames 0.2 s apart with different styles (red then invert).
2. **Then, at the same instant:** shockwave on the floor + debris + shake 0.6–0.9 for 0.35 s + FOV punch +6.
3. **Then the residue:** sparks or particles fading over 0.5–1 s.
4. **Sound** on frame 0: a layered hit, transient + body + tail (`roblox-game-sounds`). The impact frame without a sound feels like a glitch.

`VFXKit.heavyHit(attacker, victim)` does steps 1–2.

## 4. Rarity reveal ladder (the RNG clip look)
- **Escalate on one axis per tier** so players feel the climb. In `VFXKit.Tiers`:
  - Common: colour only.
  - Rare: + a small starburst.
  - Epic: + a bigger burst and a little shake.
  - Legendary: + a flash.
  - Secret: + a stronger flash/shake and a darker background.
  - Top tier: a full cutscene.
- **Tier colours from OKLCH** at the same lightness (L 0.70–0.85, C 0.12–0.20), so every tier reads equally bright and only the effects get louder. Keep the same colours in the shop, index and chat messages.
- **Before the result:** a short build-up (0.6–1.2 s), e.g. an orb with "???" over the head, rising pitch, a slow pulse. Rarer results can hold the build-up longer (players learn "longer = better"), but never more than 2 s for common rolls.
- **The title card:**
  - the TIER word big, with depth text;
  - `[ SUBTITLE ]` in brackets;
  - the item name;
  - the odds line ("1 in 1,000").

  The odds make it a brag. Use `VFXKit.titleCard`.
- **Top-tier cutscene** (what made the RNG clip):
  - hide the HUD;
  - swap the scene: a dedicated stage, built in a ViewportFrame or a far-away lit room, or the sky turning;
  - **one line of story text** in a different font (serif/italic), e.g. "Every roll you ever made led here.";
  - a white flash;
  - the title card.

  3–6 s, and skippable after the first view.
- **Announce rare drops to the server:** a chat/system line plus a small toast for others. That's social proof and a reason to keep rolling.

## 5. Verify in Studio (the loop)
1. Start Play. In the Client datamodel, put the kit in ReplicatedStorage, `require` it, and call each effect on the local character.
   - Over MCP, create a ModuleScript and set its `Source`. `loadstring` is disabled in the client.
2. To screenshot short effects, call them with long durations (impact 4 s, starburst time 6, title hold 5), then `screen_capture`. Real durations are too short to catch.
3. Check:
   - silhouettes read;
   - the title is readable on a phone (Device Simulator, `samsung_galaxy_a06`);
   - Lighting has no leftover `VFXImpactCC` afterwards;
   - FOV is back to its base value;
   - no errors in the console.
4. Stop Play. Nothing in the place changes; do not save or publish without the owner's OK.

## 6. Known limits of the kit (16 Nov)
- The shockwave is a filled neon disc. For a ring, use a torus MeshPart or a circle of Beams.
- Starburst spikes are world parts, so an active impact-frame tint colours them too. Play them after the frame, as `heavyHit` does.
- No flipbook or texture VFX (slashes, smoke, energy swirls) yet. Make the sprites with the `roblox-chatgpt-art-pipeline` skill (flipbook sheets), then use `ParticleEmitter` with `FlipbookLayout`.
- Not tested on a real phone. Many neon parts at once can cost frames on low-end phones: keep starbursts ≤ 24 spikes.

## 7. Report + save
- A table: moment | tier/frequency | effects used | length | sound | screenshot.
- Save screenshots and the change log in the game's vault notes. If the effect is TikTok-worthy, hand an 8-second Studio capture idea to `roblox-game-video-pipeline`. A claim caption over a raw Studio capture is the format that worked.
